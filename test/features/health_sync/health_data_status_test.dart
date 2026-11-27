// 2026-11-04 (auditoría Apple Salud, Fase 3).

import 'package:elena_app/src/features/health_sync/application/health_data_status.dart';
import 'package:elena_app/src/features/health_sync/application/health_import_service.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

HealthSyncResult _result(Map<HealthMetric, List<HealthSample>> m) =>
    HealthSyncResult(
      windowStart: DateTime(2026, 10, 28),
      windowEnd: DateTime(2026, 11, 4),
      samplesByMetric: m,
      errors: const {},
      completedAt: DateTime(2026, 11, 4),
    );

HealthSample _sample(HealthMetric m, DateTime at, double v,
        [String source = 'iPhone']) =>
    HealthSample(metric: m, value: v, start: at, end: at, sourceName: source);

void main() {
  test('merge guarda el dato más reciente y el último peso', () {
    final s = HealthDataStatus.empty.merge(_result({
      HealthMetric.steps: [
        _sample(HealthMetric.steps, DateTime(2026, 11, 3, 10), 100),
        _sample(HealthMetric.steps, DateTime(2026, 11, 4, 9), 100),
      ],
      HealthMetric.weight: [
        _sample(
            HealthMetric.weight, DateTime(2026, 11, 2, 7), 79.0, 'Withings'),
        _sample(
            HealthMetric.weight, DateTime(2026, 11, 4, 7), 78.4, 'Withings'),
      ],
    }));
    expect(s.lastSeen[HealthMetric.steps], DateTime(2026, 11, 4, 9));
    expect(s.latestWeight?.kg, 78.4);
    expect(s.latestWeight?.source, 'Withings');
  });

  test('pasos o sueño sin datos en 7 días → aviso de permisos', () {
    final s = HealthDataStatus(lastSeen: {
      HealthMetric.steps: DateTime(2026, 11, 4),
      HealthMetric.sleepSession: DateTime(2026, 10, 20),
    });
    expect(
        s.staleMetrics(DateTime(2026, 11, 4, 12)), [HealthMetric.sleepSession]);
    // Peso o entrenamientos ausentes no se reclaman (no todos tienen báscula).
    expect(
        HealthDataStatus(lastSeen: {
          HealthMetric.steps: DateTime(2026, 11, 4),
          HealthMetric.sleepSession: DateTime(2026, 11, 4),
        }).staleMetrics(DateTime(2026, 11, 4, 12)),
        isEmpty);
  });

  test('persiste y recupera', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = HealthDataStatus(
      lastSeen: {HealthMetric.sleepSession: DateTime(2026, 11, 4, 6, 10)},
      latestWeight: HealthLatestWeight(
          kg: 78.4, at: DateTime(2026, 11, 4, 7), source: 'Withings'),
    );
    await s.save(prefs);
    final back = HealthDataStatus.load(prefs);
    expect(
        back.lastSeen[HealthMetric.sleepSession], DateTime(2026, 11, 4, 6, 10));
    expect(back.latestWeight?.kg, 78.4);
  });

  test('pesos importados antes por Apple Salud no cuentan como medición', () {
    expect(
      BiometricLockService.countsAsMeasurement(null,
          notes: 'Importado de Apple Watch'),
      isFalse,
    );
    expect(
      BiometricLockService.countsAsMeasurement(null, notes: 'Me sentí bien'),
      isTrue,
    );
  });

  test('última comida: el ayuno más reciente en las 14 h previas', () {
    final asleep = DateTime(2026, 11, 4, 23);
    expect(
      HealthImportService.lastMealBefore(asleep, [
        DateTime(2026, 11, 3, 20),
        DateTime(2026, 11, 4, 19, 30),
        DateTime(2026, 11, 5, 8), // después de dormirse: no
      ]),
      DateTime(2026, 11, 4, 19, 30),
    );
    expect(
      HealthImportService.lastMealBefore(asleep, [DateTime(2026, 11, 3, 6)]),
      isNull,
    );
  });

  test('actividad se atribuye al mediodía de su fecha', () {
    expect(
      HealthImportService.activityTimestampFor(
          '2026-11-03', DateTime(2026, 11, 4, 9)),
      DateTime(2026, 11, 3, 12),
    );
    // Hoy antes del mediodía: ahora.
    final now = DateTime(2026, 11, 4, 9);
    expect(HealthImportService.activityTimestampFor('2026-11-04', now), now);
  });
}
