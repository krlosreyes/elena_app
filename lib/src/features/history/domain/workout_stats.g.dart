// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkoutStats _$WorkoutStatsFromJson(Map<String, dynamic> json) =>
    _WorkoutStats(
      date: DateTime.parse(json['date'] as String),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      caloriesBurned: (json['caloriesBurned'] as num).toInt(),
      workoutType: json['workoutType'] as String,
      totalSets: (json['totalSets'] as num).toInt(),
    );

Map<String, dynamic> _$WorkoutStatsToJson(_WorkoutStats instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'totalVolume': instance.totalVolume,
      'durationMinutes': instance.durationMinutes,
      'caloriesBurned': instance.caloriesBurned,
      'workoutType': instance.workoutType,
      'totalSets': instance.totalSets,
    };
