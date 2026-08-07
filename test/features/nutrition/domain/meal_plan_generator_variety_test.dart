// SPEC-275 — Variedad/rotación: el motor evita repetir alimentos de
// `avoidFoodIds` (p. ej. los de ayer) sin sacrificar la calidad del plato.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  final anyFat = FoodCatalog.byCategory(FoodCategory.fat).first;

  NutritionIntake intake() => NutritionIntake(
        updatedAt: DateTime(2026, 8, 8),
        meals: [
          IntakeMeal(slot: MealSlot.lunch, items: [IntakeItem(foodId: anyFat.id)]),
        ],
      );

  String proteinIdOf(MealPlan plan) => plan.meals.single.items
      .firstWhere((i) => i.role == PlanItemRole.protein)
      .foodId;

  test('evitar la proteína de ayer produce una distinta hoy', () {
    final day1 = gen.generate(
        intake: intake(), targetProteinG: 60, dateId: '2026-08-08', phase: 1);
    final p1 = proteinIdOf(day1);

    final day2 = gen.generate(
      intake: intake(),
      targetProteinG: 60,
      dateId: '2026-08-09',
      phase: 1,
      avoidFoodIds: {p1},
    );
    final p2 = proteinIdOf(day2);

    expect(p2, isNot(p1));
  });

  test('sin avoid, el resultado es el mismo (determinismo intacto)', () {
    final a = gen.generate(
        intake: intake(), targetProteinG: 60, dateId: '2026-08-08', phase: 1);
    final b = gen.generate(
        intake: intake(), targetProteinG: 60, dateId: '2026-08-08', phase: 1);
    expect(proteinIdOf(a), proteinIdOf(b));
  });

  test('si TODO está evitado, igual entrega un plato completo (calidad > variedad)',
      () {
    // Evitar todas las proteínas del catálogo → el motor igual pone una.
    final allProteinIds =
        FoodCatalog.byCategory(FoodCategory.protein).map((f) => f.id).toSet();
    final plan = gen.generate(
      intake: intake(),
      targetProteinG: 60,
      dateId: '2026-08-10',
      phase: 1,
      avoidFoodIds: allProteinIds,
    );
    expect(
      plan.meals.single.items.any((i) => i.role == PlanItemRole.protein),
      true,
    );
  });
}
