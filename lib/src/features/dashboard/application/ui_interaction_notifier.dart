import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';

/// Notifier para gestionar la visibilidad de banners y sugerencias que el
/// usuario descarta.
///
/// Historia:
/// - SPEC-72.2 (descartado): persistencia con `essential_focus_shown`
///   silenciaba para siempre, sin forma de reactivar.
/// - SPEC-72.2 v2: descartes solo en memoria; `resetDismissals()`
///   reseteaba al cruzar medianoche (SPEC-58 DailyResetNotifier).
/// - SPEC-194 (2026-06-06): cada cold start reseteaba el state →
///   TODOS los banners reaparecían al abrir/actualizar la app
///   (EngagementBanner, AdaptiveSuggestionCard, HydrationCoach) aunque
///   el usuario los hubiese descartado segundos antes. Refactor:
///   persistir los dismissals por día calendárico en SharedPreferences.
///   La clave incluye `YYYY-MM-DD`, así el día siguiente reaparecen
///   naturalmente sin necesidad de `resetDismissals()`.
class UiInteractionState {
  final bool isEngagementBannerDismissed;
  final bool isAdaptiveSuggestionDismissed;
  final bool isHydrationCoachDismissed;
  final bool isBiometricReminderDismissed;

  /// Propuesta "racha protagonista" (2026-07-15, P4).
  final bool isStreakAtRiskDismissed;

  /// Módulo "Tu Glucosa" (23-jul): usuario tocó "Ahora no" en el sheet
  /// de consentimiento del Protocolo de Seguimiento de Glucosa.
  /// Mismo criterio día-calendario que el resto: reaparece mañana si
  /// sigue elegible y sin consentimiento — evita el loop de volver a
  /// mostrarlo en cada rebuild del Dashboard dentro del mismo día.
  final bool isGlucoseConsentDismissed;

  const UiInteractionState({
    this.isEngagementBannerDismissed = false,
    this.isAdaptiveSuggestionDismissed = false,
    this.isHydrationCoachDismissed = false,
    this.isBiometricReminderDismissed = false,
    this.isStreakAtRiskDismissed = false,
    this.isGlucoseConsentDismissed = false,
  });

  UiInteractionState copyWith({
    bool? isEngagementBannerDismissed,
    bool? isAdaptiveSuggestionDismissed,
    bool? isHydrationCoachDismissed,
    bool? isBiometricReminderDismissed,
    bool? isStreakAtRiskDismissed,
    bool? isGlucoseConsentDismissed,
  }) {
    return UiInteractionState(
      isEngagementBannerDismissed:
          isEngagementBannerDismissed ?? this.isEngagementBannerDismissed,
      isAdaptiveSuggestionDismissed:
          isAdaptiveSuggestionDismissed ?? this.isAdaptiveSuggestionDismissed,
      isHydrationCoachDismissed:
          isHydrationCoachDismissed ?? this.isHydrationCoachDismissed,
      isBiometricReminderDismissed:
          isBiometricReminderDismissed ?? this.isBiometricReminderDismissed,
      isStreakAtRiskDismissed:
          isStreakAtRiskDismissed ?? this.isStreakAtRiskDismissed,
      isGlucoseConsentDismissed:
          isGlucoseConsentDismissed ?? this.isGlucoseConsentDismissed,
    );
  }
}

/// SPEC-194: claves de SharedPreferences por banner y día calendárico.
/// El día se computa con `now` cada vez que se lee/escribe; la
/// implementación es cycle-aware-neutra porque los banners viven en
/// dimensión calendárica (cf. METABOLIC_DAY_CONSTITUTION §9 — overlays
/// y banners de UX no están atados al ciclo metabólico).
String _engagementKey(String day) => 'ui_dismiss_engagement_$day';
String _adaptiveKey(String day) => 'ui_dismiss_adaptive_$day';
String _hydrationCoachKey(String day) => 'ui_dismiss_hydration_coach_$day';
String _biometricReminderKey(String day) =>
    'ui_dismiss_biometric_reminder_$day';
