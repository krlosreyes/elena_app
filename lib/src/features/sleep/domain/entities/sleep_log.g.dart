// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SleepLogImpl _$$SleepLogImplFromJson(Map<String, dynamic> json) =>
    _$SleepLogImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      hours: (json['hours'] as num).toDouble(),
      timestamp:
          const TimestampConverter().fromJson(json['timestamp'] as Object),
    );

Map<String, dynamic> _$$SleepLogImplToJson(_$SleepLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'hours': instance.hours,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
    };
