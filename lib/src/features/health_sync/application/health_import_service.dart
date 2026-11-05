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
//
// 2026-11-04 (auditoría Apple Salud):
//   - Peso: ya NO se escribe un check-in por día. Las medidas son una vez
//     por semana (bloqueo semanal); un peso diario de la báscula llenaba
//     el historial, apagaba el recordatorio y — sin `source` — contaba
//     como medición manual. Ahora solo se reporta el último peso leído
//     (`latestWeight`) para prellenar el formulario semanal.
//   - Sueño: la "última comida" sale del inicio real del ayuno (ciclo
//     metabólico) cuando existe; `inicio - 3h` queda solo como respaldo.
//   - Movimiento: con Apple Watch cuentan los minutos de ejercicio (anillo
//     verde); sin Watch, solo los pasos por encima de una base diaria.

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

/// Resumen de cuántos samples se persistieron efectivamente.
class HealthImportSummary {
  final int weightsImported;
  final int sleepSessionsImported;
  final int stepsActivitiesImported;

  /// SPEC-203: entrenamientos reales importados (HKWorkout → ExerciseLog).
  final int workoutsImported;

  /// 2026-11-04: días con minutos de ejercicio del Apple Watch importados.
  final int activeMinutesImported;

  /// 2026-11-04: el peso más reciente leído (no se persiste como check-in).
  final HealthSample? latestWeight;
  final List<String> errors;

  const HealthImportSummary({
    this.weightsImported = 0,
    this.sleepSessionsImported = 0,
    this.stepsActivitiesImported = 0,
    this.workoutsImported = 0,
    this.activeMinutesImported = 0,
    this.latestWeight,
    this.errors = const [],
  });

  int get totalImported =>
      weightsImported +
      sleepSessionsImported +
      stepsActivitiesImported +
      workoutsImported +
      activeMinutesImported;

  bool get isEmpty => totalImported == 0;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() => 'HealthImportSummary(weights=$weightsImported, '
      'sleep=$sleepSessionsImported, '
      'steps=$stepsActivitiesImported, '
      'workouts=$workoutsImported, active=$activeMinutesImported, '
      'latestWeight=${latestWeight?.value}, errors=${errors.length})';
}

/// 2026-11-04 (auditoría Apple Salud): base diaria de pasos que NO cuenta
/// como ejercicio. Antes, 500 pasos ya daban 10 min de "caminata" y 8.000
/// pasos de un día normal sumaban 80 min — casi todos los días aparecían
/// como activos. Ahora solo cuenta lo que supera la base (aprox. lo que
/// alguien sedentario camina sin proponérselo). Valor a validar con los
/// médicos del piloto.
const int kDailyStepsBaseline = 4000;

/// Minutos mínimos para registrar actividad derivada de pasos.
const int _minStepMinutes = 10;

/// Tope de minutos derivados de pasos en un día.
const int _maxStepMinutes = 90;

/// Minutos mínimos de ejercicio (Apple Watch) para registrar el día.
const int _minActiveMinutes = 5;

/// Carga los inicios de ayuno recientes del usuario (= última comida
/// declarada). Inyectable para tests.
typedef FastStartsLoader = Future<List<DateTime>> Function(String userId);

/// Servicio de importación. Stateless — recibe las dependencias por
/// constructor para que el AutoSyncController las inyecte.
class HealthImportService {
  final BiometricRepository _biometricRepo;
  final SleepRepository _sleepRepo;
  final ExerciseRepository _exerciseRepo;

  final FastStartsLoader? _fastStartsLoader;

  /// "Ahora" inyectable (timestamps de actividad de hoy).
  final DateTime Function() _now;

  HealthImportService({
    required BiometricRepository biometricRepository,
    required SleepRepository sleepRepository,
    required ExerciseRepository exerciseRepository,
    FastStartsLoader? fastStartsLoader,
    DateTime Function()? now,
  })  : _biometricRepo = biometricRepository,
        _sleepRepo = sleepRepository,
        _exerciseRepo = exerciseRepository,
        _fastStartsLoader = fastStartsLoader,
        _now = now ?? DateTime.now;

  /// Biometría: hoy solo se usa para compatibilidad (el peso ya no se
  /// escribe). Se conserva para no romper el contrato del constructor.
  BiometricRepository get biometricRepository => _biometricRepo;

