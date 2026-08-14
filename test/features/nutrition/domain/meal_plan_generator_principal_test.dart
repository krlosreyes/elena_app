// SPEC-291 — La materia prima principal del plato siempre sale del repertorio:
// el motor nunca sirve una proteína que el usuario no eligió (usa una receta
// cuya proteína está en el repertorio, o arma un plato solo con sus alimentos).

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_generator.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gen = MealPlanGenerator();

  NutritionIntake repertoireIntake(List<String> ids) => NutritionIntake(
        updatedAt: DateTime(2026, 8, 13),
        repertoire: ids.map((id) => IntakeItem(foodId: id)).toList(),
      );

  bool isProtein(String id) =>
      FoodCatalog.byId(id)?.category == FoodCategory.protein;

  test('ninguna comida sirve una proteína fuera del repertorio', () {
    final repertoires = [
      ['pollo', 'arroz', 'aguacate', 'brocoli', 'huevo'],
      ['salmon', 'quinua', 'espinaca', 'aceite_oliva'],
      ['lentejas', 'arroz', 'tomate', 'aguacate', 'cebolla'],
    ];
    for (final rep in repertoires) {
      final repSet = rep.toSet();
      final plan = gen.generate(
        intake: repertoireIntake(rep),
        targetProteinG: 60,
        dateId: '2026-08-13',
        phase: 1,
      );
      for (final meal in plan.meals) {
        for (final it in meal.items) {
          if (isProtein(it.foodId)) {
            expect(repSet.contains(it.foodId), true,
                reason: 'repertorio $rep → sirvió proteína no elegida '
                    '${it.foodId} en ${meal.slot}');
          }
        }
      }
    }
  });

  test('la receta elegida (si hay) usa una proteína del repertorio', () {
    final rep = ['pollo', 'brocoli', 'aguacate', 'arroz', 'huevo'];
    final repSet = rep.toSet();
    final plan = gen.generate(
      intake: repertoireIntake(rep),
      targetProteinG: 60,
      dateId: '2026-08-13',
      phase: 1,
    );
    for (final meal in plan.meals) {
      final proteins =
          meal.items.map((i) => i.foodId).where(isProtein).toList();
      // Si el plato tiene proteína, alguna debe ser del repertorio.
      if (proteins.isNotEmpty) {
        expect(proteins.any(repSet.contains), true);
      }
    }
  });
}
