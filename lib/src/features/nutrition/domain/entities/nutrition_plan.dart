
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'nutrition_plan.freezed.dart';
part 'nutrition_plan.g.dart';


@freezed
abstract class NutritionPlan with _$NutritionPlan {
  @JsonSerializable(explicitToJson: true)
  const factory NutritionPlan({
    required String id,
    required String userId,
    @Default('1.0.0') String algorithmVersion,
    @TimestampConverter() required DateTime calculatedAt,
    required BaseMetrics baseMetrics,
    required MacroTargets macroTargets,
    required VisualPlate visualPlate,
    required WeeklyAdjustment weeklyAdjustment,
  }) = _NutritionPlan;

  factory NutritionPlan.fromJson(Map<String, dynamic> json) => _$NutritionPlanFromJson(json);
}

@freezed
abstract class BaseMetrics with _$BaseMetrics {
  const factory BaseMetrics({
    required double weightKg,
    required double bodyFatPercentage,
    required double fatFreeMassKg,
    required double bmr,
    required double tdee,
    required double activityMultiplier,
  }) = _BaseMetrics;

  factory BaseMetrics.fromJson(Map<String, dynamic> json) => _$BaseMetricsFromJson(json);
}

@freezed
abstract class MacroTargets with _$MacroTargets {
  const factory MacroTargets({
    required int totalCalories,
    required int proteinGrams,
    required int fatGrams,
    required int carbsGrams,
  }) = _MacroTargets;

  factory MacroTargets.fromJson(Map<String, dynamic> json) => _$MacroTargetsFromJson(json);
}

@freezed
abstract class VisualPlate with _$VisualPlate {
  const factory VisualPlate({
    required double vegetablesPercent,
    required double proteinPercent,
    required double carbsPercent,
    required String carbsType,
  }) = _VisualPlate;

  factory VisualPlate.fromJson(Map<String, dynamic> json) => _$VisualPlateFromJson(json);
}

@freezed
abstract class WeeklyAdjustment with _$WeeklyAdjustment {
  const factory WeeklyAdjustment({
    @Default(false) bool isAdjusted,
    @TimestampConverter() DateTime? lastAdjustmentDate,
    String? adjustmentReason,
  }) = _WeeklyAdjustment;

  factory WeeklyAdjustment.fromJson(Map<String, dynamic> json) => _$WeeklyAdjustmentFromJson(json);
}

class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json);
    return json as DateTime;
  }

  @override
  Object toJson(DateTime date) => Timestamp.fromDate(date);
}
