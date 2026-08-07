// SPEC-274 — Tests del score de adherencia a la Minuta.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/minuta_adherence_score.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart'
    show MealSlot;
import 'package:flutter_test/flutter_test.dart';

void main() {
  MealPlan planWith(List<MealSlot> slots) => MealPlan(
        date: '2026-08-08',
        meals: [for (final s in slots) MealPlanEntry(slot: s)],
      );

  group('adherence', () {
    test('0 sin comidas', () {
      expect(MinutaAdherenceScore.adherence(planWith(const [])), 0.0);
    });

    test('cumplidas / propuestas (Comí y Cambié cuentan, saltar no)', () {
      var plan =
          planWith([MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]);
      plan = plan.markAdherence(MealSlot.breakfast, AdherenceMark.ate);
      plan = plan.markAdherence(MealSlot.lunch, AdherenceMark.changed);
      plan = plan.markAdherence(MealSlot.dinner, AdherenceMark.skipped);
      // 2 de 3 cumplidas.
      expect(MinutaAdherenceScore.adherence(plan), closeTo(2 / 3, 1e-9));
    });

    test('todas cumplidas → 1.0', () {
      var plan = planWith([MealSlot.breakfast, MealSlot.lunch]);
      plan = plan.markAdherence(MealSlot.breakfast, AdherenceMark.ate);
      plan = plan.markAdherence(MealSlot.lunch, AdherenceMark.ate);
      expect(MinutaAdherenceScore.adherence(plan), 1.0);
    });
  });

  group('effective — guardarraíl de no-regresión', () {
    test('sin minuta → devuelve el fallback (cero cambio)', () {
      expect(
        MinutaAdherenceScore.effective(fallbackScore: 0.42, plan: null),
        0.42,
      );
    });

    test('minuta generada pero SIN marcar → fallback', () {
      final plan = planWith([MealSlot.breakfast, MealSlot.lunch]);
      expect(plan.markedCount, 0);
      expect(
        MinutaAdherenceScore.effective(fallbackScore: 0.42, plan: plan),
        0.42,
      );
    });

    test('minuta con al menos una marca → usa la adherencia', () {
      var plan = planWith([MealSlot.breakfast, MealSlot.lunch]);
      plan = plan.markAdherence(MealSlot.breakfast, AdherenceMark.ate);
      // 1 de 2 = 0.5, ignora el fallback.
      expect(
        MinutaAdherenceScore.effective(fallbackScore: 0.42, plan: plan),
        0.5,
      );
    });

    test('fallback se clampa a [0,1]', () {
      expect(
        MinutaAdherenceScore.effective(fallbackScore: 1.5, plan: null),
        1.0,
      );
    });
  });
}
