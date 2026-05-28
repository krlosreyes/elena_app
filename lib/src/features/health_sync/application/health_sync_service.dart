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

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';

/// Mapeo de nuestras métricas neutrales al enum del SDK.
const Map<HealthMetric, hp.HealthDataType> _typeMap = {
  HealthMetric.weight: hp.HealthDataType.WEIGHT,
  HealthMetric.sleepSession: hp.HealthDataType.SLEEP_SESSION,
  HealthMetric.steps: hp.HealthDataType.STEPS,
};

/// Servicio de sincronización con HealthKit (iOS) / Health Connect (Android).
class HealthSyncService {
  /// Instancia del plugin. Inyectable para tests.
  final hp.Health _plugin;

  /// Conjunto de métricas que la app puede sincronizar. Constante.
  static const Set<HealthMetric> supportedMetrics = {
    HealthMetric.weight,
    HealthMetric.sleepSession,
    HealthMetric.steps,
  };

  bool _configured = false;

  HealthSyncService({hp.Health? plugin}) : _plugin = plugin ?? hp.Health();

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
        if (status == hp.HealthConnectSdkStatus.sdkUnavailable) {
          return const HealthConnectNotInstalled();
        }
      }

      final types = supportedMetrics.map((m) => _typeMap[m]!).toList();
      final permissions = List<hp.HealthDataAccess>.filled(
        types.length,
        hp.HealthDataAccess.READ,
      );

      final granted = await _plugin.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (granted) {
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
        if (status == hp.HealthConnectSdkStatus.sdkUnavailable) {
          return const HealthConnectNotInstalled();
        }
      }

      final types = supportedMetrics.map((m) => _typeMap[m]!).toList();
      final permissions = List<hp.HealthDataAccess>.filled(
        types.length,
        hp.HealthDataAccess.READ,
      );

      final has = await _plugin.hasPermissions(
        types,
        permissions: permissions,
      );

      // hasPermissions() retorna null en iOS por la limitación de HK
      // (no se puede saber el estado, solo intentar leer). Tratamos
      // null como "indeterminado → asumimos granted optimistically y
      // dejamos que sync() detecte el caso real".
      if (has == null) return const HealthPermissionGranted();
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
  Future<List<HealthSample>> _fetchMetric(
    HealthMetric metric,
    DateTime start,
    DateTime end,
  ) async {
    final type = _typeMap[metric]!;
    final points = await _plugin.getHealthDataFromTypes(
      types: [type],
      startTime: start,
      endTime: end,
    );

    // El plugin puede devolver duplicados si distintos dispositivos
    // (iPhone + Apple Watch) reportan lo mismo. Deduplica por (start,
    // value, source).
    final deduped = _plugin.removeDuplicates(points);

    final samples = <HealthSample>[];
    for (final p in deduped) {
      final sample = _toSample(metric, p);
      if (sample != null) samples.add(sample);
    }

    // Orden cronológico: más viejo primero. Los notifiers procesan
    // en ese orden para que el más reciente quede como "actual".
    samples.sort((a, b) => a.start.compareTo(b.start));
    return samples;
  }

  /// Traduce un `HealthDataPoint` del plugin a `HealthSample` neutral.
  /// Retorna null si el dato es inválido (valor no numérico, etc.).
  HealthSample? _toSample(HealthMetric metric, hp.HealthDataPoint p) {
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
