// SPEC-289.2 — El motor genera desde el REPERTORIO plano (sin comida asignada):
// desayuno/almuerzo/cena, cada uno como una receta.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  NutritionIntake repertoireIntake(List<String> ids) => NutritionIntake(
        updatedAt: DateTime(2026, 8, 12),
        repertoire: ids.map((id) => IntakeItem(foodId: id)).toList(),
      );

  test('isComplete: ≥3 alimentos en el repertorio', () {
    expect(repertoireIntake(['pollo', 'arroz']).isComplete, false);
    expect(
      repertoireIntake(['pollo', 'arroz', 'aguacate']).isComplete,
      true,
    );
  });

  test('genera desayuno/almuerzo/cena desde el repertorio', () {
    final plan = gen.generate(
      intake: repertoireIntake(
          ['pollo', 'arroz', 'aguacate', 'huevo', 'brocoli', 'espinaca']),
      targetProteinG: 60,
      dateId: '2026-08-12',
      phase: 1,
    );
    expect(plan.meals.map((m) => m.slot).toList(), [
      MealSlot.breakfast,
      MealSlot.lunch,
      MealSlot.dinner,
    ]);
    for (final m in plan.meals) {
      expect(m.recipeId, isNotNull, reason: '${m.slot} sin receta');
    }
  });

  test('repertorio vacío → sin comidas', () {
    final plan = gen.generate(
      intake: NutritionIntake(updatedAt: DateTime(2026, 8, 12)),
      targetProteinG: 60,
      dateId: '2026-08-12',
      phase: 1,
    );
    expect(plan.meals, isEmpty);
  });
}
