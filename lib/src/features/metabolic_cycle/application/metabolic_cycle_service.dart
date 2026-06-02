// SPEC-149 §RF-149-06: MetabolicCycleService — orquestador del Día Metabólico.
//
// Responsabilidades:
// - Mantener vivo el listener de fasting/sleep/nutrition + metabolic pulse.
// - En cada tick: evaluar MetabolicCycleResolver.shouldClose con el state actual.
// - Si dispara: construir feedback + ciclo cerrado + persistir + abrir nuevo.
// - Persistir apertura cuando se detecta inicio de nuevo ayuno.
//
// CONSTITUTION §3.2: no importa cloud_firestore. Depende solo de la
// interfaz MetabolicCycleRepository.
//
// El clock es inyectable para tests.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/cycle_feedback.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle_repository.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle_resolver.dart';

/// Entrada de datos del momento del check para decidir cierre + cómputo
/// del feedback. Permite que el caller arme el snapshot con su lógica
/// (FastingNotifier, SleepNotifier, etc.) sin acoplar al service.
class MetabolicCycleEvaluationInput {
  final DateTime now;
  final String currentProtocol;
  final DateTime? expectedWindowCloseTime;
  final DateTime? lastMealTime;
  final bool sleepDetectedAfterLastMeal;
  final bool newFastingStartedExplicitly;
  final DateTime? newFastingStartedAt;

  /// Magnitudes actuales de los 5 pilares. Se usan para construir el
  /// feedback al cerrar.
  final CycleMagnitudes currentMagnitudes;

  /// Score 0-100 actual del Día (deriva del provider SPEC-140).
  final int currentDailyScore;

  /// Estado boolean de cada pilar (≥0.80 = true).
  final CyclePillarsCompleted currentPillarsCompleted;

  /// Hora de cierre real de la ventana de alimentación (último log de
  /// nutrición + cierre del protocolo). Usado en feedback achievements.
  final DateTime? actualWindowClosedAt;

  /// IDs de insights recientes para evitar repetir.
  final Set<String> recentInsightIds;

  /// Tz offset del usuario para crear nuevos ciclos. Defaults a 0.
  final int tzOffsetMinutes;

  const MetabolicCycleEvaluationInput({
    required this.now,
    required this.currentProtocol,
    required this.currentDailyScore,
    required this.currentMagnitudes,
    required this.currentPillarsCompleted,
    this.expectedWindowCloseTime,
    this.lastMealTime,
    this.sleepDetectedAfterLastMeal = false,
    this.newFastingStartedExplicitly = false,
    this.newFastingStartedAt,
    this.actualWindowClosedAt,
    this.recentInsightIds = const {},
    this.tzOffsetMinutes = 0,
  });
}

/// Servicio orquestador. Singleton por sesión (Provider sin autoDispose).
class MetabolicCycleService {
  MetabolicCycleService({
    required MetabolicCycleRepository repository,
    DateTime Function() clock = _systemClock,
  })  : _repository = repository,
        _clock = clock;

  final MetabolicCycleRepository _repository;
  final DateTime Function() _clock;

