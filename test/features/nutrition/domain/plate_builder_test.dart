// Tests del PlateBuilder — SPEC-137 E.3.
//
// Cubre:
// - add/remove/clear.
// - Distribución por categoría (slots).
// - Cálculo de calidad (PlateQuality) y MealRatio derivado.
// - Generación del tip accionable.
// - Edge cases: plato vacío, cheat day activo, solo Tipo A o solo E.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/plate_builder.dart';
import 'package:flutter_test/flutter_test.dart';

Food _food(String id) {
  final f = FoodCatalog.byId(id);
  if (f == null) throw StateError('test setup: $id no existe');
  return f;
}

void main() {
  group('PlateBuilder — operaciones básicas', () {
    test('arranca vacío', () {
      final b = PlateBuilder();
      expect(b.isEmpty, isTrue);
      expect(b.itemCount, 0);
      expect(b.totalSlots, 0);
    });

    test('add agrega y aumenta itemCount + totalSlots', () {
      final b = PlateBuilder();
      b.add(_food('pollo'));
      expect(b.itemCount, 1);
      expect(b.totalSlots, 2);
      b.add(_food('brocoli'));
      expect(b.itemCount, 2);
      expect(b.totalSlots, 4);
    });

    test('remove elimina sólo la primera ocurrencia', () {
      final b = PlateBuilder();
      b.add(_food('pollo'));
      b.add(_food('pollo'));
      expect(b.itemCount, 2);
      b.remove(_food('pollo'));
      expect(b.itemCount, 1);
    });

    test('remove de food inexistente no rompe', () {
      final b = PlateBuilder();
      b.add(_food('pollo'));
      b.remove(_food('arroz'));
      expect(b.itemCount, 1);
    });

    test('clear vacía todo', () {
      final b = PlateBuilder();
      b.add(_food('pollo'));
      b.add(_food('arroz'));
      b.clear();
      expect(b.isEmpty, isTrue);
    });

    test('items es inmutable (no permite mutación externa)', () {
      final b = PlateBuilder();
      b.add(_food('pollo'));
      final list = b.items;
      expect(() => list.add(_food('arroz')), throwsUnsupportedError);
    });
  });

  group('PlateBuilder — distribución por categoría', () {
    test('slotsForCategory cuenta los slots correctos', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // 2 protein
        ..add(_food('brocoli')) // 2 carb
        ..add(_food('aguacate')); // 1 fat
      expect(b.slotsForCategory(FoodCategory.protein), 2);
      expect(b.slotsForCategory(FoodCategory.carb), 2);
      expect(b.slotsForCategory(FoodCategory.fat), 1);
      expect(b.totalSlots, 5);
    });

    test('qualityASlotsForCategory ignora alimentos Tipo E', () {
      final b = PlateBuilder()
        ..add(_food('brocoli')) // 2 carb A
        ..add(_food('arroz')); // 2 carb E
      expect(b.slotsForCategory(FoodCategory.carb), 4);
      expect(b.qualityASlotsForCategory(FoodCategory.carb), 2,
          reason: 'solo brócoli (A) cuenta como A');
    });
  });

  group('PlateBuilder — qualityFraction y aSlots/eSlots', () {
    test('plato vacío → fracción 0', () {
      expect(PlateBuilder().qualityFraction, 0.0);
    });

    test('plato 100% Tipo A → fracción 1.0', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('brocoli'));
      expect(b.qualityFraction, 1.0);
      expect(b.aSlots, 4);
      expect(b.eSlots, 0);
    });

    test('plato 100% Tipo E → fracción 0.0', () {
      final b = PlateBuilder()..add(_food('arroz'))..add(_food('pan'));
      expect(b.qualityFraction, 0.0);
      expect(b.eSlots, 4);
      expect(b.aSlots, 0);
    });

    test('mezcla pollo + brócoli + aguacate + arroz → 5/7 ≈ 0.71', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // 2 A protein
        ..add(_food('brocoli')) // 2 A carb
        ..add(_food('aguacate')) // 1 A fat
        ..add(_food('arroz')); // 2 E carb
      expect(b.totalSlots, 7);
      expect(b.aSlots, 5);
      expect(b.eSlots, 2);
      expect(b.qualityFraction, closeTo(0.714, 0.01));
    });
  });

  group('PlateBuilder.quality — thresholds del badge', () {
    test('plato vacío → cheatDay (no hay nada que evaluar)', () {
      expect(PlateBuilder().quality(), PlateQuality.cheatDay);
    });

    test('cheatDayActive=true fuerza cheatDay incluso si todo es A', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('brocoli'));
      expect(b.quality(cheatDayActive: true), PlateQuality.cheatDay);
    });

    test('fracción >= 0.85 → excellent', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('brocoli'));
      expect(b.qualityFraction, 1.0);
      expect(b.quality(), PlateQuality.excellent);
    });

    test('fracción 0.60-0.84 → good', () {
      // pollo (2 A) + brócoli (2 A) + arroz (2 E) = 4/6 ≈ 0.67
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('arroz'));
      expect(b.qualityFraction, closeTo(0.67, 0.01));
      expect(b.quality(), PlateQuality.good);
    });

    test('fracción 0.35-0.59 → needsWork', () {
      // pollo (2 A) + arroz (2 E) + pan (2 E) = 2/6 ≈ 0.33 — abajo
      // del threshold. Necesitamos algo entre 35-59%.
      // brócoli (2 A) + arroz (2 E) + pan (2 E) = 2/6 ≈ 0.33 también.
      // pollo (2 A) + brócoli (2 A) + arroz (2 E) + pan (2 E) = 4/8 = 0.5
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('arroz'))
        ..add(_food('pan'));
      expect(b.qualityFraction, 0.5);
      expect(b.quality(), PlateQuality.needsWork);
    });

    test('fracción < 0.35 → cheatDay', () {
      final b = PlateBuilder()
        ..add(_food('arroz'))
        ..add(_food('pan'))
        ..add(_food('pasta'));
      expect(b.quality(), PlateQuality.cheatDay);
    });
  });

  group('PlateBuilder.tip — sugerencias accionables', () {
    test('plato vacío → null tip', () {
      expect(PlateBuilder().tip(), isNull);
    });

    test('plato excellent → null tip (no hay nada que sugerir)', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('brocoli'));
      expect(b.tip(), isNull);
    });

    test('cheatDayActive → null tip (es decisión consciente)', () {
      final b = PlateBuilder()..add(_food('arroz'));
      expect(b.tip(cheatDayActive: true), isNull);
    });

    test('plato good con arroz → tip cambia arroz por brócoli o espinaca',
        () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('arroz'));
      final t = b.tip();
      expect(t, isNotNull);
      expect(t, contains('arroz'));
      expect(t, contains('brócoli'));
      expect(t, contains('Excelente'));
    });

    test('tip menciona el próximo nivel arriba (good → excellent)', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('arroz'));
      // 2/4 = 0.5 → needsWork; próximo arriba es good.
      final t = b.tip();
      expect(t, contains('Buen plato'),
          reason: 'desde needsWork el próximo nivel es good');
    });

    test('food sin substituteHint → sugerencia de "reducir"', () {
      // Leche, chocolate y yogur_azucarado no tienen substituteHint.
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('leche'));
      final t = b.tip();
      expect(t, isNotNull);
      expect(t, contains('leche'));
      expect(t!.toLowerCase(), contains('reduc'),
          reason: 'leche no tiene substituto; debe sugerir reducir');
    });

    test('cuando hay varios E, prioriza el que tiene substituteHint', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('leche')) // E sin hint
        ..add(_food('arroz')); // E con hint
      final t = b.tip();
      expect(t, contains('arroz'),
          reason: 'arroz tiene hint y debe ganar prioridad sobre leche');
    });
  });

  group('PlateBuilder.derivedMealRatio — puente a la persistencia', () {
    test('plato vacío → a2e1 (default seguro)', () {
      expect(PlateBuilder().derivedMealRatio, MealRatio.a2e1);
    });

    test('100% Tipo A → allA', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('brocoli'));
      expect(b.derivedMealRatio, MealRatio.allA);
    });

    test('100% Tipo E → allE', () {
      final b = PlateBuilder()..add(_food('arroz'))..add(_food('pan'));
      expect(b.derivedMealRatio, MealRatio.allE);
    });

    test('fracción ≈ 0.71 → a3e1 (≥ 0.70)', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      expect(b.qualityFraction, closeTo(0.714, 0.01));
      expect(b.derivedMealRatio, MealRatio.a3e1);
    });

    test('fracción ≈ 0.67 → a2e1 (entre 0.55 y 0.70)', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('arroz'));
      expect(b.derivedMealRatio, MealRatio.a2e1);
    });

    test('fracción 0.5 → a1e1', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('arroz'))
        ..add(_food('pan'));
      expect(b.derivedMealRatio, MealRatio.a1e1);
    });
  });

  group('PlateQuality.nextLevelUp', () {
    test('cheatDay → needsWork', () {
      expect(PlateQuality.cheatDay.nextLevelUp, PlateQuality.needsWork);
    });

    test('needsWork → good', () {
      expect(PlateQuality.needsWork.nextLevelUp, PlateQuality.good);
    });

    test('good → excellent', () {
      expect(PlateQuality.good.nextLevelUp, PlateQuality.excellent);
    });

    test('excellent → null (es el tope)', () {
      expect(PlateQuality.excellent.nextLevelUp, isNull);
    });

    test('label retorna copy LatAm', () {
      expect(PlateQuality.excellent.label, 'Excelente plato');
      expect(PlateQuality.good.label, 'Buen plato');
      expect(PlateQuality.needsWork.label, 'Plato mejorable');
      expect(PlateQuality.cheatDay.label, 'Día de permitidos');
    });
  });
}
