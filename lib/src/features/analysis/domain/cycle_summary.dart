// SPEC-192.1 (2026-06-05): vista cycle-aware del resumen de un ciclo
// metabólico cerrado.
//
// Análogo a `DailySummaryDoc` pero indexado por `cycleId` en lugar
// de `date` calendárico. Cumple METABOLIC_DAY_CONSTITUTION.md §1
// (cero referencia al reloj).
//
// IMPORTANTE — Versión light de SPEC-192 (B):
// Este value object NO se persiste en Firestore por ahora. Se deriva
// al vuelo desde `MetabolicCycle.feedback.magnitudes` (que ya se
// persiste al cierre del ciclo en SPEC-149 §RF-149-08). Si en el
// futuro se hace SPEC-192.2 + 192.5, una collection `cycle_summary`
// reemplaza esta derivación con persistencia real.
//
// Pure Dart — sin Flutter ni Riverpod.

class CycleSummaryDoc {
  /// ID canónico del ciclo cerrado. Formato ISO 8601 UTC del startedAt.
  /// Coincide con `MetabolicCycle.cycleId`.
  final String cycleId;

  /// Inicio del ciclo (`startedAt` del MetabolicCycle).
  final DateTime startedAt;

  /// Cierre del ciclo (`closedAt` del MetabolicCycle, no-null para summary).
  final DateTime closedAt;

  /// Score del Día calculado al cierre del ciclo (0-100).
  final int imrScore;

  /// Magnitudes consolidadas por pilar (0.0-1.0).
  final double fastingMagnitude;
  final double sleepQualityScore;
  final double hydrationMagnitude;
  final double exerciseMagnitude;
  final double nutritionMagnitude;

  /// Protocolo de ayuno activo en el ciclo. Útil para analítica filtrada.
  final String fastingProtocol;

  /// Duración del ayuno en horas (decimal).
  final double? fastingDurationHours;

  /// Duración de la ventana de alimentación en horas (decimal).
  final double? feedingWindowHours;

  const CycleSummaryDoc({
    required this.cycleId,
    required this.startedAt,
    required this.closedAt,
    required this.imrScore,
    required this.fastingMagnitude,
    required this.sleepQualityScore,
    required this.hydrationMagnitude,
    required this.exerciseMagnitude,
    required this.nutritionMagnitude,
    required this.fastingProtocol,
    this.fastingDurationHours,
    this.feedingWindowHours,
  });

  /// Duración total del ciclo en horas decimales.
  double get cycleDurationHours =>
      closedAt.difference(startedAt).inMinutes / 60.0;
}