  static DateTime _systemClock() => DateTime.now();

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Evalúa el estado actual contra el ciclo abierto y ejecuta cierre +
  /// apertura si corresponde. Idempotente: si no hay nada que hacer,
  /// retorna sin tocar Firestore.
  ///
  /// Retorna el resultado del check para que el caller (provider de UI)
  /// pueda reaccionar — `cycleClosed` indica que ocurrió un cierre, útil
  /// para disparar el card de cierre en Dashboard.
  Future<MetabolicCycleCheckResult> evaluateAndApply({
    required String userId,
    required MetabolicCycleEvaluationInput input,
  }) async {
    final openCycle = await _repository.fetchOpenCycle(userId);

    // Caso 1: no hay ciclo abierto — abrir uno nuevo si hay nuevo ayuno.
    if (openCycle == null) {
      if (input.newFastingStartedExplicitly &&
          input.newFastingStartedAt != null) {
        final fresh = MetabolicCycleResolver.openCycle(
          startedAt: input.newFastingStartedAt!,
          fastingProtocol: input.currentProtocol,
          tzOffsetMinutes: input.tzOffsetMinutes,
        );
        await _repository.save(userId, fresh);
        AppLogger.info(
          '[metabolicCycle] Abierto nuevo ciclo ${fresh.cycleId} '
          '(protocol ${fresh.fastingProtocol})',
        );
        return MetabolicCycleCheckResult.opened(fresh);
      }
      return MetabolicCycleCheckResult.noop();
    }

    // Caso 2: hay ciclo abierto — chequear si debe cerrarse.
    final reason = MetabolicCycleResolver.shouldClose(
      openCycle: openCycle,
      now: input.now,
      currentProtocol: input.currentProtocol,
      expectedWindowCloseTime: input.expectedWindowCloseTime,
      lastMealTime: input.lastMealTime,
      sleepDetectedAfterLastMeal: input.sleepDetectedAfterLastMeal,
      newFastingStartedExplicitly: input.newFastingStartedExplicitly,
      newFastingStartedAt: input.newFastingStartedAt,
    );

    if (reason == null) {
      return MetabolicCycleCheckResult.noop();
    }

    // Cierre: construir feedback + ciclo cerrado + persistir.
    final closeTime = _determineCloseTime(reason, input, openCycle);
    final feedback = CycleFeedbackGenerator.generate(
      magnitudes: input.currentMagnitudes,
      fastingDurationHours: _computeFastingHours(openCycle, input),
      feedingWindowHours: _computeFeedingHours(input),
      windowClosedAt: input.actualWindowClosedAt,
      recentInsightIds: input.recentInsightIds,
    );

    final closed = openCycle.close(
      closedAt: closeTime,
      reason: reason,
      fastingDurationHours: _computeFastingHours(openCycle, input),
      feedingWindowHours: _computeFeedingHours(input),
      dailyScore: input.currentDailyScore,
      pillarsCompleted: input.currentPillarsCompleted,
      magnitudes: input.currentMagnitudes,
      feedback: feedback,
    );
    await _repository.save(userId, closed);
    AppLogger.info(
      '[metabolicCycle] Cerrado ciclo ${closed.cycleId} '
      'razón=${reason.value} score=${closed.dailyScore}',
    );

    // Si el cierre fue por nuevo ayuno explícito, abrir el siguiente.
    MetabolicCycle? opened;
    if (reason == ClosureReason.manualNextFasting &&
        input.newFastingStartedAt != null) {
      opened = MetabolicCycleResolver.openCycle(
        startedAt: input.newFastingStartedAt!,
        fastingProtocol: input.currentProtocol,
        tzOffsetMinutes: input.tzOffsetMinutes,
      );
      await _repository.save(userId, opened);
      AppLogger.info(
        '[metabolicCycle] Abierto siguiente ciclo ${opened.cycleId}',
      );
    } else if (reason == ClosureReason.protocolChanged) {
      // Tras cambio de protocolo, abrir un ciclo nuevo con el nuevo
      // protocolo a partir de ahora.
      opened = MetabolicCycleResolver.openCycle(
        startedAt: input.now,
        fastingProtocol: input.currentProtocol,
        tzOffsetMinutes: input.tzOffsetMinutes,
      );
      await _repository.save(userId, opened);
      AppLogger.info(
        '[metabolicCycle] Abierto ciclo post-protocolChanged ${opened.cycleId}',
      );
    }

    return MetabolicCycleCheckResult.closed(closed: closed, opened: opened);
  }

