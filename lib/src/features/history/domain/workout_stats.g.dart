// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutStatsImpl _$$WorkoutStatsImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutStatsImpl(
      date: DateTime.parse(json['date'] as String),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      caloriesBurned: (json['caloriesBurned'] as num).toInt(),
      workoutType: json['workoutType'] as String,
      totalSets: (json['totalSets'] as num).toInt(),
    );

Map<String, dynamic> _$$WorkoutStatsImplToJson(_$WorkoutStatsImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'totalVolume': instance.totalVolume,
      'durationMinutes': instance.durationMinutes,
      'caloriesBurned': instance.caloriesBurned,
      'workoutType': instance.workoutType,
      'totalSets': instance.totalSets,
    };
