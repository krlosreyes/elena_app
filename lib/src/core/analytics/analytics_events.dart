// SPEC-193: Catálogo único de eventos de Analytics.
//
// Fuente única de verdad para nombres de evento y claves de parámetro.
// Regla (SPEC-193 §2.2): prohibido llamar logEvent con strings literales
// fuera de este catálogo. Cualquier evento nuevo se agrega AQUÍ primero.
//
// Privacidad (SPEC-193 §2.4): ningún parámetro contiene PII (email, nombre)
// ni datos de salud crudos. Solo identificadores pseudónimos y categorías
// (buckets). Los valores continuos (IMR, calidad, horas) se reportan en
// buckets, no en crudo.

class AnalyticsEvents {
  AnalyticsEvents._();

  // ── Ciclo de vida / adquisición ─────────────────────────────────────────
  static const String appOpen = 'app_open';
  static const String signupComplete = 'signup_complete';
  static const String login = 'login';
  static const String onboardingComplete = 'onboarding_complete';

  // ── Pilares / engine ────────────────────────────────────────────────────
  static const String pillarLogged = 'pillar_logged';
  static const String fastingStarted = 'fasting_started';
  static const String fastingCompleted = 'fasting_completed';
  static const String mealLogged = 'meal_logged';
  static const String imrCalculated = 'imr_calculated';

  // ── Monetización (se disparan al implementar Ola C) ──────────────────────
  static const String paywallShown = 'paywall_shown';
  static const String paywallDismissed = 'paywall_dismissed';
  static const String trialStarted = 'trial_started';
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionCancelled = 'subscription_cancelled';
  // SPEC-198: resultado de la compra/restauración desde el paywall.
  static const String purchaseCompleted = 'purchase_completed';
  static const String purchaseRestored = 'purchase_restored';
  static const String purchaseFailed = 'purchase_failed';

  // SPEC-197: un usuario Free topó con un muro de gating (insumo de conversión).
  static const String featureGateBlocked = 'feature_gate_blocked';

  // ── Conducta de coaching (se disparan al implementar SPEC-194) ───────────
  static const String coachingActionShown = 'coaching_action_shown';
  static const String coachingActionFollowed = 'coaching_action_followed';
  static const String coachingActionCompleted = 'coaching_action_completed';
  static const String coachingFeedbackShown = 'coaching_feedback_shown';

  // ── Racha (SPEC-255) ───────────────────────────────────────────────────
  /// El usuario cruzó un hito de racha (3/7/14/30/60/100 días).
  static const String streakMilestoneReached = 'streak_milestone_reached';

  /// Una racha activa se rompió (sin reserva disponible para protegerla).
  static const String streakBroken = 'streak_broken';

  /// Una reserva de racha (freeze) perdonó un día no calificado.
  static const String streakFreezeUsed = 'streak_freeze_used';

  /// El usuario abrió el explainer de "qué cuenta para mi racha".
  static const String streakExplainerOpened = 'streak_explainer_opened';

  // ── Insignias (2026-07-15) ──────────────────────────────────────────────
  /// El usuario desbloqueó una insignia nueva (ver BadgeEngine/BadgeCatalog).
  static const String badgeUnlocked = 'badge_unlocked';

  /// Lista completa para tests de unicidad (SPEC-193 §6).
  static const List<String> all = [
    appOpen,
    signupComplete,
    login,
    onboardingComplete,
    pillarLogged,
    fastingStarted,
    fastingCompleted,
    mealLogged,
    imrCalculated,
    paywallShown,
    paywallDismissed,
    trialStarted,
    subscriptionStarted,
    subscriptionCancelled,
    purchaseCompleted,
    purchaseRestored,
    purchaseFailed,
    featureGateBlocked,
    coachingActionShown,
    coachingActionFollowed,
    coachingActionCompleted,
    coachingFeedbackShown,
    streakMilestoneReached,
    streakBroken,
    streakFreezeUsed,
    streakExplainerOpened,
    badgeUnlocked,
  ];
}

/// Claves de parámetro (también sin PII).
class AnalyticsParams {
  AnalyticsParams._();

  static const String platform = 'platform';
  static const String method = 'method';
  static const String seconds = 'seconds';
  static const String fromMr = 'from_mr';
  static const String protocol = 'protocol';
  static const String hours = 'hours';
  static const String qualityBucket = 'quality_bucket';
  static const String imrBucket = 'imr_bucket';
  static const String pillar = 'pillar';
  static const String trigger = 'trigger';
  static const String plan = 'plan';
  static const String actionId = 'action_id';
  static const String source = 'source';
  static const String phase = 'phase';
  static const String outcome = 'outcome';

  /// SPEC-197: qué feature gateada topó el usuario Free (coaching, analytics,
  /// auto_sync, cycle_feedback).
  static const String feature = 'feature';

  /// SPEC-255: hito de racha cruzado (3/7/14/30/60/100 — ya es un bucket
  /// discreto por diseño, no un valor continuo).
  static const String milestoneDays = 'milestone_days';

  /// SPEC-255: bucket de la longitud de racha rota (evita reportar el día
  /// exacto en crudo, consistente con la regla de buckets del §2.4).
  static const String streakLengthBucket = 'streak_length_bucket';

  /// Insignias (2026-07-15): badgeId del catálogo cerrado (ej. 'racha_30')
  /// — no es PII ni un valor continuo, es un identificador de un catálogo
  /// fijo de ~38 valores, seguro de reportar tal cual.
  static const String badgeId = 'badge_id';

  /// Insignias: categoría de la insignia (ver BadgeCategory.all).
  static const String badgeCategory = 'badge_category';
}
