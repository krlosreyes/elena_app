import '../entities/nutrition_plan.dart';
import '../entities/metabolic_nutrition_plan.dart';

abstract class NutritionRepository {
  // ── Legacy (preserved for backwards compatibility) ──
  Future<void> saveNutritionPlan(NutritionPlan plan);
  Future<NutritionPlan?> getCurrentPlan(String userId);
  Stream<NutritionPlan?> watchCurrentPlan(String userId);

  // ── New Metabolic Engine ──
  Future<void> saveMetabolicPlan(String userId, MetabolicNutritionPlan plan);
  Stream<MetabolicNutritionPlan?> watchMetabolicPlan(String userId);
  Future<List<MetabolicNutritionPlan>> getPlanHistory(
      String userId, {int limit = 10});
}
