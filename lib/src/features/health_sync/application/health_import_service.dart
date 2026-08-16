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
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_source.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_stages.dart';
import 'package:elena_app/src/features/health_sync/application/samsung_health_service.dart'
    as samsung_health;
import 'package:elena_app/src/features/sleep/domain/sleep_repository.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_repository.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';
// ARCH-05 (auditoría 2026-07-11): este servicio solo necesita el tipo
// (contrato), no el provider Firestore, así que apunta a domain/ en vez de
// data/ — inversión de dependencia entre features (health_sync → progress).
import 'package:elena_app/src/features/progress/domain/biometric_repository.dart';
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
  String toString() => 'HealthImportSummary(weights=$weightsImported, '
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

      // Anti-duplicado: si ya hay un check-in para ese día (manual o
      // importado previamente), lo respetamos. Cubre HOY y días históricos.
      final dayDoc = await _fetchByDate(userId, dateKey);
      if (dayDoc != null) {
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
    int skippedManualExists = 0;
    for (final s in samples) {
      AppLogger.debug(
        'HealthImport[sleep]: start=${s.start}, end=${s.end}, '
        'duration=${s.duration.inMinutes}min, source=${s.sourceName}',
      );
      // SPEC-245 (2026-07-07): umbral bajado de 30 min a 5 min.
      //
      // Problema original: Apple Watch registra el sueño como etapas
      // individuales (Core, Deep, REM, Awake), cada una de 15-25 min.
      // El filtro de 30 min descartaba TODAS las etapas nocturnas del Watch,
      // resultando en 0 sesiones importadas aunque el usuario durmiera 7h.
      //
      // Con 5 min: filtramos solo ruido genuino (toques accidentales,
      // calibraciones del sensor) preservando todas las etapas reales
      // del sueño nocturno. Las etapas individuales se guardan como
      // SleepLogs separados — el más largo (o el más reciente) es el
      // que aparece en el anillo via watchLatest(orderBy: wokeUp desc).
      if (s.duration.inMinutes < 5) {
        skippedShort++;
        AppLogger.debug(
          'HealthImport[sleep]: skip <5min (${s.duration.inMinutes}min)',
        );
        continue;
      }

      // 17-jul: "regla 1" (manual gana sobre auto) — documentada arriba
      // en el header del archivo pero solo se aplicaba a peso
      // (`_fetchByDate`). Sueño escribía SIN ese chequeo, y como el
      // Dashboard elige qué mostrar por `wokeUp` más reciente sin
      // importar el origen (`watchLatest`), un sync automático que
      // corriera DESPUÉS de que el usuario registrara su sueño a mano
      // (o confirmara "ya desperté") podía desplazar silenciosamente
      // ese registro si el sample del wearable tenía un `wokeUp` más
      // tardío (típico: una etapa "despierto" espuria del reloj). Bug
      // reportado por Carlos como "el pilar de sueño no se actualiza".
      //
      // Fix: antes de escribir, chequeamos si ya existe el doc MANUAL
      // de esa noche (mismo id determinístico que usa
      // `SleepNotifier._attributionDocId`: `sleep_<attributionDayKey>`).
      // Si existe, el sample automático se descarta — el usuario ya
      // registró esa noche explícitamente y esa entrada no se pisa.
      final manualDocId = _manualSleepIdFor(s.start, s.end);
      final existingManual = await _sleepRepo.getById(userId, manualDocId);
      if (existingManual != null) {
        skippedManualExists++;
        AppLogger.debug(
          'HealthImport[sleep]: skip — ya existe registro manual '
          '$manualDocId, no se pisa',
        );
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
          // SPEC-301: etapas medidas por el dispositivo (si las hay).
          stages: SleepStages.fromHealthMap(s.sleepStages),
          // SPEC-302: procedencia = dispositivo (Apple Health / Health Connect).
          source: SleepSource.device,
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
      'saltados $skippedShort <5min, $skippedManualExists ya manual, '
      '$skippedInvalid inválidos',
    );
    return imported;
  }

  /// Id determinístico del registro MANUAL de la noche a la que
  /// pertenece `[fellAsleep, wokeUp]` — mismo esquema que
  /// `SleepNotifier._attributionDocId` (día de atribución = punto medio
  /// del intervalo). Usado para el guard "manual gana sobre auto": si
  /// ya existe un doc con este id, el sample automático no se importa.
  String _manualSleepIdFor(DateTime fellAsleep, DateTime wokeUp) =>
      'sleep_${DayBoundaryResolver.attributionDayKey(
        start: fellAsleep,
        end: wokeUp,
      )}';

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
      final sources = byDayBySource[e.key]!
          .entries
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
      // BUG-FIX: antes solo saltábamos la escritura, pero si un sync
      // anterior ya había guardado `hk_steps_{dayKey}` (antes de que
      // el workout fuera detectado), ese doc seguía en Firestore y se
      // sumaba a los minutos del ciclo junto al workout → doble-conteo.
      // Ahora también borramos el doc de pasos si existe.
      if (skipDays.contains(dayKey)) {
        skippedWorkoutDay++;
        try {
          await _exerciseRepo.deleteById(userId, 'hk_steps_$dayKey');
        } catch (e) {
          AppLogger.warning(
            'HealthImport[steps]: no pudo borrar hk_steps_$dayKey: $e',
          );
        }
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

    // SPEC-296: una misma sesión registrada por VARIAS fuentes (Apple Watch +
    // app de gym + iPhone) llega como workouts separados con uuids distintos —
    // `removeDuplicates` no los colapsa porque la fuente difiere. Deduplicamos
    // por solapamiento de tiempo + tipo, conservando el más completo (mayor
    // duración). Esto elimina las sesiones duplicadas en el pilar.
    final deduped = dedupWorkoutSamples(samples);
    if (deduped.length != samples.length) {
      AppLogger.info(
        'HealthImport[workout]: dedup ${samples.length} → ${deduped.length} '
        '(sesiones de múltiples fuentes colapsadas)',
      );
    }

    int imported = 0;
    int skippedShort = 0;
    for (final s in deduped) {
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
          // SPEC-296: datos reales de la actividad para mostrarlos en el pilar.
          caloriesKcal: s.caloriesKcal,
          distanceKm:
              s.distanceMeters == null ? null : s.distanceMeters! / 1000.0,
          sourceName: s.sourceName,
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

  /// SPEC-296: colapsa workouts que representan la MISMA sesión vista por
  /// varias fuentes (se solapan en el tiempo y son del mismo tipo). Conserva
  /// el más completo (mayor duración). Sesiones distintas o de tipo distinto
  /// que no se solapan se conservan todas.
  static List<HealthSample> dedupWorkoutSamples(List<HealthSample> samples) {
    if (samples.length <= 1) return samples;
    final sorted = [...samples]..sort((a, b) => a.start.compareTo(b.start));
    final kept = <HealthSample>[];
    for (final s in sorted) {
      final idx = kept.indexWhere((k) =>
          k.workoutActivityType == s.workoutActivityType &&
          s.start.isBefore(k.end) &&
          s.end.isAfter(k.start));
      if (idx == -1) {
        kept.add(s);
      } else if (s.value > kept[idx].value) {
        kept[idx] = s; // el más largo = el más completo
      }
    }
    return kept;
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

  // ─── Samsung Health directo (SPEC-239) ──────────────────────────

  /// Importa sesiones de sueño leídas directamente desde Samsung Health SDK,
  /// cuando Health Connect devolvió 0. Reutiliza la lógica de `_importSleep`
  /// pero recibe `SamsungSleepSession` en lugar de `HealthSample`.
  Future<int> importSamsungSleep(
    String userId,
    List<samsung_health.SamsungSleepSession> sessions,
  ) async {
    AppLogger.info(
      'HealthImport[samsung_sleep]: ${sessions.length} sesiones recibidas',
    );
    int imported = 0;
    int skippedShort = 0;
    int skippedManualExists = 0;
    for (final s in sessions) {
      if (s.durationMinutes < 30) {
        skippedShort++;
        continue;
      }

      // 17-jul: mismo guard "manual gana sobre auto" que `_importSleep`
      // — ver comentario ahí. Samsung Health es un segundo camino de
      // ingesta (SPEC-239, fallback cuando Health Connect no trae
      // sueño) y necesita la misma protección.
      final manualDocId = _manualSleepIdFor(s.start, s.end);
      final existingManual = await _sleepRepo.getById(userId, manualDocId);
      if (existingManual != null) {
        skippedManualExists++;
        AppLogger.debug(
          'HealthImport[samsung_sleep]: skip — ya existe registro '
          'manual $manualDocId, no se pisa',
        );
        continue;
      }

      final id = 'sh_sleep_${s.start.toIso8601String()}';
      final assumedLastMeal = s.start.subtract(const Duration(hours: 3));
      try {
        final log = SleepLog(
          id: id,
          fellAsleep: s.start,
          wokeUp: s.end,
          lastMealTime: assumedLastMeal,
          // SPEC-302: Samsung Health también es un dispositivo.
          source: SleepSource.device,
        );
        await _sleepRepo.save(userId, log);
        imported++;
      } catch (e, st) {
        AppLogger.warning('SamsungSleepLog inválido: $e');
        AppLogger.debug('Session: $s', e, st);
      }
    }
    AppLogger.info(
      'HealthImport[samsung_sleep]: importados $imported, '
      'saltados $skippedShort <30min, $skippedManualExists ya manual',
    );
    return imported;
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

  /// Fetch directo por fecha (yyyy-MM-dd).
  /// Usa `fetchByDate` del repositorio para cubrir tanto HOY como días
  /// históricos, respetando datos manuales en cualquier fecha.
  /// (Hallazgo-3 auditoría 2026-07-04: antes solo chequeaba HOY.)
  Future<BiometricCheckIn?> _fetchByDate(String userId, String date) async {
    try {
      return await _biometricRepo.fetchByDate(userId, date);
    } catch (_) {
      return null;
    }
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
