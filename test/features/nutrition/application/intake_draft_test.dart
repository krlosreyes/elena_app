// SPEC-270 (fase 2) — Tests del builder IntakeDraft.
//
// Cubre el mapeo draft → dominio: comidas vacías se descartan, snacks/
// bebidas/restricciones se trasladan bien, y fromIntake(build()) es un
// round-trip estable (editar un intake y re-guardarlo no pierde datos).

import 'package:elena_app/src/features/nutrition/application/intake_draft.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IntakeDraft — build()', () {
    test('draft inicial no está completo y no produce comidas', () {
      final d = IntakeDraft.initial(
        breakfastTime: '07:30',
        lunchTime: '13:00',
        dinnerTime: '20:00',
      );
      expect(d.isComplete, false);
      expect(d.build().meals, isEmpty);
    });

    test('solo las comidas con contenido llegan al intake', () {
      final d = IntakeDraft.initial();
      // Desayuno con un item real; almuerzo/cena vacíos.
      d.meals
          .firstWhere((m) => m.slot == MealSlot.breakfast)
          .items
          .add(const IntakeItem(foodId: 'huevo', qty: PortionQty.plenty));

      expect(d.isComplete, true);
      final intake = d.build();
      expect(intake.meals.length, 1);
      expect(intake.meals.single.slot, MealSlot.breakfast);
      expect(intake.meals.single.items.single.foodId, 'huevo');
    });

    test('item en blanco no cuenta como contenido', () {
      final d = IntakeDraft.initial();
      d.meals.first.items.add(const IntakeItem()); // sin id ni texto
      expect(d.isComplete, false);
      expect(d.build().meals, isEmpty);
    });

    test('bebidas: alcohol activo enlaza al protocolo; inactivo no', () {
      final d = IntakeDraft.initial()..drinksAlcohol = true;
      expect(d.build().drinks.alcoholRef, 'consumo_consciente');

      final d2 = IntakeDraft.initial()..drinksAlcohol = false;
      expect(d2.build().drinks.alcoholRef, isNull);
    });

    test('restricciones y contexto se trasladan al intake', () {
      final d = IntakeDraft.initial()
        ..diet = DietType.vegetarian
        ..excludes.add('cerdo')
        ..allergies.add('mani')
        ..cookTime = LevelLowMidHigh.low
        ..cooksAtHome = false;

      final intake = d.build();
      expect(intake.restrictions.diet, DietType.vegetarian);
      expect(intake.restrictions.allBanned, containsAll(['cerdo', 'mani']));
      expect(intake.context.cookTime, LevelLowMidHigh.low);
      expect(intake.context.cooksAtHome, false);
    });
  });

  group('IntakeDraft — fromIntake round-trip', () {
    test('editar y reconstruir preserva comidas, snacks y restricciones', () {
      final original = NutritionIntake(
        updatedAt: DateTime(2026, 8, 7),
        mealsPerDay: 2,
        meals: const [
          IntakeMeal(
            slot: MealSlot.breakfast,
            timeApprox: '07:30',
            items: [IntakeItem(foodId: 'arepa', qty: PortionQty.normal)],
          ),
          IntakeMeal(
            slot: MealSlot.dinner,
            timeApprox: '20:00',
            items: [IntakeItem(foodId: 'pollo', qty: PortionQty.plenty)],
          ),
        ],
        snacks: const [
          IntakeSnack(
              freeText: 'galletas', frequency: ConsumptionFrequency.daily),
        ],
        restrictions: const IntakeRestrictions(
          diet: DietType.pescatarian,
          excludes: ['cerdo'],
          allergies: ['mani'],
        ),
      );

      final rebuilt = IntakeDraft.fromIntake(original).build();

      expect(rebuilt.meals.length, 2);
      expect(
        rebuilt.meals.map((m) => m.slot),
        containsAll([MealSlot.breakfast, MealSlot.dinner]),
      );
      expect(rebuilt.snacks.single.freeText, 'galletas');
      expect(rebuilt.restrictions.diet, DietType.pescatarian);
      expect(rebuilt.restrictions.allBanned, containsAll(['cerdo', 'mani']));
    });

    test('fromIntake conserva comidas extra (slot other)', () {
      final original = NutritionIntake(
        updatedAt: DateTime(2026, 8, 7),
        meals: const [
          IntakeMeal(
            slot: MealSlot.other,
            timeApprox: '17:00',
            items: [IntakeItem(foodId: 'fruta')],
          ),
        ],
      );
      final rebuilt = IntakeDraft.fromIntake(original).build();
      expect(rebuilt.meals.any((m) => m.slot == MealSlot.other), true);
    });
  });
}
