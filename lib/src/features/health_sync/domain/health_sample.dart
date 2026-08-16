// SPEC-132: modelo neutro de una muestra devuelta por HealthKit /
// Health Connect. NO depende del SDK del plugin `health` — el
// `HealthSyncService` traduce los `HealthDataPoint` a esta forma
// para que los notifiers de cada pilar (peso, sueño, ejercicio)
// puedan consumirlos sin tocar el plugin directamente.

import 'health_metric.dart';

/// Una muestra individual leída del proveedor nativo de salud.
///
/// Todos los campos son neutrales respecto a iOS/Android. Por ejemplo,
/// `sourceName` viene como 'com.apple.health' en iOS o
/// 'com.google.android.apps.fitness' en Android.
class HealthSample {
  /// Tipo de métrica representada.
  final HealthMetric metric;

  /// Valor numérico en la unidad canónica de la métrica
  /// (ver `HealthMetricX.canonicalUnit`).
  ///
  /// - weight: kilogramos (double).
  /// - sleepSession: minutos (double).
  /// - steps: cuenta (double, sin decimales pero se mantiene double
  ///   por uniformidad con el plugin).
  final double value;

  /// Inicio del rango temporal de la muestra. Para mediciones
  /// puntuales (peso) `start == end`.
  final DateTime start;

  /// Fin del rango temporal de la muestra.
  final DateTime end;

  /// Identificador del paquete que originó la muestra (Apple Watch,
  /// Garmin, Mi Band, etc.). Se usa para mostrar un badge "Fuente: …"
  /// en la UI cuando el dato no fue ingresado manualmente.
  final String sourceName;

  /// Identificador opcional devuelto por el plugin. Se persiste para
  /// permitir deduplicación en futuras syncs (si el mismo dispositivo
  /// se sincroniza dos veces en la misma ventana).
  final String? uuid;

  /// SPEC-203: solo para `HealthMetric.workout` — el tipo de actividad
  /// nativo (ej. 'RUNNING', 'TRADITIONAL_STRENGTH_TRAINING'). Se mapea a
  /// `ExerciseType` en el import. `null` para las demás métricas.
  final String? workoutActivityType;

  /// SPEC-296: solo workout — energía activa quemada (kcal), si el proveedor
  /// la reporta. `null` si no viene.
  final double? caloriesKcal;

  /// SPEC-296: solo workout — distancia recorrida (metros), si viene.
  final double? distanceMeters;

  /// SPEC-301: solo sueño, muestra INDIVIDUAL (antes de consolidar) — la etapa
  /// de esta muestra derivada del tipo nativo: 'deep' | 'light' | 'rem' |
  /// 'awake' | 'asleep' (genérico, sin etapa) | null. El Apple Watch / relojes
  /// con sensor escriben una muestra por etapa; el iPhone solo 'asleep'.
  final String? sleepStage;

  /// SPEC-301: solo sueño, muestra CONSOLIDADA de la noche — minutos por etapa
  /// sumados del grupo: {'deep': m, 'light': m, 'rem': m, 'awake': m}. Vacío/
  /// null si el dispositivo no reporta etapas (solo hubo 'asleep' genérico).
  final Map<String, int>? sleepStages;

  const HealthSample({
    required this.metric,
    required this.value,
    required this.start,
    required this.end,
    required this.sourceName,
    this.uuid,
    this.workoutActivityType,
    this.caloriesKcal,
    this.distanceMeters,
    this.sleepStage,
    this.sleepStages,
  });

  /// Duración del rango (útil sobre todo para sueño).
  Duration get duration => end.difference(start);

  @override
  String toString() =>
      'HealthSample(${metric.name}, $value ${metric.canonicalUnit}, '
      '$start → $end, src=$sourceName)';
}
