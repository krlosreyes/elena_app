// SPEC-209: Tests de la lógica de providers derivados de sueño.
//
// Verifica que sleepDurationProvider, isSleepOptimalProvider,
// sleepAdherenceProvider y recoveryStatusProvider computan correctamente
// a partir de un SleepState dado.
//
// Usa overrideWithValue para inyectar el SleepState sin instanciar
// SleepNotifier (que requiere Firebase/HealthKit).

import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/shared/providers/sleep_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

SleepState _stateWithHours(double hours) {
  final now = DateTime(2026, 6, 14, 8, 0);
  final fellAsleep = now.subtract(Duration(minutes: (hours * 60).round()));
  final lastMealTime = fellAsleep.subtract(const Duration(hours: 2));
  return SleepState(
    lastLog: SleepLog(
      id: 'test-log',
      fellAsleep: fellAsleep,
      wokeUp: now,
      lastMealTime: lastMealTime,
    ),
  );
}

ProviderContainer _containerWithSleep(SleepState state) {
  return ProviderContainer(
    overrides: [
      // overrideWithValue inyecta el state directamente sin crear
      // SleepNotifier (que requiere Firebase y HealthKit).
      sleepProvider.overrideWithValue(state),
    ],
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('SPEC-209 — providers derivados leen de sleepProvider', () {
    test('SPEC-209-01: sin log → sleepDurationProvider = 0.0', () {
      final container = _containerWithSleep(SleepState());
      addTearDown(container.dispose);

      expect(container.read(sleepDurationProvider), 0.0);
    });

    test('SPEC-209-02: 8h de sueño → sleepDurationProvider ≈ 8.0', () {
      final container = _containerWithSleep(_stateWithHours(8.0));
      addTearDown(container.dispose);

      expect(container.read(sleepDurationProvider), closeTo(8.0, 0.05));
    });

    test('SPEC-209-03: 7.5h → optimal, adherencia = 1.0, status = OPTIMAL',
        () {
      final container = _containerWithSleep(_stateWithHours(7.5));
      addTearDown(container.dispose);

      expect(container.read(isSleepOptimalProvider), isTrue);
      expect(container.read(isSleepSufficientProvider), isTrue);
      expect(container.read(sleepAdherenceProvider), 1.0);
      expect(container.read(recoveryStatusProvider), 'OPTIMAL');
    });

    test('SPEC-209-04: 6.6h → sufficient pero no optimal, adherencia = 0.6',
        () {
      final container = _containerWithSleep(_stateWithHours(6.6));
      addTearDown(container.dispose);

      expect(container.read(isSleepSufficientProvider), isTrue);
      expect(container.read(isSleepOptimalProvider), isFalse);
      expect(container.read(sleepAdherenceProvider), 0.6);
      expect(container.read(recoveryStatusProvider), 'ADEQUATE');
    });

    test('SPEC-209-05: 5.0h → insufficient, adherencia = 0.0', () {
      final container = _containerWithSleep(_stateWithHours(5.0));
      addTearDown(container.dispose);

      expect(container.read(isSleepSufficientProvider), isFalse);
      expect(container.read(isSleepOptimalProvider), isFalse);
      expect(container.read(sleepAdherenceProvider), 0.0);
      expect(container.read(recoveryStatusProvider), 'INSUFFICIENT');
    });

    test('SPEC-209-06: exactamente 7.0h → límite inferior de optimal', () {
      final container = _containerWithSleep(_stateWithHours(7.0));
      addTearDown(container.dispose);

      expect(container.read(isSleepOptimalProvider), isTrue);
      expect(container.read(sleepAdherenceProvider), 1.0);
    });

    test('SPEC-209-07: exactamente 6.5h → límite inferior de sufficient', () {
      final container = _containerWithSleep(_stateWithHours(6.5));
      addTearDown(container.dispose);

      expect(container.read(isSleepSufficientProvider), isTrue);
      expect(container.read(isSleepOptimalProvider), isFalse);
      expect(container.read(sleepAdherenceProvider), 0.6);
    });
  });
}
