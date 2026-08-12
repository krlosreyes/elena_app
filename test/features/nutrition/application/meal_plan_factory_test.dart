// SPEC-273 — Tests de la fábrica pura de la Minuta.
//
// Verifica que la fábrica ata bien ProteinTargetService + el motor: la
// proteína del día se reparte cerca del objetivo derivado de la biometría,
// y el plan sale con la fecha correcta.

import 'package:elena_app/src/features/nutrition/application/meal_plan_factory.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factory = MealPlanFactory();

  // Un alimento real cualquiera para poblar el intake.
  final anyFat = FoodCatalog.byCategory(FoodCategory.fat).first;

  NutritionIntake intake() => NutritionIntake(
        updatedAt: DateTime(2026, 8, 8),
        meals: [
          IntakeMeal(slot: MealSlot.breakfast, items: [IntakeItem(foodId: anyFat.id)]),
          IntakeMeal(slot: MealSlot.lunch, items: [IntakeItem(foodId: anyFat.id)]),
          IntakeMeal(slot: MealSlot.dinner, items: [IntakeItem(foodId: anyFat.id)]),
        ],
      );

  test('build produce un plan del día con proteína ≈ objetivo', () {
    final plan = factory.build(
      intake: intake(),
      heightCm: 185,
      gender: 'M',
      pal: 1.5, // moderado → 1.0 g/kg → ~80 g
      windowFirst: '07:30',
      windowLast: '19:30',
      now: DateTime(2026, 8, 8, 9),
    );

    expect(plan.date, '2026-08-08');
    expect(plan.windowFirst, '07:30');
    expect(plan.meals.length, 3);
    expect(plan.status, PlanStatus.proposed);

    final sum = plan.meals.fold<double>(0, (a, m) => a + m.targetProteinG);
    expect(sum, closeTo(79.5, 1.0));
  });

  test('SPEC-284: cada comida ES una receta con ingredientes', () {
    final plan = factory.build(
      intake: intake(),
      heightCm: 160,
      gender: 'F',
      pal: 1.2,
      now: DateTime(2026, 8, 8),
    );
    for (final meal in plan.meals) {
      expect(meal.recipeId, isNotNull,
          reason: 'la comida ${meal.slot} debería tener receta');
      expect(RecipeCatalog.byId(meal.recipeId!), isNotNull,
          reason: 'recipeId ${meal.recipeId} debe existir en el recetario');
      expect(meal.items, isNotEmpty,
          reason: 'la receta debería aportar ingredientes centrales');
    }
  });
}
