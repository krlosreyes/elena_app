// Tests del HealthImportService — SPEC-132 Bloque C.
//
// Cubren las reglas de negocio críticas:
//   1. Dedup por día (peso): múltiples samples del mismo día → 1 doc.
//   2. Idempotencia (sueño): mismo uuid → mismo id de log.
//   3. Threshold (pasos): <5000/día NO genera ExerciseLog.
//   4. Failure isolation: si una métrica falla, las otras siguen.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_repository.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_repository.dart';
import 'package:elena_app/src/features/health_sync/application/health_import_service.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ──────────────────────────────────────────────────────────────

class _FakeSleepRepository implements SleepRepository {
  final List<SleepLog> saved = [];
  @override
  Future<void> save(String userId, SleepLog log) async {
    saved.add(log);
  }

  @override
  Future<void> delete(String userId, String logId) async {}

  @override
  Stream<SleepLog?> watchLatest(String userId) => const Stream.empty();

  /// SPEC-159: nuevo método del contrato. Para los tests de import
  /// service no se valida el historial — Stream.empty() es suficiente.
  @override
  Stream<List<SleepLog>> watchRecent(String userId, {int limit = 7}) =>
      const Stream.empty();
}

class _FakeExerciseRepository implements ExerciseRepository {
  final List<ExerciseLog> saved = [];
  @override
  Future<void> save(String userId, ExerciseLog log) async {
    saved.add(log);
  }

  @override
  Stream<List<ExerciseLog>> watchToday(String userId) => const Stream.empty();

  /// SPEC-149.2: nuevo método del contrato. El fake no filtra por
  /// ventana — los tests de import service no validan eso.
  @override
  Stream<List<ExerciseLog>> watchSince(
    String userId,
    DateTime since, {
    DateTime? until,
  }) =>
      const Stream.empty();

  @override
  Future<void> removeLastSession(String userId, DateTime since) async {}
}

// Fake del BiometricRepository: reusamos fake_cloud_firestore para tener
// fetchToday() funcionando como en producción.

// ── Helpers ────────────────────────────────────────────────────────────

HealthSample _weightSample({
  required DateTime at,
  required double kg,
  String? uuid,
}) =>
    HealthSample(
      metric: HealthMetric.weight,
      value: kg,
      start: at,
      end: at,
      sourceName: 'Apple Watch',
      uuid: uuid,
    );

HealthSample _sleepSample({
  required DateTime fellAsleep,
  required DateTime wokeUp,
  String? uuid,
}) =>
    HealthSample(
      metric: HealthMetric.sleepSession,
      value: wokeUp.difference(fellAsleep).inMinutes.toDouble(),
      start: fellAsleep,
      end: wokeUp,
      sourceName: 'iPhone',
      uuid: uuid,
    );

HealthSample _stepsSample({
  required DateTime at,
  required double count,
}) =>
    HealthSample(
      metric: HealthMetric.steps,
      value: count,
      start: at,
      end: at,
      sourceName: 'iPhone',
    );

HealthSample _workoutSample({
  required DateTime start,
  required int minutes,
  required String activityType,
  String? uuid,
}) =>
    HealthSample(
      metric: HealthMetric.workout,
      value: minutes.toDouble(),
      start: start,
      end: start.add(Duration(minutes: minutes)),
      sourceName: 'Apple Watch',
      uuid: uuid,
      workoutActivityType: activityType,
    );

HealthSyncResult _resultWith(Map<HealthMetric, List<HealthSample>> samples) {
  return HealthSyncResult(
    windowStart: DateTime(2026, 5, 20),
    windowEnd: DateTime(2026, 5, 27),
    samplesByMetric: samples,
    errors: const {},
    completedAt: DateTime.now(),
  );
}

