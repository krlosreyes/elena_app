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

  // ── SPEC-138: UPF (NOVA 4) en el plato ────────────────────────────────

  group('SPEC-138 — PlateBuilder.upfSlots', () {
    test('plato vacio: upfSlots 0', () {
      expect(PlateBuilder().upfSlots, 0);
    });

    test('solo NOVA 1: upfSlots 0', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('aguacate'));
      expect(b.upfSlots, 0);
      expect(b.hasUltraProcessed, isFalse);
    });

    test('1 galleta (NOVA 4, categoría carb=2 slots) cuenta 2', () {
      final b = PlateBuilder()..add(_food('galletas'));
      expect(b.upfSlots, 2);
      expect(b.hasUltraProcessed, isTrue);
    });

    test('1 margarina (NOVA 4, categoría fat=1 slot) cuenta 1', () {
      final b = PlateBuilder()..add(_food('margarina'));
      expect(b.upfSlots, 1);
    });

    test('mix: pollo (NOVA 1, 2) + gaseosa (NOVA 4, 2) = upfSlots 2', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('gaseosa'));
      expect(b.totalSlots, 4);
      expect(b.upfSlots, 2);
      expect(b.hasUltraProcessed, isTrue);
    });
  });

  group('SPEC-138 — PlateBuilder.upfSharePercent', () {
    test('plato vacío: 0% (sin división por cero)', () {
      expect(PlateBuilder().upfSharePercent, 0);
    });

    test('100% UPF: solo galletas', () {
      final b = PlateBuilder()..add(_food('galletas'));
      expect(b.upfSharePercent, 100);
    });

    test('50% UPF: pollo + gaseosa (2 slots cada uno)', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('gaseosa'));
      expect(b.upfSharePercent, 50);
    });

    test('0% UPF: plato 100% natural', () {
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('aguacate'))
        ..add(_food('brocoli'));
      expect(b.upfSharePercent, 0);
    });

    test('redondeo a entero: 1 margarina + 1 pollo = 20%', () {
      // pollo 2 slots, margarina 1 slot → 1/5 = 20%
      final b = PlateBuilder()
        ..add(_food('pollo'))
        ..add(_food('brocoli'))
        ..add(_food('margarina'));
      expect(b.totalSlots, 5);
      expect(b.upfSlots, 1);
      expect(b.upfSharePercent, 20);
    });
  });

  group('SPEC-138 — ortogonalidad con qualityScore', () {
    test('plato puede tener qualityPercent alto y UPF presente', () {
      // Margarina tiene qualityScore=30 pero NOVA 4. Pollo+aguacate
      // sostienen el plato por encima del 60% pero el UPF% no es 0.
      final b = PlateBuilder()
        ..add(_food('pollo'))      // q95, slots 2
        ..add(_food('aguacate'))   // q100, slots 1
        ..add(_food('margarina')); // q30, slots 1
      // q = (95*2 + 100*1 + 30*1) / 4 = 320/4 = 80
      expect(b.qualityPercent, 80);
      // upf% = 1/4 = 25
      expect(b.upfSharePercent, 25);
    });

    test('leche entera: NOVA 1 pero qualityScore medio (50)', () {
      // Demuestra que NOVA y qualityScore son independientes.
      final f = _food('leche_entera');
      expect(f.nova, NovaGroup.unprocessed);
      expect(f.qualityScore, lessThanOrEqualTo(50));
      expect(f.isUltraProcessed, isFalse);
    });
  });
}
