// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecommendationPlanImpl _$$RecommendationPlanImplFromJson(
        Map<String, dynamic> json) =>
    _$RecommendationPlanImpl(
      dailyWaterIntakeLitres:
          (json['dailyWaterIntakeLitres'] as num).toDouble(),
      recommendedFastingProtocol: json['recommendedFastingProtocol'] as String,
      fastingWindowDescription: json['fastingWindowDescription'] as String,
      recommendedEatingWindowStart:
          json['recommendedEatingWindowStart'] as String,
      recommendedEatingWindowEnd: json['recommendedEatingWindowEnd'] as String,
      exerciseZoneHeartRate: (json['exerciseZoneHeartRate'] as num).toInt(),
      exerciseFrequency: json['exerciseFrequency'] as String,
      exerciseDescription: json['exerciseDescription'] as String,
      requiresGlucometer: json['requiresGlucometer'] as bool,
      glucoseTargetFasting: json['glucoseTargetFasting'] as String?,
      glucoseTargetPostMeal: json['glucoseTargetPostMeal'] as String?,
      monitoringFocusMessage: json['monitoringFocusMessage'] as String?,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$$RecommendationPlanImplToJson(
        _$RecommendationPlanImpl instance) =>
    <String, dynamic>{
      'dailyWaterIntakeLitres': instance.dailyWaterIntakeLitres,
      'recommendedFastingProtocol': instance.recommendedFastingProtocol,
      'fastingWindowDescription': instance.fastingWindowDescription,
      'recommendedEatingWindowStart': instance.recommendedEatingWindowStart,
      'recommendedEatingWindowEnd': instance.recommendedEatingWindowEnd,
      'exerciseZoneHeartRate': instance.exerciseZoneHeartRate,
      'exerciseFrequency': instance.exerciseFrequency,
      'exerciseDescription': instance.exerciseDescription,
      'requiresGlucometer': instance.requiresGlucometer,
      'glucoseTargetFasting': instance.glucoseTargetFasting,
      'glucoseTargetPostMeal': instance.glucoseTargetPostMeal,
      'monitoringFocusMessage': instance.monitoringFocusMessage,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
