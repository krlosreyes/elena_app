// SPEC-289 (fase 3) — Tests del builder IntakeDraft (modelo de repertorio).

import 'package:elena_app/src/features/nutrition/application/intake_draft.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IntakeDraft — repertorio', () {
    test('inicial está vacío y no completo', () {
      final d = IntakeDraft.initial();
      expect(d.repertoire, isEmpty);
      expect(d.isComplete, false);
    });

    test('toggle marca y desmarca', () {
      final d = IntakeDraft.initial();
      d.toggle('pollo');
      expect(d.has('pollo'), true);
      d.toggle('pollo');
      expect(d.has('pollo'), false);
    });

    test('isComplete con ≥3 alimentos', () {
      final d = IntakeDraft.initial()
        ..toggle('pollo')
        ..toggle('arroz');
      expect(d.isComplete, false);
      d.toggle('aguacate');
      expect(d.isComplete, true);
    });

    test('build() escribe repertorio, snacks y régimen', () {
      final d = IntakeDraft.initial()
        ..diet = DietType.vegetarian
        ..toggle('huevo')
        ..toggle('arroz')
        ..toggle('aguacate')
        ..toggleSnack('almendras')
        ..allergies.add('gluten');
      final intake = d.build();
      expect(intake.repertoireFoodIds, {'huevo', 'arroz', 'aguacate'});
      expect(intake.snacks.map((s) => s.foodId), contains('almendras'));
      expect(intake.restrictions.diet, DietType.vegetarian);
      expect(intake.restrictions.allergies, contains('gluten'));
      expect(intake.isComplete, true);
    });

    test('fromIntake(build()) es un round-trip estable del repertorio', () {
      final d = IntakeDraft.initial()
        ..toggle('pollo')
        ..toggle('brocoli')
        ..toggle('aguacate');
      final back = IntakeDraft.fromIntake(d.build());
      expect(back.repertoire, d.repertoire);
    });

    test('fromIntake levanta foodIds de un intake viejo por comida', () {
      final legacy = NutritionIntake(
        updatedAt: DateTime(2026, 8, 12),
        meals: [
          IntakeMeal(slot: MealSlot.lunch, items: [
            IntakeItem(foodId: 'pollo'),
            IntakeItem(foodId: 'arroz'),
          ]),
        ],
      );
      final d = IntakeDraft.fromIntake(legacy);
      expect(d.repertoire, {'pollo', 'arroz'});
    });
  });
}
