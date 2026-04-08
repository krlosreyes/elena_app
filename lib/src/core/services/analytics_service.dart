import 'package:firebase_analytics/firebase_analytics.dart';

/// Servicio centralizado de analytics para Elena App.
///
/// Registra eventos clave del usuario en Firebase Analytics
/// para monitoreo de la beta cerrada.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Getter público del observer para el GoRouter.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ─── Eventos de Onboarding ───────────────────────────────────────────

  static Future<void> logOnboardingComplete(double initialImr) =>
      _analytics.logEvent(
        name: 'onboarding_complete',
        parameters: {'initial_imr': initialImr},
      );

  // ─── Eventos de Ayuno ────────────────────────────────────────────────

  static Future<void> logFastingStarted(String protocol) => _analytics.logEvent(
    name: 'fast_started',
    parameters: {'protocol': protocol},
  );

  static Future<void> logFastingCompleted(double hours) =>
      _analytics.logEvent(name: 'fast_completed', parameters: {'hours': hours});

  // ─── Eventos de Nutrición ────────────────────────────────────────────

  static Future<void> logMealLogged() => _analytics.logEvent(name: 'log_meal');

  // ─── Eventos de Sueño ───────────────────────────────────────────────

  static Future<void> logSleepLogged(double hours) =>
      _analytics.logEvent(name: 'log_sleep', parameters: {'hours': hours});

  // ─── Eventos de IMR ─────────────────────────────────────────────────

  static Future<void> logImrCalculated(double score) =>
      _analytics.logEvent(name: 'imr_calculated', parameters: {'score': score});

  // ─── Pantallas (manual, complementa al observer) ────────────────────

  static Future<void> setCurrentScreen(String screenName) =>
      _analytics.logScreenView(screenName: screenName);
}
