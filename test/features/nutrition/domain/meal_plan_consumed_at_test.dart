// SPEC-298 — La marca de adherencia sella la HORA de consumo (consumedAt):
// ancla de la ventana de alimentación y base de la recomendación de timing.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MealPlan planWith(List<MealPlanEntry> meals) =>
      MealPlan(date: '2026-08-14', meals: meals);

  MealPlanEntry entry(MealSlot slot, {List<PlanItem> items = const []}) =>
      MealPlanEntry(slot: slot, items: items);

  MealPlanEntry lunchOf(MealPlan p) =>
      p.meals.firstWhere((m) => m.slot == MealSlot.lunch);

  test('marcar "Comí" sella la hora provista y deja el plan logged', () {
    final plan = planWith([entry(MealSlot.lunch)]);
    final at = DateTime(2026, 8, 14, 13, 20);

    final updated =
        plan.markAdherence(MealSlot.lunch, AdherenceMark.ate, at: at);

    expect(lunchOf(updated).consumedAt, at);
    expect(lunchOf(updated).adherence, AdherenceMark.ate);
    expect(updated.status, PlanStatus.logged);
  });

  test('marcar "Cambié" también sella hora', () {
    final plan = planWith([entry(MealSlot.dinner)]);
    final at = DateTime(2026, 8, 14, 20, 5);
    final updated =
        plan.markAdherence(MealSlot.dinner, AdherenceMark.changed, at: at);
    expect(updated.meals.single.consumedAt, at);
  });

  test('marcar "Me salté" limpia la hora', () {
    final at = DateTime(2026, 8, 14, 13, 0);
    final plan = planWith([entry(MealSlot.lunch)])
        .markAdherence(MealSlot.lunch, AdherenceMark.ate, at: at);
    expect(lunchOf(plan).consumedAt, at);

    final skipped = plan.markAdherence(MealSlot.lunch, AdherenceMark.skipped);
    expect(lunchOf(skipped).consumedAt, isNull);
    expect(lunchOf(skipped).adherence, AdherenceMark.skipped);
  });

  test('setConsumedAt corrige la hora (el lápiz)', () {
    final plan = planWith([entry(MealSlot.lunch)]).markAdherence(
        MealSlot.lunch, AdherenceMark.ate,
        at: DateTime(2026, 8, 14, 14, 0));
    final corrected =
        plan.setConsumedAt(MealSlot.lunch, DateTime(2026, 8, 14, 12, 30));
    expect(lunchOf(corrected).consumedAt, DateTime(2026, 8, 14, 12, 30));
  });

  test('firstConsumedAt = la más temprana; lastConsumedAt = la más tardía', () {
    final plan = planWith([
      entry(MealSlot.breakfast),
      entry(MealSlot.lunch),
      entry(MealSlot.dinner),
    ])
        .markAdherence(MealSlot.lunch, AdherenceMark.ate,
            at: DateTime(2026, 8, 14, 13, 0))
        .markAdherence(MealSlot.breakfast, AdherenceMark.ate,
            at: DateTime(2026, 8, 14, 8, 15))
        .markAdherence(MealSlot.dinner, AdherenceMark.ate,
            at: DateTime(2026, 8, 14, 20, 40));

    expect(plan.firstConsumedAt, DateTime(2026, 8, 14, 8, 15));
    expect(plan.lastConsumedAt, DateTime(2026, 8, 14, 20, 40));
  });

  test('firstConsumedAt es null si nada se ha marcado', () {
    expect(planWith([entry(MealSlot.lunch)]).firstConsumedAt, isNull);
  });

  test('JSON round-trip preserva consumedAt', () {
    final plan = planWith([entry(MealSlot.lunch)]).markAdherence(
        MealSlot.lunch, AdherenceMark.ate,
        at: DateTime(2026, 8, 14, 13, 45));
    final restored = MealPlan.fromJson(plan.toJson());
    expect(lunchOf(restored).consumedAt, DateTime(2026, 8, 14, 13, 45));
  });

  test('editar cantidad/quitar ingrediente NO pierde la hora', () {
    final plan = planWith([
      entry(MealSlot.lunch, items: const [
        PlanItem(foodId: 'huevo'),
        PlanItem(foodId: 'aguacate'),
      ]),
    ]).markAdherence(MealSlot.lunch, AdherenceMark.ate,
        at: DateTime(2026, 8, 14, 13, 0));

    final q = plan.setItemQuantity(MealSlot.lunch, 'huevo', 3);
    expect(lunchOf(q).consumedAt, DateTime(2026, 8, 14, 13, 0));

    final r = plan.removeItem(MealSlot.lunch, 'aguacate');
    expect(lunchOf(r).consumedAt, DateTime(2026, 8, 14, 13, 0));
  });

  test('cambiar el PLATO completo (setMealRecipe) limpia la hora', () {
    final plan = planWith([entry(MealSlot.lunch)]).markAdherence(
        MealSlot.lunch, AdherenceMark.ate,
        at: DateTime(2026, 8, 14, 13, 0));
    final swapped =
        plan.setMealRecipe(MealSlot.lunch, 'pollo_plancha_ensalada', const []);
    expect(lunchOf(swapped).consumedAt, isNull);
    expect(lunchOf(swapped).adherence, isNull);
  });
}
