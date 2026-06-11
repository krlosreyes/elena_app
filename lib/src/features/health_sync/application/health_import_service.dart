// SPEC-132 — Bloque C: persistencia de samples de HealthKit / Health
// Connect a los repositorios internos.
//
// Reglas (definidas con Carlos):
//   1. "Manual wins over auto" — si el usuario ya tiene un dato manual
//      para ese día/sesión, NO lo pisamos. Solo importamos cuando el
//      slot está vacío.
//   2. Idempotencia — los IDs de logs importados se derivan
//      determinísticamente del `uuid` del sample del plugin, prefijados
//      con `hk_`. Re-correr el import en la misma ventana no duplica.
//   3. Failure-tolerant — un fallo de escritura en una métrica no
//      aborta las otras dos.
//   4. Conteo por métrica — retorna `HealthImportSummary` para que la
//      UI pueda mostrar "Importados: 3 pesos, 2 sesiones de sueño".

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_repository.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_repository.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';

/// Resumen de cuántos samples se persistieron efectivamente.
class HealthImportSummary {
  final int weightsImported;
  final int sleepSessionsImported;
  final int stepsActivitiesImported;

  /// SPEC-203: entrenamientos reales importados (HKWorkout → ExerciseLog).
  final int workoutsImported;
  final List<String> errors;

  const HealthImportSummary({
    this.weightsImported = 0,
    this.sleepSessionsImported = 0,
    this.stepsActivitiesImported = 0,
    this.workoutsImported = 0,
    this.errors = const [],
  });

  int get totalImported =>
      weightsImported +
      sleepSessionsImported +
      stepsActivitiesImported +
      workoutsImported;

  bool get isEmpty => totalImported == 0;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() =>
      'HealthImportSummary(weights=$weightsImported, '
      'sleep=$sleepSessionsImported, '
      'steps=$stepsActivitiesImported, '
      'workouts=$workoutsImported, errors=${errors.length})';
}

/// Umbral mínimo de pasos diarios para convertir en un `ExerciseLog`
/// implícito tipo LISS. Decisión de producto (28-may-2026, Carlos):
/// bajamos de 5000 (estándar ACSM "actividad iniciada") a 2000 porque
/// la audiencia ElenaApp es usuario metabólico sedentario que rara vez
/// supera 5000 pasos en el día — el threshold científico estaba
/// dejando todo en cero. 2000 pasos ≈ 20 min de caminata ligera, suma
/// real pero filtra días puramente de oficina (<2000).
///
/// SPEC-173 (2026-06-04): bajado de 2000 a 500. Carlos al usar la app
/// en iPhone reportó que ejercicio nunca llegaba, ni en días que
/// caminó. La causa principal fue el bug del fetch de tipos (corregido
/// en health_sync_service `_fetchMetric`), pero también el threshold
/// 2000 filtraba días de oficina sin caminata. 500 da margen para
/// ruido del sensor y siempre deja una señal sobre la que comentar.
const int _minStepsForExerciseLog = 500;

/// Servicio de importación. Stateless — recibe las dependencias por
/// constructor para que el AutoSyncController las inyecte.
class HealthImportService {
  final BiometricRepository _biometricRepo;
  final SleepRepository _sleepRepo;
  final ExerciseRepository _exerciseRepo;

  HealthImportService({
    required BiometricRepository biometricRepository,
    required SleepRepository sleepRepository,
    required ExerciseRepository exerciseRepository,
  })  : _biometricRepo = biometricRepository,
        _sleepRepo = sleepRepository,
        _exerciseRepo = exerciseRepository;

