// SPEC-158 + SPEC-190 (2026-06-05): provider que alimenta el
// MealsRatioCard.
//
// Migrado a "últimos 7 CICLOS CERRADOS" en lugar de "últimos 7 días"
// para cumplir §1 de METABOLIC_DAY_CONSTITUTION.md (cero reloj).
//
// Estrategia:
//   1. Lee los últimos 7 ciclos cerrados via `last7ClosedCyclesProvider`.
//   2. Lee los logs nutricionales en el rango cubierto por esos ciclos
//      (`oldestCycle.startedAt` → `newestCycle.closedAt`).
//   3. Filtra los logs cycle-aware: solo cuentan los que cayeron dentro
//      de algún `[cycle.startedAt, cycle.closedAt]` (descarta huérfanos).
//   4. Delega el cálculo a `MealsRatioComputer`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/nutrition/application/meals_ratio_computer.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/meals_ratio_breakdown.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

/// SPEC-190: ventana = N últimos ciclos cerrados. Fijo en 7 (decisión
/// Carlos 2026-06-05 §D1). El concepto "semanal" se preserva en el copy
/// pero la lógica es cycle-aware.
const int kMealsRatioWindowCycles = 7;

final lastWeekMealsRatioProvider =
    StreamProvider.autoDispose<MealsRatioBreakdown>((ref) {
  final account = ref.watch(authStateProvider).value;
  final cyclesAsync = ref.watch(last7ClosedCyclesProvider);

  // Sin auth o sin ciclos cargados → empty placeholder.
  final cycles = cyclesAsync.valueOrNull ?? const <MetabolicCycle>[];
  if (account == null || cycles.isEmpty) {
    return Stream.value(MealsRatioBreakdown.empty(
      rangeStart: DateTime.now(),
      rangeEnd: DateTime.now(),
    ));
  }

  // Rango temporal cubierto por los ciclos cerrados. Los ciclos vienen
  // ordenados por startedAt desc → cycles.first es el más reciente.
  final newest = cycles.first;
  final oldest = cycles.last;
  final rangeStart = oldest.startedAt;
  final rangeEnd = newest.closedAt ?? DateTime.now();

  return ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(account.uid, rangeStart, until: rangeEnd)
      .map((logs) {
    final cycleAwareLogs = _filterByCycles(logs, cycles);
    return MealsRatioComputer.compute(
      logs: cycleAwareLogs,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  });
});

/// SPEC-190: filtra logs que cayeron dentro de algún ciclo cerrado de
/// la lista. Descarta huérfanos (logs entre ciclos o post-cierre).
/// Política conservadora: si el timestamp está fuera de los ciclos
/// conocidos, el log NO cuenta para la analítica semanal.
List<NutritionLog> _filterByCycles(
  List<NutritionLog> logs,
  List<MetabolicCycle> cycles,
) {
  return logs.where((log) {
    for (final c in cycles) {
      final closedAt = c.closedAt;
      if (closedAt == null) continue;
      if (!log.timestamp.isBefore(c.startedAt) &&
          !log.timestamp.isAfter(closedAt)) {
        return true;
      }
    }
    return false;
  }).toList();
}
