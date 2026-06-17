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
/// SPEC-221 (2026-06-17): este enum es el INTERNO del orchestrator.
/// El enum canónico para UI/notificaciones/coaching es `FastingPhase`
/// de `fasting_status.dart` (6 valores, más granular y científicamente
/// preciso). Este se mantiene por compatibilidad con Freezed
/// (`OrchestratorState.fastingPhase`). Pendiente: unificar tras
/// correr `build_runner` y renombrar a `OrchestratorFastingBand`.
///
/// Mapeo interno (umbrales del OrchestratorEngine):
///   <4h   → alerta       (= early)
///   4–8h  → gluconeogenesis
///   8–12h → cetosis       (= ketosis)
///   12h+  → autofagia     (= deepFasting)
enum FastingPhase {
  /// Estado post-ingesta (insulina activa). Equivale a 'early'.
  alerta,

  /// Producción de glucosa hepática. Equivale a 'gluconeogenesis'.
  gluconeogenesis,

  /// Uso de grasa como energía primaria. Equivale a 'ketosis'.
  cetosis,

  /// Reciclaje celular profundo. Equivale a 'deepFasting'.
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