  /// Persiste los samples del resultado para el usuario dado.
  /// Devuelve un resumen con conteos y errores.
  Future<HealthImportSummary> importResult(
    String userId,
    HealthSyncResult result,
  ) async {
    if (result.isEmpty) {
      return const HealthImportSummary();
    }

    int sleepSessions = 0;
    int stepsActivities = 0;
    int workouts = 0;
    int activeDays = 0;
    final errors = <String>[];

    // SPEC-203: días con entrenamiento real → los pasos de esos días NO
    // cuentan como ejercicio (evita doble-conteo trote = pasos + workout).
    final workoutSamples = result.samplesFor(HealthMetric.workout);
    final workoutDays = workoutSamples.map((s) => _dateKey(s.start)).toSet();

    // ── Peso: solo el más reciente, sin escribir ────────────────────
    final HealthSample? latestWeight =
        latestWeightOf(result.samplesFor(HealthMetric.weight));

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

    // ── Minutos de ejercicio (Apple Watch) ──────────────────────────
    final activeSamples = result.samplesFor(HealthMetric.activeMinutes);
    final activeByDay = maxPerSourceByDay(activeSamples);
    final daysWithWatchActivity =
        activeByDay.entries.where((e) => e.value > 0).map((e) => e.key).toSet();
    if (activeByDay.isNotEmpty) {
      try {
        activeDays = await _importActiveMinutes(
          userId,
          activeByDay,
          workoutMinutesByDay(dedupWorkoutSamples(workoutSamples)),
        );
      } catch (e, st) {
        AppLogger.error('HealthImport: activeMinutes falló', e, st);
        errors.add('Minutos de ejercicio: $e');
      }
    }

    // ── Pasos → actividad (solo días SIN workout ni datos del Watch) ─
    final stepsSamples = result.samplesFor(HealthMetric.steps);
    if (stepsSamples.isNotEmpty) {
      try {
        stepsActivities = await _importSteps(
          userId,
          stepsSamples,
          skipDays: {...workoutDays, ...daysWithWatchActivity},
        );
      } catch (e, st) {
        AppLogger.error('HealthImport: steps falló', e, st);
        errors.add('Pasos: $e');
      }
    }

    return HealthImportSummary(
      sleepSessionsImported: sleepSessions,
      stepsActivitiesImported: stepsActivities,
      workoutsImported: workouts,
      activeMinutesImported: activeDays,
      latestWeight: latestWeight,
      errors: errors,
    );
  }

  // ─── Peso ────────────────────────────────────────────────────────

