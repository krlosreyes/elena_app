// SPEC-140 §8.2: tests de las funciones puras del Score del Día.
//
// Los providers `dailyScoreProvider` y `dailyScoreDeltaProvider` son
// wrappers thin que watchean `streakProvider`. La lógica matemática
// vive en `computeDailyScore` / `computeDailyScoreDelta` — testeamos
// esas funciones directamente sin necesidad de mock del notifier.

import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

StreakEntry _entry({
  String date = '2026-05-01',
  double? fasting,
  double? sleep,
  double? hydration,
  double? exercise,
  double? nutrition,
}) =>
    StreakEntry(
      date: date,
      fastingCompleted: (fasting ?? 0) >= 0.8,
      sleepCompleted: (sleep ?? 0) >= 0.8,
      hydrationCompleted: (hydration ?? 0) >= 0.75,
      exerciseLogged: (exercise ?? 0) >= 0.67,
      nutritionLogged: (nutrition ?? 0) > 0,
      imrScore: 70,
      fastingMagnitude: fasting,
      sleepQualityScore: sleep,
      hydrationMagnitude: hydration,
      exerciseMagnitude: exercise,
      nutritionMagnitude: nutrition,
    );

void main() {
  group('SPEC-140 — computeDailyScore', () {
    test('Sin todayEntry → 0', () {
      expect(computeDailyScore(null), 0);
    });

    test('Todas las magnitudes en 1.0 → 100', () {
      final e = _entry(
        fasting: 1.0,
        sleep: 1.0,
        hydration: 1.0,
        exercise: 1.0,
        nutrition: 1.0,
      );
      expect(computeDailyScore(e), 100);
    });

    test('Todas las magnitudes en 0.0 → 0', () {
      final e = _entry(
        fasting: 0.0,
        sleep: 0.0,
        hydration: 0.0,
        exercise: 0.0,
        nutrition: 0.0,
      );
      expect(computeDailyScore(e), 0);
    });

    test('Renormalización: solo sueño en 1.0 → 100', () {
      // Peso único 0.25 / 0.25 = 1.0 → 100.
      final e = _entry(sleep: 1.0);
      expect(computeDailyScore(e), 100);
    });

    test('SPEC-140 pesos: sueño 1.0 + ayuno 0.5 → 77', () {
      // weighted = 0.25*1.0 + 0.22*0.5 = 0.36
      // total = 0.25 + 0.22 = 0.47
      // result = 0.36/0.47 = 0.766 → 77 (rounded)
      final e = _entry(sleep: 1.0, fasting: 0.5);
      expect(computeDailyScore(e), 77);
    });

    test('Magnitudes uniformes en 0.5 → 50', () {
      // Cuando todas las magnitudes son iguales, el score = magnitud × 100,
      // sin importar los pesos (porque ∑w·q / ∑w = q).
      final e = _entry(
        fasting: 0.5,
        sleep: 0.5,
        hydration: 0.5,
        exercise: 0.5,
        nutrition: 0.5,
      );
      expect(computeDailyScore(e), 50);
    });
  });

  group('SPEC-140 — computeDailyScoreDelta', () {
    test('History vacío → null', () {
      expect(computeDailyScoreDelta(const []), isNull);
    });

    test('History con 1 entrada → null', () {
      expect(
        computeDailyScoreDelta([_entry(date: '2026-05-01')]),
        isNull,
      );
    });

    test('Hoy uniforme 1.0 + ayer uniforme 0.88 → +12', () {
      final today = _entry(
        date: '2026-05-02',
        fasting: 1.0,
        sleep: 1.0,
        hydration: 1.0,
        exercise: 1.0,
        nutrition: 1.0,
      );
      final yesterday = _entry(
        date: '2026-05-01',
        fasting: 0.88,
        sleep: 0.88,
        hydration: 0.88,
        exercise: 0.88,
        nutrition: 0.88,
      );
      expect(computeDailyScoreDelta([today, yesterday]), 12);
    });

    test('Hoy 0.60 + ayer 0.73 → -13', () {
      final today = _entry(
        date: '2026-05-02',
        fasting: 0.60,
        sleep: 0.60,
        hydration: 0.60,
        exercise: 0.60,
        nutrition: 0.60,
      );
      final yesterday = _entry(
        date: '2026-05-01',
        fasting: 0.73,
        sleep: 0.73,
        hydration: 0.73,
        exercise: 0.73,
        nutrition: 0.73,
      );
      expect(computeDailyScoreDelta([today, yesterday]), -13);
    });

    test('Hoy y ayer iguales → 0', () {
      final today = _entry(date: '2026-05-02', sleep: 0.8);
      final yesterday = _entry(date: '2026-05-01', sleep: 0.8);
      expect(computeDailyScoreDelta([today, yesterday]), 0);
    });
  });
}
