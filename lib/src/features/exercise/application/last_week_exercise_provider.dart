// SPEC-161: provider que alimenta el ExerciseWeeklyCard.
//
// Combina watchSince(uid, 7d) del ExerciseRepository + el target del
// usuario (exerciseGoalMinutes). Delega cómputo al
// ExerciseWeeklyComputer.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/exercise/application/exercise_weekly_computer.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_weekly_insight.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

const int kExerciseCardWindowDays = 7;

/// Target diario del usuario en minutos. Fallback razonable si no hay.
int _targetFor(int? exerciseGoalMinutes) {
  if (exerciseGoalMinutes == null || exerciseGoalMinutes <= 0) return 30;
  return exerciseGoalMinutes;
}

final lastWeekExerciseProvider =
    StreamProvider.autoDispose<ExerciseWeeklyBreakdown>((ref) {
  final account = ref.watch(authStateProvider).value;
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final target = _targetFor(user?.exerciseGoalMinutes);

  final today = DateTime.now();
  final rangeEnd = DayBoundaryResolver.startOfDay(today);
  final rangeStart =
      rangeEnd.subtract(const Duration(days: kExerciseCardWindowDays - 1));

  if (account == null) {
    return Stream.value(
      ExerciseWeeklyBreakdown.empty(
        targetMinutesPerDay: target,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }

  return ref
      .watch(exerciseRepositoryProvider)
      .watchSince(account.uid, rangeStart)
      .map((logs) => ExerciseWeeklyComputer.compute(
            logs: logs,
            targetMinutesPerDay: target,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          ));
});
