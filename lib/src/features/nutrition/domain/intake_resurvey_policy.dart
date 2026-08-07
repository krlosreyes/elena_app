// SPEC-275 — Cuándo re-encuestar el intake dietético.
//
// Decisión de Carlos (§9, fundamento científico): la re-encuesta del
// retrato dietético ocurre cada 4 semanas en fase activa y cada 12 en
// mantenimiento. Base: la formación de hábito tiene mediana ~66 días
// (Lally 2010) y la adaptación metabólica / mesetas aparecen entre 2 y 8
// semanas — re-encuestar a las 4 semanas cae en la ventana para ajustar
// antes de que la meseta se asiente; en mantenimiento se estira a 12.
//
// Servicio PURO (sin Riverpod / Flutter): decide si el intake está
// "vencido" comparando su `updatedAt` con ahora. La UI (SPEC-273) lo usa
// para mostrar un banner "actualiza tu minuta".

/// Fase del proceso del usuario para la cadencia de re-encuesta.
enum IntakePhase {
  /// Transformación activa: re-encuesta cada 4 semanas.
  active,

  /// Mantenimiento: re-encuesta cada 12 semanas.
  maintenance,
}

class IntakeResurveyPolicy {
  const IntakeResurveyPolicy();

  /// 4 semanas.
  static const int activeIntervalDays = 28;

  /// 12 semanas.
  static const int maintenanceIntervalDays = 84;

  int intervalDays(IntakePhase phase) => switch (phase) {
        IntakePhase.active => activeIntervalDays,
        IntakePhase.maintenance => maintenanceIntervalDays,
      };

  /// True si ya toca re-encuestar (han pasado ≥ intervalo desde updatedAt).
  bool isDue({
    required DateTime updatedAt,
    required DateTime now,
    IntakePhase phase = IntakePhase.active,
  }) {
    return now.difference(updatedAt).inDays >= intervalDays(phase);
  }

  /// Días que faltan para la próxima re-encuesta (negativo o 0 = ya vencida).
  int daysUntilDue({
    required DateTime updatedAt,
    required DateTime now,
    IntakePhase phase = IntakePhase.active,
  }) {
    return intervalDays(phase) - now.difference(updatedAt).inDays;
  }
}
