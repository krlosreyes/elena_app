// Tests del HealthImportService — SPEC-132 Bloque C.
//
// Cubren las reglas de negocio críticas:
//   1. Dedup por día (peso): múltiples samples del mismo día → 1 doc.
//   2. Idempotencia (sueño): mismo uuid → mismo id de log.
//   3. Threshold (pasos): <5000/día NO genera ExerciseLog.
//   4. Failure isolation: si una métrica falla, las otras siguen.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_repository.dart';
import 'package:elena_app/src/features/health_sync/application/samsung_health_service.dart'
    as samsung_health;
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

  /// 17-jul: nuevo método del contrato (guard "manual gana sobre
  /// auto"). Simula el `.set()` idempotente de Firestore por id —
  /// busca el guardado más reciente con ese id dentro de `saved`.
  @override
  Future<SleepLog?> getById(String userId, String docId) async {
    for (final log in saved.reversed) {
      if (log.id == docId) return log;
    }
    return null;
  }
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

  @override
  Future<void> deleteById(String userId, String logId) async {
    saved.removeWhere((log) => log.id == logId);
  }
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

  group('peso (2026-11-04: ya no se escribe check-in diario)', () {
    test('no persiste check-ins y reporta el peso más reciente', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.weight: [
            _weightSample(at: DateTime(2026, 5, 24, 8), kg: 80),
            _weightSample(at: DateTime(2026, 5, 26, 8), kg: 79.5),
            _weightSample(at: DateTime(2026, 5, 25, 8), kg: 79.8),
          ],
        }),
      );
      expect(summary.weightsImported, 0);
      expect(summary.latestWeight?.value, 79.5);
      expect(await biometricRepo.fetchLatest(userId), isNull);
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

    test('sesión < 5 min se descarta como ruido (SPEC-245)', () async {
      // SPEC-245 (2026-07-07): umbral bajado de 30 min a 5 min. Apple
      // Watch registra el sueño como etapas individuales (Core/Deep/REM/
      // Awake) de 15-25 min cada una — el filtro viejo de 30 min las
      // descartaba TODAS, resultando en 0 sesiones importadas aunque el
      // usuario durmiera 7h. Este test comprobaba el umbral viejo con
      // una siesta de 20 min; con el umbral actual de 5 min esa siesta
      // ya no es ruido, así que la muestra se acorta a 3 min.
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.sleepSession: [
            _sleepSample(
              fellAsleep: DateTime(2026, 5, 26, 14),
              wokeUp: DateTime(2026, 5, 26, 14, 3),
            ),
          ],
        }),
      );
      expect(summary.sleepSessionsImported, 0);
      expect(sleepRepo.saved, isEmpty);
    });

    test(
        'siesta de 20 min SÍ se importa (por encima del umbral de 5 min, SPEC-245)',
        () async {
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
      expect(summary.sleepSessionsImported, 1);
      expect(sleepRepo.saved, isNotEmpty);
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

    test('lastMealTime = inicio real del ayuno cuando existe', () async {
      final withCycles = HealthImportService(
        biometricRepository: biometricRepo,
        sleepRepository: sleepRepo,
        exerciseRepository: exerciseRepo,
        fastStartsLoader: (_) async => [
          DateTime(2026, 5, 25, 19, 30), // ayuno de la noche anterior
          DateTime(2026, 5, 26, 19, 45), // ayuno de esta noche
        ],
      );
      await withCycles.importResult(
        userId,
        _resultWith({
          HealthMetric.sleepSession: [
            _sleepSample(
              fellAsleep: DateTime(2026, 5, 26, 23),
              wokeUp: DateTime(2026, 5, 27, 7),
              uuid: 'y',
            ),
          ],
        }),
      );
      expect(sleepRepo.saved.first.lastMealTime, DateTime(2026, 5, 26, 19, 45));
    });

    // 17-jul: "manual gana sobre auto" (Carlos reportó "sueño sigue sin
    // actualizar" — un sync automático posterior desplazaba en el
    // Dashboard lo que el usuario acababa de registrar a mano, porque
    // watchLatest elige por `wokeUp` más reciente sin importar origen).
    test(
        'sample de wearable se descarta si ya existe registro manual de esa noche',
        () async {
      final fellAsleep = DateTime(2026, 5, 26, 23);
      final wokeUp = DateTime(2026, 5, 27, 7);
      final manualDocId = 'sleep_${DayBoundaryResolver.attributionDayKey(
        start: fellAsleep,
        end: wokeUp,
      )}';
      // Simula que el usuario ya confirmó su sueño a mano ANTES de que
      // corra el auto-sync.
      sleepRepo.saved.add(SleepLog(
        id: manualDocId,
        fellAsleep: fellAsleep,
        wokeUp: wokeUp,
        lastMealTime: fellAsleep.subtract(const Duration(hours: 4)),
      ));

      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.sleepSession: [
            // Mismo intervalo de noche, pero un `wokeUp` más tardío —
            // el escenario real que desplazaba el dato manual antes
            // del fix (watchLatest hubiera elegido este por ser más
            // reciente).
            _sleepSample(
              fellAsleep: fellAsleep,
              wokeUp: wokeUp.add(const Duration(minutes: 45)),
              uuid: 'watch-etapa-espuria',
            ),
          ],
        }),
      );

      expect(summary.sleepSessionsImported, 0);
      expect(sleepRepo.saved.length, 1);
      expect(sleepRepo.saved.single.id, manualDocId);
    });

    test(
        'sin registro manual, el sample de wearable sí se importa (comportamiento normal)',
        () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.sleepSession: [
            _sleepSample(
              fellAsleep: DateTime(2026, 5, 26, 23),
              wokeUp: DateTime(2026, 5, 27, 7),
              uuid: 'watch-normal',
            ),
          ],
        }),
      );
      expect(summary.sleepSessionsImported, 1);
      expect(sleepRepo.saved, isNotEmpty);
    });

    test(
        'Samsung Health: sesión se descarta si ya existe registro manual de esa noche',
        () async {
      final start = DateTime(2026, 5, 26, 23);
      final end = DateTime(2026, 5, 27, 7);
      final manualDocId = 'sleep_${DayBoundaryResolver.attributionDayKey(
        start: start,
        end: end,
      )}';
      sleepRepo.saved.add(SleepLog(
        id: manualDocId,
        fellAsleep: start,
        wokeUp: end,
        lastMealTime: start.subtract(const Duration(hours: 4)),
      ));

      final imported = await service.importSamsungSleep(userId, [
        samsung_health.SamsungSleepSession(
          start: start,
          end: end.add(const Duration(minutes: 30)),
          durationMinutes:
              end.add(const Duration(minutes: 30)).difference(start).inMinutes,
        ),
      ]);

      expect(imported, 0);
      expect(sleepRepo.saved.length, 1);
      expect(sleepRepo.saved.single.id, manualDocId);
    });
  });

  group('pasos (2026-11-04: solo lo que supera la base diaria)', () {
    test('un día por debajo de la base no genera actividad', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 12), count: 3500),
          ],
        }),
      );
      expect(summary.stepsActivitiesImported, 0);
      expect(exerciseRepo.saved, isEmpty);
    });

    test('8.000 pasos → 40 min de caminata (lo que supera 4.000)', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 9), count: 3000),
            _stepsSample(at: DateTime(2026, 5, 26, 15), count: 5000),
          ],
        }),
      );
      expect(summary.stepsActivitiesImported, 1);
      final log = exerciseRepo.saved.single;
      expect(log.durationMinutes, 40);
      expect(log.type, ExerciseType.liss);
      expect(log.intensity, ExerciseIntensity.low);
      expect(log.id, 'hk_steps_2026-05-26');
      // Atribuido al mediodía: cae en el día metabólico de esa fecha.
      expect(log.timestamp, DateTime(2026, 5, 26, 12));
    });

    test('tope de 90 min', () {
      expect(HealthImportService.stepMinutesFor(30000), 90);
      expect(HealthImportService.stepMinutesFor(4500), 0); // < 10 min
      expect(HealthImportService.stepMinutesFor(5000), 10);
    });

    test('iPhone + Watch el mismo día no se suman (máximo por fuente)', () {
      final byDay = HealthImportService.maxPerSourceByDay([
        _stepsSample(at: DateTime(2026, 5, 26, 9), count: 6000),
        HealthSample(
          metric: HealthMetric.steps,
          value: 7000,
          start: DateTime(2026, 5, 26, 10),
          end: DateTime(2026, 5, 26, 10),
          sourceName: 'Apple Watch',
        ),
      ]);
      expect(byDay['2026-05-26'], 7000);
    });
  });

  group('minutos de ejercicio (Apple Watch)', () {
    HealthSample active(DateTime at, double minutes) => HealthSample(
          metric: HealthMetric.activeMinutes,
          value: minutes,
          start: at,
          end: at.add(const Duration(minutes: 1)),
          sourceName: 'Apple Watch',
        );

    test('se importan y desplazan a los pasos de ese día', () async {
      final summary = await service.importResult(
        userId,
        _resultWith({
          HealthMetric.activeMinutes: [
            active(DateTime(2026, 5, 26, 8), 15),
            active(DateTime(2026, 5, 26, 18), 20),
          ],
          HealthMetric.steps: [
            _stepsSample(at: DateTime(2026, 5, 26, 12), count: 9000),
          ],
        }),
      );
      expect(summary.activeMinutesImported, 1);
      expect(summary.stepsActivitiesImported, 0);
      final log = exerciseRepo.saved.single;
      expect(log.id, 'hk_active_2026-05-26');
      expect(log.durationMinutes, 35);
      expect(log.intensity, ExerciseIntensity.moderate);
    });

    test('se descuentan los minutos ya cubiertos por un entrenamiento',
        () async {
      await service.importResult(
        userId,
        _resultWith({
          HealthMetric.workout: [
            _workoutSample(
              start: DateTime(2026, 5, 26, 18),
              minutes: 30,
              activityType: 'RUNNING',
              uuid: 'run1',
            ),
          ],
          HealthMetric.activeMinutes: [
            active(DateTime(2026, 5, 26, 18), 32),
          ],
        }),
      );
      // 32 - 30 = 2 < 5 → solo queda el entrenamiento.
      expect(exerciseRepo.saved.map((e) => e.id), ['hk_workout_run1']);
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
}
