// ─────────────────────────────────────────────────────────────────────────────
// ELENA SYSTEM — Dashboard Domain Helpers
// ─────────────────────────────────────────────────────────────────────────────
//
// Pure Dart functions. No Flutter, no Riverpod, no Firestore.
// Consumed by providers that bridge to the UI.
// ─────────────────────────────────────────────────────────────────────────────

/// Aggregated dashboard score from multiple pillars.
class DashboardScoreResult {
  final double score;
  final String label;

  const DashboardScoreResult({required this.score, required this.label});
}

/// Current fasting window state.
class FastingWindowState {
  /// `fasting` or `feeding`.
  final String state;

  /// Elapsed time in the current window.
  final Duration elapsed;

  /// Duration to next milestone (end of fasting or feeding window).
  final Duration nextMilestone;

  const FastingWindowState({
    required this.state,
    required this.elapsed,
    required this.nextMilestone,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// computeDashboardScore
// ═══════════════════════════════════════════════════════════════════════════════

/// Computes a 0-100 unified score from pillar inputs.
///
/// All inputs are 0-100 normalised scores.
/// Weights: training 25%, sleep 25%, nutrition 20%, hydration 15%, fasting 15%.
DashboardScoreResult computeDashboardScore({
  required double trainingScore,
  required double sleepScore,
  required double nutritionScore,
  required double hydrationScore,
  required double fastingScore,
}) {
  final raw = (trainingScore * 0.25) +
      (sleepScore * 0.25) +
      (nutritionScore * 0.20) +
      (hydrationScore * 0.15) +
      (fastingScore * 0.15);

  final score = raw.clamp(0.0, 100.0);

  final String label;
  if (score >= 80) {
    label = 'Estado Óptimo';
  } else if (score >= 60) {
    label = 'Estable';
  } else {
    label = 'Fatiga';
  }

  return DashboardScoreResult(score: score, label: label);
}

// ═══════════════════════════════════════════════════════════════════════════════
// getFastingState
// ═══════════════════════════════════════════════════════════════════════════════

/// Derives fasting-window state from raw controller values.
///
/// [isFasting] and [isFeeding] come from `FastingState`.
/// [elapsed] comes from `FastingState.elapsed`.
/// [plannedHours] is the fasting goal (e.g. 16).
FastingWindowState getFastingWindowState({
  required bool isFasting,
  required Duration elapsed,
  required int plannedHours,
}) {
  if (isFasting) {
    final goal = Duration(hours: plannedHours);
    final remaining = goal - elapsed;
    return FastingWindowState(
      state: 'fasting',
      elapsed: elapsed,
      nextMilestone: remaining.isNegative ? Duration.zero : remaining,
    );
  }

  // Feeding window = 24 - plannedHours
  final feedingHours = 24 - plannedHours;
  final feedingGoal = Duration(hours: feedingHours);
  final remaining = feedingGoal - elapsed;

  return FastingWindowState(
    state: 'feeding',
    elapsed: elapsed,
    nextMilestone: remaining.isNegative ? Duration.zero : remaining,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// generateDailySuggestion
// ═══════════════════════════════════════════════════════════════════════════════

/// Produces a context-aware suggestion string.
///
/// Priority rules (highest first):
/// 1. Low sleep → rest suggestion
/// 2. Prolonged fasting (>16 h) → hydration
/// 3. Active training session → recovery
/// 4. Low hydration → drink water
/// 5. Default → keep it up
String generateDailySuggestion({
  required double sleepScore,
  required double hydrationScore,
  required bool isFastingProlonged,
  required bool isTrainingActive,
}) {
  if (sleepScore < 40) {
    return 'Tu descanso fue insuficiente. Prioriza una siesta corta o reduce intensidad hoy.';
  }
  if (isFastingProlonged) {
    return 'Llevas un ayuno prolongado. Mantén la hidratación para estabilizar electrolitos.';
  }
  if (isTrainingActive) {
    return 'Sesión de entrenamiento activa. Planifica tu ventana de recuperación post-ejercicio.';
  }
  if (hydrationScore < 40) {
    return 'Tu nivel de hidratación está bajo. Bebe 250 ml ahora para mejorar transporte celular.';
  }
  return 'Sistemas estables. Continúa con tu protocolo metabólico actual.';
}
