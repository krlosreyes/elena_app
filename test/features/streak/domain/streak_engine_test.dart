// Tests unitarios de StreakEngine.
//
// Cubre:
// - Evaluadores por pilar (umbrales documentados).
// - StreakEntry.pillarsCompleted (booleans, hasta SPEC-65).
// - computeLongestStreak con historial sintético.
//
// Funciones puras: no requieren mocks ni reloj.

import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Evaluadores por pilar', () {
    test('evaluateFasting con protocolo 16:8: requiere ≥ 12.8h', () {
      expect(
          StreakEngine.evaluateFasting(
              fastingHours: 12.8, fastingProtocol: '16:8'),
          isTrue);
      expect(
          StreakEngine.evaluateFasting(
              fastingHours: 12.7, fastingProtocol: '16:8'),
          isFalse);
    });

    test('evaluateFasting con protocolo Ninguno: requiere ≥ 10h', () {
      expect(
          StreakEngine.evaluateFasting(
              fastingHours: 10, fastingProtocol: 'Ninguno'),
          isTrue);
      expect(
          StreakEngine.evaluateFasting(
              fastingHours: 9.99, fastingProtocol: 'Ninguno'),
          isFalse);
    });

    test('evaluateSleep: requiere ≥ 6.5h (umbral AASM)', () {
      expect(StreakEngine.evaluateSleep(sleepHours: 6.5), isTrue);
      expect(StreakEngine.evaluateSleep(sleepHours: 6.4), isFalse);
    });

    test('evaluateHydration: requiere ≥ 75% de la meta', () {
      expect(
          StreakEngine.evaluateHydration(progressPercentage: 0.75), isTrue);
      expect(
          StreakEngine.evaluateHydration(progressPercentage: 0.74), isFalse);
    });

    test('evaluateExercise: requiere ≥ 20 min (dosis mínima ACSM)', () {
      expect(StreakEngine.evaluateExercise(exerciseMinutes: 20), isTrue);
      expect(StreakEngine.evaluateExercise(exerciseMinutes: 19), isFalse);
    });

    test('evaluateNutrition: requiere ≥ 1 comida registrada', () {
      expect(StreakEngine.evaluateNutrition(mealsLogged: 1), isTrue);
      expect(StreakEngine.evaluateNutrition(mealsLogged: 0), isFalse);
    });
  });

  group('StreakEntry.qualifiesForStreak', () {
    StreakEntry make({
      bool fasting = false,
      bool sleep = false,
      bool hydration = false,
      bool exercise = false,
      bool nutrition = false,
      int imr = 0,
    }) =>
        StreakEntry(
          date: '2026-05-06',
          fastingCompleted: fasting,
          sleepCompleted: sleep,
          hydrationCompleted: hydration,
          exerciseLogged: exercise,
          nutritionLogged: nutrition,
          imrScore: imr,
        );

    test('Cero pilares: no califica', () {
      expect(make().pillarsCompleted, 0);
      expect(make().qualifiesForStreak, isFalse);
    });

    test('2 pilares: aún no califica', () {
      final e = make(fasting: true, sleep: true);
      expect(e.pillarsCompleted, 2);
      expect(e.qualifiesForStreak, isFalse);
    });

    test('3 pilares: califica (umbral SPEC-06)', () {
      final e = make(fasting: true, sleep: true, hydration: true);
      expect(e.pillarsCompleted, 3);
      expect(e.qualifiesForStreak, isTrue);
    });

    test('5 pilares + IMR alto: engaged (SPEC-07)', () {
      final e = make(
        fasting: true,
        sleep: true,
        hydration: true,
        exercise: true,
        nutrition: true,
        imr: 75,
      );
      expect(e.pillarsCompleted, 5);
      expect(e.qualifiesForStreak, isTrue);
      expect(e.isEngaged, isTrue);
    });

    test('IMR bajo (< 60) NO está engaged aunque califique', () {
      final e = make(
        fasting: true,
        sleep: true,
        hydration: true,
        imr: 50,
      );
      expect(e.qualifiesForStreak, isTrue);
      expect(e.isEngaged, isFalse);
    });
  });

  group('computeLongestStreak', () {
    StreakEntry day(String date,
            {bool ok = true, int imr = 70, int pillars = 3}) =>
        StreakEntry(
          date: date,
          fastingCompleted: ok && pillars >= 1,
          sleepCompleted: ok && pillars >= 2,
          hydrationCompleted: ok && pillars >= 3,
          exerciseLogged: ok && pillars >= 4,
          nutritionLogged: ok && pillars >= 5,
          imrScore: imr,
        );

    test('Historial vacío -> 0', () {
      expect(StreakEngine.computeLongestStreak([]), 0);
    });

    test('1 día calificado -> 1', () {
      expect(StreakEngine.computeLongestStreak([day('2026-05-01')]), 1);
    });

    test('3 días consecutivos calificados -> 3', () {
      final h = [
        day('2026-05-01'),
        day('2026-05-02'),
        day('2026-05-03'),
      ];
      expect(StreakEngine.computeLongestStreak(h), 3);
    });

    test('Brecha rompe la racha -> max de los segmentos', () {
      final h = [
        day('2026-05-01'),
        day('2026-05-02'),
        // Salto el 03
        day('2026-05-04'),
        day('2026-05-05'),
        day('2026-05-06'),
        day('2026-05-07'),
      ];
      // Segmento 1: 2 días (01-02). Segmento 2: 4 días (04-07).
      expect(StreakEngine.computeLongestStreak(h), 4);
    });

    test('Día no calificado en medio rompe la racha', () {
      final h = [
        day('2026-05-01'),
        day('2026-05-02'),
        day('2026-05-03', pillars: 1), // 1 pilar, no califica
        day('2026-05-04'),
        day('2026-05-05'),
      ];
      expect(StreakEngine.computeLongestStreak(h), 2);
    });
  });
}
