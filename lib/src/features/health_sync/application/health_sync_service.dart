// SPEC-132: wrapper sobre el plugin `health` (carp.dk, v13.3.1) que
// unifica HealthKit (iOS) y Health Connect (Android) detrás de una
// API neutra. Toda la lógica que el resto de la app necesita pasa
// por esta clase — nadie más debe importar el SDK del plugin.
//
// Diseño:
// - Stateful: instancia única vía `Health()` del plugin, configurada
//   en el constructor.
// - Read-only: solo solicita permisos de READ para evitar conflicto
//   con la propiedad del dato del usuario en HK/HC.
// - Per-metric error isolation: si una métrica falla (timeout, datos
//   corruptos), las otras dos siguen adelante y se reportan en
//   `HealthSyncResult.errors`.
// - Plataforma-aware: en Web/Desktop retorna `HealthPermissionUnavailable`
//   sin crashear; en Android distingue Health Connect no instalado.

import 'dart:async' show TimeoutException;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health/health.dart' as hp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';

/// Mapeo de nuestras métricas neutrales a uno o más tipos del SDK.
///
/// IMPORTANTE: el plugin `health` ^13.3.1 usa tipos distintos según
/// plataforma para sueño:
///   - Android (Health Connect): Samsung Galaxy Watch escribe etapas
///     detalladas (`SleepSessionRecord.Stage`) además de la sesión
///     principal. El plugin las expone como tipos independientes
///     (SLEEP_ASLEEP, DEEP, LIGHT, REM). Todos mapean al mismo permiso
///     READ_SLEEP en HC, por lo que no generan prompts extra.
///     `_consolidateSleepByNight` une solapamientos en 1 sesión/noche.
///   - iOS (HealthKit): `SLEEP_SESSION` NO existe. El Apple Watch
///     escribe sueño en MÚLTIPLES categorías:
///       - SLEEP_IN_BED = tiempo en cama (incluye despertarse a mitad)
///       - SLEEP_ASLEEP = tiempo dormido (sin etapas)
///       - SLEEP_DEEP / LIGHT / REM = etapas específicas cuando hay Watch
///     SPEC-173.bugfix1 (2026-06-04): SLEEP_IN_BED EXCLUIDO porque
///     producía sleep reportado ~7h cuando el ASLEEP real era ~5h
///     (Carlos validó en iPhone). La consolidación por noche usa
///     `min(start) → max(end)` y el IN_BED dominaba siempre los
///     bordes. Pedimos solo las 4 categorías de sueño "activo":
///     ASLEEP (genérico) + DEEP + LIGHT + REM. Si solo hay ASLEEP
///     (iPhone sin Watch) seguimos cubiertos.
List<hp.HealthDataType> _typesFor(HealthMetric metric) {
  switch (metric) {
    case HealthMetric.weight:
      return [hp.HealthDataType.WEIGHT];
    case HealthMetric.sleepSession:
      if (!kIsWeb && Platform.isIOS) {
        return [
          hp.HealthDataType.SLEEP_ASLEEP,
          hp.HealthDataType.SLEEP_DEEP,
          hp.HealthDataType.SLEEP_LIGHT,
          hp.HealthDataType.SLEEP_REM,
          // SPEC-301: despierto DENTRO de la ventana (fragmentación). Comparte
          // el permiso READ_SLEEP, así que no agrega prompts.
          hp.HealthDataType.SLEEP_AWAKE,
        ];
      }
      // Android / Health Connect: SLEEP_SESSION cubre la sesión consolidada.
      // Samsung Galaxy Watch 7 también escribe etapas separadas —
      // pedimos las 4 etapas de sueño "activo" para capturarlas.
      // _fetchMetric usa try/catch independiente por tipo y
      // _consolidateSleepByNight unifica los solapamientos en 1 noche.
      return [
        hp.HealthDataType.SLEEP_SESSION,
        hp.HealthDataType.SLEEP_ASLEEP,
        hp.HealthDataType.SLEEP_DEEP,
        hp.HealthDataType.SLEEP_LIGHT,
        hp.HealthDataType.SLEEP_REM,
        // SPEC-301: despierto dentro de la ventana (fragmentación).
        hp.HealthDataType.SLEEP_AWAKE,
      ];
    case HealthMetric.steps:
      return [hp.HealthDataType.STEPS];
    case HealthMetric.workout:
      // SPEC-203: entrenamientos reales (HKWorkout / ExerciseSessionRecord).
      return [hp.HealthDataType.WORKOUT];
    case HealthMetric.activeMinutes:
      // 2026-11-04: minutos de ejercicio del Apple Watch. Solo HealthKit.
      if (!kIsWeb && Platform.isIOS) return [hp.HealthDataType.EXERCISE_TIME];
      return const [];
  }
}

