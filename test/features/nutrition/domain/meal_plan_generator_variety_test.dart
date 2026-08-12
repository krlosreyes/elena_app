// SPEC-284 — Variedad de la Minuta con el contrato receta-primero.
//
// La variedad ya no rota "la proteína de ayer": ahora el motor rota, de forma
// DETERMINÍSTICA por día, entre las mejores recetas compatibles. Mismo día →
// misma receta (reproducible); días distintos → puede variar.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  NutritionIntake intake() => NutritionIntake(
        updatedAt: DateTime(2026, 8, 12),
        meals: [
          IntakeMeal(
            slot: MealSlot.lunch,
            items: [
              IntakeItem(foodId: 'pollo'),
              IntakeItem(foodId: 'brocoli'),
              IntakeItem(foodId: 'aguacate'),
            ],
          ),
        ],
      );

  MealPlan run(String dateId) => gen.generate(
        intake: intake(),
        targetProteinG: 60,
        dateId: dateId,
        phase: 1,
      );

  String? recipeOf(String dateId) => run(dateId).meals.single.recipeId;

  test('determinismo: el mismo día produce la misma receta', () {
    expect(recipeOf('2026-08-12'), recipeOf('2026-08-12'));
  });

  test('variedad: a lo largo de varios días la receta cambia', () {
    final ids = <String?>{};
    for (var d = 10; d <= 24; d++) {
      ids.add(recipeOf('2026-08-${d.toString().padLeft(2, '0')}'));
    }
    expect(ids.length, greaterThan(1));
  });

  test('siempre hay receta (recipeId no nulo) para el almuerzo', () {
    expect(recipeOf('2026-08-12'), isNotNull);
  });
}