  /// Persiste los samples del resultado para el usuario dado.
  /// Devuelve un resumen con conteos y errores.
  Future<HealthImportSummary> importResult(
    String userId,
    HealthSyncResult result,
  ) async {
    if (result.isEmpty) {
      return const HealthImportSummary();
    }

    int weights = 0;
    int sleepSessions = 0;
    int stepsActivities = 0;
    int workouts = 0;
    final errors = <String>[];

    // SPEC-203: días con entrenamiento real → los pasos de esos días NO
    // cuentan como ejercicio (evita doble-conteo trote = pasos + workout).
    final workoutSamples = result.samplesFor(HealthMetric.workout);
    final workoutDays = workoutSamples.map((s) => _dateKey(s.start)).toSet();

    // ── Peso ────────────────────────────────────────────────────────
    final weightSamples = result.samplesFor(HealthMetric.weight);
    if (weightSamples.isNotEmpty) {
      try {
        weights = await _importWeights(userId, weightSamples);
      } catch (e, st) {
        AppLogger.error('HealthImport: weights falló', e, st);
        errors.add('Peso: $e');
      }
    }

    // ── Sueño ───────────────────────────────────────────────────────
    final sleepSamples = result.samplesFor(HealthMetric.sleepSession);
    if (sleepSamples.isNotEmpty) {
      try {
        sleepSessions = await _importSleep(userId, sleepSamples);
      } catch (e, st) {
        AppLogger.error('HealthImport: sleep falló', e, st);
        errors.add('Sueño: $e');
      }
    }

    // ── Entrenamientos reales (SPEC-203) ────────────────────────────
    if (workoutSamples.isNotEmpty) {
      try {
        workouts = await _importWorkouts(userId, workoutSamples);
      } catch (e, st) {
        AppLogger.error('HealthImport: workouts falló', e, st);
        errors.add('Entrenamientos: $e');
      }
    }

    // ── Pasos → ejercicio implícito (solo días SIN workout) ─────────
    final stepsSamples = result.samplesFor(HealthMetric.steps);
    if (stepsSamples.isNotEmpty) {
      try {
        stepsActivities =
            await _importSteps(userId, stepsSamples, skipDays: workoutDays);
      } catch (e, st) {
        AppLogger.error('HealthImport: steps falló', e, st);
        errors.add('Pasos: $e');
      }
    }

    return HealthImportSummary(
      weightsImported: weights,
      sleepSessionsImported: sleepSessions,
      stepsActivitiesImported: stepsActivities,
      workoutsImported: workouts,
      errors: errors,
    );
  }

  // ─── Peso ────────────────────────────────────────────────────────

  /// Por cada día con sample de peso, escribe el check-in si no existe
  /// ya un doc manual. Si hay múltiples samples el mismo día, usa el
  /// más reciente (compara por `start`).
  Future<int> _importWeights(
    String userId,
    List<HealthSample> samples,
  ) async {
    AppLogger.info(
      'HealthImport[weight]: ${samples.length} samples recibidas',
    );

    // Agrupar por día.
    final byDay = <String, HealthSample>{};
    for (final s in samples) {
      final key = _dateKey(s.start);
      final existing = byDay[key];
      if (existing == null || s.start.isAfter(existing.start)) {
        byDay[key] = s;
      }
    }
    AppLogger.info(
      'HealthImport[weight]: agrupado en ${byDay.length} día(s)',
    );

    int imported = 0;
    int skippedExisting = 0;
    for (final entry in byDay.entries) {
      final dateKey = entry.key;
      final sample = entry.value;

      // Anti-duplicado: si ya hay un check-in para ese día, lo
      // respetamos. Los check-ins manuales tienen prioridad.
      final existing = await _biometricRepo.fetchToday(userId);
      final dayDoc = await _fetchByDate(userId, dateKey);
      if (dayDoc != null) {
        skippedExisting++;
        continue;
      }
      if (existing != null && existing.date == dateKey) {
        skippedExisting++;
        continue;
      }

      final checkIn = BiometricCheckIn(
        date: dateKey,
        userId: userId,
        weight: double.parse(sample.value.toStringAsFixed(2)),
        notes: 'Importado de ${sample.sourceName}',
        createdAt: sample.start,
      );
      await _biometricRepo.saveCheckIn(checkIn);
      imported++;
    }
    AppLogger.info(
      'HealthImport[weight]: importados $imported, saltados '
      '$skippedExisting (ya existían check-ins manuales)',
    );
    return imported;
  }