/// Tipo principal de cada métrica para el check de permisos individual en
/// Android. Evita verificar la lista completa (que incluye etapas de sueño
/// secundarias) en una sola llamada — todas las etapas de sueño mapean al
/// mismo permiso READ_SLEEP que `SLEEP_SESSION`, por lo que verificar una
/// es suficiente.
hp.HealthDataType _primaryTypeFor(HealthMetric metric) {
  switch (metric) {
    case HealthMetric.weight:
      return hp.HealthDataType.WEIGHT;
    case HealthMetric.sleepSession:
      return hp.HealthDataType.SLEEP_SESSION;
    case HealthMetric.steps:
      return hp.HealthDataType.STEPS;
    case HealthMetric.workout:
      return hp.HealthDataType.WORKOUT;
    case HealthMetric.activeMinutes:
      return hp.HealthDataType.EXERCISE_TIME;
  }
}

/// Key de SharedPreferences para el flag de autorización iOS HealthKit.
/// Persiste entre sesiones para que el auto-sync funcione en cold open.
const String _kIosHealthAuthGrantedKey = 'health.iosAuthGranted';

/// Servicio de sincronización con HealthKit (iOS) / Health Connect (Android).
class HealthSyncService {
  /// Instancia del plugin. Inyectable para tests.
  final hp.Health _plugin;

  /// SharedPreferences para persistir el flag de autorización iOS entre
  /// sesiones. Null en tests o cuando no está disponible.
  final SharedPreferences? _prefs;

  /// Conjunto de métricas que la app puede sincronizar. Constante.
  static const Set<HealthMetric> supportedMetrics = {
    HealthMetric.weight,
    HealthMetric.sleepSession,
    HealthMetric.steps,
    // SPEC-203: entrenamientos reales (workouts).
    HealthMetric.workout,
    // 2026-11-04: minutos de ejercicio (solo iOS; en Android no pide nada).
    HealthMetric.activeMinutes,
  };

  bool _configured = false;

  /// SPEC-132 fix iOS: HealthKit nunca confirma el estado real de
  /// permisos vía `hasPermissions()` — siempre retorna null. Antes
  /// asumíamos "null = granted optimistically", pero eso causaba que
  /// el auto-sync intentara leer SIN haber disparado nunca el sheet
  /// nativo (porque el botón "Conectar" no aparecía). Resultado:
  /// errores "Authorization not determined" en loop.
  ///
  /// Fix: trackeamos si el usuario ya autorizó HealthKit, tanto en
  /// memoria (esta sesión) como en SharedPreferences (entre sesiones).
  /// BUG-FIX (2026-06-13): el flag en memoria se reseteaba en cada
  /// cold open → checkPermissions() retornaba Denied → auto-sync
  /// abortaba → Apple Watch nunca sincronizaba automáticamente.
  /// Ahora también leemos/escribimos en SharedPreferences.
  bool _iosAuthRequestedThisSession = false;

  HealthSyncService({hp.Health? plugin, SharedPreferences? prefs})
      : _plugin = plugin ?? hp.Health(),
        _prefs = prefs {
    // Hidratar el flag desde prefs al construir el servicio.
    if (prefs != null && (prefs.getBool(_kIosHealthAuthGrantedKey) ?? false)) {
      _iosAuthRequestedThisSession = true;
    }
  }

