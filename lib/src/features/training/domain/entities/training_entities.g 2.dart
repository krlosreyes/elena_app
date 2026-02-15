// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      targetMuscle: $enumDecode(_$TargetMuscleEnumMap, json['targetMuscle']),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
        _$WorkoutSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'type': instance.type,
      'targetMuscle': _$TargetMuscleEnumMap[instance.targetMuscle]!,
      'durationMinutes': instance.durationMinutes,
      'sets': instance.sets,
    };

const _$TargetMuscleEnumMap = {
  TargetMuscle.chest: 'chest',
  TargetMuscle.back: 'back',
  TargetMuscle.legs: 'legs',
  TargetMuscle.fullBody: 'fullBody',
  TargetMuscle.cardio: 'cardio',
};

_$ExerciseSetImpl _$$ExerciseSetImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseSetImpl(
      exerciseName: json['exerciseName'] as String,
      weight: (json['weight'] as num).toDouble(),
      repsCompleted: (json['repsCompleted'] as num).toInt(),
      rir: (json['rir'] as num).toInt(),
    );

Map<String, dynamic> _$$ExerciseSetImplToJson(_$ExerciseSetImpl instance) =>
    <String, dynamic>{
      'exerciseName': instance.exerciseName,
      'weight': instance.weight,
      'repsCompleted': instance.repsCompleted,
      'rir': instance.rir,
    };

_$WeeklyTrainingStatsImpl _$$WeeklyTrainingStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$WeeklyTrainingStatsImpl(
      totalStrengthMins: (json['totalStrengthMins'] as num).toInt(),
      totalHiitMins: (json['totalHiitMins'] as num).toInt(),
      zone2Mins: (json['zone2Mins'] as num).toInt(),
      consecutiveWeeksTrained: (json['consecutiveWeeksTrained'] as num).toInt(),
    );

Map<String, dynamic> _$$WeeklyTrainingStatsImplToJson(
        _$WeeklyTrainingStatsImpl instance) =>
    <String, dynamic>{
      'totalStrengthMins': instance.totalStrengthMins,
      'totalHiitMins': instance.totalHiitMins,
      'zone2Mins': instance.zone2Mins,
      'consecutiveWeeksTrained': instance.consecutiveWeeksTrained,
    };

_$WorkoutRecommendationImpl _$$WorkoutRecommendationImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkoutRecommendationImpl(
      type: json['type'] as String,
      targetMuscle:
          $enumDecodeNullable(_$TargetMuscleEnumMap, json['targetMuscle']),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      intensity: json['intensity'] as String,
      notes: json['notes'] as String,
    );

Map<String, dynamic> _$$WorkoutRecommendationImplToJson(
        _$WorkoutRecommendationImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'targetMuscle': _$TargetMuscleEnumMap[instance.targetMuscle],
      'durationMinutes': instance.durationMinutes,
      'intensity': instance.intensity,
      'notes': instance.notes,
    };
