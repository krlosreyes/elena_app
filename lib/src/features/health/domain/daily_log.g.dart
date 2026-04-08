// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyLog _$DailyLogFromJson(Map<String, dynamic> json) => _DailyLog(
      id: json['id'] as String,
      waterGlasses: (json['waterGlasses'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinGrams: (json['proteinGrams'] as num?)?.toInt() ?? 0,
      carbsGrams: (json['carbsGrams'] as num?)?.toInt() ?? 0,
      fatGrams: (json['fatGrams'] as num?)?.toInt() ?? 0,
      exerciseMinutes: (json['exerciseMinutes'] as num?)?.toInt() ?? 0,
      sleepMinutes: (json['sleepMinutes'] as num?)?.toInt() ?? 0,
      fastingStartTime:
          const OptionalTimestampConverter().fromJson(json['fastingStartTime']),
      fastingEndTime:
          const OptionalTimestampConverter().fromJson(json['fastingEndTime']),
      imrScore: (json['mtiScore'] as num?)?.toDouble() ?? 0.0,
      mealEntries: (json['mealEntries'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      exerciseEntries: (json['exerciseEntries'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DailyLogToJson(_DailyLog instance) => <String, dynamic>{
      'id': instance.id,
      'waterGlasses': instance.waterGlasses,
      'calories': instance.calories,
      'proteinGrams': instance.proteinGrams,
      'carbsGrams': instance.carbsGrams,
      'fatGrams': instance.fatGrams,
      'exerciseMinutes': instance.exerciseMinutes,
      'sleepMinutes': instance.sleepMinutes,
      'fastingStartTime':
          const OptionalTimestampConverter().toJson(instance.fastingStartTime),
      'fastingEndTime':
          const OptionalTimestampConverter().toJson(instance.fastingEndTime),
      'mtiScore': instance.imrScore,
      'mealEntries': instance.mealEntries,
      'exerciseEntries': instance.exerciseEntries,
    };
