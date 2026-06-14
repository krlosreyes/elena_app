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
///
/// El clock NO es campo del service — cada llamada (`evaluateAndApply`,
/// `bootstrapIfMissing`) recibe `now` en su input. Esto facilita testing
/// determinístico sin tener que inyectar un clock en el constructor.
class MetabolicCycleService {
  MetabolicCycleService({
    required MetabolicCycleRepository repository,
  }) : _repository = repository;

  final MetabolicCycleRepository _repository;

  // SPEC-214: flag de serialización. Previene que dos llamadas concurrentes
  // a evaluateAndApply (e.g., tap usuario + listener Riverpod) lean el
  // mismo openCycle y creen duplicados. La llamada concurrente devuelve
  // noop inmediatamente — el resultado es correcto porque evaluateAndApply
  // es idempotente: el in-flight ya está procesando el estado actual.
  bool _evaluating = false;

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Evalúa el estado actual contra el ciclo abierto y ejecuta cierre +
  /// apertura si corresponde. Idempotente: si no hay nada que hacer,
  /// retorna sin tocar Firestore.
  ///
  /// Retorna el resultado del check para que el caller (provider de UI)
  /// pueda reaccionar — `cycleClosed` indica que ocurrió un cierre, útil
  /// para disparar el card de cierre en Dashboard.
  ///
  /// SPEC-214: serializado — si ya hay una evaluación en curso, la llamada
  /// concurrente devuelve `noop` inmediatamente sin tocar Firestore.
  Future<MetabolicCycleCheckResult> evaluateAndApply({
    required String userId,
    required MetabolicCycleEvaluationInput input,
  }) async {
    if (_evaluating) {
      AppLogger.debug(
        '[cycle.evaluate.skip] evaluateAndApply ya en curso — '
        'llamada concurrente descartada (SPEC-214).',
      );
      return MetabolicCycleCheckResult.noop();
    }
    _evaluating = true;
    try {
    final openCycle = await _repository.fetchOpenCycle(userId);

    // Caso 1: no hay ciclo abierto — abrir uno nuevo si hay nuevo ayuno.
    if (openCycle == null) {
      if (input.newFastingStartedExplicitly &&
          input.newFastingStartedAt != null) {
        // SPEC-184 (2026-06-05): defensa contra apertura sospechosa.
        // Si el `newFastingStartedAt` difiere significativamente de
        // `now`, probablemente venimos del bootstrap del FastingNotifier
        // que NO debería haber pasado por aquí (cf. SPEC-183).
        // Loguear warning para que se vea en Crashlytics si vuelve a
        // pasar. Decision: NO bloqueamos la apertura (preservar
        // comportamiento legítimo de "viaje en el tiempo" via
        // startFastingManual) pero la marcamos.
        final deltaMinutes =
            input.now.difference(input.newFastingStartedAt!).inMinutes.abs();
        if (deltaMinutes > 5) {
          AppLogger.warning(
            '[cycle.open.suspicious] startedAt difiere de now por '
            '${deltaMinutes}min. Posible bootstrap mal etiquetado '
            'o viaje en el tiempo legítimo. '
            'Ver docs/METABOLIC_DAY_CONSTITUTION.md §5.',
          );
        }
        final fresh = MetabolicCycleResolver.openCycle(
          startedAt: input.newFastingStartedAt!,
          fastingProtocol: input.currentProtocol,
          tzOffsetMinutes: input.tzOffsetMinutes,
        );
        _persistCycle(userId, fresh);
        // SPEC-184: log estructurado con motivo. Permite reconstruir el
        // historial de aperturas desde Crashlytics sin tocar Firestore.
        AppLogger.info(
          '[cycle.open] cycleId=${fresh.cycleId} '
          'startedAt=${fresh.startedAt.toIso8601String()} '
          'protocol=${fresh.fastingProtocol} '
          'source=userInitiated',
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
    _persistCycle(userId, closed);
    // SPEC-184: log estructurado del cierre. Incluye reason, duración
    // del ayuno y duración de ventana para diagnóstico rápido. Ver
    // docs/METABOLIC_DAY_CONSTITUTION.md §6.
    final cycleDurationHours =
        closeTime.difference(openCycle.startedAt).inMinutes / 60.0;
    AppLogger.info(
      '[cycle.close] cycleId=${closed.cycleId} '
      'closedAt=${closeTime.toIso8601String()} '
      'reason=${reason.value} '
      'durationHours=${cycleDurationHours.toStringAsFixed(2)} '
      'score=${closed.dailyScore}',
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
      _persistCycle(userId, opened);
      // SPEC-184: log estructurado de re-apertura encadenada.
      AppLogger.info(
        '[cycle.open] cycleId=${opened.cycleId} '
        'startedAt=${opened.startedAt.toIso8601String()} '
        'protocol=${opened.fastingProtocol} '
        'source=chainedAfterClose',
      );
    } else if (reason == ClosureReason.protocolChanged) {
      // Tras cambio de protocolo, abrir un ciclo nuevo con el nuevo
      // protocolo a partir de ahora.
      opened = MetabolicCycleResolver.openCycle(
        startedAt: input.now,
        fastingProtocol: input.currentProtocol,
        tzOffsetMinutes: input.tzOffsetMinutes,
      );
      _persistCycle(userId, opened);
      // SPEC-184: log estructurado de re-apertura por cambio de protocolo.
      AppLogger.info(
        '[cycle.open] cycleId=${opened.cycleId} '
        'startedAt=${opened.startedAt.toIso8601String()} '
        'protocol=${opened.fastingProtocol} '
        'source=protocolChanged',
      );
    }

    return MetabolicCycleCheckResult.closed(closed: closed, opened: opened);
    } finally {
      // SPEC-214: siempre liberar el flag, incluso si el método lanzó.
      _evaluating = false;
    }
  }

  /// SPEC-206 (offline-first): persiste un ciclo SIN bloquear en el ack del
  /// servidor. El `.set()` subyacente escribe en la caché local al instante
  /// → el listener `watchOpenCycle` emite enseguida y los pilares se re-anclan
  /// en tiempo real al nuevo límite, ONLINE U OFFLINE. Sincroniza al
  /// reconectar.
  ///
  /// Con `await` (como antes), offline el Future del write NO resolvía: el
  /// cierre del ciclo colgaba y la apertura del ciclo nuevo NUNCA corría →
  /// quedaba sin ciclo abierto → los pilares caían al fallback de reloj
  /// (medianoche) y MEZCLABAN dos días metabólicos. Ver SPEC-206 §3.
  void _persistCycle(String userId, MetabolicCycle cycle) {
    unawaited(
      _repository.save(userId, cycle).catchError((Object e) {
        AppLogger.warning(
          '[cycle.persist] save de ${cycle.cycleId} falló '
          '(se reintenta al sincronizar): $e',
        );
      }),
    );
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

    // SPEC-185 + SPEC-189 (2026-06-05): NO crear ciclo sin ayuno
    // persistido. Cumple §1 + §2 de la Constitución del Día Metabólico
    // (docs/METABOLIC_DAY_CONSTITUTION.md): el ÚNICO evento que crea
    // ciclo es el tap consciente del usuario en "Iniciar ayuno".
    //
    // SPEC-189: eliminado el branch `useCalendarFallback` que creaba
    // ciclo con `DateTime(now.year, now.month, now.day)` (medianoche
    // calendárica). Ese branch contaminaba el modelo con el reloj.
    //
    // Política: si no hay ayuno real persistido, NO inventar uno.
    // El primer tap legítimo del usuario lo creará en el evaluator
    // (SPEC-183 garantiza `source=userInitiated`).
    if (lastFastingStartTime == null) {
      AppLogger.info(
        '[cycle.bootstrap.skip] no hay lastFastingStartTime '
        'persistido → no creamos ciclo. El próximo tap "Iniciar ayuno" '
        'lo creará legítimamente. Ver §1+§2 METABOLIC_DAY_CONSTITUTION.md',
      );
      return null;
    }

    final startedAt = lastFastingStartTime;

    final cycle = MetabolicCycleResolver.openCycle(
      startedAt: startedAt,
      fastingProtocol: protocol,
      tzOffsetMinutes: tzOffsetMinutes,
    );
    _persistCycle(userId, cycle);
    // SPEC-184: log estructurado del bootstrap one-shot. Este es el
    // único caso legítimo en que el sistema crea ciclo sin tap directo
    // del usuario — el contrato es: solo al primer login con ayuno
    // persistido, para reconstruir el ciclo retroactivo. NO debe
    // repetirse en bootstraps posteriores (porque `existing != null`).
    AppLogger.info(
      '[cycle.open] cycleId=${cycle.cycleId} '
      'startedAt=${cycle.startedAt.toIso8601String()} '
      'protocol=${cycle.fastingProtocol} '
      'source=bootstrapOneShot',
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
