import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
class WorkoutSession with _$WorkoutSession {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WorkoutSession({
    required String id,
    required String userId,
    @TimestampConverter() required DateTime startTime,
    @TimestampConverter() required DateTime endTime,
    required int intensityLevel, // 1-10
    required String type, // Fuerza, HIIT, Movilidad
    TargetMuscle? targetMuscle,
    @Default([]) List<ExerciseSet> sets,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);
}

extension WorkoutSessionX on WorkoutSession {
  int get durationMinutes => endTime.difference(startTime).inMinutes;
  DateTime get date => startTime;
}



@freezed
class ExerciseSet with _$ExerciseSet {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExerciseSet({
    required int setIndex,
    required String exerciseName,
    required double weight,
    required int repsCompleted,
    required int rir, // 0-4
    @Default(false) bool isDone,
  }) = _ExerciseSet;

  factory ExerciseSet.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSetFromJson(json);
}

@freezed
class RoutineExercise with _$RoutineExercise {
  @JsonSerializable(fieldRename: FieldRename.snake)
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

  factory RoutineExercise.fromJson(Map<String, dynamic> json) =>
      _$RoutineExerciseFromJson(json);
}

@freezed
class WeeklyTrainingStats with _$WeeklyTrainingStats {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WeeklyTrainingStats({
    required int totalStrengthMins,
    required int totalHiitMins,
    required int zone2Mins,
    required int consecutiveWeeksTrained,
  }) = _WeeklyTrainingStats;

  factory WeeklyTrainingStats.fromJson(Map<String, dynamic> json) =>
      _$WeeklyTrainingStatsFromJson(json);
}

@freezed
class WorkoutRecommendation with _$WorkoutRecommendation {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WorkoutRecommendation({
    required String type, // Strength, Cardio, ActiveRecovery, Deload
    TargetMuscle? targetMuscle,
    required int durationMinutes,
    required String intensity, // "Zone 2", "RIR 2"
    required String notes,
  }) = _WorkoutRecommendation;

  factory WorkoutRecommendation.fromJson(Map<String, dynamic> json) =>
      _$WorkoutRecommendationFromJson(json);

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
class TrainingCycle with _$TrainingCycle {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TrainingCycle({
    required int sessionCount,
    required bool isDeloadActive,
    required int cycleNumber,
    DateTime? deloadStartDate,
  }) = _TrainingCycle;

  factory TrainingCycle.fromJson(Map<String, dynamic> json) =>
      _$TrainingCycleFromJson(json);
}
