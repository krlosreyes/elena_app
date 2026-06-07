// SPEC-161 + SPEC-190 (2026-06-05): provider que alimenta el
// ExerciseWeeklyCard. Migrado a "últimos 7 ciclos cerrados" en lugar
// de "últimos 7 días" para cumplir METABOLIC_DAY_CONSTITUTION.md §1.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/exercise/application/exercise_weekly_computer.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_weekly_insight.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_providers.dart';

/// SPEC-190: ventana = 7 ciclos cerrados.
const int kExerciseCardWindowCycles = 7;

final lastWeekExerciseProvider =
    StreamProvider.autoDispose<ExerciseWeeklyBreakdown>((ref) {
  final account = ref.watch(authStateProvider).value;
  final target = ref.watch(effectiveExerciseGoalProvider);
  final cyclesAsync = ref.watch(last7ClosedCyclesProvider);
  final cycles = cyclesAsync.valueOrNull ?? const <MetabolicCycle>[];

  if (account == null || cycles.isEmpty) {
    final now = DateTime.now();
    return Stream.value(
      ExerciseWeeklyBreakdown.empty(
        targetMinutesPerDay: target,
        rangeStart: now,
        rangeEnd: now,
      ),
    );
  }

  final newest = cycles.first;
  final oldest = cycles.last;
  final rangeStart = oldest.startedAt;
  final rangeEnd = newest.closedAt ?? DateTime.now();

  return ref
      .watch(exerciseRepositoryProvider)
      .watchSince(account.uid, rangeStart, until: rangeEnd)
      .map((logs) {
    final cycleAwareLogs = _filterByCycles(logs, cycles);
    return ExerciseWeeklyComputer.compute(
      logs: cycleAwareLogs,
      targetMinutesPerDay: target,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  });
});

/// SPEC-190: filtra logs por pertenencia a algún ciclo cerrado de la
/// lista. Descarta logs huérfanos entre ciclos.
List<ExerciseLog> _filterByCycles(
  List<ExerciseLog> logs,
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
