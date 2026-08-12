// SPEC-284 (antes SPEC-282) — El motor nunca SIRVE un alimento con cautela
// de medicina funcional (histamina/inflamación) como plato sugerido.
//
// Con el contrato receta-primero (1.C), la comida ES una receta del recetario.
// El invariante se cumple curando el recetario: ninguna receta usa un alimento
// con cautela como ingrediente central. Estos tests lo blindan.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  bool hasCaution(String foodId) =>
      (FoodCatalog.byId(foodId)?.cautions ?? const []).isNotEmpty;

  test('sanity: el cerdo tiene cautelas', () {
    expect(hasCaution('cerdo'), true);
  });

  test('ninguna receta del recetario usa un alimento con cautela', () {
    for (final r in RecipeCatalog.all) {
      for (final id in r.foodIds) {
        expect(hasCaution(id), false,
            reason: 'la receta ${r.id} usa $id que tiene cautela');
      }
    }
  });

  test('la minuta generada nunca incluye un alimento con cautela', () {
    for (final foods in [
      ['cerdo'],
      ['pollo', 'aguacate'],
      ['huevo'],
      ['salmon', 'brocoli'],
    ]) {
      final plan = gen.generate(
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
      for (final meal in plan.meals) {
        for (final it in meal.items) {
          expect(hasCaution(it.foodId), false,
              reason: 'intake $foods → sirvió ${it.foodId} con cautela');
        }
      }
    }
  });
}
