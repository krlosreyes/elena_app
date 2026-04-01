import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/training_enums.dart';

final trainingControllerProvider = NotifierProvider<TrainingController, TrainingStatusState>(() {
  return TrainingController();
});

class TrainingStatusState {
  final bool isTimerRunning;
  final int elapsedSeconds;
  final TrainingSessionStep phase;
  final ExerciseCategory category;
  final int rpe;

  TrainingStatusState({
    this.isTimerRunning = false,
    this.elapsedSeconds = 0,
    this.phase = TrainingSessionStep.selection,
    this.category = ExerciseCategory.strength,
    this.rpe = 7,
  });

  TrainingStatusState copyWith({
    bool? isTimerRunning,
    int? elapsedSeconds,
    TrainingSessionStep? phase,
    ExerciseCategory? category,
    int? rpe,
  }) {
    return TrainingStatusState(
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      phase: phase ?? this.phase,
      category: category ?? this.category,
      rpe: rpe ?? this.rpe,
    );
  }
}

class TrainingController extends Notifier<TrainingStatusState> {
  Timer? _timer;

  @override
  TrainingStatusState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return TrainingStatusState();
  }

  void selectCategory(ExerciseCategory category) {
    state = state.copyWith(category: category);
  }

  void startMission() {
    _timer?.cancel();
    state = state.copyWith(
      isTimerRunning: true,
      elapsedSeconds: 0,
      phase: TrainingSessionStep.active,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void finishMission() {
    _timer?.cancel();
    state = state.copyWith(
      isTimerRunning: false,
      phase: TrainingSessionStep.summary,
    );
  }

  void updateRpe(int rpe) {
    state = state.copyWith(rpe: rpe);
  }

  void resetSession() {
    _timer?.cancel();
    state = TrainingStatusState();
  }

  Duration get sessionDuration => Duration(seconds: state.elapsedSeconds);
}
