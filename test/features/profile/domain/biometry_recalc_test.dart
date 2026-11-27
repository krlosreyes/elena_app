// SPEC-92: tests puros del helper `BiometryRecalc`. No dependen de
// Flutter ni de Firebase — corren con `flutter test`.

import 'package:elena_app/src/features/profile/domain/biometry_recalc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BiometryRecalc.recompute — hombre adulto típico', () {
    test('cintura sube → %grasa sube y queda coherente (ALTA)', () {
      final base = BiometryRecalc.recompute(
        weightKg: 80,
        heightCm: 175,
        waistCm: 85,
        neckCm: 38,
        gender: 'M',
      );
      final after = BiometryRecalc.recompute(
        weightKg: 80,
        heightCm: 175,
        waistCm: 92,
        neckCm: 38,
        gender: 'M',
      );

      expect(base.bodyFatPercentage, isNotNull);
      expect(after.bodyFatPercentage, isNotNull);
      expect(after.bodyFatPercentage!, greaterThan(base.bodyFatPercentage!));
      expect(after.confidenceLevel, 'ALTA');
      expect(after.isCoherent, isTrue);
    });

    test('cuello sube → %grasa baja y queda coherente (ALTA)', () {
      final base = BiometryRecalc.recompute(
        weightKg: 80,
        heightCm: 175,
        waistCm: 90,
        neckCm: 38,
        gender: 'M',
      );
      final after = BiometryRecalc.recompute(
        weightKg: 80,
        heightCm: 175,
        waistCm: 90,
        neckCm: 42,
        gender: 'M',
      );

      expect(after.bodyFatPercentage!, lessThan(base.bodyFatPercentage!));
      expect(after.confidenceLevel, 'ALTA');
      expect(after.isCoherent, isTrue);
    });
  });

  group('BiometryRecalc.recompute — mujer adulta típica', () {
    test('con cadera: Navy métrica, coherente (SPEC-306)', () {
      final result = BiometryRecalc.recompute(
        weightKg: 65,
        heightCm: 165,
        waistCm: 80,
        neckCm: 33,
        hipCm: 100,
        gender: 'F',
      );

      expect(result.bodyFatPercentage, closeTo(31.89, 0.05));
      expect(result.isCoherent, isTrue);
    });

    test('sin cadera: no calcula (BAJA) en vez de inventar', () {
      final result = BiometryRecalc.recompute(
        weightKg: 65,
        heightCm: 165,
        waistCm: 75,
        neckCm: 32,
        gender: 'F',
      );

      expect(result.bodyFatPercentage, isNull);
      expect(result.confidenceLevel, 'BAJA');
      expect(result.isCoherent, isFalse);
    });
  });

  group('BiometryRecalc.recompute — casos degenerados', () {
    test('waist null → no calcula, devuelve null + BAJA + !isCoherent', () {
      final result = BiometryRecalc.recompute(
        weightKg: 80,
        heightCm: 175,
        waistCm: null,
        neckCm: 38,
        gender: 'M',
      );

      expect(result.bodyFatPercentage, isNull);
      expect(result.confidenceLevel, 'BAJA');
      expect(result.isCoherent, isFalse);
    });

    test('neck null → no calcula, devuelve null + BAJA', () {
      final result = BiometryRecalc.recompute(
        weightKg: 80,
        heightCm: 175,
        waistCm: 85,
        neckCm: null,
        gender: 'M',
      );

      expect(result.bodyFatPercentage, isNull);
      expect(result.confidenceLevel, 'BAJA');
      expect(result.isCoherent, isFalse);
    });

    test('cintura ≤ cuello: no calcula (SPEC-306, antes devolvía 15 %)', () {
      final result = BiometryRecalc.recompute(
        weightKg: 50,
        heightCm: 180,
        waistCm: 30,
        neckCm: 38,
        gender: 'M',
      );
      expect(result.bodyFatPercentage, isNull);
      expect(result.confidenceLevel, 'BAJA');
    });
  });

  group('BiometryRecalc.recompute — gender parsing', () {
    test('"m" (lowercase) trata como masculino', () {
      final result = BiometryRecalc.recompute(
        weightKg: 80,
        heightCm: 175,
        waistCm: 90,
        neckCm: 38,
        gender: 'm',
      );
      expect(result.bodyFatPercentage, isNotNull);
    });

    test('"Otro" trata como femenino (necesita cadera)', () {
      final result = BiometryRecalc.recompute(
        weightKg: 65,
        heightCm: 165,
        waistCm: 80,
        neckCm: 33,
        hipCm: 100,
        gender: 'Otro',
      );
      expect(result.bodyFatPercentage, closeTo(31.89, 0.05));
    });
  });
}
