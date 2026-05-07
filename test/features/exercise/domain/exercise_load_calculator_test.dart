// Tests del ExerciseLoadCalculator — SPEC-68.

import 'package:elena_app/src/features/exercise/domain/exercise_load_calculator.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseLoadCalculator.calculate — base', () {
    test('Duración 0 → carga 0', () {
      expect(
        ExerciseLoadCalculator.calculate(durationMinutes: 0),
        0.0,
      );
    });

    test('60 min sin tipo/intensidad (legacy) → 1.0', () {
      // Backward compat: logs sin type/intensity equivalen al cálculo
      // SPEC-03: minutos/60.
      expect(
        ExerciseLoadCalculator.calculate(durationMinutes: 60),
        1.0,
      );
    });

    test('30 min sin tipo/intensidad → 0.5', () {
      expect(
        ExerciseLoadCalculator.calculate(durationMinutes: 30),
        0.5,
      );
    });
  });

  group('ExerciseLoadCalculator — multiplicadores por tipo', () {
    test('CA SPEC-68: 30 min HIIT > 30 min LISS por margen ≥ 1.4×', () {
      final liss = ExerciseLoadCalculator.calculate(
        durationMinutes: 30,
        type: ExerciseType.liss,
        intensity: ExerciseIntensity.moderate,
      );
      final hiit = ExerciseLoadCalculator.calculate(
        durationMinutes: 30,
        type: ExerciseType.hiit,
        intensity: ExerciseIntensity.moderate,
      );
      expect(hiit / liss, closeTo(1.5, 1e-9));
    });

    test('STRENGTH multiplicador = 1.3', () {
      // 30 min STRENGTH @ moderate = 0.5 × 1.3 × 1.0 = 0.65.
      final result = ExerciseLoadCalculator.calculate(
        durationMinutes: 30,
        type: ExerciseType.strength,
        intensity: ExerciseIntensity.moderate,
      );
      expect(result, closeTo(0.65, 1e-9));
    });

    test('MOBILITY multiplicador = 0.6', () {
      // 60 min MOBILITY @ moderate = 1.0 × 0.6 × 1.0 = 0.6.
      final result = ExerciseLoadCalculator.calculate(
        durationMinutes: 60,
        type: ExerciseType.mobility,
        intensity: ExerciseIntensity.moderate,
      );
      expect(result, closeTo(0.6, 1e-9));
    });
  });

  group('ExerciseLoadCalculator — multiplicadores por intensidad', () {
    test('Misma duración + tipo: high > moderate > low', () {
      final low = ExerciseLoadCalculator.calculate(
        durationMinutes: 30,
        type: ExerciseType.hiit,
        intensity: ExerciseIntensity.low,
      );
      final mod = ExerciseLoadCalculator.calculate(
        durationMinutes: 30,
        type: ExerciseType.hiit,
        intensity: ExerciseIntensity.moderate,
      );
      final high = ExerciseLoadCalculator.calculate(
        durationMinutes: 30,
        type: ExerciseType.hiit,
        intensity: ExerciseIntensity.high,
      );
      expect(low, lessThan(mod));
      expect(mod, lessThan(high));
    });

    test('60 min HIIT @ high alcanza el clamp superior 1.5', () {
      // 1.0 × 1.5 × 1.3 = 1.95 → clamp a 1.5.
      final result = ExerciseLoadCalculator.calculate(
        durationMinutes: 60,
        type: ExerciseType.hiit,
        intensity: ExerciseIntensity.high,
      );
      expect(result, 1.5);
    });
  });

  group('ExerciseLoadCalculator.sumDailyLoad', () {
    ExerciseLog _log({
      required int min,
      ExerciseType? type,
      ExerciseIntensity? intensity,
    }) =>
        ExerciseLog(
          id: 'x',
          userId: 'u',
          durationMinutes: min,
          activityType: type?.name ?? 'unknown',
          timestamp: DateTime(2026, 5, 1, 8),
          type: type,
          intensity: intensity,
        );

    test('Suma de varias sesiones', () {
      final logs = [
        _log(
          min: 20,
          type: ExerciseType.liss,
          intensity: ExerciseIntensity.moderate,
        ), // 0.333...
        _log(
          min: 20,
          type: ExerciseType.strength,
          intensity: ExerciseIntensity.moderate,
        ), // 0.433...
      ];
      final total = ExerciseLoadCalculator.sumDailyLoad(logs);
      expect(total, closeTo(0.333 + 0.433, 0.01));
    });

    test('Lista vacía → 0', () {
      expect(ExerciseLoadCalculator.sumDailyLoad(const []), 0.0);
    });

    test('Suma se clampa a 2.0 en casos extremos', () {
      final logs = List.generate(
        4,
        (_) => _log(
          min: 60,
          type: ExerciseType.hiit,
          intensity: ExerciseIntensity.high,
        ), // cada uno: 1.5 (clamp)
      );
      final total = ExerciseLoadCalculator.sumDailyLoad(logs);
      expect(total, 2.0);
    });
  });
}
