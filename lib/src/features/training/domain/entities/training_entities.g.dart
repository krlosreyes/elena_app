// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTime: const TimestampConverter().fromJson(json['start_time']),
      endTime: const TimestampConverter().fromJson(json['end_time']),
      intensityLevel: (json['intensity_level'] as num).toInt(),
      type: json['type'] as String,
      targetMuscle:
          $enumDecodeNullable(_$TargetMuscleEnumMap, json['target_muscle']),
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
        _$WorkoutSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'start_time': const TimestampConverter().toJson(instance.startTime),
      'end_time': const TimestampConverter().toJson(instance.endTime),
      'intensity_level': instance.intensityLevel,
      'type': instance.type,
      'target_muscle': _$TargetMuscleEnumMap[instance.targetMuscle],
      'sets': instance.sets,
    };

const _$TargetMuscleEnumMap = {
  TargetMuscle.chest: 'chest',
  TargetMuscle.back: 'back',
  TargetMuscle.legs: 'legs',
  TargetMuscle.fullBody: 'fullBody',
  TargetMuscle.cardio: 'cardio',
  TargetMuscle.fuerza: 'fuerza',
  TargetMuscle.hiit: 'hiit',
  TargetMuscle.movilidad: 'movilidad',
};

_$ExerciseSetImpl _$$ExerciseSetImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseSetImpl(
      setIndex: (json['set_index'] as num).toInt(),
      exerciseName: json['exercise_name'] as String,
      weight: (json['weight'] as num).toDouble(),
      repsCompleted: (json['reps_completed'] as num).toInt(),
      rir: (json['rir'] as num).toInt(),
      isDone: json['is_done'] as bool? ?? false,
    );

Map<String, dynamic> _$$ExerciseSetImplToJson(_$ExerciseSetImpl instance) =>
    <String, dynamic>{
      'set_index': instance.setIndex,
      'exercise_name': instance.exerciseName,
      'weight': instance.weight,
      'reps_completed': instance.repsCompleted,
      'rir': instance.rir,
      'is_done': instance.isDone,
    };

_$ExerciseImpl _$$ExerciseImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      targetReps: json['target_reps'] as String,
      rir: (json['rir'] as num).toInt(),
      restSeconds: (json['rest_seconds'] as num).toInt(),
      targetMuscle: json['target_muscle'] as String? ?? 'Unknown',
      requiresWeight: json['requires_weight'] as bool? ?? true,
    );

Map<String, dynamic> _$$ExerciseImplToJson(_$ExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sets': instance.sets,
      'target_reps': instance.targetReps,
      'rir': instance.rir,
      'rest_seconds': instance.restSeconds,
      'target_muscle': instance.targetMuscle,
      'requires_weight': instance.requiresWeight,
    };

_$WeeklyTrainingStatsImpl _$$WeeklyTrainingStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$WeeklyTrainingStatsImpl(
      totalStrengthMins: (json['total_strength_mins'] as num).toInt(),
      totalHiitMins: (json['total_hiit_mins'] as num).toInt(),
      zone2Mins: (json['zone2_mins'] as num).toInt(),
      consecutiveWeeksTrained:
          (json['consecutive_weeks_trained'] as num).toInt(),
    );

Map<String, dynamic> _$$WeeklyTrainingStatsImplToJson(
        _$WeeklyTrainingStatsImpl instance) =>
    <String, dynamic>{
      'total_strength_mins': instance.totalStrengthMins,
      'total_hiit_mins': instance.totalHiitMins,
      'zone2_mins': instance.zone2Mins,
      'consecutive_weeks_trained': instance.consecutiveWeeksTrained,
    };

_$WorkoutRecommendationImpl _$$WorkoutRecommendationImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkoutRecommendationImpl(
      type: json['type'] as String,
      targetMuscle:
          $enumDecodeNullable(_$TargetMuscleEnumMap, json['target_muscle']),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      intensity: json['intensity'] as String,
      notes: json['notes'] as String,
    );

Map<String, dynamic> _$$WorkoutRecommendationImplToJson(
        _$WorkoutRecommendationImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'target_muscle': _$TargetMuscleEnumMap[instance.targetMuscle],
      'duration_minutes': instance.durationMinutes,
      'intensity': instance.intensity,
      'notes': instance.notes,
    };

_$TrainingCycleImpl _$$TrainingCycleImplFromJson(Map<String, dynamic> json) =>
    _$TrainingCycleImpl(
      sessionCount: (json['session_count'] as num).toInt(),
      isDeloadActive: json['is_deload_active'] as bool,
      cycleNumber: (json['cycle_number'] as num).toInt(),
      deloadStartDate: json['deload_start_date'] == null
          ? null
          : DateTime.parse(json['deload_start_date'] as String),
    );

Map<String, dynamic> _$$TrainingCycleImplToJson(_$TrainingCycleImpl instance) =>
    <String, dynamic>{
      'session_count': instance.sessionCount,
      'is_deload_active': instance.isDeloadActive,
      'cycle_number': instance.cycleNumber,
      'deload_start_date': instance.deloadStartDate?.toIso8601String(),
    };
