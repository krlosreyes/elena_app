// Tests del PlateBuilder — SPEC-137 E.4 (scoring numerico).

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
  group('PlateBuilder operaciones basicas', () {
    test('arranca vacio', () {
      final b = PlateBuilder();
      expect(b.isEmpty, isTrue);
      expect(b.totalSlots, 0);
      expect(b.qualityPercent, 0);
    });

    test('add agrega item', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.itemCount, 1);
      expect(b.totalSlots, 2);
    });

    test('remove elimina primera ocurrencia', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('pollo'));
      expect(b.itemCount, 2);
      b.remove(_food('pollo'));
      expect(b.itemCount, 1);
    });

    test('clear vacia todo', () {
      final b = PlateBuilder()..add(_food('pollo'));
      b.clear();
      expect(b.isEmpty, isTrue);
    });

    test('items es inmutable', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(() => b.items.add(_food('arroz')), throwsUnsupportedError);
    });
  });

  group('PlateBuilder distribucion por categoria', () {
    test('slotsForCategory cuenta correctamente', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // 2 protein
        ..add(_food('aguacate')) // 1 fat
        ..add(_food('arroz')); // 2 carb
      expect(b.slotsForCategory(FoodCategory.protein), 2);
      expect(b.slotsForCategory(FoodCategory.fat), 1);
      expect(b.slotsForCategory(FoodCategory.carb), 2);
    });

    test('qualityScoreForCategory promedia ponderado por slots', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // protein 95
        ..add(_food('frijoles')); // protein 70
      // Ambos pesan 2 slots cada uno. Promedio: (95*2 + 70*2) / 4 = 82.5 -> 83.
      expect(b.qualityScoreForCategory(FoodCategory.protein),
          inInclusiveRange(82, 83));
    });

    test('qualityScoreForCategory para categoria vacia es 0', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.qualityScoreForCategory(FoodCategory.carb), 0);
    });
  });

  group('PlateBuilder.qualityPercent promedio ponderado', () {
    test('vacio -> 0', () {
      expect(PlateBuilder().qualityPercent, 0);
    });

    test('solo pollo (95) -> 95', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.qualityPercent, 95);
    });

    test('solo azucar (0) -> 0', () {
      final b = PlateBuilder()..add(_food('azucar'));
      expect(b.qualityPercent, 0);
    });

    test('pollo + aguacate + brocoli -> score alto', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // 95, 2 slots = 190
        ..add(_food('aguacate')) // 100, 1 slot = 100
        ..add(_food('brocoli')); // 100, 2 slots = 200
      // (190 + 100 + 200) / 5 = 98
      expect(b.qualityPercent, inInclusiveRange(97, 98));
    });

    test('pollo + arroz blanco -> score medio-bajo', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // 95 x 2 = 190
        ..add(_food('arroz')); // 10 x 2 = 20
      // (190 + 20) / 4 = 52.5 -> 53
      expect(b.qualityPercent, inInclusiveRange(52, 53));
    });

    test('pollo + aguacate + arroz (3x1 aprox) -> >= 60', () {
      final b = PlateBuilder()
        ..add(_food('pollo')) // 95 x 2 = 190
        ..add(_food('aguacate')) // 100 x 1 = 100
        ..add(_food('arroz')); // 10 x 2 = 20
      // (190 + 100 + 20) / 5 = 62
      expect(b.qualityPercent, inInclusiveRange(60, 63));
    });
  });

  group('PlateBuilder.quality niveles cualitativos', () {
    test('vacio -> cheatDay', () {
      expect(PlateBuilder().quality(), PlateQuality.cheatDay);
    });

    test('cheatDayActive fuerza cheatDay', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.quality(cheatDayActive: true), PlateQuality.cheatDay);
    });

    test('score >= 75 -> excellent', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('aguacate'));
      expect(b.qualityPercent, greaterThanOrEqualTo(75));
      expect(b.quality(), PlateQuality.excellent);
    });

    test('score 60-74 -> good', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      expect(b.qualityPercent, inInclusiveRange(60, 74));
      expect(b.quality(), PlateQuality.good);
    });

    test('score 35-59 -> needsWork', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('arroz'));
      expect(b.qualityPercent, inInclusiveRange(35, 59));
      expect(b.quality(), PlateQuality.needsWork);
    });

    test('score < 35 -> cheatDay', () {
      final b = PlateBuilder()
        ..add(_food('arroz'))
        ..add(_food('pan'))
        ..add(_food('azucar'));
      expect(b.qualityPercent, lessThan(35));
      expect(b.quality(), PlateQuality.cheatDay);
    });
  });

  group('PlateBuilder.tip sugerencias accionables', () {
    test('vacio -> null', () {
      expect(PlateBuilder().tip(), isNull);
    });

    test('excellent -> null', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('aguacate'));
      expect(b.tip(), isNull);
    });

    test('cheatDayActive -> null', () {
      final b = PlateBuilder()..add(_food('arroz'));
      expect(b.tip(cheatDayActive: true), isNull);
    });

    test('solo carbos -> sugerir proteina Y grasa', () {
      final b = PlateBuilder()..add(_food('arroz'))..add(_food('pan'));
      final t = b.tip();
      expect(t, isNotNull);
      expect(t!.toLowerCase(), contains('solo tiene carbos'));
    });

    test('carbos + grasa, sin proteina -> sugerir proteina', () {
      final b = PlateBuilder()
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      final t = b.tip();
      expect(t, isNotNull);
      expect(t!.toLowerCase(), contains('proteína'));
    });

    test('carbos + proteina, sin grasa -> sugerir grasa', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('arroz'))
        ..add(_food('pan'));
      final t = b.tip();
      expect(t, isNotNull);
      expect(t!.toLowerCase(), contains('grasa'));
    });

    test('plato balanceado pero good -> sugerir reducir item bajo', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      // arroz tiene el score mas bajo (10) — deberia aparecer en el tip.
      final t = b.tip();
      expect(t, isNotNull);
      expect(t!.toLowerCase(), contains('arroz'));
    });
  });

  group('PlateBuilder.derivedMealRatio', () {
    test('vacio -> a2e1', () {
      expect(PlateBuilder().derivedMealRatio, MealRatio.a2e1);
    });

    test('score 100 (todo optimo) -> allA o a3e1', () {
      final b = PlateBuilder()..add(_food('brocoli'));
      expect(b.derivedMealRatio, anyOf(MealRatio.allA, MealRatio.a3e1));
    });

    test('score >= 70 -> a3e1 (3x1)', () {
      final b = PlateBuilder()..add(_food('pollo'));
      expect(b.qualityPercent, greaterThanOrEqualTo(70));
      expect(b.derivedMealRatio, anyOf(MealRatio.allA, MealRatio.a3e1));
    });

    test('score ~62 -> a2e1', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('aguacate'))
        ..add(_food('arroz'));
      expect(b.derivedMealRatio, MealRatio.a2e1);
    });

    test('score ~52 -> a1e1', () {
      final b = PlateBuilder()..add(_food('pollo'))..add(_food('arroz'));
      expect(b.derivedMealRatio, MealRatio.a1e1);
    });

    test('score muy bajo -> allE', () {
      final b = PlateBuilder()
        ..add(_food('arroz'))
        ..add(_food('pan'))
        ..add(_food('azucar'));
      expect(b.derivedMealRatio, MealRatio.allE);
    });
  });

  group('PlateQuality enum', () {
    test('nextLevelUp progresion', () {
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
