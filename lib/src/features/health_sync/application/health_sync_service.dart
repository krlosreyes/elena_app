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

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health/health.dart' as hp;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';

/// Mapeo de nuestras métricas neutrales a uno o más tipos del SDK.
///
/// IMPORTANTE: el plugin `health` ^13.3.1 usa tipos distintos según
/// plataforma para sueño:
///   - Android (Health Connect): `SLEEP_SESSION` agrupa toda la noche.
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
        ];
      }
      return [hp.HealthDataType.SLEEP_SESSION];
    case HealthMetric.steps:
      return [hp.HealthDataType.STEPS];
    case HealthMetric.workout:
      // SPEC-203: entrenamientos reales (HKWorkout / ExerciseSessionRecord).
      return [hp.HealthDataType.WORKOUT];
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
  Future<HealthPermissionStatus> checkPermissions() async {
    if (!isPlatformSupported) {
      return const HealthPermissionUnavailable(
        reason: 'Plataforma no soportada',
      );
    }

    try {
      await _ensureConfigured();

      if (!kIsWeb && Platform.isAndroid) {
        final status = await _plugin.getHealthConnectSdkStatus();
        // SPEC-223: misma lógica que requestAuthorization — cualquier
        // estado distinto de sdkAvailable es "no disponible".
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

      final has = await _plugin.hasPermissions(
        types,
        permissions: permissions,
      );

      // hasPermissions() retorna null en iOS por la limitación de HK
      // (no se puede saber el estado real, solo intentar leer).
      //
      // Comportamiento corregido:
      //  - Si null Y el usuario YA solicitó autorización en esta
      //    sesión → asumimos granted (HK no nos lo confirma pero el
      //    usuario vio el sheet y aceptó).
      //  - Si null Y el usuario NUNCA solicitó autorización → forzamos
      //    Denied. Esto hace que la UI muestre el botón "Conectar" y
      //    dispare el sheet nativo cuando el usuario lo toca.
      if (has == null) {
        return _iosAuthRequestedThisSession
            ? const HealthPermissionGranted()
            : const HealthPermissionDenied();
      }
      return has
          ? const HealthPermissionGranted()
          : const HealthPermissionDenied();
    } catch (e, st) {
      AppLogger.error(
        'HealthSyncService.checkPermissions falló',
        e,
        st,
      );
      return HealthPermissionUnavailable(reason: e.toString());
    }
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
    final allPoints = <hp.HealthDataPoint>[];
    for (final type in types) {
      try {
        final points = await _plugin.getHealthDataFromTypes(
          types: [type],
          startTime: start,
          endTime: end,
        );
        AppLogger.info(
          'HealthSync: ${metric.label}/${type.name} → ${points.length} samples',
        );
        allPoints.addAll(points);
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
    if (metric == HealthMetric.sleepSession && samples.length > 1) {
      final consolidated = _consolidateSleepByNight(samples);
      consolidated.sort((a, b) => a.start.compareTo(b.start));
      return consolidated;
    }

    // Orden cronológico: más viejo primero. Los notifiers procesan
    // en ese orden para que el más reciente quede como "actual".
    samples.sort((a, b) => a.start.compareTo(b.start));
    return samples;
  }

  /// Agrupa samples de sueño en "noches" — muestras separadas por
  /// gaps de menos de 2h se consideran parte de la misma sesión.
  /// Por cada grupo emitimos 1 HealthSample con start = mínimo y
  /// end = máximo del grupo. El valor (minutos) se recalcula del
  /// rango total.
  List<HealthSample> _consolidateSleepByNight(List<HealthSample> raw) {
    if (raw.isEmpty) return raw;
    final sorted = [...raw]..sort((a, b) => a.start.compareTo(b.start));

    const maxGap = Duration(hours: 2);
    final groups = <List<HealthSample>>[];
    var current = <HealthSample>[sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final prev = current.last;
      final curr = sorted[i];
      // Si la próxima muestra arranca dentro de 2h del fin de la
      // anterior, sigue siendo la misma sesión.
      if (curr.start.difference(prev.end) <= maxGap) {
        current.add(curr);
      } else {
        groups.add(current);
        current = [curr];
      }
    }
    groups.add(current);

    return groups.map((group) {
      final earliest = group.map((s) => s.start).reduce(
            (a, b) => a.isBefore(b) ? a : b,
          );
      final latest = group.map((s) => s.end).reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );
      return HealthSample(
        metric: HealthMetric.sleepSession,
        value: latest.difference(earliest).inMinutes.toDouble(),
        start: earliest,
        end: latest,
        sourceName: group.first.sourceName,
        // El uuid del primer sample del grupo sirve como id estable —
        // mientras el grupo no cambie de composición, este id no cambia.
        uuid: group.first.uuid,
      );
    }).toList();
  }

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
      final v = p.value;
      if (v is hp.WorkoutHealthValue) {
        activity = v.workoutActivityType.name;
      }
      return HealthSample(
        metric: metric,
        value: minutes,
        start: p.dateFrom,
        end: p.dateTo,
        sourceName: p.sourceName,
        uuid: p.uuid,
        workoutActivityType: activity,
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
    }

    return HealthSample(
      metric: metric,
      value: numeric,
      start: p.dateFrom,
      end: p.dateTo,
      sourceName: p.sourceName,
      uuid: p.uuid,
    );
  }
}