  /// `true` si la plataforma soporta el plugin (iOS o Android).
  /// Web/Desktop nunca van a poder leer datos nativos de salud.
  bool get isPlatformSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (_) {
      // Platform no disponible en tests sin TestWidgetsFlutterBinding.
      return false;
    }
  }

  /// Inicializa el plugin. Es idempotente — `configure()` del plugin
  /// puede llamarse varias veces sin efectos secundarios.
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _plugin.configure();
    _configured = true;
  }

  // ─── Permisos ──────────────────────────────────────────────────────────

  /// Solicita autorización para las métricas soportadas. En iOS abre el
  /// sheet de HealthKit; en Android lanza la UI de Health Connect.
  ///
  /// IMPORTANTE: en iOS el sistema NUNCA devuelve "denied" — solo
  /// "granted" o "not determined" (privacidad). Por eso después de
  /// solicitar autorización hay que intentar leer datos para verificar
  /// si efectivamente hay acceso. Manejamos eso en `sync()`.
  Future<HealthPermissionStatus> requestAuthorization() async {
    if (!isPlatformSupported) {
      return const HealthPermissionUnavailable(
        reason: 'Plataforma no soportada (Web/Desktop)',
      );
    }

    try {
      await _ensureConfigured();

      // En Android, chequear que Health Connect esté instalado.
      if (!kIsWeb && Platform.isAndroid) {
        final status = await _plugin.getHealthConnectSdkStatus();
        // SPEC-223: sdkUnavailable = Android < 9 / sin Google Play.
        // sdkNotInstalled = Android 9-13 sin la app HC instalada.
        // Ambos casos deben mostrar el CTA de instalación.
        if (status != hp.HealthConnectSdkStatus.sdkAvailable) {
          return const HealthConnectNotInstalled();
        }
      }

      // _typesFor puede retornar múltiples tipos por métrica
      // (en iOS, sleep son 5 categorías distintas).
      final types = supportedMetrics.expand(_typesFor).toList();
      final permissions = List<hp.HealthDataAccess>.filled(
        types.length,
        hp.HealthDataAccess.READ,
      );

      final granted = await _plugin.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (granted) {
        _iosAuthRequestedThisSession = true;
        // BUG-FIX (2026-06-13): persistir en prefs para que cold opens
        // posteriores arranquen con el flag ya hidratado y el auto-sync
        // no aborte por falso "Denied".
        await _prefs?.setBool(_kIosHealthAuthGrantedKey, true);
        return const HealthPermissionGranted();
      } else {
        return const HealthPermissionDenied();
      }
    } catch (e, st) {
      AppLogger.error(
        'HealthSyncService.requestAuthorization falló',
        e,
        st,
      );
      return HealthPermissionUnavailable(reason: e.toString());
    }
  }

  /// Consulta el estado actual de permisos sin solicitar nada.
  /// Útil al abrir la app para decidir si mostrar el badge de
  /// "Sincronizando..." o el CTA "Conectar Apple Health".
  ///
  /// SPEC-237 (Android fix): en Android verificamos per-métrica.
  /// `hasPermissions(todosLosTipos)` es atómico — si WORKOUT está denegado
  /// retornaba `false` aunque sleep/steps estuvieran concedidos, abortando
  /// el sync completo. Ahora retorna `HealthPermissionPartial` cuando
  /// algunas métricas tienen permiso, y el sync omite las denegadas.
  Future<HealthPermissionStatus> checkPermissions() async {
    if (!isPlatformSupported) {
      return const HealthPermissionUnavailable(
        reason: 'Plataforma no soportada',
      );
    }

    try {
      await _ensureConfigured();

      if (!kIsWeb && Platform.isAndroid) {
        final sdkStatus = await _plugin.getHealthConnectSdkStatus();
        if (sdkStatus != hp.HealthConnectSdkStatus.sdkAvailable) {
          return const HealthConnectNotInstalled();
        }
        // Verificación per-métrica para Android/Health Connect.
        return await _checkPermissionsAndroid();
      }

      // iOS: hasPermissions() siempre retorna null (limitación de HK).
      // Usamos el flag de sesión/prefs como proxy del estado real.
      final types = supportedMetrics.expand(_typesFor).toList();
      final permissions = List<hp.HealthDataAccess>.filled(
        types.length,
        hp.HealthDataAccess.READ,
      );
      final has = await _plugin.hasPermissions(types, permissions: permissions);

      if (has == null) {
        return _iosAuthRequestedThisSession
            ? const HealthPermissionGranted()
            : const HealthPermissionDenied();
      }
      return has
          ? const HealthPermissionGranted()
          : const HealthPermissionDenied();
    } catch (e, st) {
      AppLogger.error('HealthSyncService.checkPermissions falló', e, st);
      return HealthPermissionUnavailable(reason: e.toString());
    }
  }

  /// SPEC-237: verifica permisos individualmente en Android.
  ///
  /// Usa el tipo principal de cada métrica (`_primaryTypeFor`) — en sueño,
  /// todas las etapas comparten el mismo permiso READ_SLEEP que SLEEP_SESSION,
  /// así que verificar una es suficiente para determinar el acceso.
  ///
  /// Retorna:
  ///   - `HealthPermissionGranted` si todas las métricas tienen permiso.
  ///   - `HealthPermissionPartial` si algunas sí y otras no.
  ///   - `HealthPermissionDenied` si ninguna tiene permiso.
  Future<HealthPermissionStatus> _checkPermissionsAndroid() async {
    final granted = <HealthMetric>[];
    final denied = <HealthMetric>[];

    for (final metric in supportedMetrics) {
      // Métricas sin tipo en Health Connect (minutos de ejercicio) no
      // cuentan: si no, Android siempre quedaría como "parcial".
      if (_typesFor(metric).isEmpty) continue;
      try {
        final has = await _plugin.hasPermissions(
          [_primaryTypeFor(metric)],
          permissions: [hp.HealthDataAccess.READ],
        );
        if (has == true) {
          granted.add(metric);
          AppLogger.debug('HealthSync HC: ${metric.label} → permiso OK');
        } else {
          denied.add(metric);
          AppLogger.debug(
              'HealthSync HC: ${metric.label} → sin permiso (has=$has)');
        }
      } catch (e) {
        denied.add(metric);
        AppLogger.debug('HealthSync HC: ${metric.label} → check falló: $e');
      }
    }

    if (granted.isEmpty) return const HealthPermissionDenied();
    if (denied.isEmpty) return const HealthPermissionGranted();
    return HealthPermissionPartial(granted: granted, denied: denied);
  }

  /// En Android: abre Google Play en la página de Health Connect para
  /// que el usuario lo instale. No-op en iOS / Web.
  Future<void> openHealthConnectInstall() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _ensureConfigured();
      await _plugin.installHealthConnect();
    } catch (e, st) {
      AppLogger.error(
        'HealthSyncService.openHealthConnectInstall falló',
        e,
        st,
      );
    }
  }

  /// SPEC-238: abre la pantalla de ajustes de Health Connect via intent.
  /// Úsalo como fallback cuando no se puede lanzar Samsung Health
  /// directamente. No-op en iOS / Web.
  Future<void> openHealthConnectSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      const hcPackage = 'com.google.android.apps.healthdata';
      final intent = AndroidIntent(
        action: 'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS',
        package: hcPackage,
        flags: <int>[0x10000000], // FLAG_ACTIVITY_NEW_TASK
      );
      await intent.launch();
    } catch (e, st) {
      AppLogger.error(
        'HealthSyncService.openHealthConnectSettings falló',
        e,
        st,
      );
    }
  }

  // ─── Sync ──────────────────────────────────────────────────────────────

  /// Sincroniza las 3 métricas soportadas en la ventana indicada.
  /// `window` por defecto: últimos 7 días. La ventana corta protege
  /// contra payloads gigantes (un usuario con 5 años de Apple Watch
  /// puede tener decenas de miles de samples de peso).
  ///
  /// El método NO falla globalmente: cada métrica se procesa en su
  /// propio try/catch y los errores se reportan en
  /// `HealthSyncResult.errors`.
  Future<HealthSyncResult> sync({
    Duration window = const Duration(days: 7),
    DateTime? now,
  }) async {
    final end = now ?? DateTime.now();
    final start = end.subtract(window);

    if (!isPlatformSupported) {
      return HealthSyncResult.empty(start, end);
    }

    try {
      await _ensureConfigured();
    } catch (e, st) {
      AppLogger.error(
        'HealthSyncService.sync: configure falló',
        e,
        st,
      );
      return HealthSyncResult(
        windowStart: start,
        windowEnd: end,
        samplesByMetric: const {},
        errors: {for (final m in supportedMetrics) m: e.toString()},
        completedAt: DateTime.now(),
      );
    }

    final results = <HealthMetric, List<HealthSample>>{};
    final errors = <HealthMetric, String>{};

    for (final metric in supportedMetrics) {
      try {
        final samples = await _fetchMetric(metric, start, end);
        results[metric] = samples;
      } catch (e, st) {
        AppLogger.error(
          'HealthSyncService.sync: ${metric.label} falló',
          e,
          st,
        );
        errors[metric] = e.toString();
      }
    }

    return HealthSyncResult(
      windowStart: start,
      windowEnd: end,
      samplesByMetric: results,
      errors: errors,
      completedAt: DateTime.now(),
    );
  }

  /// Lee una métrica del plugin y la traduce a `HealthSample`.
  ///
  /// SPEC-173 (2026-06-04): cada tipo se pide en SU PROPIA call con
  /// try/catch propio. Antes pedíamos los 5 tipos de sleep iOS en una
  /// sola call → si UNO solo fallaba autorización (DEEP/REM frecuentes
  /// en iPhones sin Apple Watch), la call entera tiraba y todo sleep
  /// caía a cero. Ahora un tipo denegado solo pierde ese tipo.
  /// Loguea cuántos samples entraron por tipo para diagnóstico.
  Future<List<HealthSample>> _fetchMetric(
    HealthMetric metric,
    DateTime start,
    DateTime end,
  ) async {
    final types = _typesFor(metric);
    // Timeout por tipo: si HealthKit/HC no responde en 30s, no bloqueamos
    // el sync completo ni dejamos isRunning=true para siempre.
    // WORKOUT en iOS requiere HKObjectType.workoutType() y puede colgar
    // si el permiso nunca fue concedido interactivamente.
    const kFetchTimeout = Duration(seconds: 30);

    final allPoints = <hp.HealthDataPoint>[];
    for (final type in types) {
      try {
        final points = await _plugin.getHealthDataFromTypes(
          types: [type],
          startTime: start,
          endTime: end,
        ).timeout(kFetchTimeout);
        AppLogger.info(
          'HealthSync: ${metric.label}/${type.name} → ${points.length} samples',
        );
        allPoints.addAll(points);
      } on TimeoutException {
        AppLogger.warning(
          'HealthSync: ${metric.label}/${type.name} timeout (>30s) — se omite',
        );
      } catch (e) {
        AppLogger.warning(
          'HealthSync: ${metric.label}/${type.name} falló: $e',
        );
      }
    }

    // El plugin puede devolver duplicados si distintos dispositivos
    // (iPhone + Apple Watch) reportan lo mismo. Deduplica por (start,
    // value, source).
    final deduped = _plugin.removeDuplicates(allPoints);

    final samples = <HealthSample>[];
    for (final p in deduped) {
      final sample = _toSample(metric, p);
      if (sample != null) samples.add(sample);
    }

    // SPEC-132 fix iOS sueño: el Apple Watch escribe MUCHAS muestras
    // por noche (una por cada etapa: IN_BED, ASLEEP, DEEP, LIGHT, REM,
    // a veces 20+ por sesión). Las consolidamos en 1 sample por noche
    // antes de devolverlas — el SleepLog ya espera 1 sesión por noche.
    if (metric == HealthMetric.sleepSession && samples.isNotEmpty) {
      final consolidated = _consolidateSleepByNight(samples);
      consolidated.sort((a, b) => a.start.compareTo(b.start));
      return consolidated;
    }

    // Orden cronológico: más viejo primero. Los notifiers procesan
    // en ese orden para que el más reciente quede como "actual".
    samples.sort((a, b) => a.start.compareTo(b.start));
    return samples;
  }

  /// Consolida las muestras de sueño en una sesión por noche. Ver
  /// [consolidateSleepByNight].
  List<HealthSample> _consolidateSleepByNight(List<HealthSample> raw) =>
      consolidateSleepByNight(raw);

  /// Traduce un `HealthDataPoint` del plugin a `HealthSample` neutral.
  /// Retorna null si el dato es inválido (valor no numérico, etc.).
  HealthSample? _toSample(HealthMetric metric, hp.HealthDataPoint p) {
    // SPEC-203: workout — el value es WorkoutHealthValue (no numérico). El
    // "valor" del sample son los MINUTOS reales (dateTo - dateFrom) y el
    // tipo de actividad nativo se conserva para mapear a ExerciseType.
    if (metric == HealthMetric.workout) {
      final minutes = p.dateTo.difference(p.dateFrom).inMinutes.toDouble();
      if (minutes <= 0) return null;
      String? activity;
      double? kcal;
      double? distanceM;
      final v = p.value;
      if (v is hp.WorkoutHealthValue) {
        activity = v.workoutActivityType.name;
        // SPEC-296: el plugin expone energía y distancia del workout.
        kcal = v.totalEnergyBurned?.toDouble();
        distanceM = v.totalDistance?.toDouble();
      }
      return HealthSample(
        metric: metric,
        value: minutes,
        start: p.dateFrom,
        end: p.dateTo,
        sourceName: p.sourceName,
        uuid: p.uuid,
        workoutActivityType: activity,
        caloriesKcal: kcal,
        distanceMeters: distanceM,
      );
    }

    final value = p.value;
    double numeric;

    if (value is hp.NumericHealthValue) {
      numeric = value.numericValue.toDouble();
    } else {
      // SLEEP_SESSION en algunas versiones retorna WorkoutHealthValue
      // o similar. Fallback: derivar minutos del rango temporal.
      if (metric == HealthMetric.sleepSession) {
        numeric = p.dateTo.difference(p.dateFrom).inMinutes.toDouble();
      } else {
        return null;
      }
    }

    // Normalización por métrica.
    switch (metric) {
      case HealthMetric.weight:
        // Plugin devuelve en kg en ambas plataformas — no se necesita
        // conversión.
        break;
      case HealthMetric.sleepSession:
        // Si la unidad reportada no es minutos, derivar del rango.
        if (p.unit != hp.HealthDataUnit.MINUTE) {
          numeric = p.dateTo.difference(p.dateFrom).inMinutes.toDouble();
        }
        break;
      case HealthMetric.steps:
        // count — sin conversión.
        break;
      case HealthMetric.workout:
        // Inalcanzable: workout retorna temprano arriba.
        break;
      case HealthMetric.activeMinutes:
        // HealthKit reporta minutos; si viniera otra unidad, usar el rango.
        if (p.unit != hp.HealthDataUnit.MINUTE) {
          numeric = p.dateTo.difference(p.dateFrom).inMinutes.toDouble();
        }
        break;
    }

    return HealthSample(
      metric: metric,
      value: numeric,
      start: p.dateFrom,
      end: p.dateTo,
      sourceName: p.sourceName,
      uuid: p.uuid,
      // SPEC-301: etapa de esta muestra de sueño (deep/light/rem/awake/asleep).
      sleepStage:
          metric == HealthMetric.sleepSession ? _sleepStageOf(p.type) : null,
    );
  }

  /// SPEC-301: mapea el tipo nativo de una muestra de sueño a nuestra etapa
  /// neutral. Los genéricos (ASLEEP/SESSION/IN_BED) no son una etapa: cuentan
  /// para la duración total pero no para el desglose.
  String _sleepStageOf(hp.HealthDataType type) {
    switch (type) {
      case hp.HealthDataType.SLEEP_DEEP:
        return 'deep';
      case hp.HealthDataType.SLEEP_REM:
        return 'rem';
      case hp.HealthDataType.SLEEP_LIGHT:
        return 'light';
      case hp.HealthDataType.SLEEP_AWAKE:
        return 'awake';
      default:
        return 'asleep';
    }
  }
}

