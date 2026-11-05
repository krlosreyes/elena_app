// 2026-11-04 (auditoría Apple Salud, Fase 3): qué llegó de verdad y cuándo.
//
// iOS nunca dice si el usuario negó un permiso (privacidad): la app solo ve
// "cero datos". Por eso guardamos, por métrica, cuándo fue el dato más
// reciente que recibimos. Si una métrica conectada no trae nada en 7 días,
// la tarjeta lo dice y manda a revisar permisos en Ajustes › Salud.
//
// También guarda el último peso de la báscula: ya no se escribe como
// check-in diario (ver health_import_service.dart), pero prellena el
// formulario de medición semanal.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';

/// Días sin datos a partir de los cuales una métrica se considera "callada".
const int kHealthStaleDays = 7;

class HealthLatestWeight {
  const HealthLatestWeight({
    required this.kg,
    required this.at,
    required this.source,
  });

  final double kg;
  final DateTime at;
  final String source;
}

class HealthDataStatus {
  const HealthDataStatus({this.lastSeen = const {}, this.latestWeight});

  /// Dato más reciente recibido por métrica.
  final Map<HealthMetric, DateTime> lastSeen;
  final HealthLatestWeight? latestWeight;

  static const empty = HealthDataStatus();

  /// Métricas que el usuario normalmente tendría y que no traen datos en
  /// [kHealthStaleDays] días. Pasos y sueño son las señales base de
  /// cualquier iPhone; peso, entrenamiento y minutos dependen de tener
  /// báscula o reloj, así que no se reclaman.
  List<HealthMetric> staleMetrics(DateTime now) {
    const expected = [HealthMetric.steps, HealthMetric.sleepSession];
    return [
      for (final m in expected)
        if (lastSeen[m] == null ||
            now.difference(lastSeen[m]!).inDays >= kHealthStaleDays)
          m,
    ];
  }

  HealthDataStatus merge(HealthSyncResult result) {
    final seen = {...lastSeen};
    for (final m in HealthMetric.values) {
      for (final HealthSample s in result.samplesFor(m)) {
        final t = s.end.isAfter(s.start) ? s.end : s.start;
        if (seen[m] == null || t.isAfter(seen[m]!)) seen[m] = t;
      }
    }
    HealthLatestWeight? w = latestWeight;
    for (final s in result.samplesFor(HealthMetric.weight)) {
      if (s.value <= 0) continue;
      if (w == null || s.start.isAfter(w.at)) {
        w = HealthLatestWeight(kg: s.value, at: s.start, source: s.sourceName);
      }
    }
    return HealthDataStatus(lastSeen: seen, latestWeight: w);
  }

  // ─── Persistencia ────────────────────────────────────────────────

  static String _seenKey(HealthMetric m) => 'health.lastSeen.${m.name}';
  static const _wKg = 'health.latestWeight.kg';
  static const _wAt = 'health.latestWeight.at';
  static const _wSrc = 'health.latestWeight.source';

  static HealthDataStatus load(SharedPreferences prefs) {
    final seen = <HealthMetric, DateTime>{};
    for (final m in HealthMetric.values) {
      final raw = prefs.getString(_seenKey(m));
      final t = raw == null ? null : DateTime.tryParse(raw);
      if (t != null) seen[m] = t;
    }
    final kg = prefs.getDouble(_wKg);
    final at = DateTime.tryParse(prefs.getString(_wAt) ?? '');
    return HealthDataStatus(
      lastSeen: seen,
      latestWeight: (kg != null && at != null)
          ? HealthLatestWeight(
              kg: kg, at: at, source: prefs.getString(_wSrc) ?? 'Apple Salud')
          : null,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    for (final e in lastSeen.entries) {
      await prefs.setString(_seenKey(e.key), e.value.toIso8601String());
    }
    final w = latestWeight;
    if (w != null) {
      await prefs.setDouble(_wKg, w.kg);
      await prefs.setString(_wAt, w.at.toIso8601String());
      await prefs.setString(_wSrc, w.source);
    }
  }
}

final healthDataStatusProvider = StateProvider<HealthDataStatus>((ref) {
  return HealthDataStatus.load(ref.watch(sharedPreferencesProvider));
});
