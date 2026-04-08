import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/weekly_routine.dart';
import '../domain/training_enums.dart';

final trainingControllerProvider =
    NotifierProvider<TrainingController, TrainingStatusState>(() {
  return TrainingController();
});

class TrainingStatusState {
  final bool isTimerRunning;
  final int elapsedSeconds;
  final TrainingSessionStep phase;
  final ExerciseCategory category;
  final int rpe;
  final DateTime? startTime;
  final DateTime? cardioStartTime;
  final int cardioTotalSeconds;
  final WorkoutDay? activeWorkoutDay;
  final int currentExerciseIndex;
  final int setsCompletedThisExercise;
  final double cardioCalsBurned;
  final String cardioPhase;
  final double userWeightKg;

  TrainingStatusState({
    this.isTimerRunning = false,
    this.elapsedSeconds = 0,
    this.phase = TrainingSessionStep.selection,
    this.category = ExerciseCategory.strength,
    this.rpe = 7,
    this.startTime,
    this.cardioStartTime,
    this.cardioTotalSeconds = 0,
    this.activeWorkoutDay,
    this.currentExerciseIndex = 0,
    this.setsCompletedThisExercise = 0,
    this.cardioCalsBurned = 0.0,
    this.cardioPhase = 'WARMUP',
    this.userWeightKg = 65.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'isTimerRunning': isTimerRunning,
      'elapsedSeconds': elapsedSeconds,
      'phase': phase.index,
      'category': category.index,
      'rpe': rpe,
      'startTime': startTime?.toIso8601String(),
      'cardioStartTime': cardioStartTime?.toIso8601String(),
      'cardioTotalSeconds': cardioTotalSeconds,
      'activeWorkoutDay': activeWorkoutDay?.toJson(),
      'currentExerciseIndex': currentExerciseIndex,
      'setsCompletedThisExercise': setsCompletedThisExercise,
      'cardioCalsBurned': cardioCalsBurned,
      'cardioPhase': cardioPhase,
      'userWeightKg': userWeightKg,
    };
  }

  factory TrainingStatusState.fromJson(Map<String, dynamic> json) {
    return TrainingStatusState(
      isTimerRunning: json['isTimerRunning'] ?? false,
      elapsedSeconds: json['elapsedSeconds'] ?? 0,
      phase: TrainingSessionStep.values[json['phase'] ?? 0],
      category: ExerciseCategory.values[json['category'] ?? 0],
      rpe: json['rpe'] ?? 7,
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      cardioStartTime: json['cardioStartTime'] != null
          ? DateTime.parse(json['cardioStartTime'])
          : null,
      cardioTotalSeconds: json['cardioTotalSeconds'] ?? 0,
      activeWorkoutDay: json['activeWorkoutDay'] != null
          ? WorkoutDay.fromJson(json['activeWorkoutDay'])
          : null,
      currentExerciseIndex: json['currentExerciseIndex'] ?? 0,
      setsCompletedThisExercise: json['setsCompletedThisExercise'] ?? 0,
      cardioCalsBurned:
          double.tryParse(json['cardioCalsBurned']?.toString() ?? '0') ?? 0.0,
      cardioPhase: json['cardioPhase'] ?? 'WARMUP',
      userWeightKg:
          double.tryParse(json['userWeightKg']?.toString() ?? '65') ?? 65.0,
    );
  }

  int get cardioRemainingSeconds {
    if (cardioStartTime == null) return cardioTotalSeconds;
    final elapsed = DateTime.now().difference(cardioStartTime!).inSeconds;
    final remaining = cardioTotalSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  TrainingStatusState copyWith({
    bool? isTimerRunning,
    int? elapsedSeconds,
    TrainingSessionStep? phase,
    ExerciseCategory? category,
    int? rpe,
    DateTime? startTime,
    DateTime? cardioStartTime,
    int? cardioTotalSeconds,
    WorkoutDay? activeWorkoutDay,
    int? currentExerciseIndex,
    int? setsCompletedThisExercise,
    double? cardioCalsBurned,
    String? cardioPhase,
    double? userWeightKg,
  }) {
    return TrainingStatusState(
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      phase: phase ?? this.phase,
      category: category ?? this.category,
      rpe: rpe ?? this.rpe,
      startTime: startTime ?? this.startTime,
      cardioStartTime: cardioStartTime ?? this.cardioStartTime,
      cardioTotalSeconds: cardioTotalSeconds ?? this.cardioTotalSeconds,
      activeWorkoutDay: activeWorkoutDay ?? this.activeWorkoutDay,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      setsCompletedThisExercise:
          setsCompletedThisExercise ?? this.setsCompletedThisExercise,
      cardioCalsBurned: cardioCalsBurned ?? this.cardioCalsBurned,
      cardioPhase: cardioPhase ?? this.cardioPhase,
      userWeightKg: userWeightKg ?? this.userWeightKg,
    );
  }
}

class TrainingController extends Notifier<TrainingStatusState> {
  Timer? _timer;

