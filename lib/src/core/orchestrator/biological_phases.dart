// ─────────────────────────────────────────────────────────────────────────────
// SPEC-01: Enums Biológicos Tipados (SOURCE OF TRUTH)
// ─────────────────────────────────────────────────────────────────────────────
//
// Contrato único entre:
// - OrchestratorEngine
// - CircadianRules
// - UI (Dashboard / Cards)
//
// ⚠️ REGLA: Si agregas/modificas fases aquí, debes actualizar:
// - phase_info_mapper.dart
// - cualquier switch exhaustivo
//
// SPEC-00: Dart puro — sin dependencias externas.
// ─────────────────────────────────────────────────────────────────────────────

/// Bandas internas del OrchestratorEngine para lógica de decisión.
///
/// SPEC-221 (2026-06-17): renombrado de `FastingPhase` a
/// `OrchestratorFastingBand` para eliminar la ambigüedad con el
/// `FastingPhase` canónico de UI en `fasting_status.dart`.
///
/// Umbrales del OrchestratorEngine:
///   <4h   → alerta
///   4–8h  → gluconeogenesis
///   8–12h → cetosis
///   12h+  → autofagia
enum OrchestratorFastingBand {
  /// Estado post-ingesta (insulina activa).
  alerta,

  /// Producción de glucosa hepática.
  gluconeogenesis,

  /// Uso de grasa como energía primaria.
  cetosis,

  /// Reciclaje celular profundo.
  autofagia,
}

/// Fases del ritmo circadiano basadas en hora del día.
///
/// Mapeo:
///   22:30–06:00 → sueno
///   06:00–09:00 → alerta
///   09:00–13:00 → cognitivo
///   13:00–15:00 → receso
///   15:00–20:00 → motorFuerza
///   20:00–22:30 → creatividad
enum CircadianPhase {
  /// Fase de descanso profundo y recuperación hormonal
  sueno,

  /// Activación inicial del sistema (cortisol ↑)
  alerta,

  /// Máximo rendimiento mental
  cognitivo,

  /// Baja energía postprandial
  receso,

  /// Máximo rendimiento físico
  motorFuerza,

  /// Estado creativo / introspectivo
  creatividad,
}

/// Los 5 pilares metabólicos del sistema Elena.
enum Pillar {
  fasting,
  nutrition,
  hydration,
  sleep,
  exercise,
}

/// Prioridad de recomendaciones del Orchestrator.
enum RecommendationPriority {
  high,
  medium,
  low,
}
