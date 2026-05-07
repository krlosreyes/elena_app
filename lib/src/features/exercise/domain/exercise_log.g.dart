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
      timestamp: const TimestampConverter().fromJson(json['timestamp']),
      intensityMultiplier:
          (json['intensityMultiplier'] as num?)?.toDouble() ?? 1.0,
      type: $enumDecodeNullable(_$ExerciseTypeEnumMap, json['type']),
      intensity:
          $enumDecodeNullable(_$ExerciseIntensityEnumMap, json['intensity']),
      rpe: (json['rpe'] as num?)?.toInt(),
      heartRateAvg: (json['heartRateAvg'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ExerciseLogImplToJson(_$ExerciseLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'durationMinutes': instance.durationMinutes,
      'activityType': instance.activityType,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'intensityMultiplier': instance.intensityMultiplier,
      'type': _$ExerciseTypeEnumMap[instance.type],
      'intensity': _$ExerciseIntensityEnumMap[instance.intensity],
      'rpe': instance.rpe,
      'heartRateAvg': instance.heartRateAvg,
    };

const _$ExerciseTypeEnumMap = {
  ExerciseType.liss: 'liss',
  ExerciseType.hiit: 'hiit',
  ExerciseType.strength: 'strength',
  ExerciseType.mobility: 'mobility',
};

const _$ExerciseIntensityEnumMap = {
  ExerciseIntensity.low: 'low',
  ExerciseIntensity.moderate: 'moderate',
  ExerciseIntensity.high: 'high',
};
