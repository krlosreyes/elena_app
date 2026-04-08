import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_entities.freezed.dart';
part 'training_entities.g.dart';

enum TargetMuscle { chest, back, legs, fullBody, cardio, fuerza, hiit, movilidad }

/// Converts Firestore Timestamp ↔ Dart DateTime for Freezed JSON serialization.
class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json);
    return DateTime.now(); // Fallback
  }

  @override
  dynamic toJson(DateTime date) => Timestamp.fromDate(date);
}


@freezed
// NO mezclar DiagnosticableTreeMixin
sealed class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required String id,
    required String userId,
    @TimestampConverter() required DateTime startTime,
    @TimestampConverter() required DateTime endTime,
    required int intensityLevel,
    required String type,
    TargetMuscle? targetMuscle,
    @Default([]) List<ExerciseSet> sets,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);
}

@freezed
// NO mezclar DiagnosticableTreeMixin
sealed class ExerciseSet with _$ExerciseSet {
  const factory ExerciseSet({
    required int setIndex,
    required String exerciseName,
    required double weight,
    required int repsCompleted,
    required int rir,
    @Default(false) bool isDone,
  }) = _ExerciseSet;

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => _$ExerciseSetFromJson(json);
}

@freezed
// NO mezclar DiagnosticableTreeMixin
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
  }) = _RoutineExercise;

  factory RoutineExercise.fromJson(Map<String, dynamic> json) => _$RoutineExerciseFromJson(json);
}

@freezed
// NO mezclar DiagnosticableTreeMixin
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
// NO mezclar DiagnosticableTreeMixin
sealed class WorkoutRecommendation with _$WorkoutRecommendation {
  const factory WorkoutRecommendation({
    required String type,
    TargetMuscle? targetMuscle,
    required int durationMinutes,
    required String intensity,
    required String notes,
  }) = _WorkoutRecommendation;

  factory WorkoutRecommendation.fromJson(Map<String, dynamic> json) => _$WorkoutRecommendationFromJson(json);
}

@freezed
// NO mezclar DiagnosticableTreeMixin
sealed class TrainingCycle with _$TrainingCycle {
  const factory TrainingCycle({
    required int sessionCount,
    required bool isDeloadActive,
    required int cycleNumber,
    DateTime? deloadStartDate,
  }) = _TrainingCycle;

  factory TrainingCycle.fromJson(Map<String, dynamic> json) => _$TrainingCycleFromJson(json);
}
