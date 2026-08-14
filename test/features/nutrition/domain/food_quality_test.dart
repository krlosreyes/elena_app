// SPEC-292 — Asesor de calidad de alimentos.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/food_quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un ultraprocesado es "poor" y trae explicación', () {
    final choco = FoodCatalog.byId('chocolatina')!;
    expect(FoodQuality.isPoor(choco), true);
    expect(FoodQuality.explanation(choco), isNotNull);
    expect(FoodQuality.shortReason(choco), isNotNull);
  });

  test('una proteína magra de alta calidad es "good" y sin aviso', () {
    final pollo = FoodCatalog.byId('pollo')!;
    expect(FoodQuality.levelOf(pollo), FoodQualityLevel.good);
    expect(FoodQuality.explanation(pollo), isNull);
    expect(FoodQuality.shortReason(pollo), isNull);
  });

  test('todo alimento del catálogo se clasifica sin crashear', () {
    for (final f in FoodCatalog.all) {
      expect(FoodQuality.levelOf(f), isA<FoodQualityLevel>());
    }
  });
}
