import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommendation_plan.freezed.dart';
part 'recommendation_plan.g.dart';

@freezed
class RecommendationPlan with _$RecommendationPlan {
  const factory RecommendationPlan({
    // 1. Hidratación
    required double dailyWaterIntakeLitres,
    
    // 2. Ayuno
    required String recommendedFastingProtocol, // e.g., '14:10'
    required String fastingWindowDescription, // e.g., 'Cena antes de las 8pm'

    // 3. Ejercicio (Zona 2 / MAF)
    required int exerciseZoneHeartRate, // MAF 180 Formula
    required String exerciseFrequency, // e.g., 'Caminata 45min diarios'
    required String exerciseDescription, // Explicación de Zona 2

    // 4. Monitoreo de Glucosa
    required bool requiresGlucometer,
    String? glucoseTargetFasting, // e.g., '< 100 mg/dL'
    String? glucoseTargetPostMeal, // e.g., '< 140 mg/dL'
    String? monitoringFocusMessage, // Mensaje educativo

    // Metadata
    required DateTime generatedAt,
  }) = _RecommendationPlan;

  factory RecommendationPlan.fromJson(Map<String, dynamic> json) =>
      _$RecommendationPlanFromJson(json);
}
