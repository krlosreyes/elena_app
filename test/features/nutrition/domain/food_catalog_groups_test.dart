// SPEC-289.1 — Agrupación del catálogo para los checklists del onboarding:
// Proteínas / Carbohidratos / Grasas / Comidas y antojos.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los 4 grupos del usuario tienen alimentos', () {
    for (final g in UserFoodGroup.values) {
      expect(FoodCatalog.byUserGroup(g), isNotEmpty, reason: 'grupo $g vacío');
    }
  });

  test('cada comboId existe y cae en "Comidas y antojos"', () {
    for (final id in FoodCatalog.comboIds) {
      final f = FoodCatalog.byId(id);
      expect(f, isNotNull, reason: '$id no existe en el catálogo');
      expect(FoodCatalog.groupOf(f!), UserFoodGroup.combo);
    }
  });

  test('un combo NO aparece también en su macro', () {
    final combo = FoodCatalog.byUserGroup(UserFoodGroup.combo).map((f) => f.id);
    for (final g in [
      UserFoodGroup.protein,
      UserFoodGroup.carb,
      UserFoodGroup.fat,
    ]) {
      final ids = FoodCatalog.byUserGroup(g).map((f) => f.id).toSet();
      expect(ids.intersection(combo.toSet()), isEmpty,
          reason: 'un combo se coló en $g');
    }
  });

  test('los everyday nuevos están en el catálogo', () {
    for (final id in [
      'perro_caliente',
      'taco',
      'tamal',
      'wrap',
      'nuggets',
      'pollo_frito',
      'papas_fritas',
      'mortadela',
      'salchichon',
      'helado',
      'chocolatina',
    ]) {
      expect(FoodCatalog.byId(id), isNotNull, reason: 'falta $id');
    }
  });

  test('todo alimento pertenece a exactamente un grupo', () {
    for (final f in FoodCatalog.all) {
      final groups = UserFoodGroup.values
          .where((g) => FoodCatalog.byUserGroup(g).contains(f))
          .length;
      expect(groups, 1, reason: '${f.id} está en $groups grupos');
    }
  });
}
