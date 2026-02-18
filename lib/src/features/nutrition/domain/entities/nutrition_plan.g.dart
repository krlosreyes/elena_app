// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NutritionPlanImpl _$$NutritionPlanImplFromJson(Map<String, dynamic> json) =>
    _$NutritionPlanImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      algorithmVersion: json['algorithmVersion'] as String? ?? '1.0.0',
      calculatedAt:
          const TimestampConverter().fromJson(json['calculatedAt'] as Object),
      baseMetrics:
          BaseMetrics.fromJson(json['baseMetrics'] as Map<String, dynamic>),
      macroTargets:
          MacroTargets.fromJson(json['macroTargets'] as Map<String, dynamic>),
      visualPlate:
          VisualPlate.fromJson(json['visualPlate'] as Map<String, dynamic>),
      weeklyAdjustment: WeeklyAdjustment.fromJson(
          json['weeklyAdjustment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$NutritionPlanImplToJson(_$NutritionPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'algorithmVersion': instance.algorithmVersion,
      'calculatedAt': const TimestampConverter().toJson(instance.calculatedAt),
      'baseMetrics': instance.baseMetrics,
      'macroTargets': instance.macroTargets,
      'visualPlate': instance.visualPlate,
      'weeklyAdjustment': instance.weeklyAdjustment,
    };

_$BaseMetricsImpl _$$BaseMetricsImplFromJson(Map<String, dynamic> json) =>
    _$BaseMetricsImpl(
      weightKg: (json['weightKg'] as num).toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num).toDouble(),
      fatFreeMassKg: (json['fatFreeMassKg'] as num).toDouble(),
      bmr: (json['bmr'] as num).toDouble(),
      tdee: (json['tdee'] as num).toDouble(),
      activityMultiplier: (json['activityMultiplier'] as num).toDouble(),
    );

Map<String, dynamic> _$$BaseMetricsImplToJson(_$BaseMetricsImpl instance) =>
    <String, dynamic>{
      'weightKg': instance.weightKg,
      'bodyFatPercentage': instance.bodyFatPercentage,
      'fatFreeMassKg': instance.fatFreeMassKg,
      'bmr': instance.bmr,
      'tdee': instance.tdee,
      'activityMultiplier': instance.activityMultiplier,
    };

_$MacroTargetsImpl _$$MacroTargetsImplFromJson(Map<String, dynamic> json) =>
    _$MacroTargetsImpl(
      totalCalories: (json['totalCalories'] as num).toInt(),
      proteinGrams: (json['proteinGrams'] as num).toInt(),
      fatGrams: (json['fatGrams'] as num).toInt(),
      carbsGrams: (json['carbsGrams'] as num).toInt(),
    );

Map<String, dynamic> _$$MacroTargetsImplToJson(_$MacroTargetsImpl instance) =>
    <String, dynamic>{
      'totalCalories': instance.totalCalories,
      'proteinGrams': instance.proteinGrams,
      'fatGrams': instance.fatGrams,
      'carbsGrams': instance.carbsGrams,
    };

_$VisualPlateImpl _$$VisualPlateImplFromJson(Map<String, dynamic> json) =>
    _$VisualPlateImpl(
      vegetablesPercent: (json['vegetablesPercent'] as num).toDouble(),
      proteinPercent: (json['proteinPercent'] as num).toDouble(),
      carbsPercent: (json['carbsPercent'] as num).toDouble(),
      carbsType: json['carbsType'] as String,
    );

Map<String, dynamic> _$$VisualPlateImplToJson(_$VisualPlateImpl instance) =>
    <String, dynamic>{
      'vegetablesPercent': instance.vegetablesPercent,
      'proteinPercent': instance.proteinPercent,
      'carbsPercent': instance.carbsPercent,
      'carbsType': instance.carbsType,
    };

_$WeeklyAdjustmentImpl _$$WeeklyAdjustmentImplFromJson(
        Map<String, dynamic> json) =>
    _$WeeklyAdjustmentImpl(
      isAdjusted: json['isAdjusted'] as bool? ?? false,
      lastAdjustmentDate: _$JsonConverterFromJson<Object, DateTime>(
          json['lastAdjustmentDate'], const TimestampConverter().fromJson),
      adjustmentReason: json['adjustmentReason'] as String?,
    );

Map<String, dynamic> _$$WeeklyAdjustmentImplToJson(
        _$WeeklyAdjustmentImpl instance) =>
    <String, dynamic>{
      'isAdjusted': instance.isAdjusted,
      'lastAdjustmentDate': _$JsonConverterToJson<Object, DateTime>(
          instance.lastAdjustmentDate, const TimestampConverter().toJson),
      'adjustmentReason': instance.adjustmentReason,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
