// SPEC-280 — Tests de MealPlan.replaceItem (elegir alternativa).

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart'
    show MealSlot;
import 'package:flutter_test/flutter_test.dart';

void main() {
  MealPlan plan() => const MealPlan(
        date: '2026-08-08',
        meals: [
          MealPlanEntry(
            slot: MealSlot.lunch,
            targetProteinG: 30,
            items: [
              PlanItem(foodId: 'pollo', role: PlanItemRole.protein),
              PlanItem(foodId: 'brocoli', role: PlanItemRole.veg),
            ],
            adherence: AdherenceMark.ate,
          ),
        ],
      );

  test('reemplaza el alimento elegido y preserva el resto', () {
    final updated = plan().replaceItem(
      MealSlot.lunch,
      'pollo',
      const PlanItem(foodId: 'pescado', role: PlanItemRole.protein),
    );
    final meal = updated.meals.single;
    expect(meal.items.map((i) => i.foodId), containsAll(['pescado', 'brocoli']));
    expect(meal.items.any((i) => i.foodId == 'pollo'), false);
    // No pierde la adherencia ya marcada.
    expect(meal.adherence, AdherenceMark.ate);
  });

  test('si el alimento no está, devuelve el mismo plan', () {
    final p = plan();
    final updated = p.replaceItem(
      MealSlot.lunch,
      'no_existe',
      const PlanItem(foodId: 'pescado', role: PlanItemRole.protein),
    );
    expect(identical(updated, p), true);
  });

  test('no toca comidas de otro slot', () {
    const p = MealPlan(
      date: '2026-08-08',
      meals: [
        MealPlanEntry(
          slot: MealSlot.breakfast,
          items: [PlanItem(foodId: 'huevo', role: PlanItemRole.protein)],
        ),
        MealPlanEntry(
          slot: MealSlot.lunch,
          items: [PlanItem(foodId: 'pollo', role: PlanItemRole.protein)],
        ),
      ],
    );
    final updated = p.replaceItem(
      MealSlot.lunch,
      'pollo',
      const PlanItem(foodId: 'atun', role: PlanItemRole.protein),
    );
    expect(
      updated.meals
          .firstWhere((m) => m.slot == MealSlot.breakfast)
          .items
          .single
          .foodId,
      'huevo',
    );
    expect(
      updated.meals
          .firstWhere((m) => m.slot == MealSlot.lunch)
          .items
          .single
          .foodId,
      'atun',
    );
  });
}
