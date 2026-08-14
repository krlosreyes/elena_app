// SPEC-292 — Delete del CRUD por ingrediente: MealPlan.removeItem.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MealPlan planWith(List<String> ids) => MealPlan(
        date: '2026-08-13',
        meals: [
          MealPlanEntry(
            slot: MealSlot.lunch,
            items: ids.map((id) => PlanItem(foodId: id)).toList(),
          ),
        ],
      );

  test('removeItem quita el alimento indicado', () {
    final updated = planWith(['pollo', 'arroz', 'aguacate'])
        .removeItem(MealSlot.lunch, 'arroz');
    expect(
      updated.meals.single.items.map((i) => i.foodId),
      ['pollo', 'aguacate'],
    );
  });

  test('removeItem es no-op si el alimento no está', () {
    final plan = planWith(['pollo']);
    expect(identical(plan.removeItem(MealSlot.lunch, 'x'), plan), true);
  });

  test('removeItem preserva recipeId y adherencia de la comida', () {
    final plan = MealPlan(
      date: '2026-08-13',
      meals: [
        MealPlanEntry(
          slot: MealSlot.lunch,
          recipeId: 'pollo_plancha',
          adherence: AdherenceMark.ate,
          items: [PlanItem(foodId: 'pollo'), PlanItem(foodId: 'arroz')],
        ),
      ],
    );
    final m = plan.removeItem(MealSlot.lunch, 'arroz').meals.single;
    expect(m.recipeId, 'pollo_plancha');
    expect(m.adherence, AdherenceMark.ate);
    expect(m.items.map((i) => i.foodId), ['pollo']);
  });
}
