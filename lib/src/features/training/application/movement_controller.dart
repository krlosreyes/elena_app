import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class ExerciseController extends Notifier<ExerciseState> {
  @override
  ExerciseState build() {
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
