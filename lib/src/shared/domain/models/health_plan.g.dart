// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthPlan _$HealthPlanFromJson(Map<String, dynamic> json) => _HealthPlan(
      protocol: json['protocol'] as String,
      hydrationGoal: (json['hydrationGoal'] as num).toInt(),
      maxHeartRate: (json['maxHeartRate'] as num).toInt(),
      exerciseStrategy: json['exerciseStrategy'] as String,
      exerciseFrequency: json['exerciseFrequency'] as String,
      nutritionStrategy: json['nutritionStrategy'] as String,
      breakingFastTip: json['breakingFastTip'] as String,
      glucoseStrategy: json['glucoseStrategy'] as String?,
      whyThisPlan: json['whyThisPlan'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$HealthPlanToJson(_HealthPlan instance) =>
    <String, dynamic>{
      'protocol': instance.protocol,
      'hydrationGoal': instance.hydrationGoal,
      'maxHeartRate': instance.maxHeartRate,
      'exerciseStrategy': instance.exerciseStrategy,
      'exerciseFrequency': instance.exerciseFrequency,
      'nutritionStrategy': instance.nutritionStrategy,
      'breakingFastTip': instance.breakingFastTip,
      'glucoseStrategy': instance.glucoseStrategy,
      'whyThisPlan': instance.whyThisPlan,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