void main() {
  late _FakeSleepRepository sleepRepo;
  late _FakeExerciseRepository exerciseRepo;
  late BiometricRepository biometricRepo;
  late HealthImportService service;
  const userId = 'user-123';

  setUp(() {
    sleepRepo = _FakeSleepRepository();
    exerciseRepo = _FakeExerciseRepository();
    final FirebaseFirestore fake = FakeFirebaseFirestore();
    biometricRepo = BiometricRepository(fake);
    service = HealthImportService(
      biometricRepository: biometricRepo,
      sleepRepository: sleepRepo,
      exerciseRepository: exerciseRepo,
    );
  });

  group('peso', () {
    test('un sample por día se persiste como BiometricCheckIn', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.weight: [
            _weightSample(at: DateTime(2026, 5, 26, 8), kg: 79.5),
          ],
        }),
      );
      expect(summary.weightsImported, 1);
      expect(summary.sleepSessionsImported, 0);
      expect(summary.totalImported, 1);
    });

    test('múltiples samples mismo día → 1 doc, el más reciente', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.weight: [
            _weightSample(at: DateTime(2026, 5, 26, 8), kg: 79.5),
            _weightSample(at: DateTime(2026, 5, 26, 18), kg: 79.2),
          ],
        }),
      );
      expect(summary.weightsImported, 1);
    });

    test('samples de días distintos generan docs separados', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.weight: [
            _weightSample(at: DateTime(2026, 5, 25, 8), kg: 80.0),
            _weightSample(at: DateTime(2026, 5, 26, 8), kg: 79.5),
            _weightSample(at: DateTime(2026, 5, 27, 8), kg: 79.0),
          ],
        }),
      );
      expect(summary.weightsImported, 3);
    });
  });

  group('sueño', () {
    test('una sesión > 30 min se persiste', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.sleepSession: [
            _sleepSample(
              fellAsleep: DateTime(2026, 5, 26, 23),
              wokeUp: DateTime(2026, 5, 27, 7),
              uuid: 'sleep-uuid-1',
            ),
          ],
        }),
      );
      expect(summary.sleepSessionsImported, 1);
      expect(sleepRepo.saved.length, 1);
      expect(sleepRepo.saved.first.id, 'hk_sleep_sleep-uuid-1');
    });

    test('siesta < 30 min se descarta como ruido', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.sleepSession: [
            _sleepSample(
              fellAsleep: DateTime(2026, 5, 26, 14),
              wokeUp: DateTime(2026, 5, 26, 14, 20),
            ),
          ],
        }),
      );
      expect(summary.sleepSessionsImported, 0);
      expect(sleepRepo.saved, isEmpty);
    });

    test('id determinístico cuando hay uuid', () async {
      await service.importResult(
        userId,
        _resultWith({
          HealthMetric.sleepSession: [
            _sleepSample(
              fellAsleep: DateTime(2026, 5, 26, 23),
              wokeUp: DateTime(2026, 5, 27, 7),
              uuid: 'abc-123',
            ),
          ],
        }),
      );
      expect(sleepRepo.saved.first.id, 'hk_sleep_abc-123');
    });

    test('lastMealTime se deriva como fellAsleep - 3h', () async {
      await service.importResult(
        userId,
        _resultWith({
          HealthMetric.sleepSession: [
            _sleepSample(
              fellAsleep: DateTime(2026, 5, 26, 23),
              wokeUp: DateTime(2026, 5, 27, 7),
              uuid: 'x',
            ),
          ],
        }),
      );
      expect(
        sleepRepo.saved.first.lastMealTime,
        DateTime(2026, 5, 26, 20),
      );
    });
  });

  group('pasos', () {
    // SPEC-173 (2026-06-04): umbral bajado de 2000 a 500 pasos. 1500 ahora
    // SÍ genera log; un día por debajo de 500 (oficina pura) no.
    test('día con < 500 pasos NO genera ExerciseLog', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 12), count: 300),
          ],
        }),
      );
      expect(summary.stepsActivitiesImported, 0);
      expect(exerciseRepo.saved, isEmpty);
    });

    test('día con ≥ 2000 pasos genera ExerciseLog tipo LISS', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 12), count: 8000),
          ],
        }),
      );
      expect(summary.stepsActivitiesImported, 1);
      expect(exerciseRepo.saved.length, 1);
      expect(exerciseRepo.saved.first.type, ExerciseType.liss);
      expect(exerciseRepo.saved.first.intensity, ExerciseIntensity.low);
    });

    test('agrega pasos del mismo día antes de validar threshold', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 9), count: 800),
            _stepsSample(at: DateTime(2026, 5, 26, 15), count: 1400),
          ],
        }),
      );
      // 800 + 1400 = 2200 ≥ 2000 threshold → 1 ExerciseLog
      expect(summary.stepsActivitiesImported, 1);
    });

    test('id determinístico por día', () async {
      await service.importResult(
        userId,
        _resultWith({
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 12), count: 8000),
          ],
        }),
      );
      expect(exerciseRepo.saved.first.id, 'hk_steps_2026-05-26');
    });

    test('duración clamp 10-120 min', () async {
      await service.importResult(
        userId,
        _resultWith({
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 12), count: 30000),
          ],
        }),
      );
      // 30000/100 = 300 → clamp a 120
      expect(exerciseRepo.saved.first.durationMinutes, 120);
    });
  });

  group('workouts (SPEC-203)', () {
    test('fuerza → ExerciseLog type strength con minutos reales', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.workout: [
            _workoutSample(
              start: DateTime(2026, 5, 26, 18),
              minutes: 45,
              activityType: 'TRADITIONAL_STRENGTH_TRAINING',
              uuid: 'w1',
            ),
          ],
        }),
      );
      expect(summary.workoutsImported, 1);
      expect(exerciseRepo.saved.single.type, ExerciseType.strength);
      expect(exerciseRepo.saved.single.durationMinutes, 45);
      expect(exerciseRepo.saved.single.id, 'hk_workout_w1');
    });

    test('caminata → liss', () async {
      await service.importResult(
        userId,
        _resultWith({
          HealthMetric.workout: [
            _workoutSample(
              start: DateTime(2026, 5, 26, 7),
              minutes: 30,
              activityType: 'WALKING',
              uuid: 'w2',
            ),
          ],
        }),
      );
      expect(exerciseRepo.saved.single.type, ExerciseType.liss);
    });

    test('un día con workout NO importa los pasos de ese día', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.workout: [
            _workoutSample(
              start: DateTime(2026, 5, 26, 18),
              minutes: 40,
              activityType: 'RUNNING',
              uuid: 'w3',
            ),
          ],
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 12), count: 9000),
          ],
        }),
      );
      expect(summary.workoutsImported, 1);
      expect(summary.stepsActivitiesImported, 0); // pasos desplazados
      expect(exerciseRepo.saved.length, 1);
      expect(exerciseRepo.saved.single.id, 'hk_workout_w3');
    });

    test('día SIN workout → los pasos siguen contando', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.workout: [
            _workoutSample(
              start: DateTime(2026, 5, 25, 18),
              minutes: 40,
              activityType: 'RUNNING',
              uuid: 'w4',
            ),
          ],
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 12), count: 9000),
          ],
        }),
      );
      expect(summary.workoutsImported, 1);
      expect(summary.stepsActivitiesImported, 1); // 26 no tuvo workout
    });

    test('workout < 5 min se descarta como ruido', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.workout: [
            _workoutSample(
              start: DateTime(2026, 5, 26, 18),
              minutes: 3,
              activityType: 'WALKING',
            ),
          ],
        }),
      );
      expect(summary.workoutsImported, 0);
      expect(exerciseRepo.saved, isEmpty);
    });
  });

  group('empty result', () {
    test('result vacío no escribe nada', () async {
      final summary = await service.importResult(
        userId,
        HealthSyncResult.empty(
          DateTime(2026, 5, 20),
          DateTime(2026, 5, 27),
        ),
      );
      expect(summary.totalImported, 0);
      expect(sleepRepo.saved, isEmpty);
      expect(exerciseRepo.saved, isEmpty);
    });
  });

  group('BiometricCheckIn mapeado', () {
    test('notas incluyen sourceName del sample', () async {
      await service.importResult(
        userId,
        _resultWith({
          HealthMetric.weight: [
            _weightSample(at: DateTime(2026, 5, 26, 8), kg: 79.5),
          ],
        }),
      );
      final saved = await biometricRepo.fetchToday(userId);
      // fetchToday usa la fecha del sistema — solo verificamos shape si
      // el sample es de hoy. Como el sample es 2026-05-26, solo
      // chequeamos via fetchLatest:
      final latest = await biometricRepo.fetchLatest(userId);
      expect(latest, isNotNull);
      expect(latest!.notes, contains('Apple Watch'));
      expect(saved?.userId ?? latest.userId, userId);
    });

    test('peso se redondea a 2 decimales', () async {
      await service.importResult(
        userId,
        _resultWith({
          HealthMetric.weight: [
            _weightSample(
              at: DateTime(2026, 5, 26, 8),
              kg: 79.456789,
            ),
          ],
        }),
      );
      final latest = await biometricRepo.fetchLatest(userId);
      expect(latest, isNotNull);
      expect(latest!.weight, closeTo(79.46, 0.001));
    });

    test('BiometricCheckIn.fromJson round-trip funciona', () {
      final c = BiometricCheckIn(
        date: '2026-05-26',
        userId: 'u',
        weight: 79.5,
        notes: 'Importado de Apple Watch',
        createdAt: DateTime(2026, 5, 26, 8),
      );
      final json = c.toJson();
      final back = BiometricCheckIn.fromJson(json);
      expect(back.weight, 79.5);
      expect(back.notes, 'Importado de Apple Watch');
    });
  });
}
