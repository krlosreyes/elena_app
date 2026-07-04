// SPEC-197 — gating de features por entitlement (Dart puro, testeable).
//
// Fuente única de "qué puede hacer este usuario". Los callsites preguntan,
// no deciden. Criterio de tiers (SPEC-197 §2):
//   Free    = registro 5 pilares + IMR del día + 1 acción de coaching/día.
//   Trial   = 14 días desde el registro con acceso completo (SPEC-240).
//   Premium = coaching ilimitado + feedback de cierre + histórico/longitudinal
//             + sync automático de wearables.

/// Duración del periodo de prueba gratuito (SPEC-240).
const int kTrialDurationDays = 14;

class FeatureGate {
  const FeatureGate({
    required this.isPremium,
    required this.isInTrial,
  });

  final bool isPremium;

  /// True durante los primeros [kTrialDurationDays] días desde el registro.
  /// Los usuarios en trial tienen acceso completo igual que Premium.
  final bool isInTrial;

  /// True si el usuario tiene acceso completo, ya sea por suscripción o trial.
  bool get hasFullAccess => isPremium || isInTrial;

  /// Feedback de cierre de ciclo (coaching) — Premium o Trial.
  bool get cycleFeedbackAllowed => hasFullAccess;

  /// Histórico / tendencia longitudinal en Análisis — Premium o Trial.
  bool get analyticsHistoryAllowed => hasFullAccess;

  /// Sync automático de wearables (HealthKit / Health Connect) — Premium o Trial.
  bool get autoSyncAllowed => hasFullAccess;

  /// Acción secundaria de coaching — Premium o Trial.
  bool get coachingSecondaryAllowed => hasFullAccess;

  /// ¿Se puede mostrar una acción de coaching, dado cuántas se mostraron HOY?
  /// Free: máximo 1/día. Premium/Trial: ilimitado.
  bool coachingActionAllowed(int actionsShownToday) =>
      hasFullAccess || actionsShownToday < 1;
}
