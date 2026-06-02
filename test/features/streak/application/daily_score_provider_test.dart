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

  group('SPEC-140 §8.4 — no regresión IMR legacy', () {
    // Documenta la magnitud del shift causado por el rebalanceo de
    // pesos. SPEC §R-01 dice ±2-3 puntos típicos, ±5 como techo.
    // El IMR legacy consume el dailyQualityScore vía weeklyQualityScore
    // → bloque Metabolismo (peso 0.25 × 0.30 = 7.5% del IMR total).

    test('Magnitudes mixtas: shift de dailyQualityScore < 5 puntos', () {
      // Escenario realista: usuario que ayuna bien, se hidrata mal,
      // come bien pero no se ejercita lo suficiente.
      final entry = _entry(
        fasting: 0.85,
        sleep: 0.75,
        hydration: 0.35,
        exercise: 0.60,
        nutrition: 0.90,
      );

      // Score con pesos SPEC-140 (vía el getter actual).
      final newScore = entry.dailyQualityScore;

      // Score con pesos pre-SPEC-140 (cálculo manual para comparación).
      // wSleep 0.25, wFasting 0.20, wHydration 0.20, wExercise 0.20,
      // wNutrition 0.15. Todas las magnitudes presentes → sin renormalización.
      const wSleepOld = 0.25;
      const wFastingOld = 0.20;
      const wHydrationOld = 0.20;
      const wExerciseOld = 0.20;
      const wNutritionOld = 0.15;
      final oldScore = wSleepOld * 0.75 +
          wFastingOld * 0.85 +
          wHydrationOld * 0.35 +
          wExerciseOld * 0.60 +
          wNutritionOld * 0.90;

      final shiftPoints = ((newScore - oldScore) * 100).abs();

      expect(
        shiftPoints,
        lessThanOrEqualTo(5.0),
        reason: 'SPEC-140 §R-01: shift típico ±2-3 puntos, techo ±5',
      );
    });

    test('Magnitudes uniformes: shift es 0 (∑w·q / ∑w = q sin importar pesos)',
        () {
      final entry = _entry(
        fasting: 0.7,
        sleep: 0.7,
        hydration: 0.7,
        exercise: 0.7,
        nutrition: 0.7,
      );
      // Cuando todas las magnitudes son iguales, el score = q × 100,
      // independiente de los pesos. Esta propiedad protege a usuarios
      // perfectos / cero de cualquier shift por SPEC-140.
      expect((entry.dailyQualityScore * 100).round(), 70);
    });
  });
}
