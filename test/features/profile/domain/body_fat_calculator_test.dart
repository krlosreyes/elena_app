// SPEC-90 §6 — tests del calculador US Navy.
//
// Verifica que el cálculo es razonable en escenarios típicos y que
// los fallbacks protegen contra inputs basura.

import 'package:elena_app/src/features/profile/domain/body_fat_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-90 — BodyFatCalculator hombres', () {
    test('delgado: rango realista bajo', () {
      // Navy formula con waist=78, neck=38, height=180 → ~16.6%.
      // Esa es la realidad de la fórmula para esos antropométricos —
      // describe un sujeto delgado pero no atlético extremo.
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 78,
        neckCm: 38,
        heightCm: 180,
        isMale: true,
      );
      expect(bf, greaterThan(10));
      expect(bf, lessThan(20));
    });

    test('promedio adulto: rango realista medio', () {
      // waist=88, neck=38, height=180 → ~18-22%
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 88,
        neckCm: 38,
        heightCm: 180,
        isMale: true,
      );
      expect(bf, greaterThan(15));
      expect(bf, lessThan(25));
    });

    test('sobrepeso: rango realista alto', () {
      // waist=110, neck=42, height=170 → > 28%
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 110,
        neckCm: 42,
        heightCm: 170,
        isMale: true,
      );
      expect(bf, greaterThan(25));
    });

    test('inputs inválidos (cintura ≤ cuello) → fallback default masculino',
        () {
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 38,
        neckCm: 40,
        heightCm: 180,
        isMale: true,
      );
      expect(bf, 15.0);
    });

    test('altura cero → 0 (sin datos)', () {
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 85,
        neckCm: 38,
        heightCm: 0,
        isMale: true,
      );
      expect(bf, 0.0);
    });
  });

  group('SPEC-90 — BodyFatCalculator mujeres (aproximación WHtR)', () {
    test('WHtR bajo → < 20%', () {
      // 60/170 = 0.353 → bajo
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 60,
        neckCm: 32,
        heightCm: 170,
        isMale: false,
      );
      expect(bf, lessThan(20));
    });

    test('WHtR medio → 22-30%', () {
      // 75/165 = 0.455
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 75,
        neckCm: 33,
        heightCm: 165,
        isMale: false,
      );
      expect(bf, inInclusiveRange(22, 30));
    });

    test('WHtR alto → > 32%', () {
      // 95/160 = 0.59
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 95,
        neckCm: 35,
        heightCm: 160,
        isMale: false,
      );
      expect(bf, greaterThanOrEqualTo(34));
    });
  });

  group('SPEC-90 — isCoherent', () {
    test('valores realistas → true', () {
      expect(
        BodyFatCalculator.isCoherent(
          weight: 80,
          height: 180,
          calculatedBodyFatPct: 18,
        ),
        isTrue,
      );
    });

    test('lean mass absurdamente bajo (< 20kg) → false', () {
      // 80kg con 80% grasa → lean = 16kg
      expect(
        BodyFatCalculator.isCoherent(
          weight: 80,
          height: 180,
          calculatedBodyFatPct: 80,
        ),
        isFalse,
      );
    });

    test('lean mass > 95% peso → false', () {
      // 80kg con 1% grasa → lean = 79.2kg = 99% peso
      expect(
        BodyFatCalculator.isCoherent(
          weight: 80,
          height: 180,
          calculatedBodyFatPct: 1,
        ),
        isFalse,
      );
    });
  });
}
