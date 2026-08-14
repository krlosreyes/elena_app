// SPEC-294 — Proteína por porción y escalado por cantidad.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/food_protein.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('huevo ×3 suma 3× la proteína de un huevo', () {
    final one = platedProteinG([const PlanItem(foodId: 'huevo')]);
    final three =
        platedProteinG([const PlanItem(foodId: 'huevo', quantity: 3)]);
    expect(one, greaterThan(0));
    expect(three, closeTo(one * 3, 0.001));
  });

  test('suma varios ítems escalando por su cantidad', () {
    final p = platedProteinG([
      const PlanItem(foodId: 'pollo'),
      const PlanItem(foodId: 'huevo', quantity: 2),
    ]);
    // pollo 26 + huevo 6×2 = 38
    expect(p, closeTo(38, 0.001));
  });

  test('la proteína está definida para TODO el catálogo (no null)', () {
    for (final f in FoodCatalog.all) {
      expect(proteinPerPortion(f), isA<double>());
      expect(proteinPerPortion(f) >= 0, true);
    }
  });

  test('las proteínas magras aportan más que las verduras', () {
    final pollo = proteinPerPortion(FoodCatalog.byId('pollo')!);
    final lechuga = proteinPerPortion(FoodCatalog.byId('lechuga')!);
    expect(pollo, greaterThan(lechuga));
    expect(pollo, greaterThan(15));
  });
}
