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
import 'package:elena_app/src/features/analysis/application/weekly_window.dart';
import 'package:elena_app/src/features/analysis/domain/cycle_comparison.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';

/// Tamaño de cada ventana (current y previous). Coherente con
/// `kMealsRatioWindowCycles` etc. en SPEC-190.
const int kCycleComparisonWindowSize = 7;

/// `CycleComparison` de los ciclos cerrados en los últimos 7 días (current)
/// vs los 7 días anteriores (previous).
///
/// AsyncValue para que la UI maneje loading/error consistentemente.
final cycleComparisonProvider =
    Provider.autoDispose<AsyncValue<CycleComparison>>((ref) {
  final cyclesAsync = ref.watch(last14ClosedCyclesProvider);
  return cyclesAsync.whenData((all) {
    // Fix números (2026-10-30): la ventana es de CALENDARIO, no de cantidad.
    // Antes eran "los últimos 7 ciclos", y a un usuario con pocos registros
    // le mostraba como "su semana" ciclos de hace un mes y medio. Ahora:
    // current = ciclos cerrados en los últimos 7 días (hoy incluido),
    // previous = los 7 días anteriores. Ver weekly_window.dart.
    final split = splitCyclesByWeeklyWindow(all, DateTime.now());
    final current = split.current;
    final previous = split.previous;

    final currentSummaries = CycleSummaryComputer.fromCycles(current);
    final previousSummaries = CycleSummaryComputer.fromCycles(previous);

    return CycleComparisonService.compute(
      currentSummaries: currentSummaries,
      previousSummaries: previousSummaries,
    );
  });
});
