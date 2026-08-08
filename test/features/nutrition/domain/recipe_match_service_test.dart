// SPEC-278 — Tests del motor de cruce recetas ↔ preferencias.

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_match_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svc = RecipeMatchService();

  NutritionIntake intake({
    required List<String> foods,
    DietType diet = DietType.omnivore,
    List<String> excludes = const [],
  }) =>
      NutritionIntake(
        updatedAt: DateTime(2026, 8, 8),
        meals: [
          IntakeMeal(
            slot: MealSlot.lunch,
            items: foods.map((f) => IntakeItem(foodId: f)).toList(),
          ),
        ],
        restrictions: IntakeRestrictions(diet: diet, excludes: excludes),
      );

  test('recomienda primero la receta con más ingredientes que ya comes', () {
    final res = svc.match(
      intake: intake(foods: ['pollo', 'aguacate', 'lechuga', 'tomate']),
      slot: MealSlot.lunch,
    );
    expect(res, isNotEmpty);
    // Pollo a la plancha comparte pollo+lechuga+tomate+aguacate → gana.
    expect(res.first.recipe.id, 'pollo_plancha_ensalada');
    expect(res.first.overlap, 4);
  });

  test('respeta la dieta: vegano no recibe recetas con animal', () {
    final res = svc.match(
      intake: intake(foods: ['tofu', 'brocoli', 'aguacate'], diet: DietType.vegan),
      slot: MealSlot.lunch,
    );
    expect(res, isNotEmpty);
    for (final m in res) {
      expect(m.recipe.fitsDiet(DietType.vegan), true, reason: m.recipe.id);
    }
    // Una receta con pollo NO puede aparecer.
    expect(res.any((m) => m.recipe.id == 'pollo_plancha_ensalada'), false);
  });

  test('excluye recetas que usan un alimento vetado', () {
    final res = svc.match(
      intake: intake(foods: ['pollo', 'lechuga'], excludes: ['pollo']),
      slot: MealSlot.lunch,
      limit: 50,
    );
    for (final m in res) {
      expect(m.recipe.foodIds.contains('pollo'), false, reason: m.recipe.id);
    }
  });

  test('filtra por comida (slot)', () {
    final res = svc.match(
      intake: intake(foods: ['huevo', 'espinaca', 'aguacate']),
      slot: MealSlot.breakfast,
      limit: 50,
    );
    for (final m in res) {
      expect(m.recipe.fitsSlot(MealSlot.breakfast), true, reason: m.recipe.id);
    }
  });

  test('lista de mercado no duplica ingredientes compartidos', () {
    final r1 = RecipeCatalog.byId('pollo_plancha_ensalada')!;
    final r2 = RecipeCatalog.byId('salmon_brocoli_vapor')!;
    final lista = svc.shoppingList([r1, r2]);
    // aceite_oliva está en ambas → aparece una sola vez.
    final aceites = lista.where((t) => t.toLowerCase().contains('aceite de oliva'));
    expect(aceites.length, 1);
  });
}
