// SPEC-272 + SPEC-276 — Tests del motor de la Minuta.
//
// Contrato nuevo (SPEC-276): el motor arma UN plato coherente por comida
// con el repertorio del usuario — una proteína, 1–2 vegetales, una grasa,
// carbo opcional — completa roles faltantes marcados "Nuevo" y propone a lo
// sumo UNA mejora suave marcada. Los tests introspectan el catálogo (no
// hardcodean ids) para no romperse si el catálogo cambia.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  List<Food> byQ(Iterable<Food> xs) =>
      xs.toList()..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

  bool isVeg(Food f) =>
      f.category == FoodCategory.carb && f.qualityScore >= 70;

  final proteins = byQ(FoodCatalog.byCategory(FoodCategory.protein));
  final vegs = byQ(FoodCatalog.byCategory(FoodCategory.carb).where(isVeg));
  final fats = byQ(FoodCatalog.byCategory(FoodCategory.fat));
  final weakCarbs = FoodCatalog.byCategory(FoodCategory.carb)
      .where((f) => f.nova.isUltraProcessed || f.qualityScore < 15)
      .toList()
    ..sort((a, b) => a.qualityScore.compareTo(b.qualityScore));

  NutritionIntake intakeWith(List<String> foodIds, {MealSlot slot = MealSlot.lunch}) =>
      NutritionIntake(
        updatedAt: DateTime(2026, 8, 8),
        meals: [
          IntakeMeal(
            slot: slot,
            items: foodIds.map((id) => IntakeItem(foodId: id)).toList(),
          ),
        ],
      );

  MealPlanEntry only(MealPlan p) => p.meals.single;
  Iterable<PlanItem> role(MealPlanEntry e, PlanItemRole r) =>
      e.items.where((i) => i.role == r);

  MealPlan gen1(NutritionIntake i, {int phase = 1, Set<String> avoid = const {}}) =>
      gen.generate(
        intake: i,
        targetProteinG: 60,
        dateId: '2026-08-08',
        phase: phase,
        avoidFoodIds: avoid,
      );

  test('exactamente UNA proteína aunque el usuario liste varias', () {
    final e = only(gen1(intakeWith(proteins.take(3).map((f) => f.id).toList())));
    expect(role(e, PlanItemRole.protein).length, 1);
  });

  test('arma el plato con los alimentos del usuario (fromUser)', () {
    final p = proteins.first, v = vegs.first, f = fats.first;
    final e = only(gen1(intakeWith([p.id, v.id, f.id])));
    // Los tres ítems del usuario, sin sugerencias nuevas.
    expect(e.items.map((i) => i.foodId), containsAll([p.id, v.id, f.id]));
    expect(e.items.every((i) => i.origin == PlanItemOrigin.fromUser), true);
    expect(e.items.length, 3);
  });

  test('completa un rol faltante con sugerencia marcada "Nuevo"', () {
    // Solo proteína fuerte: le faltan vegetal y grasa.
    final e = only(gen1(intakeWith([proteins.first.id])));
    expect(role(e, PlanItemRole.protein).single.origin, PlanItemOrigin.fromUser);
    expect(role(e, PlanItemRole.veg).single.origin, PlanItemOrigin.newSuggestion);
    expect(role(e, PlanItemRole.fat).single.origin, PlanItemOrigin.newSuggestion);
  });

  test('NO inyecta proteína si el usuario ya tiene una', () {
    final e = only(gen1(intakeWith([proteins.first.id])));
    expect(
      role(e, PlanItemRole.protein)
          .every((i) => i.origin != PlanItemOrigin.newSuggestion),
      true,
    );
  });

  test('es un plato, no una lista: tope de ítems y una sola proteína', () {
    final many = <String>[
      ...proteins.take(4).map((f) => f.id),
      ...vegs.take(3).map((f) => f.id),
      ...fats.take(2).map((f) => f.id),
      ...FoodCatalog.byCategory(FoodCategory.carb)
          .where((f) => !isVeg(f))
          .take(2)
          .map((f) => f.id),
    ];
    final e = only(gen1(intakeWith(many)));
    expect(e.items.length, lessThanOrEqualTo(5));
    expect(role(e, PlanItemRole.protein).length, 1);
    expect(role(e, PlanItemRole.veg).length, lessThanOrEqualTo(2));
  });

  test('mejora suave: cambia el ítem débil y registra swappedFrom', () {
    // Requiere que exista al menos un carbo débil en el catálogo.
    if (weakCarbs.isEmpty) return;
    final weak = weakCarbs.first;
    final e = only(gen1(intakeWith([proteins.first.id, weak.id])));
    expect(e.swappedFrom, contains(weak.id));
    expect(e.items.any((i) => i.origin == PlanItemOrigin.upgrade), true);
    expect(e.rationale, startsWith('Mejora'));
  });

  test('determinismo: misma entrada, misma minuta', () {
    final i = intakeWith([proteins.first.id, vegs.first.id, fats.first.id]);
    final a = only(gen1(i));
    final b = only(gen1(i));
    expect(a.items, b.items);
  });
}
