// SPEC-141 §RF-141-03 (2026-06-05): tests del dominio longitudinal en
// StreakEngine. Cubre `computeMonthlyQualityScore`,
// `computeActiveDaysLast90` y `computeAdherenceTrend`.
//
// Funciones puras — no requieren Riverpod ni Flutter.

import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper para construir StreakEntry con magnitudes.
StreakEntry _entry(
  String date, {
  double magnitude = 0.8,
  bool qualifies = true,
}) {
  return StreakEntry(
    date: date,
    fastingCompleted: qualifies,
    sleepCompleted: qualifies,
    hydrationCompleted: qualifies,
    exerciseLogged: qualifies,
    nutritionLogged: qualifies,
    imrScore: qualifies ? 70 : 30,
    fastingMagnitude: magnitude,
    sleepQualityScore: magnitude,
    hydrationMagnitude: magnitude,
    exerciseMagnitude: magnitude,
    nutritionMagnitude: magnitude,
  );
}

String _isoDaysAgo(int days) {
  final d = DateTime.now().subtract(Duration(days: days));
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

void main() {
  group('SPEC-141 §RF-141-03 — computeMonthlyQualityScore', () {
    test('historial vacío → 0.0', () {
      expect(StreakEngine.computeMonthlyQualityScore(const []), 0.0);
    });

    test('todas las entradas en ventana 30d → promedio de magnitudes', () {
      final history = [
        _entry(_isoDaysAgo(5), magnitude: 1.0),
        _entry(_isoDaysAgo(10), magnitude: 0.6),
        _entry(_isoDaysAgo(20), magnitude: 0.8),
      ];
      // Promedio de 3 entries con mag 1.0/0.6/0.8 = 0.8.
      final score = StreakEngine.computeMonthlyQualityScore(history);
      expect(score, closeTo(0.8, 0.01));
    });

    test('entradas fuera de la ventana 30d ignoradas', () {
      final history = [
        _entry(_isoDaysAgo(5), magnitude: 1.0),
        _entry(_isoDaysAgo(45), magnitude: 0.0), // fuera de 30d
      ];
      // Solo 1 entry válida con mag 1.0.
      expect(StreakEngine.computeMonthlyQualityScore(history), 1.0);
    });

    test('clamp a [0, 1]', () {
      final history = [_entry(_isoDaysAgo(1), magnitude: 1.0)];
      expect(StreakEngine.computeMonthlyQualityScore(history), 1.0);
    });
  });

  group('SPEC-141 §RF-141-03 — computeActiveDaysLast90', () {
    test('historial vacío → 0', () {
      expect(StreakEngine.computeActiveDaysLast90(const []), 0);
    });

    test('cuenta solo días qualifies==true', () {
      final history = [
        _entry(_isoDaysAgo(1)),
        _entry(_isoDaysAgo(2), qualifies: false), // no califica
        _entry(_isoDaysAgo(3)),
      ];
      expect(StreakEngine.computeActiveDaysLast90(history), 2);
    });

    test('días duplicados (mismo date) cuentan una vez', () {
      final today = _isoDaysAgo(0);
      final history = [_entry(today), _entry(today), _entry(today)];
      expect(StreakEngine.computeActiveDaysLast90(history), 1);
    });

    test('entradas fuera de 90d ignoradas', () {
      final history = [
        _entry(_isoDaysAgo(1)),
        _entry(_isoDaysAgo(120)),
      ];
      expect(StreakEngine.computeActiveDaysLast90(history), 1);
    });
  });

  group('SPEC-141 §RF-141-03 — computeAdherenceTrend', () {
    test('historial vacío → 0.0', () {
      expect(StreakEngine.computeAdherenceTrend(const []), 0.0);
    });

    test('usuario nuevo con 1 día de presencia → score bajo', () {
      final history = [_entry(_isoDaysAgo(0))];
      final trend = StreakEngine.computeAdherenceTrend(history);
      // streakNorm = currentStreak/14 (currentStreak es 1) = 0.071
      // activeFrac = 1/90 = 0.011
      // adherence = 0.55 * 0.071 + 0.45 * 0.011 ≈ 0.044
      expect(trend, lessThan(0.1));
    });

    test('usuario con 30 días seguidos califican → score alto', () {
      final history = List<StreakEntry>.generate(
        30,
        (i) => _entry(_isoDaysAgo(i)),
      );
      final trend = StreakEngine.computeAdherenceTrend(history);
      // currentStreak >= 14 (clamp) → streakNorm = 1.0
      // activeFrac = 30/90 ≈ 0.333
      // adherence = 0.55 + 0.45 * 0.333 ≈ 0.70
      expect(trend, greaterThanOrEqualTo(0.65));
      expect(trend, lessThan(0.85));
    });

    test('usuario "perfecto" (14d streak + 90/90 días) → 1.0', () {
      final history = List<StreakEntry>.generate(
        90,
        (i) => _entry(_isoDaysAgo(i)),
      );
      final trend = StreakEngine.computeAdherenceTrend(history);
      expect(trend, 1.0);
    });

    test('clamp a [0, 1]', () {
      final history = List<StreakEntry>.generate(
        200, // > 90 días
        (i) => _entry(_isoDaysAgo(i)),
      );
      final trend = StreakEngine.computeAdherenceTrend(history);
      expect(trend, lessThanOrEqualTo(1.0));
      expect(trend, greaterThanOrEqualTo(0.0));
    });
  });
}
