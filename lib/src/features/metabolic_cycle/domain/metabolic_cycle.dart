// SPEC-149: MetabolicCycle — un Día Metabólico.
//
// Ciclo de duración variable (típicamente 22-28h) anclado al inicio del
// ayuno del usuario. Reemplaza semánticamente al "día calendárico" para
// el cómputo del Score del Día y el coaching de cierre, sin tocar la
// persistencia legacy de daily_summary.
//
// El cycleId se construye desde el ISO timestamp de startedAt — esto
// garantiza idempotencia: dos clientes que reciben el mismo
// FastingInterval inicial calculan el mismo cycleId y convergen en
// Firestore.
//
// Dart puro, sin Flutter, sin Firestore. La serialización vive en el
// repository.

import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/cycle_feedback.dart';

class MetabolicCycle {
  /// ID único del ciclo. Formato canónico: ISO timestamp del startedAt
  /// en UTC. Ejemplo: '2026-06-01T21:00:00.000Z'.
  final String cycleId;

  /// Momento exacto del inicio del ayuno que abre este ciclo.
  final DateTime startedAt;

  /// Momento del cierre. Null mientras el ciclo está abierto.
  final DateTime? closedAt;

  /// Razón del cierre. Null si está abierto.
  final ClosureReason? closureReason;

  /// Duración del ayuno completado en horas decimales. Null mientras
  /// abierto. Para usuarios calendáricos puede ser null al cierre si
  /// nunca hubo ayuno explícito.
  final double? fastingDurationHours;

  /// Duración de la ventana de alimentación en horas decimales. Null
  /// mientras abierto.
  final double? feedingWindowHours;

  /// Score del Día final del ciclo (0-100). Null mientras abierto.
  final int? dailyScore;

  /// Estado de cada pilar al cierre. Null mientras abierto.
  final CyclePillarsCompleted? pillarsCompleted;

  /// Magnitudes específicas de cada pilar al cierre. Null mientras abierto.
  final CycleMagnitudes? magnitudes;

  /// Coaching feedback generado al cierre. Null mientras abierto.
  final CycleFeedback? feedback;

  /// Protocolo de ayuno del usuario en el momento de creación del ciclo.
  /// Persistido por ciclo para que análisis pueda filtrar por protocolo
  /// histórico aunque el usuario cambie.
  final String fastingProtocol;

  /// Offset de zona horaria en minutos del usuario al crear el ciclo.
  /// Soporte para usuarios viajeros + reconstrucción de hora local.
  final int tzOffsetMinutes;

  /// SPEC-227: score en vivo del ciclo abierto. El evaluador lo stampa
  /// cada ~10s. Al cierre, `MetabolicCycleService` lo usa como fuente
  /// canónica en lugar de leer el score de los providers en vivo, que
  /// pueden estar stale por el ordering de listeners Riverpod.
  /// Solo presente en ciclos abiertos; `close()` no lo propaga.
  final int? liveScore;

  const MetabolicCycle({
    required this.cycleId,
    required this.startedAt,
    this.closedAt,
    this.closureReason,
    this.fastingDurationHours,
    this.feedingWindowHours,
    this.dailyScore,
    this.pillarsCompleted,
    this.magnitudes,
    this.feedback,
    required this.fastingProtocol,
    required this.tzOffsetMinutes,
    this.liveScore,
  });

  /// True si el ciclo está abierto (sin closedAt).
  bool get isOpen => closedAt == null;

  /// True si el ciclo está cerrado.
  bool get isClosed => closedAt != null;

  /// Duración total del ciclo. Null si está abierto.
  Duration? get totalDuration => closedAt?.difference(startedAt);

  /// Construye un cycleId canónico desde un timestamp.
  /// Usa el ISO 8601 en UTC para garantizar idempotencia cross-device.
  static String buildCycleId(DateTime startedAt) =>
      startedAt.toUtc().toIso8601String();

  /// Crea un ciclo abierto. Útil para los gatillos de apertura.
  factory MetabolicCycle.open({
    required DateTime startedAt,
    required String fastingProtocol,
    required int tzOffsetMinutes,
  }) {
    return MetabolicCycle(
      cycleId: buildCycleId(startedAt),
      startedAt: startedAt,
      fastingProtocol: fastingProtocol,
      tzOffsetMinutes: tzOffsetMinutes,
    );
  }

  /// SPEC-260 (2026-07-30): re-ancla un ciclo ABIERTO a un nuevo
  /// `startedAt` sin cerrarlo ni tocar el progreso de los pilares.
  ///
  /// Caso de uso: el usuario corrige la hora de inicio de su ayuno
  /// ("empecé a las 21:15 pero lo registré al despertar"). El Día
  /// Metabólico debe seguir esa corrección — su ancla ES el inicio del
  /// ayuno (ver METABOLIC_DAY_CONSTITUTION.md §2) — pero mover el ancla
  /// NO debe reiniciar hidratación/nutrición/ejercicio/sueño: esos
  /// pilares viven en el StreakEntry del día, no en el ciclo, y solo se
  /// resetean en el path de cierre+apertura (`triggerDailyReset`). Este
  /// método evita ese path a propósito.
  ///
  /// Decisión de diseño — `cycleId` SE PRESERVA: aunque el formato
  /// canónico del id es el ISO de `startedAt` (idempotencia cross-device
  /// al ABRIR), re-anclar es una acción deliberada de UN dispositivo.
  /// Mantener el mismo id garantiza que el `save` (merge sobre
  /// `doc(cycleId)`) actualice el MISMO documento en vez de crear uno
  /// nuevo y dejar el anterior abierto (dos ciclos abiertos = data
  /// malformada). El invariante id==ISO(startedAt) se relaja solo para
  /// ciclos corregidos a mano, sin consecuencias funcionales: los streams
  /// ordenan por el CAMPO `startedAt`, no por el id del documento.
  ///
  /// Lanza [StateError] si el ciclo ya está cerrado (no se re-ancla un
  /// ciclo histórico) y [ArgumentError] si `newStartedAt` es futuro
  /// respecto a [now] cuando se provee.
  MetabolicCycle reanchor({
    required DateTime newStartedAt,
    DateTime? now,
  }) {
    if (isClosed) {
      throw StateError(
        'No se puede re-anclar un ciclo cerrado (cycleId: $cycleId).',
      );
    }
    if (now != null && newStartedAt.isAfter(now)) {
      throw ArgumentError(
        'newStartedAt ($newStartedAt) no puede ser futuro respecto a $now.',
      );
    }
    return MetabolicCycle(
      cycleId: cycleId,
      startedAt: newStartedAt,
      // closedAt/closureReason/etc. permanecen null: sigue ABIERTO.
      fastingProtocol: fastingProtocol,
      tzOffsetMinutes: tzOffsetMinutes,
      liveScore: liveScore,
    );
  }

