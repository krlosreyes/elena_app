// SPEC-197 — gating de features por entitlement (Dart puro, testeable).
//
// Fuente única de "qué puede hacer este usuario". Los callsites preguntan,
// no deciden. Criterio de tiers (SPEC-197 §2):
//   Free    = registro 5 pilares + IMR del día + 1 acción de coaching/día.
//   Premium = coaching ilimitado + feedback de cierre + histórico/longitudinal
//             + sync automático de wearables.

class FeatureGate {
  const FeatureGate({required this.isPremium});

  final bool isPremium;

  /// Feedback de cierre de ciclo (coaching) — solo Premium.
  bool get cycleFeedbackAllowed => isPremium;

  /// Histórico / tendencia longitudinal en Análisis — solo Premium.
  /// Free ve únicamente el día actual.
  bool get analyticsHistoryAllowed => isPremium;

  /// Sync automático de wearables (HealthKit / Health Connect) — solo Premium.
  /// Free registra manualmente.
  bool get autoSyncAllowed => isPremium;

  /// Acción secundaria de coaching — solo Premium.
  bool get coachingSecondaryAllowed => isPremium;

  /// ¿Se puede mostrar una acción de coaching, dado cuántas se mostraron HOY?
  /// Free: máximo 1/día. Premium: ilimitado.
  bool coachingActionAllowed(int actionsShownToday) =>
      isPremium || actionsShownToday < 1;
}