  @override
  TrainingStatusState build() {
    ref.onDispose(() => _timer?.cancel());
    // Restoration logic handled in _init()
    _init();
    return TrainingStatusState();
  }

  static const _kPrefKey = 'active_training_session';

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_kPrefKey);
      if (data != null) {
        final saved = TrainingStatusState.fromJson(jsonDecode(data));
        // Only restore if the session was recently active (e.g. within 2 hours)
        final now = DateTime.now();
        if (saved.startTime != null &&
            now.difference(saved.startTime!).inHours < 4) {
          state = saved;
          if (state.isTimerRunning) {
            _resumeTimer();
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKey, jsonEncode(state.toJson()));
    } catch (e) {
      // Ignore
    }
  }

  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = now.difference(state.startTime!).inSeconds;

      // Update cardio info if running
      double cals = state.cardioCalsBurned;
      String phase = state.cardioPhase;
      if (state.cardioStartTime != null) {
        final cardioElapsed = now.difference(state.cardioStartTime!).inSeconds;
        // MET formula: kcal/min = (MET × 3.5 × weightKg) / 200
        // Zone 2 cardio ≈ MET 5.0 (brisk walk / light jog)
        const double met = 5.0;
        final w = state.userWeightKg;
        final kcalPerMin = (met * 3.5 * w) / 200;
        cals = kcalPerMin * (cardioElapsed / 60.0);

        // Phase logic
        final total = state.cardioTotalSeconds;
        int warmup = total > 900 ? 300 : 120;
        int cooldown = total > 900 ? 300 : 120;

        if (cardioElapsed < warmup) {
          phase = 'WARMUP';
        } else if (cardioElapsed > total - cooldown) {
          phase = 'COOLDOWN';
        } else {
          phase = 'MAIN';
        }
      }

      state = state.copyWith(
        elapsedSeconds: diff,
        cardioCalsBurned: cals,
        cardioPhase: phase,
      );
      _persist();
    });
  }

  void initSession(WorkoutDay day, {double weightKg = 65.0}) {
    _timer?.cancel();
    final now = DateTime.now();
    state = state.copyWith(
      isTimerRunning: true,
      elapsedSeconds: 0,
      phase: TrainingSessionStep.active,
      startTime: now,
      activeWorkoutDay: day,
      currentExerciseIndex: 0,
      setsCompletedThisExercise: 0,
      userWeightKg: weightKg,
    );

    // Auto-setup cardio if first exercise is cardio
    if (day.exercises.isNotEmpty) {
      final first = day.exercises.first;
      if (first.muscleGroup.toLowerCase() == 'cardio' &&
          first.targetMinutes > 0) {
        initCardio(first.targetMinutes);
      }
    }

    _resumeTimer();
    _persist();
  }

  void initCardio(int totalMinutes) {
    state = state.copyWith(
      cardioStartTime: state.cardioStartTime ?? DateTime.now(),
      cardioTotalSeconds: totalMinutes * 60,
      cardioPhase: 'WARMUP',
    );
    _persist();
  }

  void startCardio() {
    if (!state.isTimerRunning) {
      state = state.copyWith(
        isTimerRunning: true,
        startTime: state.startTime ?? DateTime.now(),
      );
      _resumeTimer();
    }
    if (state.cardioStartTime == null) {
      state = state.copyWith(cardioStartTime: DateTime.now());
    }
    _persist();
  }

  void stopCardio() {
    _persist();
  }

  void updateRoutineProgress({int? exerciseIndex, int? setsCompleted}) {
    state = state.copyWith(
      currentExerciseIndex: exerciseIndex ?? state.currentExerciseIndex,
      setsCompletedThisExercise:
          setsCompleted ?? state.setsCompletedThisExercise,
    );
    _persist();
  }

  void selectCategory(ExerciseCategory category) {
    state = state.copyWith(category: category);
    _persist();
  }

  void updateRpe(int rpe) {
    state = state.copyWith(rpe: rpe);
    _persist();
  }

  void finishSession() {
    _timer?.cancel();
    state = state.copyWith(
      isTimerRunning: false,
      phase: TrainingSessionStep.summary,
    );
    _persist();
  }

  void startMission() {
    _timer?.cancel();
    final now = DateTime.now();
    state = state.copyWith(
      isTimerRunning: true,
      elapsedSeconds: 0,
      phase: TrainingSessionStep.active,
      startTime: now,
      activeWorkoutDay: null,
      currentExerciseIndex: 0,
      setsCompletedThisExercise: 0,
    );
    _resumeTimer();
    _persist();
  }

  void resetSession() {
    _timer?.cancel();
    state = TrainingStatusState();
    SharedPreferences.getInstance().then((p) => p.remove(_kPrefKey));
  }

  Duration get sessionDuration => Duration(seconds: state.elapsedSeconds);
}
