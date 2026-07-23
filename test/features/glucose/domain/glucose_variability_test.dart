// Módulo "Tu Glucosa" — tests de GlucoseVariability (propuesta §2.5 y
// §12.2, Monnier et al. 2017). Cubre R8 (mínimo 7 lecturas) y el
// umbral %CV ≥36%.

import 'package:elena_app/src/features/glucose/domain/glucose_variability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlucoseVariability.compute — R8 mínimo de datos', () {
    test('con menos de 7 valores → insufficientData', () {
      final result = GlucoseVariability.compute([90, 95, 100, 92, 88, 91]);
      expect(result.sampleSize, 0);
      expect(result.hasEnoughData, isFalse);
      expect(result, same(GlucoseVariabilityResult.insufficientData));
    });

    test('con exactamente 7 valores → sí calcula', () {
      final result =
          GlucoseVariability.compute([90, 95, 100, 92, 88, 91, 93]);
      expect(result.sampleSize, 7);
      expect(result.hasEnoughData, isTrue);
    });

    test('lista vacía → insufficientData sin excepción', () {
      final result = GlucoseVariability.compute(const []);
      expect(result.sampleSize, 0);
      expect(result.isHighVariability, isFalse);
    });
  });

  group('GlucoseVariability.compute — cálculo estadístico', () {
    test('valores idénticos → SD 0, %CV 0, sin alta variabilidad', () {
      final result =
          GlucoseVariability.compute([100, 100, 100, 100, 100, 100, 100]);
      expect(result.standardDeviation, 0);
      expect(result.coefficientOfVariationPercent, 0);
      expect(result.isHighVariability, isFalse);
    });

    test('alta dispersión (%CV ≥ 36%) → isHighVariability true', () {
      // Media 100, con dispersión amplia (60-140) → %CV muy por encima
      // del umbral de Monnier (36%).
      final result = GlucoseVariability.compute(
          [60, 140, 60, 140, 60, 140, 100]);
      expect(result.coefficientOfVariationPercent,
          greaterThanOrEqualTo(GlucoseVariability.kHighVariabilityThresholdPercent));
      expect(result.isHighVariability, isTrue);
    });

    test('baja dispersión (%CV < 36%) → isHighVariability false', () {
      final result =
          GlucoseVariability.compute([95, 98, 100, 97, 99, 96, 101]);
      expect(result.isHighVariability, isFalse);
    });
  });
}
