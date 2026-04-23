import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';

const essentialFocusKey = "essential_focus_shown";

/// Notifier para gestionar la visibilidad temporal de elementos de la UI
/// que el usuario decide descartar durante su sesión actual.
class UiInteractionState {
  final bool isEngagementBannerDismissed;
  final bool isAdaptiveSuggestionDismissed;

  const UiInteractionState({
    this.isEngagementBannerDismissed = false,
    this.isAdaptiveSuggestionDismissed = false,
  });

  UiInteractionState copyWith({
    bool? isEngagementBannerDismissed,
    bool? isAdaptiveSuggestionDismissed,
  }) {
    return UiInteractionState(
      isEngagementBannerDismissed: isEngagementBannerDismissed ?? this.isEngagementBannerDismissed,
      isAdaptiveSuggestionDismissed: isAdaptiveSuggestionDismissed ?? this.isAdaptiveSuggestionDismissed,
    );
  }
}

class UiInteractionNotifier extends StateNotifier<UiInteractionState> {
  final Ref _ref;

  UiInteractionNotifier(this._ref) : super(const UiInteractionState()) {
    _init();
  }

  void _init() {
    final prefs = _ref.read(sharedPreferencesProvider);
    state = state.copyWith(
      isAdaptiveSuggestionDismissed: prefs.getBool(essentialFocusKey) ?? false,
    );
  }

  void dismissEngagementBanner() {
    state = state.copyWith(isEngagementBannerDismissed: true);
  }

  void dismissAdaptiveSuggestion() {
    state = state.copyWith(isAdaptiveSuggestionDismissed: true);
    _ref.read(sharedPreferencesProvider).setBool(essentialFocusKey, true);
  }

  /// Resetea los descartes (útil al cambiar de día o refrescar datos profundos)
  void resetDismissals() {
    state = const UiInteractionState();
  }
}

final uiInteractionProvider = StateNotifierProvider<UiInteractionNotifier, UiInteractionState>((ref) {
  return UiInteractionNotifier(ref);
});