String _streakAtRiskKey(String day) => 'ui_dismiss_streak_at_risk_$day';
String _glucoseConsentKey(String day) => 'ui_dismiss_glucose_consent_$day';

class UiInteractionNotifier extends StateNotifier<UiInteractionState> {
  final Ref _ref;

  UiInteractionNotifier(this._ref) : super(const UiInteractionState()) {
    _hydrateFromPrefs();
  }

  String _todayKey() => DayBoundaryResolver.dayKeyIso(DateTime.now());

  void _hydrateFromPrefs() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final day = _todayKey();
    state = UiInteractionState(
      isEngagementBannerDismissed: prefs.getBool(_engagementKey(day)) ?? false,
      isAdaptiveSuggestionDismissed: prefs.getBool(_adaptiveKey(day)) ?? false,
      isHydrationCoachDismissed:
          prefs.getBool(_hydrationCoachKey(day)) ?? false,
      isBiometricReminderDismissed:
          prefs.getBool(_biometricReminderKey(day)) ?? false,
      isStreakAtRiskDismissed: prefs.getBool(_streakAtRiskKey(day)) ?? false,
      isGlucoseConsentDismissed:
          prefs.getBool(_glucoseConsentKey(day)) ?? false,
    );
  }

  Future<void> dismissEngagementBanner() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(_engagementKey(_todayKey()), true);
    state = state.copyWith(isEngagementBannerDismissed: true);
  }

  Future<void> dismissAdaptiveSuggestion() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(_adaptiveKey(_todayKey()), true);
    state = state.copyWith(isAdaptiveSuggestionDismissed: true);
  }

  /// SPEC-70.4: usuario descarta el coach educativo sobre logging de
  /// hidratación. Reaparece al día siguiente porque la clave incluye
  /// el día calendárico.
  Future<void> dismissHydrationCoach() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(_hydrationCoachKey(_todayKey()), true);
    state = state.copyWith(isHydrationCoachDismissed: true);
  }

  /// Carlos (2026-07-13): usuario descarta el recordatorio de check-in
  /// biométrico (7 días desde el último registro). Reaparece mañana si
  /// la condición sigue activa — mismo patrón día-calendario que el
  /// resto de banners. No lo "apaga" para siempre: solo pospone un día.
  Future<void> dismissBiometricReminder() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(_biometricReminderKey(_todayKey()), true);
    state = state.copyWith(isBiometricReminderDismissed: true);
  }

  /// Propuesta "racha protagonista" (2026-07-15, P4): usuario descarta el
  /// aviso de racha en riesgo por hoy. Reaparece mañana si la condición
  /// sigue activa — mismo patrón día-calendario que el resto de banners.
  Future<void> dismissStreakAtRisk() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(_streakAtRiskKey(_todayKey()), true);
    state = state.copyWith(isStreakAtRiskDismissed: true);
  }

  /// Módulo "Tu Glucosa" (23-jul): mismo criterio que
  /// `dismissStreakAtRisk` — pospone un día, no apaga para siempre.
  Future<void> dismissGlucoseConsent() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(_glucoseConsentKey(_todayKey()), true);
    state = state.copyWith(isGlucoseConsentDismissed: true);
  }

  /// SPEC-194: ya no se necesita reset manual. La clave incluye el día,
  /// así el día siguiente arranca limpio automáticamente. Se mantiene
  /// como no-op por compatibilidad con DailyResetNotifier (SPEC-58),
  /// que sigue llamándolo. Re-hidrata desde prefs para refrescar el
  /// state si cambió el día.
  void resetDismissals() {
    if (!mounted) return;
    _hydrateFromPrefs();
  }
}

final uiInteractionProvider =
    StateNotifierProvider<UiInteractionNotifier, UiInteractionState>((ref) {
  return UiInteractionNotifier(ref);
});
