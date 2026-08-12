// SPEC-284 — Tests del motor de la Minuta (contrato receta-primero).
//
// Nuevo contrato (decisión 1.C de Carlos): cada comida de la minuta ES una
// receta del recetario (`RecipeCatalog`), elegida por el matcher (SPEC-278)
// según lo que el usuario ya come, respetando dieta + vetos. El motor ya no
// "compone un plato de alimentos sueltos" en el camino principal; eso queda
// como fallback solo si NINGUNA receta encaja.
//
// Los tests introspectan el recetario (no hardcodean ids) para no romperse.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  NutritionIntake intakeWith(
    List<String> foodIds, {
    MealSlot slot = MealSlot.lunch,
  }) =>
      NutritionIntake(
        updatedAt: DateTime(2026, 8, 12),
        meals: [
          IntakeMeal(
            slot: slot,
            items: foodIds.map((id) => IntakeItem(foodId: id)).toList(),
          ),
        ],
      );

  MealPlan gen1(
    NutritionIntake i, {
    String dateId = '2026-08-12',
    int phase = 1,
  }) =>
      gen.generate(
        intake: i,
        targetProteinG: 60,
        dateId: dateId,
        phase: phase,
      );

  MealPlanEntry only(MealPlan p) => p.meals.single;

  test('cada comida ES una receta: recipeId no nulo', () {
    for (final slot in [
      MealSlot.breakfast,
      MealSlot.lunch,
      MealSlot.dinner,
    ]) {
      final e = only(gen1(intakeWith(['huevo', 'aguacate'], slot: slot)));
      expect(e.recipeId, isNotNull,
          reason: 'la comida $slot debería tener receta');
      expect(RecipeCatalog.byId(e.recipeId!), isNotNull,
          reason: 'recipeId ${e.recipeId} debe existir en el recetario');
    }
  });

  test('la receta elegida encaja en la comida (slot) correspondiente', () {
    final e =
        only(gen1(intakeWith(['huevo', 'aguacate'], slot: MealSlot.breakfast)));
    final recipe = RecipeCatalog.byId(e.recipeId!)!;
    expect(recipe.fitsSlot(MealSlot.breakfast), true);
  });

  test('los ítems del plato salen de la receta (no inventados)', () {
    final e = only(gen1(intakeWith(['pollo', 'brocoli'])));
    final recipe = RecipeCatalog.byId(e.recipeId!)!;
    for (final it in e.items) {
      expect(recipe.foodIds.contains(it.foodId), true,
          reason: '${it.foodId} no es ingrediente de ${recipe.id}');
    }
    expect(e.items, isNotEmpty);
  });

  test('respeta la dieta: un vegano nunca recibe una receta con carne', () {
    final intake = NutritionIntake(
      updatedAt: DateTime(2026, 8, 12),
      restrictions: const IntakeRestrictions(diet: DietType.vegan),
      meals: [
        IntakeMeal(
          slot: MealSlot.lunch,
          items: [IntakeItem(foodId: 'lentejas'), IntakeItem(foodId: 'arroz')],
        ),
      ],
    );
    final e = only(gen1(intake));
    final recipe = RecipeCatalog.byId(e.recipeId!)!;
    expect(recipe.fitsDiet(DietType.vegan), true);
  });

  test('determinismo: misma entrada y mismo día → misma minuta', () {
    final i = intakeWith(['pollo', 'brocoli', 'aguacate']);
    final a = only(gen1(i));
    final b = only(gen1(i));
    expect(a.recipeId, b.recipeId);
    expect(a.items.map((x) => x.foodId), b.items.map((x) => x.foodId));
  });

  test('variedad: a lo largo de la semana la receta no es siempre la misma',
      () {
    final i = intakeWith(['huevo', 'aguacate', 'espinaca', 'tomate']);
    final ids = <String?>{};
    for (var d = 10; d <= 20; d++) {
      final dateId = '2026-08-${d.toString().padLeft(2, '0')}';
      ids.add(only(gen1(i, dateId: dateId)).recipeId);
    }
    // Con varias recetas compatibles, la rotación diaria produce variedad.
    expect(ids.length, greaterThan(1));
  });
}
