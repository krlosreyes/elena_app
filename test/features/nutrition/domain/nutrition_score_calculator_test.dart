// Tests de NutritionScoreCalculator — rediseño 2026-07-25.
//
// Antes de este rediseño, la fórmula no tenía test unitario dedicado
// (solo se ejercitaba indirectamente vía nutrition_notifier_test.dart).
// Estos tests documentan y protegen la fórmula nueva: 0.60 calidad de
// plato (Cociente A) + 0.20 conteo de comidas + 0.20 ventana circadiana.
//
// Caso de regresión central (el bug que motivó el rediseño, ver
// docs internos "Pilar Nutrición: dos métricas paralelas" 2026-07-25):
// 3 platos 100% Tipo E, todos dentro de ventana, target 3 → ANTES el
// score daba 1.0 (perfecto). AHORA debe quedar bajo, dominado por la
// mala composición.

import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionLog _log({
  String id = 'l',
  MealRatio ratio = MealRatio.a2e1,
  bool withinCircadianWindow = true,
}) =>
    NutritionLog(
      id: id,
      timestamp: DateTime(2026, 7, 25, 13),
      label: 'Almuerzo',
      withinCircadianWindow: withinCircadianWindow,
      ratio: ratio,
    );

void main() {
  group('plateQualityScore', () {
    test('lista vacía → 0.0', () {
      expect(NutritionScoreCalculator.plateQualityScore([]), 0.0);
    });

    test('3 platos Todo E → 0.0 (mismo criterio que CocienteAService)', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.allE),
        _log(id: '2', ratio: MealRatio.allE),
        _log(id: '3', ratio: MealRatio.allE),
      ];
      expect(NutritionScoreCalculator.plateQualityScore(logs), 0.0);
    });

    test('3 platos Todo A → 1.0', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.allA),
        _log(id: '2', ratio: MealRatio.allA),
        _log(id: '3', ratio: MealRatio.allA),
      ];
      expect(NutritionScoreCalculator.plateQualityScore(logs), 1.0);
    });
  });

  group('score — caso de regresión central del rediseño 2026-07-25', () {
    test(
        '3 platos 100% Tipo E dentro de ventana, target 3 → score bajo, '
        'NO 1.0 (antes del rediseño daba 1.0 — el bug reportado)', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.allE),
        _log(id: '2', ratio: MealRatio.allE),
        _log(id: '3', ratio: MealRatio.allE),
      ];
      final mealCountScore =
          NutritionScoreCalculator.mealCountScore(logs.length, 3);
      final windowAdherence = NutritionScoreCalculator.windowAdherence(logs);
      final plateQualityScore =
          NutritionScoreCalculator.plateQualityScore(logs);

      expect(mealCountScore, 1.0);
      expect(windowAdherence, 1.0);
      expect(plateQualityScore, 0.0);

      final score = NutritionScoreCalculator.score(
        mealCountScore: mealCountScore,
        windowAdherence: windowAdherence,
        plateQualityScore: plateQualityScore,
      );

      // 0.60·0.0 + 0.20·1.0 + 0.20·1.0 = 0.40 — muy lejos del 1.0 previo.
      expect(score, closeTo(0.40, 1e-9));
      expect(score, lessThan(0.5),
          reason: 'un día de comidas 100% Tipo E nunca debe cruzar la '
              'mitad del score, aunque se hayan registrado las 3 comidas '
              'a tiempo');
    });

    test('3 platos perfectos (Todo A) dentro de ventana, target 3 → 1.0', () {
      final logs = [
        _log(id: '1', ratio: MealRatio.allA),
        _log(id: '2', ratio: MealRatio.allA),
        _log(id: '3', ratio: MealRatio.allA),
      ];
      final score = NutritionScoreCalculator.score(
        mealCountScore: NutritionScoreCalculator.mealCountScore(3, 3),
        windowAdherence: NutritionScoreCalculator.windowAdherence(logs),
        plateQualityScore: NutritionScoreCalculator.plateQualityScore(logs),
      );
      expect(score, closeTo(1.0, 1e-9));
    });

    test(
        '3 platos con ratio por defecto (a2e1, A-dominante) → sigue dando '
        '1.0 — no rompe el fixture existente de nutrition_notifier_test', () {
      final logs = [_log(id: '1'), _log(id: '2'), _log(id: '3')];
      final score = NutritionScoreCalculator.score(
        mealCountScore: NutritionScoreCalculator.mealCountScore(3, 3),
        windowAdherence: NutritionScoreCalculator.windowAdherence(logs),
        plateQualityScore: NutritionScoreCalculator.plateQualityScore(logs),
      );
      expect(score, closeTo(1.0, 1e-9));
    });

    test('sin logs → 0.0 (no penaliza, tampoco aporta)', () {
      final score = NutritionScoreCalculator.score(
        mealCountScore: NutritionScoreCalculator.mealCountScore(0, 3),
        windowAdherence: NutritionScoreCalculator.windowAdherence(const []),
        plateQualityScore: NutritionScoreCalculator.plateQualityScore(const []),
      );
      expect(score, 0.0);
    });

    test('score siempre queda en [0.0, 1.0] para cualquier combinación', () {
      for (final r1 in MealRatio.values) {
        for (final r2 in MealRatio.values) {
          final logs = [
            _log(id: '1', ratio: r1),
            _log(id: '2', ratio: r2, withinCircadianWindow: false),
          ];
          final score = NutritionScoreCalculator.score(
            mealCountScore: NutritionScoreCalculator.mealCountScore(2, 3),
            windowAdherence: NutritionScoreCalculator.windowAdherence(logs),
            plateQualityScore: NutritionScoreCalculator.plateQualityScore(logs),
          );
          expect(score, inInclusiveRange(0.0, 1.0),
              reason: 'fuera de rango para [$r1, $r2]: $score');
        }
      }
    });
  });
}
