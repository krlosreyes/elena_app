// SPEC-297 — La minuta del día no repite recetas entre comidas, prefiere una
// proteína principal distinta cuando se puede, y marca honestamente qué es del
// usuario ("suyo") y qué es sugerencia ("Nuevo").

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  NutritionIntake repertoireWith(List<String> ids) => NutritionIntake(
        updatedAt: DateTime(2026, 8, 12),
        repertoire: ids.map((id) => IntakeItem(foodId: id)).toList(),
      );

  MealPlan gen1(NutritionIntake i, {String dateId = '2026-08-12'}) =>
      gen.generate(intake: i, targetProteinG: 90, dateId: dateId);

  String? principalProtein(String? recipeId) {
    if (recipeId == null) return null;
    final r = RecipeCatalog.byId(recipeId);
    if (r == null) return null;
    for (final ing in r.ingredients) {
      final id = ing.foodId;
      if (id == null || id.isEmpty) continue;
      if (FoodCatalog.byId(id)?.category == FoodCategory.protein) return id;
    }
    return null;
  }

  test('no repite la misma receta entre las comidas del día', () {
    final i = repertoireWith(
        ['huevo', 'pollo', 'salmon', 'aguacate', 'brocoli', 'espinaca']);
    for (var d = 10; d <= 24; d++) {
      final dateId = '2026-08-${d.toString().padLeft(2, '0')}';
      final ids = gen1(i, dateId: dateId)
          .meals
          .map((m) => m.recipeId)
          .whereType<String>()
          .toList();
      expect(ids.toSet().length, ids.length,
          reason: 'día $dateId repite receta: $ids');
    }
  });

  test('prefiere proteína principal distinta entre comidas cuando se puede',
      () {
    // Con pollo, salmón y huevo, las tres comidas pueden tener proteína
    // principal distinta; el motor no debería servir la misma dos veces.
    final i = repertoireWith(
        ['huevo', 'pollo', 'salmon', 'aguacate', 'brocoli', 'espinaca']);
    final plan = gen1(i);
    final proteins = plan.meals
        .map((m) => principalProtein(m.recipeId))
        .whereType<String>()
        .toList();
    expect(proteins.toSet().length, proteins.length,
        reason: 'repite proteína principal: $proteins');
  });

  test('marca "Nuevo" los ingredientes de la receta que el usuario no eligió',
      () {
    // Solo escoge pollo → la receta trae vegetales/grasa que él no seleccionó:
    // deben quedar como sugerencia ("Nuevo"), no como suyos.
    final i = NutritionIntake(
      updatedAt: DateTime(2026, 8, 12),
      meals: [
        IntakeMeal(slot: MealSlot.lunch, items: [IntakeItem(foodId: 'pollo')]),
      ],
    );
    final e = gen
        .generate(intake: i, targetProteinG: 60, dateId: '2026-08-12')
        .meals
        .single;

    expect(e.recipeId, isNotNull);

    final pollo = e.items.firstWhere((it) => it.foodId == 'pollo');
    expect(pollo.origin, PlanItemOrigin.fromUser,
        reason: 'lo que el usuario eligió debe ser "suyo"');

    // Al menos un acompañamiento no elegido, marcado como sugerencia.
    expect(
        e.items.any((it) =>
            it.foodId != 'pollo' && it.origin == PlanItemOrigin.newSuggestion),
        true,
        reason: 'los ingredientes no elegidos deben marcarse "Nuevo"');

    // Nada que el usuario no eligió debe figurar como suyo.
    final asUser = e.items
        .where((it) => it.origin == PlanItemOrigin.fromUser)
        .map((it) => it.foodId)
        .toList();
    expect(asUser, ['pollo'],
        reason: 'solo lo elegido puede ser fromUser: $asUser');
  });
}
