// SPEC-281 — Metadatos del Atlas Nutricional en el FoodCatalog.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Food f(String id) {
    final food = FoodCatalog.byId(id);
    expect(food, isNotNull, reason: 'no existe $id');
    return food!;
  }

  test('defaults: un alimento sin enriquecer tiene metadatos vacíos', () {
    final tomate = f('tomate');
    expect(tomate.micros, isEmpty);
    expect(tomate.cautions, isEmpty);
    expect(tomate.vegGroup, isNull);
    expect(tomate.proteinFraction, isNull);
    expect(tomate.qualityNote, isNull);
    expect(tomate.idealUse, isNull);
  });

  test('proteína efectiva por porción (regla del Atlas)', () {
    expect(f('carne_res').proteinFraction, closeTo(0.30, 0.001));
    expect(f('pollo').proteinFraction, closeTo(0.22, 0.001));
    expect(f('salmon').proteinFraction, closeTo(0.20, 0.001));
    expect(f('huevo').proteinFraction, closeTo(0.13, 0.001));
  });

  test('cualquier proteinFraction está en (0,1)', () {
    for (final food in FoodCatalog.all) {
      final pf = food.proteinFraction;
      if (pf != null) {
        expect(pf, greaterThan(0), reason: food.id);
        expect(pf, lessThan(1), reason: food.id);
      }
    }
  });

  test('micros y notas de calidad', () {
    expect(f('salmon').micros, contains('Omega-3'));
    expect(f('carne_res').qualityNote, isNotNull);
    expect(f('aceite_oliva').idealUse, contains('Crudo'));
    expect(f('aguacate').micros, contains('Fibra'));
  });

  test('cautelas: el cerdo marca histamina e inflamación', () {
    final cerdo = f('cerdo');
    expect(cerdo.cautions, contains(FoodCaution.histamine));
    expect(cerdo.cautions, contains(FoodCaution.inflammation));
  });

  test('subgrupos de vegetal', () {
    expect(f('brocoli').vegGroup, VegGroup.cruciferous);
    expect(f('espinaca').vegGroup, VegGroup.leafyGreen);
    expect(f('cebolla').vegGroup, VegGroup.prebiotic);
  });

  test('labels de los enums no están vacíos', () {
    for (final c in FoodCaution.values) {
      expect(c.label.trim(), isNotEmpty);
    }
    for (final g in VegGroup.values) {
      expect(g.label.trim(), isNotEmpty);
    }
  });
}
