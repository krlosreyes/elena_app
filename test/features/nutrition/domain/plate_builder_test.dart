// Tests del PlateBuilder — SPEC-137 E.3 (tabla del usuario, 22-may-2026).
//
// Cubre:
// - add/remove/clear.
// - Distribución por categoría (slots).
// - PlateQuality y MealRatio derivado.
// - Tips de mejora basados en composición global (sin verduras como
//   sustituto — el catálogo no las incluye).

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
      b.add(_food('aguacate'));
      expect(b.itemCount, 2);
      expect(b.totalSlots, 3);
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
        ..add(_food('arroz')) // 2 carb
        ..add(_food('aguacate')); // 1 fat
      expect(b.slotsForCategory(FoodCategory.protein), 2);
      expect(b.slotsForCategory(FoodCategory.carb), 2);
      expect(b.slotsForCategory(FoodCategory.fat), 1);
      expect(b.totalSlots, 5);
    });

    test('qualityASlotsForCategory en carbos siempre es 0 (todos son E)',
        () {
      final b = PlateBuilder()
        ..add(_food('arroz'))
        ..add(_food('pan'));
      expect(b.slotsForCategory(FoodCategory.carb), 4);
      expect(b.qualityASlotsForCategory(FoodCategory.carb), 0,
          reason: 'todos los carbos del catálogo son Tipo E');
    });

    test('qualityASlotsForCategory en proteína siempre = slotsForCategory',
        () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('huevo'));
      expect(b.qualityASlotsForCategory(FoodCategory.protein), 4,
          reason: 'todas las proteínas son Tipo A');
    });
  });

  group('PlateBuilder — qualityFraction', () {
    test('plato vacío → 0', () {
      expect(PlateBuilder().qualityFraction, 0.0);
    });

    test('plato 100% proteína → 1.0', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('huevo'));
      expect(b.qualityFraction, 1.0);
    });

    test('plato 100% carbos → 0.0', () {
      final b = PlateBuilder()..add(_food('arroz'))..add(_food('pan'));
      expect(b.qualityFraction, 0.0);
    });

    test('pollo + aguacate + arroz → 3/5 = 0.6', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      expect(b.qualityFraction, closeTo(0.6, 0.01));
    });
  });

  group('PlateBuilder.quality — thresholds del badge', () {
    test('plato vacío → cheatDay', () {
      expect(PlateBuilder().quality(), PlateQuality.cheatDay);
    });

    test('cheatDayActive fuerza cheatDay aunque todo sea A', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.quality(cheatDayActive: true), PlateQuality.cheatDay);
    });

    test('fracción 1.0 → excellent', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.quality(), PlateQuality.excellent);
    });

    test('fracción 0.6 → good (>= 0.60)', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      expect(b.qualityFraction, closeTo(0.6, 0.01));
      expect(b.quality(), PlateQuality.good);
    });

    test('fracción 0.5 → needsWork (>= 0.35 < 0.60)', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('arroz'))
        ..add(_food('pan'));
      // 2A / 6 total = 0.333... mmh, mejor caso:
      final b2 = PlateBuilder()
        ..add(_food('pollo')) // 2 A
        ..add(_food('aguacate')) // 1 A
        ..add(_food('arroz')) // 2 E
        ..add(_food('pan')); // 2 E
      expect(b2.qualityFraction, closeTo(0.43, 0.01));
      expect(b2.quality(), PlateQuality.needsWork);
    });

    test('fracción < 0.35 → cheatDay', () {
      final b = PlateBuilder()
        ..add(_food('aguacate')) // 1 A
        ..add(_food('arroz')) // 2 E
        ..add(_food('pan')); // 2 E
      expect(b.qualityFraction, closeTo(0.2, 0.01));
      expect(b.quality(), PlateQuality.cheatDay);
    });
  });

  group('PlateBuilder.tip — sugerencias accionables (sin verduras)', () {
    test('plato vacío → null tip', () {
      expect(PlateBuilder().tip(), isNull);
    });

    test('plato excellent → null tip', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.tip(), isNull);
    });

    test('cheatDayActive → null tip', () {
      final b = PlateBuilder()..add(_food('arroz'));
      expect(b.tip(cheatDayActive: true), isNull);
    });

    test('solo carbos → sugerir agregar proteína o grasa', () {
      final b = PlateBuilder()..add(_food('arroz'))..add(_food('pan'));
      final t = b.tip();
      expect(t, isNotNull);
      expect(t!.toLowerCase(), contains('solo carbohidratos'));
    });

    test('carbos + grasa, sin proteína → sugerir proteína', () {
      final b = PlateBuilder()
        ..add(_food('aguacate')) // grasa
        ..add(_food('arroz')); // carbo
      // 1A / 3 total = 0.33 → cheatDay, próximo nivel arriba: needsWork.
      final t = b.tip();
      expect(t, isNotNull);
      expect(t!.toLowerCase(), contains('proteína'));
      expect(t.toLowerCase(), contains('equilibrar'));
    });

    test('carbos + proteína, sin grasa → sugerir grasa', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // proteína
        ..add(_food('arroz')) // carbo
        ..add(_food('pan')); // carbo
      // 2A / 6 = 0.33 → cheatDay; ya tiene proteína pero falta grasa.
      final t = b.tip();
      expect(t, isNotNull);
      expect(t!.toLowerCase(), contains('grasa'));
      expect(t.toLowerCase(), contains('equilibrar'));
    });

    test('plato balanceado pero good → sugerir reducir carbos', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // 2 A protein
        ..add(_food('aguacate')) // 1 A fat
        ..add(_food('arroz')); // 2 E carb
      expect(b.qualityFraction, closeTo(0.6, 0.01));
      expect(b.quality(), PlateQuality.good);
      final t = b.tip();
      expect(t, isNotNull);
      expect(t!.toLowerCase(), contains('carbohidrato'));
      expect(t, contains('Excelente'));
    });
  });

  group('PlateBuilder.derivedMealRatio', () {
    test('vacío → a2e1 default', () {
      expect(PlateBuilder().derivedMealRatio, MealRatio.a2e1);
    });

    test('100% A → allA', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.derivedMealRatio, MealRatio.allA);
    });

    test('100% E → allE', () {
      final b = PlateBuilder()..add(_food('arroz'));
      expect(b.derivedMealRatio, MealRatio.allE);
    });

    test('fracción 0.6 → a2e1', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      expect(b.derivedMealRatio, MealRatio.a2e1);
    });

    test('fracción 0.71 → a3e1', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('huevo'))
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      // 5A / 7 = 0.714
      expect(b.qualityFraction, closeTo(0.714, 0.01));
      expect(b.derivedMealRatio, MealRatio.a3e1);
    });
  });

  group('PlateQuality.nextLevelUp y label', () {
    test('progresión nextLevelUp', () {
      expect(PlateQuality.cheatDay.nextLevelUp, PlateQuality.needsWork);
      expect(PlateQuality.needsWork.nextLevelUp, PlateQuality.good);
      expect(PlateQuality.good.nextLevelUp, PlateQuality.excellent);
      expect(PlateQuality.excellent.nextLevelUp, isNull);
    });

    test('labels LatAm', () {
      expect(PlateQuality.excellent.label, 'Excelente plato');
      expect(PlateQuality.good.label, 'Buen plato');
      expect(PlateQuality.needsWork.label, 'Plato mejorable');
      expect(PlateQuality.cheatDay.label, 'Día de permitidos');
    });
  });
}