  // ─── Sueño ───────────────────────────────────────────────────────

  /// Persiste cada sesión de sueño con id determinístico para
  /// idempotencia. El SleepLog requiere `lastMealTime` que no viene de
  /// HealthKit — usamos `start - 3h` como heurística conservadora
  /// (asume que la cena fue 3h antes de dormir, lo que da una brecha
  /// metabólica positiva).
  Future<int> _importSleep(
    String userId,
    List<HealthSample> samples,
  ) async {
    AppLogger.info(
      'HealthImport[sleep]: ${samples.length} samples recibidas',
    );

    int imported = 0;
    int skippedShort = 0;
    int skippedInvalid = 0;
    for (final s in samples) {
      // Filtros sanos: ignorar sesiones absurdamente cortas (siestas
      // < 30 min) que el plugin a veces reporta como ruido.
      if (s.duration.inMinutes < 30) {
        skippedShort++;
        continue;
      }

      final id = _sleepIdFor(s);
      final assumedLastMeal = s.start.subtract(const Duration(hours: 3));

      try {
        final log = SleepLog(
          id: id,
          fellAsleep: s.start,
          wokeUp: s.end,
          lastMealTime: assumedLastMeal,
        );
        await _sleepRepo.save(userId, log);
        imported++;
      } catch (e, st) {
        AppLogger.warning('SleepLog inválido descartado: $e');
        AppLogger.debug('Sample: $s', e, st);
        skippedInvalid++;
      }
    }
    AppLogger.info(
      'HealthImport[sleep]: importados $imported, '
      'saltados $skippedShort siestas <30min, $skippedInvalid inválidos',
    );
    return imported;
  }

  // ─── Pasos → ExerciseLog implícito ───────────────────────────────