  /// El peso más reciente de la ventana (o null).
  static HealthSample? latestWeightOf(List<HealthSample> samples) {
    HealthSample? best;
    for (final s in samples) {
      if (s.value <= 0) continue;
      if (best == null || s.start.isAfter(best.start)) best = s;
    }
    return best;
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

    // Inicios de ayuno reales (= última comida declarada por el usuario).
    List<DateTime> fastStarts = const [];
    if (_fastStartsLoader != null) {
      try {
        fastStarts = await _fastStartsLoader(userId);
      } catch (e) {
        AppLogger.warning('HealthImport[sleep]: no pudo leer ayunos: $e');
      }
    }

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
      final assumedLastMeal = lastMealBefore(s.start, fastStarts) ??
          s.start.subtract(const Duration(hours: 3));

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

  // ─── Pasos → actividad ───────────────────────────────────────────

  /// 2026-11-04: los pasos solo cuentan como actividad por encima de
  /// [kDailyStepsBaseline] (100 pasos ≈ 1 min de caminata, ACSM), y solo
  /// en días sin entrenamiento ni minutos de ejercicio del Watch (esos ya
  /// son la verdad del día). Los docs de días que dejan de calificar se
  /// borran — si no, quedaban los "80 min de caminata" de syncs anteriores.
  Future<int> _importSteps(
    String userId,
    List<HealthSample> samples, {
    Set<String> skipDays = const {},
  }) async {
    final byDay = maxPerSourceByDay(samples);
    AppLogger.info(
      'HealthImport[steps]: ${byDay.entries.map((e) => '${e.key}=${e.value.round()}').join(', ')} '
      '(base $kDailyStepsBaseline)',
    );

    int imported = 0;
    for (final entry in byDay.entries) {
      final dayKey = entry.key;
      final id = 'hk_steps_$dayKey';
      final minutes = stepMinutesFor(entry.value.round());
      if (skipDays.contains(dayKey) || minutes == 0) {
        await _deleteQuietly(userId, id);
        continue;
      }
      try {
        await _exerciseRepo.save(
          userId,
          ExerciseLog(
            id: id,
            userId: userId,
            durationMinutes: minutes,
            activityType: 'Caminata (Apple Salud)',
            timestamp: activityTimestampFor(dayKey, _now()),
            type: ExerciseType.liss,
            intensity: ExerciseIntensity.low,
          ),
        );
        imported++;
      } catch (e, st) {
        AppLogger.warning('ExerciseLog de pasos inválido: $e');
        AppLogger.debug('Day=$dayKey', e, st);
      }
    }
    return imported;
  }

  /// Minutos de actividad que aportan [steps] pasos en un día (0 = nada).
  static int stepMinutesFor(int steps) {
    final extra = steps - kDailyStepsBaseline;
    if (extra <= 0) return 0;
    final minutes = (extra / 100).round();
    if (minutes < _minStepMinutes) return 0;
    return minutes > _maxStepMinutes ? _maxStepMinutes : minutes;
  }

  // ─── Minutos de ejercicio (Apple Watch) ─────────────────────────

  /// Un `ExerciseLog` por día con los minutos de ejercicio del Watch que NO
  /// estén ya cubiertos por un entrenamiento registrado (el anillo verde
  /// incluye los entrenamientos: sin restarlos se contarían dos veces).
  Future<int> _importActiveMinutes(
    String userId,
    Map<String, double> activeByDay,
    Map<String, int> workoutMinutes,
  ) async {
    int imported = 0;
    for (final entry in activeByDay.entries) {
      final dayKey = entry.key;
      final id = 'hk_active_$dayKey';
      final extra = entry.value.round() - (workoutMinutes[dayKey] ?? 0);
      if (extra < _minActiveMinutes) {
        await _deleteQuietly(userId, id);
        continue;
      }
      try {
        await _exerciseRepo.save(
          userId,
          ExerciseLog(
            id: id,
            userId: userId,
            durationMinutes: extra.clamp(_minActiveMinutes, 240),
            activityType: 'Minutos activos (Apple Watch)',
            timestamp: activityTimestampFor(dayKey, _now()),
            type: ExerciseType.liss,
            intensity: ExerciseIntensity.moderate,
            sourceName: 'Apple Watch',
          ),
        );
        imported++;
      } catch (e, st) {
        AppLogger.warning('ExerciseLog de minutos activos inválido: $e');
        AppLogger.debug('Day=$dayKey', e, st);
      }
    }
    AppLogger.info('HealthImport[active]: $imported día(s) importados');
    return imported;
  }

  Future<void> _deleteQuietly(String userId, String id) async {
    try {
      await _exerciseRepo.deleteById(userId, id);
    } catch (e) {
      AppLogger.debug('HealthImport: no pudo borrar $id: $e');
    }
  }

  // ─── Helpers puros (testeables) ─────────────────────────────────

  /// Suma por (día, fuente) y toma el máximo entre fuentes del día:
  /// iPhone y Apple Watch reportan lo mismo con uuids distintos (SPEC-178).
  static Map<String, double> maxPerSourceByDay(List<HealthSample> samples) {
    final byDaySource = <String, Map<String, double>>{};
    for (final s in samples) {
      final day = _dateKey(s.start);
      final src = s.sourceName.isNotEmpty ? s.sourceName : 'unknown';
      final m = byDaySource.putIfAbsent(day, () => <String, double>{});
      m[src] = (m[src] ?? 0) + s.value;
    }
    return {
      for (final e in byDaySource.entries)
        e.key: e.value.values.fold<double>(0, (a, b) => a > b ? a : b),
    };
  }

  /// Minutos de entrenamiento por día (ya deduplicados).
  static Map<String, int> workoutMinutesByDay(List<HealthSample> workouts) {
    final out = <String, int>{};
    for (final w in workouts) {
      final day = _dateKey(w.start);
      out[day] = (out[day] ?? 0) + w.value.round();
    }
    return out;
  }

  /// Hora a la que se atribuye la actividad de un día: el mediodía, que cae
  /// dentro del día metabólico que cubre las horas de vigilia de esa fecha
  /// (antes se usaba la primera muestra, ~00:10, y los pasos caían en el
  /// día metabólico anterior). Si hoy aún no es mediodía, "ahora".
  static DateTime activityTimestampFor(String dayKey, DateTime now) {
    final noon = DateTime.parse('${dayKey}T12:00:00');
    return noon.isAfter(now) ? now : noon;
  }

  /// La última comida antes de dormir: el inicio de ayuno más reciente
  /// entre 14 h antes y el momento de dormirse. Null si no hay.
  static DateTime? lastMealBefore(DateTime fellAsleep, List<DateTime> fastStarts) {
    DateTime? best;
    final earliest = fellAsleep.subtract(const Duration(hours: 14));
    for (final t in fastStarts) {
      if (t.isAfter(fellAsleep) || t.isBefore(earliest)) continue;
      if (best == null || t.isAfter(best)) best = t;
    }
    return best;
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

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
