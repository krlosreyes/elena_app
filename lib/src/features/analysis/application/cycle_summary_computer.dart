// SPEC-192.1 (2026-06-05): mapper puro de `MetabolicCycle` cerrado a
// `CycleSummaryDoc`.
//
// Estrategia "schema completo light" (B acotada):
// - El cycle.feedback.magnitudes YA contiene los valores consolidados
//   por pilar al momento del cierre (SPEC-149 §RF-149-08).
// - Este computer simplemente expone esa data en una shape coherente
//   con el modelo cycle-aware.
// - NO computa magnitudes desde logs raw — eso ya lo hizo el evaluator
//   al cierre del ciclo.
//
// Pure Dart. Determinístico. Idempotente.

import 'package:elena_app/src/features/analysis/domain/cycle_summary.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

class CycleSummaryComputer {
  CycleSummaryComputer._();

  /// Mapea un `MetabolicCycle` cerrado a `CycleSummaryDoc`.
  ///
  /// Retorna null si el ciclo está abierto (sin `closedAt`) o sin
  /// magnitudes/score consolidados (caso edge: cierre forzado sin
  /// pasar por el evaluator normal).
  static CycleSummaryDoc? fromCycle(MetabolicCycle cycle) {
    final closedAt = cycle.closedAt;
    if (closedAt == null) return null;

    final magnitudes = cycle.magnitudes;
    final imr = cycle.dailyScore;
    if (magnitudes == null || imr == null) return null;

    return CycleSummaryDoc(
      cycleId: cycle.cycleId,
      startedAt: cycle.startedAt,
      closedAt: closedAt,
      imrScore: imr,
      fastingMagnitude: magnitudes.fastingMagnitude,
      sleepQualityScore: magnitudes.sleepQualityScore,
      hydrationMagnitude: magnitudes.hydrationMagnitude,
      exerciseMagnitude: magnitudes.exerciseMagnitude,
      nutritionMagnitude: magnitudes.nutritionMagnitude,
      fastingProtocol: cycle.fastingProtocol,
      fastingDurationHours: cycle.fastingDurationHours,
      feedingWindowHours: cycle.feedingWindowHours,
    );
  }

  /// Helper: convierte una lista de ciclos cerrados a summaries,
  /// descartando los que no califican (abiertos o sin data consolidada).
  static List<CycleSummaryDoc> fromCycles(List<MetabolicCycle> cycles) {
    final result = <CycleSummaryDoc>[];
    for (final c in cycles) {
      final summary = fromCycle(c);
      if (summary != null) result.add(summary);
    }
    return result;
  }
}
