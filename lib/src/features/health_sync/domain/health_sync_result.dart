// SPEC-132: outcome de una operación de sync. Captura tanto los
// samples leídos exitosamente como los errores por métrica,
// de manera que la UI pueda mostrar un resumen ("3 pesos, 2
// sesiones de sueño") y al mismo tiempo reportar fallas parciales
// sin abortar el resto.

import 'health_metric.dart';
import 'health_sample.dart';

/// Resultado de un sync completo contra HealthKit / Health Connect.
class HealthSyncResult {
  /// Inicio del rango consultado.
  final DateTime windowStart;

  /// Fin del rango consultado.
  final DateTime windowEnd;

  /// Samples leídos exitosamente, indexados por métrica.
  ///
  /// Si una métrica no aparece en el mapa, significa que no devolvió
  /// datos o falló (ver `errors`). Una métrica con lista vacía
  /// significa "consulta exitosa, sin datos en el rango".
  final Map<HealthMetric, List<HealthSample>> samplesByMetric;

  /// Errores parciales por métrica. Las métricas exitosas no aparecen.
  final Map<HealthMetric, String> errors;

  /// Timestamp de cierre del sync (cuando la última métrica devolvió
  /// resultado o falló). Útil para mostrar "Última sincronización:
  /// hace 5 min" en la UI.
  final DateTime completedAt;

  const HealthSyncResult({
    required this.windowStart,
    required this.windowEnd,
    required this.samplesByMetric,
    required this.errors,
    required this.completedAt,
  });

  /// Construye un resultado vacío (utilidad para casos en los que el
  /// usuario aún no concedió permisos — evita tener que retornar
  /// null y forzar checks por toda la app).
  factory HealthSyncResult.empty(DateTime windowStart, DateTime windowEnd) {
    return HealthSyncResult(
      windowStart: windowStart,
      windowEnd: windowEnd,
      samplesByMetric: const {},
      errors: const {},
      completedAt: DateTime.now(),
    );
  }

  /// Cantidad total de muestras leídas (suma de las 3 métricas).
  int get totalSamples =>
      samplesByMetric.values.fold(0, (acc, list) => acc + list.length);

  /// `true` si al menos una métrica falló (parcial o total).
  bool get hasErrors => errors.isNotEmpty;

  /// `true` si NO se leyó ningún sample (porque no había datos en el
  /// rango O porque fallaron todas las métricas).
  bool get isEmpty => totalSamples == 0;

  List<HealthSample> samplesFor(HealthMetric metric) =>
      samplesByMetric[metric] ?? const [];

  @override
  String toString() =>
      'HealthSyncResult(total=$totalSamples, errors=${errors.length}, '
      'window=$windowStart→$windowEnd)';
}
