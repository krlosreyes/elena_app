import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/health/providers/health_snapshot_provider.dart';
import '../domain/entities/workout_log.dart';

class ExerciseState {
  final int minutesCurrent;
  final int minutesGoal;
  final int streakDays;

  ExerciseState({
    required this.minutesCurrent,
    required this.minutesGoal,
    required this.streakDays,
  });

  ExerciseState copyWith({
    int? minutesCurrent,
    int? minutesGoal,
    int? streakDays,
  }) {
    return ExerciseState(
      minutesCurrent: minutesCurrent ?? this.minutesCurrent,
      minutesGoal: minutesGoal ?? this.minutesGoal,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  factory ExerciseState.fromCanonicalHealth({
    required int minutesCurrent,
    required double recoveryScore,
    required List<WorkoutLog> workouts,
  }) {
    final goal = recoveryScore < 40 ? 20 : (recoveryScore < 70 ? 30 : 45);

    return ExerciseState(
      minutesCurrent: minutesCurrent,
      minutesGoal: goal,
      streakDays: _deriveStreakDays(workouts),
    );
  }

  static int _deriveStreakDays(List<WorkoutLog> workouts) {
    if (workouts.isEmpty) return 0;

    final uniqueDays = workouts
        .map((w) => DateTime(w.date.year, w.date.month, w.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    var streak = 0;

    for (final day in uniqueDays) {
      final dayOnly = DateTime(day.year, day.month, day.day);
      if (dayOnly == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (dayOnly.isBefore(cursor)) {
        break;
      }
    }

    return streak;
  }
}

class ExerciseController extends Notifier<ExerciseState> {
  @override
  ExerciseState build() {
    final snapshot = ref.watch(healthSnapshotProvider).valueOrNull;
    if (snapshot != null) {
      // Moved to DecisionEngine in Phase 3
      // Canonical training state is derived from UserHealthState.
      return ExerciseState.fromCanonicalHealth(
        minutesCurrent: snapshot.state.dailyLog.exerciseMinutes,
        recoveryScore: snapshot.state.recoveryScore,
        workouts: snapshot.state.workouts,
      );
    }

    return ExerciseState(
      minutesCurrent: 35,
      minutesGoal: 50,
      streakDays: 12,
    );
  }

  void addMinutes(int minutes) {
    state = state.copyWith(minutesCurrent: state.minutesCurrent + minutes);
  }

  void setGoal(int goal) {
    state = state.copyWith(minutesGoal: goal);
  }
}

final exerciseProvider =
    NotifierProvider<ExerciseController, ExerciseState>(() {
  return ExerciseController();
});
