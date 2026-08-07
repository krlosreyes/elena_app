// SPEC-271 — Tests del modelo MealPlan.
//
// Cubre: round-trip JSON (incluyendo generatedFrom/window anidados y
// enums), parsing permisivo, y la lógica de adherencia (markAdherence,
// adherentCount, isAdherent) que consumirá el score de SPEC-274.

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart'
    show MealSlot;
import 'package:flutter_test/flutter_test.dart';

void main() {
  MealPlan sample() => const MealPlan(
        date: '2026-08-08',
        intakeVersion: 2,
        phase: 1,
        windowFirst: '07:30',
        windowLast: '19:30',
        status: PlanStatus.proposed,
        meals: [
          MealPlanEntry(
            slot: MealSlot.breakfast,
            targetProteinG: 20,
            items: [
              PlanItem(
                  foodId: 'huevo',
                  role: PlanItemRole.protein,
                  portion: HandPortion.palm),
              PlanItem(
                  foodId: 'aguacate',
                  role: PlanItemRole.fat,
                  portion: HandPortion.thumb),
            ],
            swappedFrom: ['jugo_naranja'],
            rationale: 'Cambiamos el jugo por fruta entera + grasa buena',
          ),
          MealPlanEntry(
            slot: MealSlot.lunch,
            targetProteinG: 30,
            items: [
              PlanItem(
                  foodId: 'pollo',
                  role: PlanItemRole.protein,
                  portion: HandPortion.palm),
            ],
          ),
        ],
      );

  group('MealPlan — round-trip JSON', () {
    test('toJson → fromJson preserva campos, anidados y enums', () {
      final restored = MealPlan.fromJson(sample().toJson());

      expect(restored.date, '2026-08-08');
      expect(restored.intakeVersion, 2);
      expect(restored.phase, 1);
      expect(restored.windowFirst, '07:30');
      expect(restored.windowLast, '19:30');
      expect(restored.status, PlanStatus.proposed);
      expect(restored.meals.length, 2);

      final b = restored.meals.first;
      expect(b.slot, MealSlot.breakfast);
      expect(b.targetProteinG, 20);
      expect(b.items.length, 2);
      expect(b.items.first.foodId, 'huevo');
      expect(b.items.first.role, PlanItemRole.protein);
      expect(b.items.first.portion, HandPortion.palm);
      expect(b.swappedFrom, ['jugo_naranja']);
      expect(b.rationale, contains('fruta entera'));
      expect(b.adherence, isNull);
    });

    test('todos los enums sobreviven el round-trip por su wire', () {
      for (final s in PlanStatus.values) {
        expect(PlanStatus.fromWire(s.wire), s);
      }
      for (final r in PlanItemRole.values) {
        expect(PlanItemRole.fromWire(r.wire), r);
      }
      for (final p in HandPortion.values) {
        expect(HandPortion.fromWire(p.wire), p);
      }
      for (final a in AdherenceMark.values) {
        expect(AdherenceMark.fromWire(a.wire), a);
      }
    });
  });

  group('MealPlan — parsing permisivo', () {
    test('payload mínimo devuelve defaults, no lanza', () {
      final p = MealPlan.fromJson(const {'date': '2026-08-08'});
      expect(p.date, '2026-08-08');
      expect(p.version, kMealPlanSchemaVersion);
      expect(p.phase, 1);
      expect(p.meals, isEmpty);
      expect(p.status, PlanStatus.proposed);
    });

    test('adherence desconocida cae a null (sin marcar)', () {
      expect(AdherenceMark.fromWire('lo-que-sea'), isNull);
      expect(AdherenceMark.fromWire(null), isNull);
    });
  });

  group('MealPlan — adherencia', () {
    test('markAdherence marca la comida y pasa el plan a logged', () {
      final plan = sample();
      expect(plan.status, PlanStatus.proposed);

      final marked = plan.markAdherence(MealSlot.breakfast, AdherenceMark.ate);
      expect(marked.status, PlanStatus.logged);
      expect(
        marked.meals.firstWhere((m) => m.slot == MealSlot.breakfast).adherence,
        AdherenceMark.ate,
      );
      // No muta el original (inmutable).
      expect(
        plan.meals.firstWhere((m) => m.slot == MealSlot.breakfast).adherence,
        isNull,
      );
    });

    test('markAdherence sobre un slot inexistente no cambia el plan', () {
      final plan = sample();
      final same = plan.markAdherence(MealSlot.other, AdherenceMark.ate);
      expect(same.status, PlanStatus.proposed);
      expect(same.markedCount, 0);
    });

    test('adherentCount cuenta ate y changed, no skipped', () {
      var plan = sample();
      plan = plan.markAdherence(MealSlot.breakfast, AdherenceMark.ate);
      plan = plan.markAdherence(MealSlot.lunch, AdherenceMark.skipped);
      expect(plan.markedCount, 2);
      expect(plan.adherentCount, 1);

      plan = plan.markAdherence(MealSlot.lunch, AdherenceMark.changed);
      expect(plan.adherentCount, 2);
    });

    test('isAdherent: ate y changed sí, skipped no', () {
      expect(AdherenceMark.ate.isAdherent, true);
      expect(AdherenceMark.changed.isAdherent, true);
      expect(AdherenceMark.skipped.isAdherent, false);
    });
  });

  group('MealPlan — dateId', () {
    test('formatea yyyy-MM-dd con ceros a la izquierda', () {
      expect(MealPlan.dateId(DateTime(2026, 8, 8)), '2026-08-08');
      expect(MealPlan.dateId(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });
}