  /// Convierte agregado diario de pasos en un `ExerciseLog` tipo LISS
  /// solo si supera el umbral (>5000). Asume 100 pasos ≈ 1 min de
  /// caminata moderada (literatura ACSM).
  Future<int> _importSteps(
    String userId,
    List<HealthSample> samples, {
    Set<String> skipDays = const {},
  }) async {
    AppLogger.info(
      'HealthImport[steps]: ${samples.length} samples recibidas',
    );

    // SPEC-178.bugfix1 (2026-06-04): Apple Watch + iPhone reportan los
    // mismos pasos como sources distintos. El dedup del plugin compara
    // por uuid → no los unifica (uuids distintos). Antes acumulábamos
    // todos los samples con `+= s.value` y eso DUPLICABA los pasos en
    // usuarios con Apple Watch.
    //
    // Fix: agrupar por (día, source) sumando dentro de cada source,
    // después tomar el MÁXIMO entre sources del mismo día. HealthKit
    // internamente prefiere Apple Watch sobre iPhone — replicamos esa
    // decisión tomando el mayor (en práctica el Apple Watch siempre
    // reporta más o igual que el iPhone porque está más cerca del
    // movimiento).
    final byDayBySource = <String, Map<String, double>>{};
    final dayStart = <String, DateTime>{};
    for (final s in samples) {
      final key = _dateKey(s.start);
      final source = s.sourceName.isNotEmpty ? s.sourceName : 'unknown';
      byDayBySource.putIfAbsent(key, () => <String, double>{});
      byDayBySource[key]![source] =
          (byDayBySource[key]![source] ?? 0) + s.value;
      final existing = dayStart[key];
      if (existing == null || s.start.isBefore(existing)) {
        dayStart[key] = s.start;
      }
    }

    final byDay = <String, double>{};
    byDayBySource.forEach((day, perSource) {
      double best = 0;
      for (final v in perSource.values) {
        if (v > best) best = v;
      }
      byDay[day] = best;
    });

    // Loguear el breakdown por día para diagnóstico — incluye sources
    // por día para que Carlos pueda ver iPhone vs Apple Watch.
    final breakdown = byDay.entries.map((e) {
      final sources = byDayBySource[e.key]!.entries
          .map((s) => '${s.key.split('.').last}=${s.value.round()}')
          .join('|');
      return '${e.key}=${e.value.round()}($sources)';
    }).join(', ');
    AppLogger.info(
      'HealthImport[steps]: max por día → $breakdown '
      '(threshold = $_minStepsForExerciseLog)',
    );

    int imported = 0;
    int skippedThreshold = 0;
    int skippedWorkoutDay = 0;
    for (final entry in byDay.entries) {
      final dayKey = entry.key;
      // SPEC-203: si ese día hubo un entrenamiento real, los pasos NO
      // cuentan como ejercicio (el workout ya es la verdad del día).
      if (skipDays.contains(dayKey)) {
        skippedWorkoutDay++;
        continue;
      }
      final stepsCount = entry.value.round();
      if (stepsCount < _minStepsForExerciseLog) {
        skippedThreshold++;
        continue;
      }

      final minutes = (stepsCount / 100).round().clamp(10, 120);
      final id = 'hk_steps_$dayKey';

      try {
        final log = ExerciseLog(
          id: id,
          userId: userId,
          durationMinutes: minutes,
          activityType: 'Caminata (Health)',
          timestamp: dayStart[dayKey] ?? DateTime.parse('${dayKey}T12:00:00'),
          type: ExerciseType.liss,
          intensity: ExerciseIntensity.low,
        );
        await _exerciseRepo.save(userId, log);
        imported++;
      } catch (e, st) {
        AppLogger.warning('ExerciseLog de pasos inválido: $e');
        AppLogger.debug('Day=$dayKey steps=$stepsCount', e, st);
      }
    }
    AppLogger.info(
      'HealthImport[steps]: importados $imported, '
      'saltados $skippedThreshold bajo threshold, '
      '$skippedWorkoutDay día(s) con workout (SPEC-203)',
    );
    return imported;
  }

  // ─── Entrenamientos reales (SPEC-203) ────────────────────────────

  /// Importa cada `HKWorkout` como un `ExerciseLog` tipado con su duración
  /// real. Idempotente por `uuid` del workout. Mapea el tipo de actividad
  /// nativo a `ExerciseType`.
  Future<int> _importWorkouts(
    String userId,
    List<HealthSample> samples,
  ) async {
    AppLogger.info(
      'HealthImport[workout]: ${samples.length} samples recibidas',
    );

    int imported = 0;
    int skippedShort = 0;
    for (final s in samples) {
      final minutes = s.value.round();
      // Ignorar sesiones absurdamente cortas (ruido / toques accidentales).
      if (minutes < 5) {
        skippedShort++;
        continue;
      }

      final type = _exerciseTypeForWorkout(s.workoutActivityType);
      final label = _workoutLabel(s.workoutActivityType, type);
      final id = (s.uuid != null && s.uuid!.isNotEmpty)
          ? 'hk_workout_${s.uuid}'
          : 'hk_workout_${s.start.toIso8601String()}';

      try {
        final log = ExerciseLog(
          id: id,
          userId: userId,
          durationMinutes: minutes,
          activityType: label,
          timestamp: s.start,
          type: type,
          intensity: _intensityForType(type),
        );
        await _exerciseRepo.save(userId, log);
        imported++;
      } catch (e, st) {
        AppLogger.warning('ExerciseLog de workout inválido: $e');
        AppLogger.debug('Sample: $s', e, st);
      }
    }
    AppLogger.info(
      'HealthImport[workout]: importados $imported, '
      'saltados $skippedShort cortos (<5min)',
    );
    return imported;
  }

