// SPEC-272 — Tests del motor de generación de la Minuta.
//
// No hardcodea ids del catálogo: los descubre en tiempo de test
// (`FoodCatalog`) para no romperse cuando el catálogo crezca. Verifica:
// determinismo, reemplazo del peor item, respeto a exclusiones, reparto de
// proteína y garantía de las reglas del plato (proteína + vegetal + grasa).

import 'dart:convert';

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  // Alimentos reales del catálogo, elegidos por propiedad (no por id).
  final lowCarb = FoodCatalog.byCategory(FoodCategory.carb)
      .reduce((a, b) => a.qualityScore <= b.qualityScore ? a : b);
  final goodFat = FoodCatalog.byCategory(FoodCategory.fat)
      .reduce((a, b) => a.qualityScore >= b.qualityScore ? a : b);
  final topProtein = ([...FoodCatalog.byCategory(FoodCategory.protein)]
        ..sort((a, b) {
          final s = b.qualityScore.compareTo(a.qualityScore);
          return s != 0 ? s : a.id.compareTo(b.id);
        }))
      .first;

  NutritionIntake intakeWith(List<IntakeMeal> meals) =>
      NutritionIntake(updatedAt: DateTime(2026, 8, 8), meals: meals);

  group('MealPlanGenerator — determinismo', () {
    test('misma entrada ⇒ misma minuta', () {
      final intake = intakeWith([
        IntakeMeal(slot: MealSlot.breakfast, items: [
          IntakeItem(foodId: lowCarb.id),
        ]),
        IntakeMeal(slot: MealSlot.lunch, items: [
          IntakeItem(foodId: goodFat.id),
        ]),
      ]);

      final a = gen.generate(
          intake: intake, targetProteinG: 80, dateId: '2026-08-08', phase: 1);
      final b = gen.generate(
          intake: intake, targetProteinG: 80, dateId: '2026-08-08', phase: 1);

      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
      expect(a.status, PlanStatus.proposed);
      expect(a.date, '2026-08-08');
    });
  });

  group('MealPlanGenerator — reemplazo suave', () {
    test('reemplaza el peor item (carbo malo) por uno mejor', () {
      final intake = intakeWith([
        IntakeMeal(slot: MealSlot.breakfast, items: [
          IntakeItem(foodId: lowCarb.id),
        ]),
      ]);

      final plan = gen.generate(
          intake: intake, targetProteinG: 60, dateId: '2026-08-08', phase: 1);
      final breakfast = plan.meals.single;

      expect(breakfast.swappedFrom, contains(lowCarb.id));
      // El item malo ya no aparece en el plato.
      expect(breakfast.items.any((i) => i.foodId == lowCarb.id), false);
      expect(breakfast.rationale, isNotEmpty);
    });
  });

  group('MealPlanGenerator — reglas del plato', () {
    test('garantiza proteína + vegetal + grasa en la comida', () {
      final intake = intakeWith([
        IntakeMeal(slot: MealSlot.lunch, items: [
          IntakeItem(foodId: lowCarb.id),
        ]),
      ]);

      final plan = gen.generate(
          intake: intake, targetProteinG: 60, dateId: '2026-08-08', phase: 1);
      final roles = plan.meals.single.items.map((i) => i.role).toSet();

      expect(roles, containsAll([
        PlanItemRole.protein,
        PlanItemRole.veg,
        PlanItemRole.fat,
      ]));
    });

    test('la proteína lleva porción de palma', () {
      final intake = intakeWith([
        IntakeMeal(slot: MealSlot.lunch, items: [IntakeItem(foodId: goodFat.id)]),
      ]);
      final plan = gen.generate(
          intake: intake, targetProteinG: 60, dateId: '2026-08-08', phase: 1);
      final protein = plan.meals.single.items
          .firstWhere((i) => i.role == PlanItemRole.protein);
      expect(protein.portion, HandPortion.palm);
    });
  });

  group('MealPlanGenerator — respeta exclusiones', () {
    test('nunca propone un alimento excluido', () {
      // El usuario prohíbe su mejor proteína → el motor elige otra.
      final intake = NutritionIntake(
        updatedAt: DateTime(2026, 8, 8),
        restrictions: IntakeRestrictions(excludes: [topProtein.name]),
        meals: [
          IntakeMeal(slot: MealSlot.lunch, items: [IntakeItem(foodId: goodFat.id)]),
        ],
      );

      final plan = gen.generate(
          intake: intake, targetProteinG: 60, dateId: '2026-08-08', phase: 1);
      final ids = plan.meals.single.items.map((i) => i.foodId).toSet();

      expect(ids.contains(topProtein.id), false);
      // Y sí incluyó ALGUNA proteína (otra distinta).
      expect(plan.meals.single.items.any((i) => i.role == PlanItemRole.protein),
          true);
    });
  });

  group('MealPlanGenerator — reparto de proteína', () {
    test('la suma por comida se acerca al objetivo del día', () {
      final intake = intakeWith([
        IntakeMeal(slot: MealSlot.breakfast, items: [IntakeItem(foodId: goodFat.id)]),
        IntakeMeal(slot: MealSlot.lunch, items: [IntakeItem(foodId: goodFat.id)]),
        IntakeMeal(slot: MealSlot.dinner, items: [IntakeItem(foodId: goodFat.id)]),
      ]);

      final plan = gen.generate(
          intake: intake, targetProteinG: 80, dateId: '2026-08-08', phase: 1);
      final sum =
          plan.meals.fold<double>(0, (a, m) => a + m.targetProteinG);

      expect(sum, closeTo(80, 0.5));
      // El desayuno pesa menos que el almuerzo.
      final b = plan.meals.firstWhere((m) => m.slot == MealSlot.breakfast);
      final l = plan.meals.firstWhere((m) => m.slot == MealSlot.lunch);
      expect(l.targetProteinG, greaterThan(b.targetProteinG));
    });
  });
}