/// Consolida muestras de sueño en una sesión por noche.
///
/// 2026-11-04 (auditoría Apple Salud). Antes la noche iba de la primera a
/// la última muestra de CUALQUIER tipo — incluidas las de "despierto"
/// (SPEC-301), que el reloj escribe al despertarte y al final de la noche.
/// Eso estiraba los bordes y repetía el bug de SPEC-173 (7 h reportadas
/// con 5 h reales). Ahora:
///   - Los bordes de la noche salen SOLO de muestras dormidas (asleep /
///     core / deep / REM). Despierto antes de dormirte o después de
///     levantarte no cuenta.
///   - Las muestras dormidas se agrupan si las separa ≤ 2 h.
///   - El despierto DENTRO de la noche se suma a `awake` (fragmentación);
///     `SleepLog.duration` lo descuenta del tiempo dormido.
///   - Cada etapa se mide como unión de intervalos: iPhone + Watch
///     reportando lo mismo no se cuenta dos veces.
List<HealthSample> consolidateSleepByNight(List<HealthSample> raw) {
  if (raw.isEmpty) return raw;
  final asleep = raw.where((s) => s.sleepStage != 'awake').toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final awake = raw.where((s) => s.sleepStage == 'awake').toList();
  if (asleep.isEmpty) return const [];

  const maxGap = Duration(hours: 2);
  final groups = <List<HealthSample>>[];
  var current = <HealthSample>[asleep.first];
  var currentEnd = asleep.first.end;
  for (var i = 1; i < asleep.length; i++) {
    final s = asleep[i];
    if (s.start.difference(currentEnd) <= maxGap) {
      current.add(s);
      if (s.end.isAfter(currentEnd)) currentEnd = s.end;
    } else {
      groups.add(current);
      current = [s];
      currentEnd = s.end;
    }
  }
  groups.add(current);

  return groups.map((group) {
    final start = group.first.start;
    final end = group.map((s) => s.end).reduce((a, b) => a.isAfter(b) ? a : b);

    final byStage = <String, List<(DateTime, DateTime)>>{};
    for (final s in group) {
      final st = s.sleepStage;
      if (st == null || st == 'asleep') continue;
      byStage.putIfAbsent(st, () => []).add((s.start, s.end));
    }
    final awakeInside = <(DateTime, DateTime)>[];
    for (final a in awake) {
      final from = a.start.isBefore(start) ? start : a.start;
      final to = a.end.isAfter(end) ? end : a.end;
      if (to.isAfter(from)) awakeInside.add((from, to));
    }
    final stageMinutes = <String, int>{
      for (final e in byStage.entries) e.key: unionMinutes(e.value),
    };
    final awakeMins = unionMinutes(awakeInside);
    if (awakeMins > 0) stageMinutes['awake'] = awakeMins;
    stageMinutes.removeWhere((_, v) => v <= 0);

    final spanMins = end.difference(start).inMinutes;
    final asleepMins =
        (awakeMins < spanMins ? spanMins - awakeMins : spanMins).toDouble();

    return HealthSample(
      metric: HealthMetric.sleepSession,
      value: asleepMins,
      start: start,
      end: end,
      sourceName: group.first.sourceName,
      // Id estable: la primera muestra dormida de la noche.
      uuid: group.first.uuid,
      sleepStages: stageMinutes.isEmpty ? null : stageMinutes,
    );
  }).toList();
}

/// Minutos cubiertos por la unión de [intervals] (sin contar solapes).
int unionMinutes(List<(DateTime, DateTime)> intervals) {
  if (intervals.isEmpty) return 0;
  final sorted = [...intervals]..sort((a, b) => a.$1.compareTo(b.$1));
  var total = 0;
  var curStart = sorted.first.$1;
  var curEnd = sorted.first.$2;
  for (final (s, e) in sorted.skip(1)) {
    if (!s.isAfter(curEnd)) {
      if (e.isAfter(curEnd)) curEnd = e;
    } else {
      total += curEnd.difference(curStart).inMinutes;
      curStart = s;
      curEnd = e;
    }
  }
  total += curEnd.difference(curStart).inMinutes;
  return total;
}
