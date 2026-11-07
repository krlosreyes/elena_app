// Barra de calidad de comida (2026-11-07).

import 'package:elena_app/src/features/nutrition/domain/meal_quality.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/presentation/widgets/meal_quality_card.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionLog _m(int hour, double? q) => NutritionLog(
      id: 'm$hour',
      timestamp: DateTime(2026, 11, 7, hour),
      label: 'Comida',
      withinCircadianWindow: true,
      quality: q,
    );

void main() {
  group('zonas y equivalencias', () {
    test('tres zonas', () {
      expect(MealQuality.labelOf(0), 'Chatarra');
      expect(MealQuality.labelOf(0.32), 'Chatarra');
      expect(MealQuality.labelOf(0.5), 'Aceptable');
      expect(MealQuality.labelOf(0.7), 'Saludable');
      expect(MealQuality.labelOf(1), 'Saludable');
    });

    test('ratio A:E equivalente', () {
      expect(MealQuality.ratioFor(1), MealRatio.allA);
      expect(MealQuality.ratioFor(0.5), MealRatio.a2e1);
      expect(MealQuality.ratioFor(0), MealRatio.allE);
    });

    test('quality fuera de [0,1] es inválida', () {
      expect(() => _m(8, 1.2), throwsA(anything));
    });
  });

  group('dayScore', () {
    test('null si no hay comidas calificadas (días viejos)', () {
      expect(MealQuality.dayScore([_m(8, null)], targetMeals: 2), isNull);
      expect(MealQuality.dayScore([], targetMeals: 2), isNull);
    });

    test('2 comidas saludables en 16:8 → 100%', () {
      expect(
        MealQuality.dayScore([_m(12, 1), _m(18, 1)], targetMeals: 2),
        1.0,
      );
    });

    test('1 de 2 comidas → máximo 50% (los huecos valen 0)', () {
      expect(MealQuality.dayScore([_m(12, 1)], targetMeals: 2), 0.5);
    });

    test('la calidad promedia', () {
      expect(
        MealQuality.dayScore([_m(12, 1), _m(18, 0)], targetMeals: 2),
        0.5,
      );
    });

    test('comida extra resta 0,15 (sin snack permitido)', () {
      final s = MealQuality.dayScore(
        [_m(12, 1), _m(15, 1), _m(18, 1)],
        targetMeals: 2,
      )!;
      expect(s, closeTo((2 - 0.15) / 2, 1e-9));
    });

    test('el orden no importa: el snack puede ir antes de la cena', () {
      final a = MealQuality.dayScore(
          [_m(12, 1), _m(15, 0.4), _m(18, 1)], targetMeals: 2);
      final b = MealQuality.dayScore(
          [_m(12, 1), _m(15, 1), _m(18, 0.4)], targetMeals: 2);
      expect(a, b);
    });

    test('una extra chatarra resta el doble que una saludable', () {
      expect(MealQuality.extraPenaltyFor(1), closeTo(0.15, 1e-9));
      expect(MealQuality.extraPenaltyFor(0), closeTo(0.30, 1e-9));
    });

    test('snack permitido: el mejor extra Aceptable no resta', () {
      expect(
        MealQuality.dayScore(
          [_m(12, 1), _m(15, 0.5), _m(18, 1)],
          targetMeals: 2,
          allowsSnack: true,
        ),
        1.0,
      );
      // Chatarra sí resta aunque el snack esté permitido.
      expect(
        MealQuality.dayScore(
          [_m(12, 1), _m(15, 0.1), _m(18, 1)],
          targetMeals: 2,
          allowsSnack: true,
        ),
        closeTo((2 - (0.15 + 0.15 * 0.9)) / 2, 1e-9),
      );
    });

    test('OMAD: una comida chatarra y nada más → 0', () {
      expect(MealQuality.dayScore([_m(14, 0)], targetMeals: 1), 0.0);
    });

    test('nunca negativo', () {
      expect(
        MealQuality.dayScore(
          [_m(8, 0), _m(10, 0), _m(12, 0), _m(14, 0)],
          targetMeals: 1,
        ),
        0.0,
      );
    });
  });

  test('mealOrdinalLabel', () {
    expect(mealOrdinalLabel(0, 2), 'Comida 1 de 2');
    expect(mealOrdinalLabel(1, 2), 'Comida 2 de 2');
    expect(mealOrdinalLabel(2, 2), 'Comida extra');
  });
}
