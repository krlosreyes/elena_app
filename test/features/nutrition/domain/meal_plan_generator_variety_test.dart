// SPEC-275 + SPEC-276 — Variedad/rotación: el motor evita repetir la
// proteína de ayer cuando el usuario tiene alternativas, sin sacrificar la
// coherencia del plato.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  final proteins = FoodCatalog.byCategory(FoodCategory.protein).toList()
    ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

  // El usuario come DOS proteínas fuertes: hay con qué rotar.
  final p1 = proteins[0];
  final p2 = proteins[1];

  NutritionIntake intake() => NutritionIntake(
        updatedAt: DateTime(2026, 8, 8),
        meals: [
          IntakeMeal(
            slot: MealSlot.lunch,
            items: [IntakeItem(foodId: p1.id), IntakeItem(foodId: p2.id)],
          ),
        ],
      );

  String proteinIdOf(MealPlan plan) => plan.meals.single.items
      .firstWhere((i) => i.role == PlanItemRole.protein)
      .foodId;

  MealPlan run({Set<String> avoid = const {}}) => gen.generate(
        intake: intake(),
        targetProteinG: 60,
        dateId: '2026-08-08',
        phase: 1,
        avoidFoodIds: avoid,
      );

  test('evitar la proteína de ayer produce otra distinta hoy', () {
    final today = proteinIdOf(run());
    final tomorrow = proteinIdOf(run(avoid: {today}));
    expect(tomorrow, isNot(today));
    expect([p1.id, p2.id], contains(tomorrow));
  });

  test('sin avoid, el resultado es el mismo (determinismo intacto)', () {
    expect(proteinIdOf(run()), proteinIdOf(run()));
  });

  test('si todo está evitado, igual entrega un plato con proteína', () {
    final plan = run(avoid: {p1.id, p2.id});
    expect(
      plan.meals.single.items.any((i) => i.role == PlanItemRole.protein),
      true,
    );
  });
}
