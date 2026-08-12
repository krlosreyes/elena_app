// SPEC-282 — El motor no INTRODUCE alimentos con cautela (histamina/
// inflamación) como sugerencia nueva ni como mejora, pero respeta los que
// el usuario ya come.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  bool hasCaution(String foodId) =>
      (FoodCatalog.byId(foodId)?.cautions ?? const []).isNotEmpty;

  MealPlan gen1(List<String> foods) => gen.generate(
        intake: NutritionIntake(
          updatedAt: DateTime(2026, 8, 12),
          meals: [
            IntakeMeal(
              slot: MealSlot.lunch,
              items: foods.map((f) => IntakeItem(foodId: f)).toList(),
            ),
          ],
        ),
        targetProteinG: 60,
        dateId: '2026-08-12',
        phase: 1,
      );

  test('sanity: el cerdo tiene cautelas', () {
    expect(hasCaution('cerdo'), true);
  });

  test('respeta un alimento con cautela que el usuario YA come', () {
    // El usuario come cerdo: debe seguir en su plato (no lo sacamos).
    final e = gen1(['cerdo']).meals.single;
    final protein =
        e.items.firstWhere((i) => i.role == PlanItemRole.protein);
    expect(protein.foodId, 'cerdo');
    expect(protein.origin, PlanItemOrigin.fromUser);
  });

  test('una sugerencia nueva NUNCA es un alimento con cautela', () {
    // Solo grasa → al motor le falta proteína y vegetal: los sugiere.
    final e = gen1(['aguacate']).meals.single;
    for (final i in e.items) {
      if (i.origin == PlanItemOrigin.newSuggestion) {
        expect(hasCaution(i.foodId), false,
            reason: 'sugirió ${i.foodId} que tiene cautela');
      }
    }
  });

  test('invariante: ningún ítem sugerido/mejora tiene cautela', () {
    for (final foods in [
      ['aguacate'],
      ['huevo'],
      ['arroz'],
      ['pollo', 'aguacate'],
    ]) {
      for (final meal in gen1(foods).meals) {
        for (final i in meal.items) {
          if (i.origin == PlanItemOrigin.newSuggestion ||
              i.origin == PlanItemOrigin.upgrade) {
            expect(hasCaution(i.foodId), false,
                reason: 'intake $foods → introdujo ${i.foodId} con cautela');
          }
        }
      }
    }
  });
}
