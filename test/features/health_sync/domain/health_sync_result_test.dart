// Tests de HealthSyncResult y HealthSample — SPEC-132 Bloque B.

import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 5, 20);
  final end = DateTime(2026, 5, 27);

  HealthSample sample({
    required HealthMetric metric,
    required double value,
    DateTime? at,
  }) =>
      HealthSample(
        metric: metric,
        value: value,
        start: at ?? DateTime(2026, 5, 25),
        end: at ?? DateTime(2026, 5, 25),
        sourceName: 'test',
      );

  group('HealthMetric.canonicalUnit', () {
    test('weight es kg', () {
      expect(HealthMetric.weight.canonicalUnit, 'kg');
    });
    test('sleepSession es minutes', () {
      expect(HealthMetric.sleepSession.canonicalUnit, 'minutes');
    });
    test('steps es count', () {
      expect(HealthMetric.steps.canonicalUnit, 'count');
    });
  });

  group('HealthSyncResult.empty', () {
    test('es realmente vacío', () {
      final r = HealthSyncResult.empty(start, end);
      expect(r.isEmpty, isTrue);
      expect(r.hasErrors, isFalse);
      expect(r.totalSamples, 0);
    });
  });

  group('HealthSyncResult.totalSamples', () {
    test('suma muestras de todas las métricas', () {
      final r = HealthSyncResult(
        windowStart: start,
        windowEnd: end,
        samplesByMetric: {
          HealthMetric.weight: [
            sample(metric: HealthMetric.weight, value: 80),
            sample(metric: HealthMetric.weight, value: 79.5),
          ],
          HealthMetric.sleepSession: [
            sample(metric: HealthMetric.sleepSession, value: 420),
          ],
        },
        errors: {},
        completedAt: DateTime.now(),
      );
      expect(r.totalSamples, 3);
      expect(r.isEmpty, isFalse);
    });
  });

  group('HealthSyncResult.hasErrors', () {
    test('marca true si hay error de alguna métrica', () {
      final r = HealthSyncResult(
        windowStart: start,
        windowEnd: end,
        samplesByMetric: const {},
        errors: const {HealthMetric.weight: 'timeout'},
        completedAt: DateTime.now(),
      );
      expect(r.hasErrors, isTrue);
    });
  });

  group('HealthSyncResult.samplesFor', () {
    test('retorna lista vacía si no hay datos de la métrica', () {
      final r = HealthSyncResult.empty(start, end);
      expect(r.samplesFor(HealthMetric.weight), isEmpty);
    });
  });
}
