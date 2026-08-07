// SPEC-270 — Tests del modelo NutritionIntake.
//
// Cubre: round-trip JSON completo (incluyendo tipos anidados y enums),
// parsing PERMISIVO ante payload vacío/corrupto (un campo dañado cae a un
// default sensato, no tumba el documento — mismo criterio que MealPreset),
// y las guardas de negocio (isComplete, isMeaningful, allBanned).

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NutritionIntake _sample() => NutritionIntake(
        version: 1,
        updatedAt: DateTime(2026, 8, 7, 9, 15),
        mealsPerDay: 3,
        meals: const [
          IntakeMeal(
            slot: MealSlot.breakfast,
            timeApprox: '07:30',
            items: [
              IntakeItem(foodId: 'arepa', qty: PortionQty.normal),
              IntakeItem(foodId: 'huevo', qty: PortionQty.plenty),
              IntakeItem(freeText: 'jugo de naranja', qty: PortionQty.little),
            ],
          ),
          IntakeMeal(
            slot: MealSlot.lunch,
            timeApprox: '13:00',
            items: [IntakeItem(foodId: 'pollo', qty: PortionQty.normal)],
          ),
        ],
        snacks: const [
          IntakeSnack(
              freeText: 'galletas', frequency: ConsumptionFrequency.daily),
        ],
        drinks: const DrinksProfile(
          sugary: ConsumptionFrequency.daily,
          coffeeSweetened: true,
          alcoholRef: 'consumo_consciente',
        ),
        restrictions: const IntakeRestrictions(
          diet: DietType.omnivore,
          excludes: ['cerdo'],
          allergies: ['mani'],
        ),
        context: const IntakeContext(
          cookTime: LevelLowMidHigh.low,
          budget: LevelLowMidHigh.mid,
          cooksAtHome: true,
        ),
        derived: const DerivedTargets(
          idealWeightKg: 68,
          targetProteinG: 68,
          windowFirst: '07:30',
          windowLast: '19:30',
        ),
      );

  group('NutritionIntake — round-trip JSON', () {
    test('toJson → fromJson preserva los campos clave', () {
      final restored = NutritionIntake.fromJson(_sample().toJson());

      expect(restored.version, 1);
      expect(restored.updatedAt, DateTime(2026, 8, 7, 9, 15));
      expect(restored.mealsPerDay, 3);
      expect(restored.meals.length, 2);
      expect(restored.meals.first.slot, MealSlot.breakfast);
      expect(restored.meals.first.timeApprox, '07:30');
      expect(restored.meals.first.items.length, 3);
      expect(restored.meals.first.items[1].foodId, 'huevo');
      expect(restored.meals.first.items[1].qty, PortionQty.plenty);
      expect(restored.meals.first.items[2].freeText, 'jugo de naranja');
      expect(restored.snacks.single.frequency, ConsumptionFrequency.daily);
      expect(restored.drinks.coffeeSweetened, true);
      expect(restored.drinks.alcoholRef, 'consumo_consciente');
      expect(restored.restrictions.diet, DietType.omnivore);
      expect(restored.restrictions.allBanned, containsAll(['cerdo', 'mani']));
      expect(restored.context.cookTime, LevelLowMidHigh.low);
      expect(
          restored.derived,
          const DerivedTargets(
            idealWeightKg: 68,
            targetProteinG: 68,
            windowFirst: '07:30',
            windowLast: '19:30',
          ));
    });

    test('todos los enums sobreviven el round-trip por su wire', () {
      for (final q in PortionQty.values) {
        expect(PortionQty.fromWire(q.wire), q);
      }
      for (final f in ConsumptionFrequency.values) {
        expect(ConsumptionFrequency.fromWire(f.wire), f);
      }
      for (final d in DietType.values) {
        expect(DietType.fromWire(d.wire), d);
      }
      for (final s in MealSlot.values) {
        expect(MealSlot.fromWire(s.wire), s);
      }
      for (final l in LevelLowMidHigh.values) {
        expect(LevelLowMidHigh.fromWire(l.wire), l);
      }
    });
  });

  group('NutritionIntake — parsing permisivo', () {
    test('payload vacío devuelve defaults sensatos, no lanza', () {
      final i = NutritionIntake.fromJson(const {});
      expect(i.version, kNutritionIntakeSchemaVersion);
      expect(i.mealsPerDay, 3);
      expect(i.meals, isEmpty);
      expect(i.snacks, isEmpty);
      expect(i.drinks.sugary, ConsumptionFrequency.sometimes);
      expect(i.restrictions.diet, DietType.omnivore);
      expect(i.context.cookTime, LevelLowMidHigh.mid);
      expect(i.derived.idealWeightKg, 0);
    });

    test('item de comida corrupto se salta sin tumbar la lista', () {
      final json = {
        'updatedAt': DateTime(2026, 8, 7).toIso8601String(),
        'meals': [
          {
            'slot': 'breakfast',
            'timeApprox': '07:00',
            'items': [
              {'foodId': 'huevo', 'qty': 'normal'},
              'esto-no-es-un-item', // corrupto: no es Map
              {'foodId': 'aguacate', 'qty': 'plenty'},
            ],
          },
        ],
      };
      final i = NutritionIntake.fromJson(json);
      expect(i.meals.single.items.length, 2);
      expect(i.meals.single.items.map((it) => it.foodId),
          containsAll(['huevo', 'aguacate']));
    });

    test('enum desconocido cae a su default seguro', () {
      final item = IntakeItem.fromJson(const {'foodId': 'x', 'qty': 'gigante'});
      expect(item.qty, PortionQty.normal);
      final diet = IntakeRestrictions.fromJson(const {'diet': 'carnivoro'});
      expect(diet.diet, DietType.omnivore);
    });
  });

  group('NutritionIntake — guardas de negocio', () {
    test('isComplete es false sin items con sentido', () {
      final empty = NutritionIntake(updatedAt: DateTime(2026));
      expect(empty.isComplete, false);

      final onlyBlank = NutritionIntake(
        updatedAt: DateTime(2026),
        meals: const [
          IntakeMeal(slot: MealSlot.breakfast, items: [IntakeItem()]),
        ],
      );
      expect(onlyBlank.isComplete, false);
    });

    test('isComplete es true con al menos un item real', () {
      final i = NutritionIntake(
        updatedAt: DateTime(2026),
        meals: const [
          IntakeMeal(
            slot: MealSlot.breakfast,
            items: [IntakeItem(foodId: 'huevo')],
          ),
        ],
      );
      expect(i.isComplete, true);
    });

    test('IntakeItem.isMeaningful distingue vacío de contenido', () {
      expect(const IntakeItem().isMeaningful, false);
      expect(const IntakeItem(foodId: '').isMeaningful, false);
      expect(const IntakeItem(foodId: 'huevo').isMeaningful, true);
      expect(const IntakeItem(freeText: '  ').isMeaningful, false);
      expect(const IntakeItem(freeText: 'tamal').isMeaningful, true);
    });

    test('allBanned une exclusiones y alergias sin duplicar', () {
      const r = IntakeRestrictions(
        excludes: ['cerdo', 'lactosa'],
        allergies: ['mani', 'lactosa'],
      );
      expect(r.allBanned.toSet(), {'cerdo', 'lactosa', 'mani'});
    });
  });
}