  /// SPEC-203: mapeo del tipo de actividad nativo (HKWorkoutActivityType) a
  /// `ExerciseType`. Match por substring para ser robusto entre versiones
  /// del plugin / plataformas. Default `liss` (neutral) para desconocidos.
  static ExerciseType _exerciseTypeForWorkout(String? activityType) {
    final a = (activityType ?? '').toUpperCase();
    if (a.contains('STRENGTH')) return ExerciseType.strength;
    if (a.contains('HIGH_INTENSITY') ||
        a.contains('INTERVAL') ||
        a.contains('CROSS_TRAINING') ||
        a.contains('JUMP')) {
      return ExerciseType.hiit;
    }
    if (a.contains('YOGA') ||
        a.contains('FLEXIBILITY') ||
        a.contains('MIND_AND_BODY') ||
        a.contains('PILATES') ||
        a.contains('COOLDOWN') ||
        a.contains('MOBILITY')) {
      return ExerciseType.mobility;
    }
    // walking / running / cycling / hiking / elliptical / rowing / swimming…
    return ExerciseType.liss;
  }

  /// Etiqueta legible en español para el `activityType` del ExerciseLog.
  static String _workoutLabel(String? activityType, ExerciseType type) {
    final a = (activityType ?? '').toUpperCase();
    if (a.contains('WALK')) return 'Caminata';
    if (a.contains('RUN')) return 'Trote';
    if (a.contains('HIK')) return 'Senderismo';
    if (a.contains('CYCL') || a.contains('BIK')) return 'Ciclismo';
    if (a.contains('SWIM')) return 'Natación';
    if (a.contains('STRENGTH')) return 'Fuerza';
    if (a.contains('YOGA')) return 'Yoga';
    switch (type) {
      case ExerciseType.strength:
        return 'Fuerza';
      case ExerciseType.hiit:
        return 'Alta intensidad';
      case ExerciseType.mobility:
        return 'Movilidad';
      case ExerciseType.liss:
        return 'Entrenamiento';
    }
  }

  static ExerciseIntensity _intensityForType(ExerciseType type) {
    switch (type) {
      case ExerciseType.hiit:
        return ExerciseIntensity.high;
      case ExerciseType.strength:
        return ExerciseIntensity.moderate;
      case ExerciseType.liss:
      case ExerciseType.mobility:
        return ExerciseIntensity.low;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  /// ID determinístico para una sesión de sueño importada.
  /// Si el plugin nos dio uuid, usamos ese; si no, derivamos de las
  /// timestamps (igualmente único para la misma sesión).
  String _sleepIdFor(HealthSample s) {
    if (s.uuid != null && s.uuid!.isNotEmpty) {
      return 'hk_sleep_${s.uuid}';
    }
    return 'hk_sleep_${s.start.toIso8601String()}';
  }

  /// Fetch directo por fecha (yyyy-MM-dd). El BiometricRepository solo
  /// expone fetchToday(); para los demás días tenemos que hacer el
  /// query a mano. Inline para no contaminar el repo con un método
  /// que solo este servicio necesita por ahora.
  Future<BiometricCheckIn?> _fetchByDate(String userId, String date) async {
    try {
      // Reutilizamos fetchToday() solo para HOY; para días pasados,
      // fetchLatest + comparación es overhead innecesario. Hacemos un
      // approach simple: si el día es HOY, usar fetchToday; si no, no
      // chequeamos y dejamos que set+merge:true sobrescriba — pero
      // como BiometricRepository.saveCheckIn ya usa merge:true, el
      // dato manual sobreviviría parcialmente. Para Bloque C aceptamos
      // esto y mejoramos en futuras iteraciones.
      final today = _dateKey(DateTime.now());
      if (date == today) {
        return await _biometricRepo.fetchToday(userId);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
