// SPEC-154: provider que alimenta el GoalsProgressDashboard.
//
// Combina:
//   - goalsProvider (lista de objetivos activos)
//   - currentUserStreamProvider (peso, grasa, exerciseGoalMinutes)
//   - periodDataProvider(week) (ya consume daily_summary)
//
// Devuelve la lista de snapshots ordenada por progreso descendente.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/period_comparison_provider.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_period.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/goal_progress_computer.dart';
import 'package:elena_app/src/features/goals/domain/goal_progress_snapshot.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Lista de snapshots de los objetivos activos, ordenada por progreso
/// descendente (los más cercanos a la meta arriba).
///
/// Estado loading mientras user o periodData están cargando. Estado
/// data con lista (puede ser vacía si el usuario no tiene goals
/// activos — el widget renderiza empty state).
final goalsProgressProvider =
    Provider.autoDispose<AsyncValue<List<GoalProgressSnapshot>>>((ref) {
  final goals = ref.watch(goalsProvider);
  final userAsync = ref.watch(currentUserStreamProvider);
  final periodAsync = ref.watch(periodDataProvider(AnalysisPeriod.week));

  if (userAsync.isLoading || periodAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (userAsync.hasError) {
    return AsyncValue.error(userAsync.error!, userAsync.stackTrace!);
  }
  if (periodAsync.hasError) {
    return AsyncValue.error(periodAsync.error!, periodAsync.stackTrace!);
  }

  final user = userAsync.value;
  final periodData = periodAsync.value;
  if (user == null || periodData == null) {
    return const AsyncValue.data([]);
  }

  // Filtrar activos.
  final activeGoals = goals.values.where((g) => g.isActive).toList();
  if (activeGoals.isEmpty) {
    return const AsyncValue.data([]);
  }

  final currentValues = GoalProgressComputer.buildCurrentValues(
    user: user,
    weekDocs: periodData.currentDocs,
  );

  final snapshots = <GoalProgressSnapshot>[];
  for (final goal in activeGoals) {
    final current = currentValues[goal.type] ?? 0.0;
    snapshots.add(GoalProgressComputer.compute(
      goal: goal,
      currentValue: current,
    ));
  }

  // SPEC-154 §2.5: ordenamos por progreso descendente para reforzar
  // sensación de logro (los goals más cercanos arriba). Empate por
  // type.index para estabilidad.
  snapshots.sort((a, b) {
    final cmp = b.progress.compareTo(a.progress);
    if (cmp != 0) return cmp;
    return a.goal.type.index.compareTo(b.goal.type.index);
  });

  return AsyncValue.data(snapshots);
});

/// Convenience: true si el usuario no tiene objetivos activos.
/// El widget lo usa para decidir si renderiza empty state vs. lista.
final hasActiveGoalsProvider = Provider.autoDispose<bool>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.values.any((g) => g.isActive);
});

/// Snapshot derivado: helper para tests / consumidores específicos
/// que quieren saber si hay algún goal con `weightTarget`.
final hasWeightGoalProvider = Provider.autoDispose<bool>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals[GoalType.weightTarget]?.isActive == true;
});
