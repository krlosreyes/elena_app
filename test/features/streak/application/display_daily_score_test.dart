// SPEC-171 §RF-171-02 (2026-06-04): tests del displayDailyScoreProvider.
//
// Validan el fallback al provider legacy cuando no hay ciclo abierto
// o el protocolo es 'Ninguno'. El cómputo cíclico per se está cubierto
// por cycle_score_computer_test.dart — acá nos enfocamos en la lógica
// de DECISIÓN del provider.

import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MetabolicCycle _openCycle({
  required String protocol,
  DateTime? startedAt,
}) {
  return MetabolicCycle(
    cycleId: 'test-cycle',
    startedAt: startedAt ?? DateTime(2026, 6, 3, 20, 30),
    fastingProtocol: protocol,
    tzOffsetMinutes: 0,
  );
}

void main() {
  group('SPEC-171 §RF-171-02 — fallback al legacy', () {
    test('sin ciclo abierto → retorna valor de dailyScoreProvider', () {
      final container = ProviderContainer(overrides: [
        currentMetabolicCycleProvider.overrideWith(
          (ref) => Stream<MetabolicCycle?>.value(null),
        ),
        dailyScoreProvider.overrideWithValue(42),
      ]);
      addTearDown(container.dispose);

      // Esperamos un microtask para que el StreamProvider emita.
      expectLater(
        Future(() => container.read(displayDailyScoreProvider)),
        completion(42),
      );
    });

    test('ciclo abierto con protocolo Ninguno → fallback al legacy', () {
      final container = ProviderContainer(overrides: [
        currentMetabolicCycleProvider.overrideWith(
          (ref) =>
              Stream<MetabolicCycle?>.value(_openCycle(protocol: 'Ninguno')),
        ),
        dailyScoreProvider.overrideWithValue(58),
      ]);
      addTearDown(container.dispose);

      expectLater(
        Future(() => container.read(displayDailyScoreProvider)),
        completion(58),
      );
    });

    test('protocolo desconocido (no canónico) → fallback al legacy', () {
      final container = ProviderContainer(overrides: [
        currentMetabolicCycleProvider.overrideWith(
          (ref) => Stream<MetabolicCycle?>.value(
            _openCycle(protocol: 'protocoloXYZ'),
          ),
        ),
        dailyScoreProvider.overrideWithValue(33),
      ]);
      addTearDown(container.dispose);

      expectLater(
        Future(() => container.read(displayDailyScoreProvider)),
        completion(33),
      );
    });
  });

  group('SPEC-171 §RF-171-03 — delta vs último ciclo cerrado', () {
    test('sin ciclo abierto → delta cae al dailyScoreDeltaProvider', () {
      final container = ProviderContainer(overrides: [
        currentMetabolicCycleProvider.overrideWith(
          (ref) => Stream<MetabolicCycle?>.value(null),
        ),
        dailyScoreDeltaProvider.overrideWithValue(7),
      ]);
      addTearDown(container.dispose);

      expectLater(
        Future(() => container.read(displayDailyScoreDeltaProvider)),
        completion(7),
      );
    });

    test('ciclo abierto válido pero sin último cerrado → delta null', () {
      final container = ProviderContainer(overrides: [
        currentMetabolicCycleProvider.overrideWith(
          (ref) =>
              Stream<MetabolicCycle?>.value(_openCycle(protocol: '16:8')),
        ),
        lastClosedMetabolicCycleProvider.overrideWith(
          (ref) => Stream<MetabolicCycle?>.value(null),
        ),
        dailyScoreDeltaProvider.overrideWithValue(-3),
      ]);
      addTearDown(container.dispose);

      expectLater(
        Future(() => container.read(displayDailyScoreDeltaProvider)),
        completion(isNull),
      );
    });
  });
}