  /// One-shot al bootstrap: si el usuario no tiene ciclo abierto pero
  /// tiene un protocolo activo y un ayuno en curso, crear ciclo
  /// retroactivo con startedAt del ayuno.
  ///
  /// Si el usuario tiene protocolo "Ninguno", abre ciclo calendárico
  /// con startedAt = inicio del día local de [now].
  Future<MetabolicCycle?> bootstrapIfMissing({
    required String userId,
    required String protocol,
    required DateTime? lastFastingStartTime,
    required DateTime now,
    int tzOffsetMinutes = 0,
  }) async {
    final existing = await _repository.fetchOpenCycle(userId);
    if (existing != null) return existing;

    DateTime startedAt;
    if (MetabolicCycleResolver.useCalendarFallback(protocol)) {
      startedAt = DateTime(now.year, now.month, now.day);
    } else {
      startedAt = lastFastingStartTime ?? now;
    }

    final cycle = MetabolicCycleResolver.openCycle(
      startedAt: startedAt,
      fastingProtocol: protocol,
      tzOffsetMinutes: tzOffsetMinutes,
    );
    await _repository.save(userId, cycle);
    AppLogger.info(
      '[metabolicCycle] Bootstrap creó ciclo inicial ${cycle.cycleId} '
      '(protocol $protocol)',
    );
    return cycle;
  }

  // ─── Lógica interna ──────────────────────────────────────────────────────

  DateTime _determineCloseTime(
    ClosureReason reason,
    MetabolicCycleEvaluationInput input,
    MetabolicCycle openCycle,
  ) {
    switch (reason) {
      case ClosureReason.manualNextFasting:
        return input.newFastingStartedAt ?? input.now;
      case ClosureReason.fallbackSleepDetected:
        // El close se ancla al lastMealTime + grace para no perder los
        // datos de hidratación que pudo haber ocurrido entre comida y
        // sueño. Usamos `now` por simplicidad.
        return input.now;
      case ClosureReason.fallbackCalendar:
        return MetabolicCycleResolver.calendarFallbackCloseAt(input.now);
      case ClosureReason.fallback3hAfterWindow:
      case ClosureReason.fallbackAbsolute:
      case ClosureReason.protocolChanged:
        return input.now;
    }
  }

  double? _computeFastingHours(
    MetabolicCycle openCycle,
    MetabolicCycleEvaluationInput input,
  ) {
    // Si tenemos el lastMealTime y la ventana abrió después del
    // startedAt del ciclo, podemos calcular las horas de ayuno reales.
    // Por simplicidad de Bloque B, usamos magnitud * 16h como
    // aproximación. Bloque C/SPEC-149.next puede refinar con datos
    // reales del FastingInterval.
    final mag = input.currentMagnitudes.fastingMagnitude.clamp(0.0, 1.5);
    final targetHours = _hoursFromProtocol(input.currentProtocol);
    if (targetHours == null) return null;
    return mag * targetHours;
  }

  double? _computeFeedingHours(MetabolicCycleEvaluationInput input) {
    final targetHours = _hoursFromProtocol(input.currentProtocol);
    if (targetHours == null) return null;
    return 24 - targetHours;
  }

  double? _hoursFromProtocol(String protocol) {
    switch (protocol) {
      case '12:12':
        return 12;
      case '14:10':
        return 14;
      case '16:8':
        return 16;
      case '18:6':
        return 18;
      case '20:4':
        return 20;
      case '22:2':
        return 22;
      case 'OMAD':
        return 23;
      case 'Ninguno':
        return null;
      default:
        return null;
    }
  }
}

/// Resultado de una evaluación del service. Útil para que el provider
/// de UI sepa si debe disparar el card de cierre o esperar.
class MetabolicCycleCheckResult {
  /// Ciclo recién cerrado, si hubo cierre.
  final MetabolicCycle? closed;

  /// Ciclo recién abierto, si la apertura ocurrió como side-effect.
  final MetabolicCycle? opened;

  const MetabolicCycleCheckResult._({this.closed, this.opened});

  factory MetabolicCycleCheckResult.noop() =>
      const MetabolicCycleCheckResult._();

  factory MetabolicCycleCheckResult.opened(MetabolicCycle cycle) =>
      MetabolicCycleCheckResult._(opened: cycle);

  factory MetabolicCycleCheckResult.closed({
    required MetabolicCycle closed,
    MetabolicCycle? opened,
  }) =>
      MetabolicCycleCheckResult._(closed: closed, opened: opened);

  bool get isNoop => closed == null && opened == null;
  bool get hasClosure => closed != null;
  bool get hasOpening => opened != null;
}
