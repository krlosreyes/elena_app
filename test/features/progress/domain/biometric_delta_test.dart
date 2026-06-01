// SPEC-143: tests del BiometricDelta. Cubre §8.3 del SPEC.

import 'package:elena_app/src/features/progress/domain/biometric_delta.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Profile circadiano default — irrelevante para los tests de BiometricDelta
// pero requerido por UserModel. Los thresholds y la lógica del delta no
// dependen del profile.
final _defaultProfile = CircadianProfile(
  wakeUpTime: DateTime(2026, 1, 1, 7, 0),
  sleepTime: DateTime(2026, 1, 1, 23, 0),
);

UserModel _baseline({
  double weight = 75.0,
  double? waistCircumference = 90.0,
  double? neckCircumference = 38.0,
  double? bodyFatPercentage = 20.0,
  bool isMeasurementEstimated = false,
}) =>
    UserModel(
      id: 'u1',
      age: 35,
      gender: 'M',
      weight: weight,
      height: 175,
      waistCircumference: waistCircumference,
      neckCircumference: neckCircumference,
      bodyFatPercentage: bodyFatPercentage,
      isMeasurementEstimated: isMeasurementEstimated,
      profile: _defaultProfile,
    );

void main() {
  group('SPEC-143 §8.3 — BiometricDelta.isSignificant', () {
    test('Peso 75.0 vs 75.3 → no significativo (0.4% < 0.5%)', () {
      const delta = BiometricDelta(weight: 75.3);
      expect(delta.isSignificant(baseline: _baseline()), isFalse);
    });

    test('Peso 75.0 vs 75.4 → significativo (0.53% > 0.5%)', () {
      const delta = BiometricDelta(weight: 75.4);
      expect(delta.isSignificant(baseline: _baseline()), isTrue);
    });

    test('Peso 75.0 vs 75.0 → no significativo (delta cero)', () {
      const delta = BiometricDelta(weight: 75.0);
      expect(delta.isSignificant(baseline: _baseline()), isFalse);
    });

    test('Cintura 90.0 vs 90.4 → no significativo (0.44% < 0.5%)', () {
      const delta = BiometricDelta(waistCircumference: 90.4);
      expect(delta.isSignificant(baseline: _baseline()), isFalse);
    });

    test('Cintura 90.0 vs 90.5 → significativo (0.55% > 0.5%)', () {
      const delta = BiometricDelta(waistCircumference: 90.5);
      expect(delta.isSignificant(baseline: _baseline()), isTrue);
    });

    test('Cuello 38.0 vs 38.2 → no significativo (0.52% < 1.0%)', () {
      const delta = BiometricDelta(neckCircumference: 38.2);
      expect(delta.isSignificant(baseline: _baseline()), isFalse);
    });

    test('Cuello 38.0 vs 38.5 → significativo (1.3% > 1.0%)', () {
      const delta = BiometricDelta(neckCircumference: 38.5);
      expect(delta.isSignificant(baseline: _baseline()), isTrue);
    });

    test('BodyFat 20.0 vs 20.3 → no significativo (0.3pp < 0.5pp)', () {
      const delta = BiometricDelta(bodyFatPercentage: 20.3);
      expect(delta.isSignificant(baseline: _baseline()), isFalse);
    });

    test('BodyFat 20.0 vs 20.5 → significativo (0.5pp >= 0.5pp)', () {
      const delta = BiometricDelta(bodyFatPercentage: 20.5);
      expect(delta.isSignificant(baseline: _baseline()), isTrue);
    });

    test('isMeasurementEstimated toggle → siempre significativo', () {
      const delta = BiometricDelta(isMeasurementEstimated: true);
      expect(
        delta.isSignificant(baseline: _baseline(isMeasurementEstimated: false)),
        isTrue,
      );
    });

    test('isMeasurementEstimated mismo valor → no significativo', () {
      const delta = BiometricDelta(isMeasurementEstimated: false);
      expect(
        delta.isSignificant(baseline: _baseline(isMeasurementEstimated: false)),
        isFalse,
      );
    });

    test('Baseline con campo null + delta con valor → siempre significativo', () {
      const delta = BiometricDelta(waistCircumference: 90.0);
      expect(
        delta.isSignificant(baseline: _baseline(waistCircumference: null)),
        isTrue,
        reason: 'Completar dato que antes era null es significativo',
      );
    });

    test('Baseline con bodyFat null + delta con valor → significativo', () {
      const delta = BiometricDelta(bodyFatPercentage: 22.0);
      expect(
        delta.isSignificant(baseline: _baseline(bodyFatPercentage: null)),
        isTrue,
      );
    });

    test('Múltiples campos, uno significativo → significativo', () {
      const delta = BiometricDelta(
        weight: 75.1,
        waistCircumference: 90.5,
      );
      expect(delta.isSignificant(baseline: _baseline()), isTrue);
    });

    test('Múltiples campos, ninguno significativo → no significativo', () {
      const delta = BiometricDelta(
        weight: 75.1,
        waistCircumference: 90.1,
        neckCircumference: 38.1,
        bodyFatPercentage: 20.2,
      );
      expect(delta.isSignificant(baseline: _baseline()), isFalse);
    });

    test('Edge: baseline.weight = 0 + delta con peso → significativo', () {
      const delta = BiometricDelta(weight: 70.0);
      expect(
        delta.isSignificant(baseline: _baseline(weight: 0)),
        isTrue,
        reason: 'División por cero protegida — cualquier cambio desde 0 dispara',
      );
    });
  });

  group('SPEC-143 — BiometricDelta.isEmpty', () {
    test('Sin campos → isEmpty', () {
      const delta = BiometricDelta();
      expect(delta.isEmpty, isTrue);
    });

    test('Con un campo → no isEmpty', () {
      const delta = BiometricDelta(weight: 75.0);
      expect(delta.isEmpty, isFalse);
    });
  });

  group('SPEC-143 — BiometricDelta.previousValuesAgainst', () {
    test('Devuelve solo los campos que cambian', () {
      final baseline = _baseline(weight: 75.0, waistCircumference: 90.0);
      const delta = BiometricDelta(weight: 73.0);
      final prev = delta.previousValuesAgainst(baseline);
      expect(prev['weight'], 75.0);
      expect(prev.containsKey('waistCircumference'), isFalse,
          reason: 'No tocó cintura, no aparece');
    });

    test('Si el delta no cambia ningún valor, devuelve mapa vacío', () {
      final baseline = _baseline(weight: 75.0);
      const delta = BiometricDelta(weight: 75.0);
      final prev = delta.previousValuesAgainst(baseline);
      expect(prev.isEmpty, isTrue);
    });

    test('Captura el valor previo null cuando se completa', () {
      final baseline = _baseline(waistCircumference: null);
      const delta = BiometricDelta(waistCircumference: 90.0);
      final prev = delta.previousValuesAgainst(baseline);
      expect(prev.containsKey('waistCircumference'), isTrue);
      expect(prev['waistCircumference'], isNull);
    });
  });

  group('SPEC-143 — BiometricDelta.applyTo', () {
    test('Aplica los campos del delta, preserva los demás', () {
      final baseline = _baseline(weight: 75.0, waistCircumference: 90.0);
      const delta = BiometricDelta(weight: 73.0);
      final result = delta.applyTo(baseline);
      expect(result.weight, 73.0);
      expect(result.waistCircumference, 90.0);
    });

    test('Delta vacío deja el baseline inalterado', () {
      final baseline = _baseline();
      const delta = BiometricDelta();
      final result = delta.applyTo(baseline);
      expect(result.weight, baseline.weight);
      expect(result.waistCircumference, baseline.waistCircumference);
      expect(result.bodyFatPercentage, baseline.bodyFatPercentage);
    });
  });

  group('SPEC-143 — BiometricSource', () {
    test('Todas las fuentes esperadas están en .all', () {
      expect(BiometricSource.all, contains('profile_edit'));
      expect(BiometricSource.all, contains('checkin_sheet'));
      expect(BiometricSource.all, contains('healthkit_sync'));
      expect(BiometricSource.all, contains('bodyfat_recompute'));
      expect(BiometricSource.all, contains('onboarding_baseline'));
      expect(BiometricSource.all, contains('spec_143_backfill'));
    });

    test('.all tiene exactamente 6 fuentes', () {
      expect(BiometricSource.all.length, 6);
    });
  });
}
