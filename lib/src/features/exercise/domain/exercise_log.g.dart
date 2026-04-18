// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseLogImpl _$$ExerciseLogImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseLogImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      activityType: json['activityType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      intensityMultiplier:
          (json['intensityMultiplier'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$ExerciseLogImplToJson(_$ExerciseLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'durationMinutes': instance.durationMinutes,
      'activityType': instance.activityType,
      'timestamp': instance.timestamp.toIso8601String(),
      'intensityMultiplier': instance.intensityMultiplier,
    };
