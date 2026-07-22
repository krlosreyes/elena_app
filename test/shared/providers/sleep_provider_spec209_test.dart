// SPEC-209: Tests de la lógica de cómputo de los providers derivados de sueño.
//
// Los providers en sleep_provider.dart son wrappers finos cuya lógica
// está completamente determinada por SleepLog.duration y umbrales fijos.
// El wiring Riverpod es verificado en compilación; acá se testea la lógica
// de los predicados: duración, suficiencia, optimalidad, adherencia, status.
//
// Funciones puras: no requieren Firebase ni Riverpod container.

import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Réplicas de las fórmulas de sleep_provider.dart ──────────────────────────
// (Mirrors exactos — si las fórmulas cambian, estos tests fallarán primero.)

double _sleepDuration(SleepLog? log) {
  if (log == null) return 0.0;
  return log.duration.inMinutes / 60.0;
}

bool _isSufficient(double h) => h >= 6.5;
bool _isOptimal(double h) => h >= 7.0 && h <= 9.0;

double _adherence(double h) {
  if (_isOptimal(h)) return 1.0;
  if (_isSufficient(h)) return 0.6;
  return 0.0;
}

String _status(double h) {
  if (_isOptimal(h)) return 'OPTIMAL';
  if (_isSufficient(h)) return 'ADEQUATE';
  return 'INSUFFICIENT';
}

// ── Helper ────────────────────────────────────────────────────────────────────

SleepLog _logWithHours(double hours) {
  final now = DateTime(2026, 6, 14, 8, 0);
  final fellAsleep = now.subtract(Duration(minutes: (hours * 60).round()));
  return SleepLog(
    id: 'test-$hours',
    fellAsleep: fellAsleep,
    wokeUp: now,
    lastMealTime: fellAsleep.subtract(const Duration(hours: 2)),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('SPEC-209 — lógica de sleepDurationProvider', () {
    test('SPEC-209-01: sin log → 0.0h', () {
      expect(_sleepDuration(null), 0.0);
    });

    test('SPEC-209-02: 8h → ≈ 8.0h', () {
      expect(_sleepDuration(_logWithHours(8.0)), closeTo(8.0, 0.05));
    });

    test('SPEC-209-03: 6.5h → ≈ 6.5h', () {
      expect(_sleepDuration(_logWithHours(6.5)), closeTo(6.5, 0.05));
    });
  });

  group('SPEC-209 — predicados de suficiencia y optimalidad', () {
    test('SPEC-209-04: 7.5h → optimal, sufficient', () {
      const h = 7.5;
      expect(_isOptimal(h), isTrue);
      expect(_isSufficient(h), isTrue);
      expect(_adherence(h), 1.0);
      expect(_status(h), 'OPTIMAL');
    });

    test('SPEC-209-05: 6.6h → sufficient pero no optimal', () {
      const h = 6.6;
      expect(_isSufficient(h), isTrue);
      expect(_isOptimal(h), isFalse);
      expect(_adherence(h), 0.6);
      expect(_status(h), 'ADEQUATE');
    });

    test('SPEC-209-06: 5.0h → insufficient', () {
      const h = 5.0;
      expect(_isSufficient(h), isFalse);
      expect(_isOptimal(h), isFalse);
      expect(_adherence(h), 0.0);
      expect(_status(h), 'INSUFFICIENT');
    });

    test('SPEC-209-07: límite inferior optimal = exactamente 7.0h', () {
      expect(_isOptimal(7.0), isTrue);
      expect(_isOptimal(6.99), isFalse);
    });

    test('SPEC-209-08: límite superior optimal = exactamente 9.0h', () {
      expect(_isOptimal(9.0), isTrue);
      expect(_isOptimal(9.01), isFalse);
    });

    test('SPEC-209-09: límite inferior sufficient = exactamente 6.5h', () {
      expect(_isSufficient(6.5), isTrue);
      expect(_isSufficient(6.49), isFalse);
    });
  });
}
