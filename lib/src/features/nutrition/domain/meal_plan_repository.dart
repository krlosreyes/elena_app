// SPEC-271 — Contrato de persistencia de la Minuta Diaria.
// Capa domain pura (mismo patrón que NutritionIntakeRepository).

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';

abstract class MealPlanRepository {
  /// Stream del plan de un día ('yyyy-MM-dd'). Emite `null` si no existe
  /// (aún no generado para ese día).
  Stream<MealPlan?> watchPlan(String userId, String dateId);

  /// Lectura puntual del plan de un día. `null` si no existe.
  Future<MealPlan?> getPlan(String userId, String dateId);

  /// Crea o actualiza (upsert) el plan del día. Usa `plan.date` como id de
  /// documento — regenerar el mismo día sobreescribe.
  Future<void> savePlan(String userId, MealPlan plan);
}
