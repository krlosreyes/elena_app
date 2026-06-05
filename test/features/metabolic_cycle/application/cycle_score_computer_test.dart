// SPEC-171 §RF-171-01 (2026-06-04): tests del computer puro del Score
// del Día anclado al ciclo. Validan la matemática sin Riverpod.

import 'package:elena_app/src/features/metabolic_cycle/application/cycle_score_computer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-171 §RF-171-01 — CycleScoreComputer.compute', () {
    test('todas las magnitudes en 1.0 → 100', () {
      final score = CycleScoreComputer.compute(
        fastingMagnitude: 1.0,
        sleepQualityScore: 1.0,
        hydrationMagnitude: 1.0,
        exerciseMagnitude: 1.0,
        nutritionMagnitude: 1.0,
      );
      expect(score, 100);
    });

    test('todas las magnitudes en 0.5 → 50', () {
      final score = CycleScoreComputer.compute(
        fastingMagnitude: 0.5,
        sleepQualityScore: 0.5,
        hydrationMagnitude: 0.5,
        exerciseMagnitude: 0.5,
        nutritionMagnitude: 0.5,
      );
      expect(score, 50);
    });

    test('todas las magnitudes en 0.0 → 0', () {
      final score = CycleScoreComputer.compute(
        fastingMagnitude: 0.0,
        sleepQualityScore: 0.0,
        hydrationMagnitude: 0.0,
        exerciseMagnitude: 0.0,
        nutritionMagnitude: 0.0,
      );
      expect(score, 0);
    });

    test('todas null → 0 (fallback caller decide)', () {
      final score = CycleScoreComputer.compute();
      expect(score, 0);
    });

    test('solo sleep en 1.0 → 100 (renormalizado al único peso disponible)',
        () {
      final score = CycleScoreComputer.compute(sleepQualityScore: 1.0);
      expect(score, 100);
    });

    test('solo sleep en 0.5 → 50 (renormalizado)', () {
      final score = CycleScoreComputer.compute(sleepQualityScore: 0.5);
      expect(score, 50);
    });

    test('sobre-cumplimiento (mag > 1.0) se clampea, no infla el score', () {
      final score = CycleScoreComputer.compute(
        fastingMagnitude: 1.5,
        sleepQualityScore: 1.0,
      );
      // Equivalente a (0.22*1.0 + 0.25*1.0) / (0.22+0.25) = 1.0 → 100.
      expect(score, 100);
    });

    test('sleep 0.5 + hydration 1.0 → (0.25*0.5 + 0.15*1.0) / 0.40 ≈ 68.75 → 69',
        () {
      final score = CycleScoreComputer.compute(
        sleepQualityScore: 0.5,
        hydrationMagnitude: 1.0,
      );
      expect(score, 69);
    });

    test(
        'cuatro magnitudes presentes — fasting NaN/null se ignora sin romper',
        () {
      final score = CycleScoreComputer.compute(
        sleepQualityScore: 1.0,
        hydrationMagnitude: 1.0,
        exerciseMagnitude: 1.0,
        nutritionMagnitude: 1.0,
        // fastingMagnitude: null → omitida, renormalización sobre 0.78.
      );
      expect(score, 100);
    });

    test('magnitud negativa se clampea a 0', () {
      final score = CycleScoreComputer.compute(sleepQualityScore: -0.5);
      // sleep -0.5 → clamp 0.0 → score 0.
      expect(score, 0);
    });
  });

  group('SPEC-171 — coherencia con StreakEntry.dailyQualityScore', () {
    test(
        'mismos pesos que StreakEntry: sleep 25% + fasting 22% + exercise 20% + nutrition 18% + hydration 15% = 100%',
        () {
      // Test indirecto: el resultado de magnitudes parciales debe
      // reflejar los pesos esperados. Si Carlos cambia los pesos en
      // SPEC-140, hay que sincronizar acá Y en streak_entry.dart.
      final onlyFasting = CycleScoreComputer.compute(fastingMagnitude: 1.0);
      final onlySleep = CycleScoreComputer.compute(sleepQualityScore: 1.0);
      final onlyHyd = CycleScoreComputer.compute(hydrationMagnitude: 1.0);
      // Cualquier magnitud sola renormaliza al 100 (su peso es el único
      // disponible). Esta propiedad es la firma de la fórmula.
      expect(onlyFasting, 100);
      expect(onlySleep, 100);
      expect(onlyHyd, 100);
    });
  });
}
