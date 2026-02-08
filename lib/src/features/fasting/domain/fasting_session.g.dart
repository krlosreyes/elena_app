// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fasting_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FastingSessionImpl _$$FastingSessionImplFromJson(Map<String, dynamic> json) =>
    _$FastingSessionImpl(
      uid: json['uid'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      plannedDurationHours: (json['plannedDurationHours'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$FastingSessionImplToJson(
        _$FastingSessionImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'plannedDurationHours': instance.plannedDurationHours,
      'isCompleted': instance.isCompleted,
    };
