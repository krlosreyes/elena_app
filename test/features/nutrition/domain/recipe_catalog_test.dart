// SPEC-278 — Integridad del recetario original.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hay una cantidad razonable de recetas', () {
    expect(RecipeCatalog.all.length, greaterThanOrEqualTo(20));
  });

  test('ids únicos', () {
    final ids = RecipeCatalog.all.map((r) => r.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('cada receta está bien formada', () {
    for (final r in RecipeCatalog.all) {
      expect(r.name.trim(), isNotEmpty, reason: r.id);
      expect(r.servings, greaterThan(0), reason: r.id);
      expect(r.prepMinutes, greaterThanOrEqualTo(0), reason: r.id);
      expect(r.ingredients, isNotEmpty, reason: r.id);
      expect(r.steps, isNotEmpty, reason: r.id);
      expect(r.slots, isNotEmpty, reason: r.id);
      expect(r.diets, isNotEmpty, reason: r.id);
      // Al menos un ingrediente central (con foodId) para poder cruzar.
      expect(r.foodIds, isNotEmpty, reason: r.id);
      // Comible por omnívoros siempre.
      expect(r.diets, contains(DietType.omnivore), reason: r.id);
    }
  });

  test('todos los foodId referenciados existen en el catálogo', () {
    for (final r in RecipeCatalog.all) {
      for (final id in r.foodIds) {
        expect(FoodCatalog.byId(id), isNotNull,
            reason: 'Receta ${r.id} referencia food inexistente: $id');
      }
    }
  });

  test('byId encuentra y byId inexistente devuelve null', () {
    expect(RecipeCatalog.byId(RecipeCatalog.all.first.id), isNotNull);
    expect(RecipeCatalog.byId('__no_existe__'), isNull);
  });
}
