// SPEC-192.3a (2026-06-05): provider derivado que expone la
// `CycleComparison` cycle-aware ("últimos 7 ciclos cerrados vs los 7
// anteriores").
//
// Reemplaza el rol de `periodComparisonProvider(AnalysisPeriod.week)`
// SOLO para `weekly_coaching_provider`. period_comparison_provider
// sigue calendárico para charts del Analysis tab (excepción documentada
// en SPEC-192 §4).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/cycle_summary_computer.dart';
import 'package:elena_app/src/features/analysis/domain/cycle_comparison.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';

/// Tamaño de cada ventana (current y previous). Coherente con
/// `kMealsRatioWindowCycles` etc. en SPEC-190.
const int kCycleComparisonWindowSize = 7;

/// `CycleComparison` derivado de los últimos 14 ciclos cerrados,
/// splittados 7 (current) + 7 (previous).
///
/// AsyncValue para que la UI maneje loading/error consistentemente.
final cycleComparisonProvider =
    Provider.autoDispose<AsyncValue<CycleComparison>>((ref) {
  final cyclesAsync = ref.watch(last14ClosedCyclesProvider);
  return cyclesAsync.whenData((all) {
    // last14ClosedCyclesProvider devuelve ciclos cerrados ordenados por
    // startedAt descendente (más reciente primero). Por la naturaleza
    // del ciclo, ese orden coincide con closedAt desc para casos
    // normales.
    final current = all.take(kCycleComparisonWindowSize).toList();
    final previous = all
        .skip(kCycleComparisonWindowSize)
        .take(kCycleComparisonWindowSize)
        .toList();

    final currentSummaries = CycleSummaryComputer.fromCycles(current);
    final previousSummaries = CycleSummaryComputer.fromCycles(previous);

    return CycleComparisonService.compute(
      currentSummaries: currentSummaries,
      previousSummaries: previousSummaries,
    );
  });
});
