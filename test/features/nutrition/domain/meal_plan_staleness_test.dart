// SPEC-295 — El plan se sella con la marca del intake para detectar que quedó
// obsoleto cuando el usuario edita sus preferencias.

import 'package:elena_app/src/features/nutrition/application/meal_plan_factory.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la fábrica sella el plan con la marca (updatedAt) del intake', () {
    final intake = NutritionIntake(
      updatedAt: DateTime(2026, 8, 14, 10, 30),
      repertoire: const [
        IntakeItem(foodId: 'pollo'),
        IntakeItem(foodId: 'arroz'),
        IntakeItem(foodId: 'aguacate'),
      ],
    );
    final plan = const MealPlanFactory().build(
      intake: intake,
      heightCm: 180,
      gender: 'M',
      pal: 1.5,
      now: DateTime(2026, 8, 14),
    );
    expect(plan.intakeStampMs, intake.updatedAt.millisecondsSinceEpoch);
  });

  test('editar el intake deja el plan OBSOLETO (marcas distintas)', () {
    final intake = NutritionIntake(
      updatedAt: DateTime(2026, 8, 14, 10, 30),
      repertoire: const [
        IntakeItem(foodId: 'pollo'),
        IntakeItem(foodId: 'arroz'),
        IntakeItem(foodId: 'aguacate'),
      ],
    );
    final plan = const MealPlanFactory().build(
      intake: intake,
      heightCm: 180,
      gender: 'M',
      pal: 1.5,
      now: DateTime(2026, 8, 14),
    );
    // El usuario edita → intake con updatedAt más nuevo.
    final edited = intake.copyWith(updatedAt: DateTime(2026, 8, 14, 11, 0));
    expect(plan.intakeStampMs != edited.updatedAt.millisecondsSinceEpoch, true);
  });

  test('intakeStampMs hace round-trip por JSON', () {
    const p = MealPlan(date: '2026-08-14', intakeStampMs: 123456);
    expect(MealPlan.fromJson(p.toJson()).intakeStampMs, 123456);
  });
}
