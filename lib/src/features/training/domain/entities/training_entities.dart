import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_entities.freezed.dart';
part 'training_entities.g.dart';

enum TargetMuscle { chest, back, legs, fullBody, cardio }

@freezed
sealed class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required String id,
    required DateTime date,
    required String type, // fuerza / cardio
    required TargetMuscle targetMuscle,
    required int durationMinutes,
    @Default([]) List<ExerciseSet> sets,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);
}

@freezed
sealed class ExerciseSet with _$ExerciseSet {
  const factory ExerciseSet({
    required String exerciseName,
    required double weight,
    required int repsCompleted,
    required int rir, // 0-4
  }) = _ExerciseSet;

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => _$ExerciseSetFromJson(json);
}

@freezed
sealed class RoutineExercise with _$RoutineExercise {
  const factory RoutineExercise({
    required String id,
    required String name,
    required int sets,
    required String targetReps,
    required int rir,
    required int restSeconds,
    @Default('Unknown') String targetMuscle,
    @Default(true) bool requiresWeight,
  }) = _Exercise;

  factory RoutineExercise.fromJson(Map<String, dynamic> json) => _$RoutineExerciseFromJson(json);
}

@freezed
sealed class WeeklyTrainingStats with _$WeeklyTrainingStats {
  const factory WeeklyTrainingStats({
    required int totalStrengthMins,
    required int totalHiitMins,
    required int zone2Mins,
    required int consecutiveWeeksTrained,
  }) = _WeeklyTrainingStats;

  factory WeeklyTrainingStats.fromJson(Map<String, dynamic> json) => _$WeeklyTrainingStatsFromJson(json);
}

@freezed
sealed class WorkoutRecommendation with _$WorkoutRecommendation {
  const factory WorkoutRecommendation({
    required String type, // Strength, Cardio, ActiveRecovery, Deload
    TargetMuscle? targetMuscle,
    required int durationMinutes,
    required String intensity, // "Zone 2", "RIR 2"
    required String notes,
  }) = _WorkoutRecommendation;

  factory WorkoutRecommendation.fromJson(Map<String, dynamic> json) => _$WorkoutRecommendationFromJson(json);

  // Factory constructors for common recommendations
  factory WorkoutRecommendation.deloadWeek() => const WorkoutRecommendation(
    type: 'Deload',
    durationMinutes: 30,
    intensity: 'Light',
    notes: 'Semana de descarga. Reducir volumen e intensidad al 50%.',
  );
  
  factory WorkoutRecommendation.activeRecovery() => const WorkoutRecommendation(
      type: 'ActiveRecovery',
      durationMinutes: 45,
      intensity: 'Zone 1',
      notes: 'Caminata ligera o movilidad. Priorizar recuperación.',
  );
}

@freezed
sealed class TrainingCycle with _$TrainingCycle {
  const factory TrainingCycle({
    required int sessionCount,
    required bool isDeloadActive,
    required int cycleNumber,
    DateTime? deloadStartDate,
  }) = _TrainingCycle;

  factory TrainingCycle.fromJson(Map<String, dynamic> json) => _$TrainingCycleFromJson(json);
}
