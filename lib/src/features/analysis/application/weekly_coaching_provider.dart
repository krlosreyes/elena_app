// SPEC-153 + SPEC-192.3b (2026-06-05): provider que alimenta el
// WeeklyCoachingCard.
//
// Refactorizado en SPEC-192.3b a cycle-aware: consume
// `cycleComparisonProvider` (últimos 7 ciclos cerrados vs los 7
// anteriores) y delega al `WeeklyCoachingComputer.fromCycleComparison`.
//
// Cumple METABOLIC_DAY_CONSTITUTION.md §1 — cero referencia al reloj.
// El widget `WeeklyCoachingCard` no cambia su firma: sigue recibiendo
// un `WeeklyCoachingInsight` con la misma estructura. Lo que cambia
// es el SIGNIFICADO de los promedios: ahora son por CICLO cerrado,
// no por DÍA calendárico.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/cycle_comparison_provider.dart';
import 'package:elena_app/src/features/analysis/application/weekly_coaching_computer.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';

/// AsyncValue del insight semanal cycle-aware.
///
/// Loading mientras Firestore responde con los últimos 14 ciclos
/// cerrados; error si la query falla; data con el WeeklyCoachingInsight
/// cuando llega la comparativa.
final weeklyCoachingProvider =
    Provider.autoDispose<AsyncValue<WeeklyCoachingInsight>>((ref) {
  final comparisonAsync = ref.watch(cycleComparisonProvider);
  return comparisonAsync.whenData((comparison) {
    return WeeklyCoachingComputer.fromCycleComparison(comparison);
  });
});
