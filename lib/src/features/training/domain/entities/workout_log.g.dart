// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutLogImpl _$$WorkoutLogImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutLogImpl(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      date: DateTime.parse(json['date'] as String),
      sessionRirScore: (json['sessionRirScore'] as num).toInt(),
      completedExercises: (json['completedExercises'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$WorkoutLogImplToJson(_$WorkoutLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'date': instance.date.toIso8601String(),
      'sessionRirScore': instance.sessionRirScore,
      'completedExercises': instance.completedExercises,
      'durationMinutes': instance.durationMinutes,
      'caloriesBurned': instance.caloriesBurned,
    };
