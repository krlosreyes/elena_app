// SPEC-293 — Cantidad editable por ingrediente (ej. huevo ×3).

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MealPlan planWith(String foodId) => MealPlan(
        date: '2026-08-14',
        meals: [
          MealPlanEntry(
            slot: MealSlot.lunch,
            items: [PlanItem(foodId: foodId)],
          ),
        ],
      );

  test('setItemQuantity fija la cantidad', () {
    final u = planWith('huevo').setItemQuantity(MealSlot.lunch, 'huevo', 3);
    expect(u.meals.single.items.single.quantity, 3);
  });

  test('setItemQuantity acota a >= 1', () {
    final u = planWith('huevo').setItemQuantity(MealSlot.lunch, 'huevo', 0);
    expect(u.meals.single.items.single.quantity, 1);
  });

  test('setItemQuantity es no-op si no cambia', () {
    final plan = planWith('huevo');
    expect(identical(plan.setItemQuantity(MealSlot.lunch, 'huevo', 1), plan),
        true);
    expect(identical(plan.setItemQuantity(MealSlot.lunch, 'x', 3), plan), true);
  });

  test('quantity hace round-trip por JSON (default 1 se omite)', () {
    final tres = PlanItem(foodId: 'huevo', quantity: 3);
    expect(PlanItem.fromJson(tres.toJson()).quantity, 3);
    final uno = const PlanItem(foodId: 'huevo');
    expect(uno.toJson().containsKey('quantity'), false);
    expect(PlanItem.fromJson(uno.toJson()).quantity, 1);
  });
}
