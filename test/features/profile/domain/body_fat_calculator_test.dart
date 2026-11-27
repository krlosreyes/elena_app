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

    test('inputs inválidos (cintura ≤ cuello) → 0 (sin dato, SPEC-306)', () {
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 38,
        neckCm: 40,
        heightCm: 180,
        isMale: true,
      );
      expect(bf, 0.0);
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

  group('SPEC-306 — BodyFatCalculator mujeres (Navy métrica con cadera)', () {
    test(
        'mismo resultado que la calculadora del sitio: 165/80/33/cadera 100 → 31,9 %',
        () {
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 80,
        neckCm: 33,
        heightCm: 165,
        hipCm: 100,
        isMale: false,
      );
      expect(bf, closeTo(31.89, 0.05));
    });

    test('sin cadera → 0 (no se inventa un valor)', () {
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 80,
        neckCm: 33,
        heightCm: 165,
        isMale: false,
      );
      expect(bf, 0.0);
    });

    test('hombre: equivale al sitio, 175/90/40 → 19,2 %', () {
      final bf = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: 90,
        neckCm: 40,
        heightCm: 175,
        isMale: true,
      );
      expect(bf, closeTo(19.21, 0.05));
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
