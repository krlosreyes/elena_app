import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier para gestionar la visibilidad temporal de elementos de la UI
/// que el usuario decide descartar durante su sesión actual.
///
/// SPEC-72.2: refactor — descartes solo en memoria. La persistencia previa
/// con `SharedPreferences` y la clave `essential_focus_shown` se eliminó
/// porque silenciaba la sugerencia para siempre, sin mecanismo en la UI
/// para reactivarla. Ahora `resetDismissals()` se invoca desde
/// `DailyResetNotifier.triggerDailyReset()` (SPEC-58), por lo que los
/// descartes desaparecen cada día naturalmente.
class UiInteractionState {
  final bool isEngagementBannerDismissed;
  final bool isAdaptiveSuggestionDismissed;
  final bool isHydrationCoachDismissed;

  const UiInteractionState({
    this.isEngagementBannerDismissed = false,
    this.isAdaptiveSuggestionDismissed = false,
    this.isHydrationCoachDismissed = false,
  });

  UiInteractionState copyWith({
    bool? isEngagementBannerDismissed,
    bool? isAdaptiveSuggestionDismissed,
    bool? isHydrationCoachDismissed,
  }) {
    return UiInteractionState(
      isEngagementBannerDismissed: isEngagementBannerDismissed ?? this.isEngagementBannerDismissed,
      isAdaptiveSuggestionDismissed: isAdaptiveSuggestionDismissed ?? this.isAdaptiveSuggestionDismissed,
      isHydrationCoachDismissed: isHydrationCoachDismissed ?? this.isHydrationCoachDismissed,
    );
  }
}

class UiInteractionNotifier extends StateNotifier<UiInteractionState> {
  UiInteractionNotifier() : super(const UiInteractionState());

  void dismissEngagementBanner() {
    state = state.copyWith(isEngagementBannerDismissed: true);
  }

  void dismissAdaptiveSuggestion() {
    state = state.copyWith(isAdaptiveSuggestionDismissed: true);
  }

  /// SPEC-70.4: usuario descarta el coach educativo sobre logging de
  /// hidratación. Reaparece al día siguiente vía `resetDismissals()`.
  void dismissHydrationCoach() {
    state = state.copyWith(isHydrationCoachDismissed: true);
  }

  /// Resetea los descartes. Invocado por `DailyResetNotifier` al cruzar
  /// medianoche (SPEC-58) para que los banners reaparezcan cada nuevo día
  /// si la condición que los origina sigue activa.
  void resetDismissals() {
    if (!mounted) return;
    state = const UiInteractionState();
  }
}

final uiInteractionProvider = StateNotifierProvider<UiInteractionNotifier, UiInteractionState>((ref) {
  return UiInteractionNotifier();
});
