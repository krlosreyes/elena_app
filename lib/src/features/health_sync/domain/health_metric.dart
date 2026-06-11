// SPEC-132: catálogo de métricas que ElenaApp lee desde HealthKit /
// Health Connect. NO incluye métricas de escritura — la app es read-only
// hacia los proveedores nativos para respetar la propiedad del dato del
// usuario y reducir el riesgo de conflicto con otras apps.
//
// Cada métrica se mapea 1:1 a un `HealthDataType` del plugin `health`
// pero se mantiene desacoplada para que el resto de la app no dependa
// del SDK del plugin.

/// Métrica biológica que la app puede importar desde el proveedor nativo.
enum HealthMetric {
  /// Peso corporal (kg). Mapea a `BiometricCheckIn.weight`.
  weight,

  /// Sesión de sueño consolidada (start/end). Mapea a `SleepLog`.
  sleepSession,

  /// Pasos diarios acumulados (count). Mapea a `ExerciseLog` cuando
  /// se considere "actividad equivalente" (>5k pasos = LISS implícito).
  steps,

  /// SPEC-203: entrenamiento real (HKWorkout) — caminata, trote, fuerza,
  /// HIIT, movilidad. Mapea a `ExerciseLog` tipado con su duración real.
  /// `value` = minutos. Tiene prioridad sobre `steps` el mismo día.
  workout,
}

extension HealthMetricX on HealthMetric {
  /// Unidad canónica que esperamos en `HealthSample.value`.
  /// El servicio normaliza siempre a esta unidad antes de devolver.
  String get canonicalUnit {
    switch (this) {
      case HealthMetric.weight:
        return 'kg';
      case HealthMetric.sleepSession:
        return 'minutes';
      case HealthMetric.steps:
        return 'count';
      case HealthMetric.workout:
        return 'minutes';
    }
  }

  /// Etiqueta human-readable para logs y UI de debug.
  String get label {
    switch (this) {
      case HealthMetric.weight:
        return 'Peso';
      case HealthMetric.sleepSession:
        return 'Sueño';
      case HealthMetric.steps:
        return 'Pasos';
      case HealthMetric.workout:
        return 'Entrenamiento';
    }
  }
}
