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
  ///
  /// UX-PROGRESO (auditoría técnica 21-jul, P1): esto NO bloquea el
  /// detalle de un pilar por completo — Free siempre puede ver la
  /// ventana de 7 días (`AnalysisRange.w1`, ya es el default al abrir
  /// cualquier detalle). Lo que este flag sigue controlando es el
  /// acceso a rangos más largos (mes/3M/6M/1A) y a la sección
  /// "Tendencia" (comparación corto vs largo plazo) — ambos requieren
  /// histórico real. Antes del 21-jul, Free no veía NADA del detalle.
  bool get analyticsHistoryAllowed => hasFullAccess;

  /// Sync automático de wearables EN SEGUNDO PLANO (resume de la app,
  /// listener nativo de background delivery, bootstrap por sesión) —
  /// Premium o Trial.
  ///
  /// UX-SYNC (auditoría técnica 21-jul, P1): el sync 100% manual que
  /// esto forzaba en Free era "la mayor fricción diaria posible contra
  /// el hábito" (auditoría). La decisión de producto no es regalar el
  /// sync automático completo (sigue siendo el diferenciador Premium
  /// real), sino separar automático de manual: ver `manualSyncAllowed`.
  bool get autoSyncAllowed => hasFullAccess;

  /// Sync manual bajo demanda (botón "Sincronizar ahora" en Perfil ›
  /// Salud, una vez que el usuario ya conectó HealthKit/Health Connect).
  /// Siempre permitido, incluso en Free — reduce la fricción de registro
  /// manual sin regalar el sync automático en segundo plano
  /// (`autoSyncAllowed`), que sigue siendo Premium/Trial.
  bool get manualSyncAllowed => true;

  /// Acción secundaria de coaching — Premium o Trial.
  bool get coachingSecondaryAllowed => hasFullAccess;

  /// ¿Se puede mostrar una acción de coaching, dado cuántas se mostraron HOY?
  /// Free: máximo 1/día. Premium/Trial: ilimitado.
  bool coachingActionAllowed(int actionsShownToday) =>
      hasFullAccess || actionsShownToday < 1;
}
