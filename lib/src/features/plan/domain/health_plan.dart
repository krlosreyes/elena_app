import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_plan.freezed.dart';
part 'health_plan.g.dart';

@freezed
class HealthPlan with _$HealthPlan {
  const factory HealthPlan({
    // 1. Métricas Base
    required String protocol, // e.g. "16:8"
    required int hydrationGoal, // Vasil of 250ml
    required int maxHeartRate, // MAF 180

    // 2. Estrategias Prescriptivas
    required String exerciseStrategy, // e.g. "Caminata Rápida en Zona 2"
    required String exerciseFrequency, // e.g. "45 min diarios"
    required String nutritionStrategy, // e.g. "Dieta 3x1"
    required String breakingFastTip, // e.g. "Romper con caldo"
    
    // 3. Clínico
    String? glucoseStrategy, // e.g. "Meta < 140 mg/dL"
    required String whyThisPlan, // Explicación personalizada

    // Metadata
    required DateTime generatedAt,
  }) = _HealthPlan;

  factory HealthPlan.fromJson(Map<String, dynamic> json) =>
      _$HealthPlanFromJson(json);
}
