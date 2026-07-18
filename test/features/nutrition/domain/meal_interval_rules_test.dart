// Tests de MealIntervalRules — SPEC-137 E.5.

import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MealIntervalRules.check — escenarios principales', () {
    test('lastMealAt null → firstMeal', () {
      final result = MealIntervalRules.check(
        lastMealAt: null,
        attemptAt: DateTime(2026, 5, 24, 12),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.firstMeal);
    });

    test('cheatDayActive → cheatDayBypass aunque haya intervalo corto', () {
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 11, 30),
        attemptAt: DateTime(2026, 5, 24, 11, 45),
        cheatDayActive: true,
      );
      expect(result, MealIntervalCheck.cheatDayBypass);
    });

    test('intervalo 4h → ok', () {
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 12),
        attemptAt: DateTime(2026, 5, 24, 16),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.ok);
    });

    test('intervalo exactamente 3h → ok (umbral inclusivo)', () {
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 12),
        attemptAt: DateTime(2026, 5, 24, 15),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.ok);
    });

    test('intervalo 2.5h → warning', () {
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 12),
        attemptAt: DateTime(2026, 5, 24, 14, 30),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.warning);
    });

    test('intervalo exactamente 2h → warning (umbral inclusivo)', () {
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 12),
        attemptAt: DateTime(2026, 5, 24, 14),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.warning);
    });

    test('intervalo 1h → blocked', () {
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 12),
        attemptAt: DateTime(2026, 5, 24, 13),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.blocked);
    });

    test('intervalo 15 min → blocked', () {
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 12),
        attemptAt: DateTime(2026, 5, 24, 12, 15),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.blocked);
    });
  });

  group('MealIntervalRules.check — casos especiales', () {
    test('intervalo 18h (más allá del corte) → firstMeal (reset nocturno)',
        () {
      // Ayer 20:00, hoy 14:00 = 18h después → asume reset por ayuno
      // nocturno, trata como primera comida del día.
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 23, 20),
        attemptAt: DateTime(2026, 5, 24, 14),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.firstMeal,
          reason: 'el ayuno nocturno ya reseteó la insulina baseline');
    });

    test('intervalo 12h → ok (ya pasaron 3h por bastante)', () {
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 8),
        attemptAt: DateTime(2026, 5, 24, 20),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.ok);
    });

    test('attemptAt en el pasado respecto a lastMealAt → ok (defensivo)',
        () {
      // No debería ocurrir, pero el service no debe romper.
      final result = MealIntervalRules.check(
        lastMealAt: DateTime(2026, 5, 24, 14),
        attemptAt: DateTime(2026, 5, 24, 13),
        cheatDayActive: false,
      );
      expect(result, MealIntervalCheck.ok);
    });
  });

  group('MealIntervalRules.nextSuggestedAt', () {
    test('null si lastMealAt es null', () {
      expect(MealIntervalRules.nextSuggestedAt(null), isNull);
    });

    test('lastMealAt + 3h', () {
      final last = DateTime(2026, 5, 24, 12);
      final next = MealIntervalRules.nextSuggestedAt(last);
      expect(next, DateTime(2026, 5, 24, 15));
    });
  });

  group('MealIntervalRules.isInNotificationWindow', () {
    test('30 min antes de next → true', () {
      // Última 12:00, next 15:00, window 14:30-15:00. Now 14:35 → true.
      final result = MealIntervalRules.isInNotificationWindow(
        lastMealAt: DateTime(2026, 5, 24, 12),
        now: DateTime(2026, 5, 24, 14, 35),
      );
      expect(result, isTrue);
    });

    test('exactamente en next → true (límite superior inclusivo)', () {
      final result = MealIntervalRules.isInNotificationWindow(
        lastMealAt: DateTime(2026, 5, 24, 12),
        now: DateTime(2026, 5, 24, 15),
      );
      expect(result, isTrue);
    });

    test('40 min antes de next → false (todavía fuera de ventana)', () {
      // Window se abre a 14:30. Now 14:20 → false.
      final result = MealIntervalRules.isInNotificationWindow(
        lastMealAt: DateTime(2026, 5, 24, 12),
        now: DateTime(2026, 5, 24, 14, 20),
      );
      expect(result, isFalse);
    });

    test('después de next → false (ya pasó el momento)', () {
      // Después de 15:00, el momento "alístate para la próxima" ya pasó.
      final result = MealIntervalRules.isInNotificationWindow(
        lastMealAt: DateTime(2026, 5, 24, 12),
        now: DateTime(2026, 5, 24, 15, 5),
      );
      expect(result, isFalse);
    });

    test('lastMealAt null → false (no hay next para anunciar)', () {
      final result = MealIntervalRules.isInNotificationWindow(
        lastMealAt: null,
        now: DateTime(2026, 5, 24, 12),
      );
      expect(result, isFalse);
    });
  });

  group('MealIntervalRules.lastMealOf', () {
    NutritionLog mk(String id, DateTime ts) => NutritionLog(
          id: id,
          timestamp: ts,
          label: 'Almuerzo',
          withinCircadianWindow: true,
          ratio: MealRatio.a2e1,
        );

    test('lista vacía → null', () {
      expect(MealIntervalRules.lastMealOf([]), isNull);
    });

    test('un solo log → su timestamp', () {
      final t = DateTime(2026, 5, 24, 12);
      expect(MealIntervalRules.lastMealOf([mk('a', t)]), t);
    });

    test('múltiples logs → el más reciente', () {
      final t1 = DateTime(2026, 5, 24, 8);
      final t2 = DateTime(2026, 5, 24, 13);
      final t3 = DateTime(2026, 5, 24, 11);
      expect(
        MealIntervalRules.lastMealOf([mk('a', t1), mk('b', t2), mk('c', t3)]),
        t2,
      );
    });

    test('orden no importa', () {
      final t1 = DateTime(2026, 5, 24, 8);
      final t2 = DateTime(2026, 5, 24, 13);
      expect(
        MealIntervalRules.lastMealOf([mk('a', t2), mk('b', t1)]),
        t2,
      );
    });
  });

  group('MealIntervalRules.firstMealOf (18-jul)', () {
    NutritionLog mk(String id, DateTime ts) => NutritionLog(
          id: id,
          timestamp: ts,
          label: 'Desayuno',
          withinCircadianWindow: true,
          ratio: MealRatio.a2e1,
        );

    test('lista vacía → null', () {
      expect(MealIntervalRules.firstMealOf([]), isNull);
    });

    test('un solo log → su timestamp', () {
      final t = DateTime(2026, 5, 24, 8, 30);
      expect(MealIntervalRules.firstMealOf([mk('a', t)]), t);
    });

    test('múltiples logs → el más temprano (no el más reciente)', () {
      final t1 = DateTime(2026, 5, 24, 8, 30);
      final t2 = DateTime(2026, 5, 24, 13, 0);
      final t3 = DateTime(2026, 5, 24, 20, 0);
      expect(
        MealIntervalRules.firstMealOf([mk('a', t2), mk('b', t1), mk('c', t3)]),
        t1,
      );
    });

    test('orden no importa', () {
      final t1 = DateTime(2026, 5, 24, 8, 30);
      final t2 = DateTime(2026, 5, 24, 13, 0);
      expect(
        MealIntervalRules.firstMealOf([mk('a', t1), mk('b', t2)]),
        t1,
      );
    });
  });

  group('Constantes', () {
    test('minInterval = 2h, recommendedInterval = 3h, lead = 30min', () {
      expect(MealIntervalRules.minInterval, const Duration(hours: 2));
      expect(MealIntervalRules.recommendedInterval, const Duration(hours: 3));
      expect(MealIntervalRules.notificationLeadTime,
          const Duration(minutes: 30));
    });
  });
}
