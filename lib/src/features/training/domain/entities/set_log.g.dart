// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SetLog _$SetLogFromJson(Map<String, dynamic> json) => _SetLog(
      id: json['id'] as String? ?? '',
      exerciseId: json['exerciseId'] as String,
      dayIndex: (json['dayIndex'] as num).toInt(),
      setNumber: (json['setNumber'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      rpe: (json['rpe'] as num?)?.toInt() ?? 5,
      loggedAt: const TimestampConverter().fromJson(json['loggedAt'] as Object),
    );

Map<String, dynamic> _$SetLogToJson(_SetLog instance) => <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'dayIndex': instance.dayIndex,
      'setNumber': instance.setNumber,
      'reps': instance.reps,
      'weightKg': instance.weightKg,
      'rpe': instance.rpe,
      'loggedAt': const TimestampConverter().toJson(instance.loggedAt),
    };
