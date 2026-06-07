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
  static const String trialStarted = 'trial_started';
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionCancelled = 'subscription_cancelled';

  // ── Conducta de coaching (se disparan al implementar SPEC-194) ───────────
  static const String coachingActionShown = 'coaching_action_shown';
  static const String coachingActionFollowed = 'coaching_action_followed';
  static const String coachingActionCompleted = 'coaching_action_completed';
  static const String coachingFeedbackShown = 'coaching_feedback_shown';

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
    trialStarted,
    subscriptionStarted,
    subscriptionCancelled,
    coachingActionShown,
    coachingActionFollowed,
    coachingActionCompleted,
    coachingFeedbackShown,
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
}
