import '../entities/nutrition_plan.dart';

abstract class NutritionRepository {
  Future<void> saveNutritionPlan(NutritionPlan plan);
  Future<NutritionPlan?> getCurrentPlan(String userId);
  Stream<NutritionPlan?> watchCurrentPlan(String userId);
}
