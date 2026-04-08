
import 'package:freezed_annotation/freezed_annotation.dart';
part 'health_plan.freezed.dart';
part 'health_plan.g.dart';

@freezed
abstract class HealthPlan with _$HealthPlan {
  const factory HealthPlan({
    required String protocol,
    required int hydrationGoal,
    required int maxHeartRate,
    required String exerciseStrategy,
    required String exerciseFrequency,
    required String nutritionStrategy,
    required String breakingFastTip,
    String? glucoseStrategy,
    required String whyThisPlan,
    required DateTime generatedAt,
  }) = _HealthPlan;

  factory HealthPlan.fromJson(Map<String, dynamic> json) => _$HealthPlanFromJson(json);
}