  /// Devuelve una copia cerrada del ciclo con los datos del momento del
  /// cierre. NO muta este objeto (preservamos inmutabilidad).
  MetabolicCycle close({
    required DateTime closedAt,
    required ClosureReason reason,
    required double? fastingDurationHours,
    required double? feedingWindowHours,
    required int dailyScore,
    required CyclePillarsCompleted pillarsCompleted,
    required CycleMagnitudes magnitudes,
    required CycleFeedback feedback,
  }) {
    if (!closedAt.isAfter(startedAt)) {
      throw ArgumentError(
        'closedAt ($closedAt) debe ser posterior a startedAt ($startedAt)',
      );
    }
    if (dailyScore < 0 || dailyScore > 100) {
      throw ArgumentError('dailyScore fuera de rango [0, 100]: $dailyScore');
    }
    return MetabolicCycle(
      cycleId: cycleId,
      startedAt: startedAt,
      closedAt: closedAt,
      closureReason: reason,
      fastingDurationHours: fastingDurationHours,
      feedingWindowHours: feedingWindowHours,
      dailyScore: dailyScore,
      pillarsCompleted: pillarsCompleted,
      magnitudes: magnitudes,
      feedback: feedback,
      fastingProtocol: fastingProtocol,
      tzOffsetMinutes: tzOffsetMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetabolicCycle &&
          cycleId == other.cycleId &&
          startedAt == other.startedAt &&
          closedAt == other.closedAt;

  @override
  int get hashCode => Object.hash(cycleId, startedAt, closedAt);

  @override
  String toString() =>
      'MetabolicCycle(id: $cycleId, isOpen: $isOpen, score: $dailyScore)';
}

/// Estado de cada pilar al cierre del ciclo. Booleanos true si el pilar
/// alcanzó el umbral de "completado" (magnitud ≥0.80 por convención
/// SPEC-149 §RF-149-03).
class CyclePillarsCompleted {
  final bool fasting;
  final bool sleep;
  final bool hydration;
  final bool exercise;
  final bool nutrition;

  const CyclePillarsCompleted({
    required this.fasting,
    required this.sleep,
    required this.hydration,
    required this.exercise,
    required this.nutrition,
  });

  /// Conteo de pilares completados (0-5).
  int get count =>
      (fasting ? 1 : 0) +
      (sleep ? 1 : 0) +
      (hydration ? 1 : 0) +
      (exercise ? 1 : 0) +
      (nutrition ? 1 : 0);

  /// True si los 5 pilares están en true — "día perfecto" del ciclo.
  bool get isPerfect => count == 5;

  @override
  bool operator ==(Object other) =>
      other is CyclePillarsCompleted &&
      fasting == other.fasting &&
      sleep == other.sleep &&
      hydration == other.hydration &&
      exercise == other.exercise &&
      nutrition == other.nutrition;

  @override
  int get hashCode =>
      Object.hash(fasting, sleep, hydration, exercise, nutrition);
}

/// Magnitudes continuas (0.0-1.0+) de cada pilar al cierre. Útiles para
/// generar feedback contextual y para que SPEC-141 (IMR longitudinal)
/// pueda reconstruir el behaviorTrend30 desde ciclos.
class CycleMagnitudes {
  final double fastingMagnitude;
  final double sleepQualityScore;
  final double hydrationMagnitude;
  final double exerciseMagnitude;
  final double nutritionMagnitude;

  const CycleMagnitudes({
    required this.fastingMagnitude,
    required this.sleepQualityScore,
    required this.hydrationMagnitude,
    required this.exerciseMagnitude,
    required this.nutritionMagnitude,
  });

  /// Magnitud más baja del ciclo y su nombre. Útil para identificar el
  /// "pilar más débil" del coaching.
  ({String pillar, double magnitude}) get weakest {
    var minPillar = 'fasting';
    var minMag = fastingMagnitude;
    if (sleepQualityScore < minMag) {
      minPillar = 'sleep';
      minMag = sleepQualityScore;
    }
    if (hydrationMagnitude < minMag) {
      minPillar = 'hydration';
      minMag = hydrationMagnitude;
    }
    if (exerciseMagnitude < minMag) {
      minPillar = 'exercise';
      minMag = exerciseMagnitude;
    }
    if (nutritionMagnitude < minMag) {
      minPillar = 'nutrition';
      minMag = nutritionMagnitude;
    }
    return (pillar: minPillar, magnitude: minMag);
  }
}
