// SPEC-69: tests de SleepQualityCalculator.
//
// Cubre:
// - CA-69-01: 7h con gap=4h vs 7h con gap=0h → primero ≥ 0.1 mayor.
// - CA-69-02: solo duración → fórmula degradada (equivale a curva piecewise).
// - Backward compat con la curva antigua de _normalizeSleep.
// - Renormalización de pesos cuando faltan dimensiones.
// - Bonus / penalización por subjectiveQuality.
// - Invariantes de SleepLog (validaciones del constructor SPEC-69).

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_quality_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-69 — Backward compatibility (solo sleepHours)', () {
    test('CA-69-02: 7h sin extras = 1.0 (zona óptima)', () {
      final score = SleepQualityCalculator.calculate(sleepHours: 7);
      expect(score, 1.0);
    });

    test('5h sin extras = 5/7 * 0.85 (curva piecewise)', () {
      final score = SleepQualityCalculator.calculate(sleepHours: 5);
      expect(score, closeTo((5.0 / 7.0) * 0.85, 1e-9));
    });

    test('0h = 0.0', () {
      expect(SleepQualityCalculator.calculate(sleepHours: 0), 0.0);
    });

    test('Negativo se trata como 0', () {
      expect(SleepQualityCalculator.calculate(sleepHours: -1), 0.0);
    });

    test('9h = 1.0', () {
      expect(SleepQualityCalculator.calculate(sleepHours: 9), 1.0);
    });

    test('11h cae bajo 1.0 pero no debajo de 0.6', () {
      final score = SleepQualityCalculator.calculate(sleepHours: 11);
      expect(score, lessThan(1.0));
      expect(score, greaterThanOrEqualTo(0.6));
    });

    test('20h satura en 0.6 (mínimo de exceso)', () {
      final score = SleepQualityCalculator.calculate(sleepHours: 20);
      expect(score, 0.6);
    });
  });

  group('SPEC-69 — CA-69-01: gap metabólico mejora la calidad', () {
    test('7h + gap=240min vs 7h + gap=0min → diferencia ≥ 0.1', () {
      final withGap = SleepQualityCalculator.calculate(
        sleepHours: 7,
        metabolicGapMinutes: 240, // 4h
      );
      final noGap = SleepQualityCalculator.calculate(
        sleepHours: 7,
        metabolicGapMinutes: 0,
      );
      expect(withGap - noGap, greaterThanOrEqualTo(0.1),
          reason: 'Cenar 4h antes de dormir debe puntuar al menos 0.1 más');
    });

    test('Gap ≥ 180min ya cuenta como óptimo (1.0 en esa dimensión)', () {
      final at3h = SleepQualityCalculator.calculate(
        sleepHours: 7,
        metabolicGapMinutes: 180,
      );
      final at4h = SleepQualityCalculator.calculate(
        sleepHours: 7,
        metabolicGapMinutes: 240,
      );
      expect(at3h, closeTo(at4h, 1e-9));
    });
  });

  group('SPEC-69 — Renormalización con dimensiones parciales', () {
    test('Solo duración + latencia → suma de pesos = 0.65', () {
      // 7h (durationScore=1.0) + latency=10min (1.0)
      // → (0.50*1 + 0.15*1) / 0.65 = 1.0
      final score = SleepQualityCalculator.calculate(
        sleepHours: 7,
        sleepLatencyMinutes: 10,
      );
      expect(score, 1.0);
    });

    test('Latencia mala penaliza proporcionalmente', () {
      // duration=1.0 (peso 0.50), latency=0.1 (peso 0.15, >60min)
      // total = (0.50 + 0.015) / 0.65 = 0.7923...
      final score = SleepQualityCalculator.calculate(
        sleepHours: 7,
        sleepLatencyMinutes: 90,
      );
      expect(score, closeTo((0.50 + 0.15 * 0.1) / 0.65, 1e-9));
    });

    test('Despertares severos bajan el score', () {
      final clean = SleepQualityCalculator.calculate(
        sleepHours: 7,
        nightAwakenings: 0,
      );
      final fragmented = SleepQualityCalculator.calculate(
        sleepHours: 7,
        nightAwakenings: 5,
      );
      expect(clean, greaterThan(fragmented));
    });
  });

  group('SPEC-69 — Fórmula completa (4 dimensiones)', () {
    test('Todas óptimas → 1.0', () {
      final score = SleepQualityCalculator.calculate(
        sleepHours: 8,
        metabolicGapMinutes: 200,
        sleepLatencyMinutes: 15,
        nightAwakenings: 0,
      );
      expect(score, 1.0);
    });

    test('Todas pésimas → cerca de scoreDuration mínimo', () {
      final score = SleepQualityCalculator.calculate(
        sleepHours: 4, // duration ≈ 0.486
        metabolicGapMinutes: 0, // 0.1
        sleepLatencyMinutes: 90, // 0.1
        nightAwakenings: 5, // 0.1
      );
      // (0.50*0.486 + 0.20*0.1 + 0.15*0.1 + 0.15*0.1) / 1.0
      const durationScore = (4.0 / 7.0) * 0.85;
      const expected = 0.50 * durationScore + 0.50 * 0.1;
      expect(score, closeTo(expected, 1e-9));
    });
  });

  group('SPEC-69 — subjectiveQuality como factor multiplicativo', () {
    test('rating=5 mejora el score', () {
      final base = SleepQualityCalculator.calculate(sleepHours: 7);
      final boosted = SleepQualityCalculator.calculate(
        sleepHours: 7,
        subjectiveQuality: 5,
      );
      // base=1.0, boosted = 1.0 * 1.10 clamped a 1.0
      expect(boosted, 1.0);
      expect(boosted, greaterThanOrEqualTo(base));
    });

    test('rating=1 penaliza el score', () {
      final base = SleepQualityCalculator.calculate(sleepHours: 8);
      final dragged = SleepQualityCalculator.calculate(
        sleepHours: 8,
        subjectiveQuality: 1,
      );
      expect(dragged, lessThan(base));
      expect(dragged, closeTo(0.85, 1e-9));
    });

    test('rating=3 es neutro', () {
      final base = SleepQualityCalculator.calculate(sleepHours: 8);
      final neutral = SleepQualityCalculator.calculate(
        sleepHours: 8,
        subjectiveQuality: 3,
      );
      expect(neutral, closeTo(base, 1e-9));
    });
  });

  group('SPEC-69 — Rango de salida garantizado [0.0, 1.0]', () {
    test('No supera 1.0 con todas las dimensiones top + subjective=5', () {
      final score = SleepQualityCalculator.calculate(
        sleepHours: 8,
        metabolicGapMinutes: 240,
        sleepLatencyMinutes: 5,
        nightAwakenings: 0,
        subjectiveQuality: 5,
      );
      expect(score, lessThanOrEqualTo(1.0));
      expect(score, greaterThanOrEqualTo(0.0));
    });

    test('No baja de 0.0 con todo malo + subjective=1', () {
      final score = SleepQualityCalculator.calculate(
        sleepHours: 1,
        metabolicGapMinutes: 0,
        sleepLatencyMinutes: 120,
        nightAwakenings: 10,
        subjectiveQuality: 1,
      );
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });
  });

  group('SPEC-69 — Invariantes de SleepLog (constructor)', () {
    final base = DateTime(2026, 5, 1, 23);
    final wake = DateTime(2026, 5, 2, 7);
    final meal = DateTime(2026, 5, 1, 19);

    test('sleepLatencyMinutes negativo lanza NegativeValue (SPEC-62)', () {
      expect(
        () => SleepLog(
          id: 'x',
          fellAsleep: base,
          wokeUp: wake,
          lastMealTime: meal,
          sleepLatencyMinutes: -5,
        ),
        throwsA(isA<NegativeValue>()
            .having((e) => e.fieldName, 'fieldName', 'sleepLatencyMinutes')
            .having((e) => e.value, 'value', -5)),
      );
    });

    test('nightAwakenings negativo lanza NegativeValue (SPEC-62)', () {
      expect(
        () => SleepLog(
          id: 'x',
          fellAsleep: base,
          wokeUp: wake,
          lastMealTime: meal,
          nightAwakenings: -1,
        ),
        throwsA(isA<NegativeValue>()
            .having((e) => e.fieldName, 'fieldName', 'nightAwakenings')),
      );
    });

    test('subjectiveQuality fuera de [1,5] lanza OutOfRange (SPEC-62)', () {
      expect(
        () => SleepLog(
          id: 'x',
          fellAsleep: base,
          wokeUp: wake,
          lastMealTime: meal,
          subjectiveQuality: 0,
        ),
        throwsA(isA<OutOfRange>()
            .having((e) => e.fieldName, 'fieldName', 'subjectiveQuality')
            .having((e) => e.min, 'min', 1)
            .having((e) => e.max, 'max', 5)),
      );
      expect(
        () => SleepLog(
          id: 'x',
          fellAsleep: base,
          wokeUp: wake,
          lastMealTime: meal,
          subjectiveQuality: 6,
        ),
        throwsA(isA<OutOfRange>()),
      );
    });

    test('Valores válidos no lanzan', () {
      expect(
        () => SleepLog(
          id: 'x',
          fellAsleep: base,
          wokeUp: wake,
          lastMealTime: meal,
          sleepLatencyMinutes: 12,
          nightAwakenings: 1,
          subjectiveQuality: 4,
        ),
        returnsNormally,
      );
    });

    test('Todos los campos null no lanzan (backward compat)', () {
      expect(
        () => SleepLog(
          id: 'x',
          fellAsleep: base,
          wokeUp: wake,
          lastMealTime: meal,
        ),
        returnsNormally,
      );
    });
  });
}
