// SPEC-137 E.5: provider del estado de la próxima comida sugerida.
//
// Combina:
// - state.todayLogs (de nutritionProvider) → última comida.
// - cheatDayProvider → si está activo, suspender el banner.
// - metabolicPulseProvider → refresca cada 10s para que el countdown
//   del banner sea reactivo sin ticker dedicado.
//
// Expone un `NextMealState` para que el Dashboard muestre el banner
// solo cuando faltan ≤ 30 min para la próxima comida sugerida.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/features/nutrition/application/cheat_day_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';

class NextMealState {
  /// Timestamp sugerido para la próxima comida (= última + 3h).
  /// Null si no hay comidas registradas hoy.
  final DateTime? nextMealAt;

  /// True si estamos dentro de la ventana de 30 min antes de [nextMealAt].
  /// El Dashboard usa este flag para decidir si renderizar el banner.
  final bool inNotificationWindow;

  /// Minutos restantes hasta [nextMealAt]. Útil para el countdown.
  /// 0 o negativo si ya pasó.
  final int minutesUntilNext;

  /// True si el usuario está en día de permitidos. Si lo está, el
  /// Dashboard NO muestra banner (respeta la decisión consciente).
  final bool cheatDayActive;

  const NextMealState({
    required this.nextMealAt,
    required this.inNotificationWindow,
    required this.minutesUntilNext,
    required this.cheatDayActive,
  });

  const NextMealState.empty()
      : nextMealAt = null,
        inNotificationWindow = false,
        minutesUntilNext = 0,
        cheatDayActive = false;

  /// Conveniencia: ¿debe el Dashboard mostrar el banner?
  bool get shouldShowBanner =>
      inNotificationWindow && !cheatDayActive && nextMealAt != null;
}

final nextMealProvider = Provider<NextMealState>((ref) {
  final nutritionState = ref.watch(nutritionProvider);
  final cheatDay = ref.watch(cheatDayProvider);
  // Watch del pulso para refrescar cada 10s. Si el stream aún no emitió
  // (primera apertura), usar DateTime.now() como fallback.
  final now = ref.watch(metabolicPulseProvider).valueOrNull ?? DateTime.now();

  final lastMealAt = MealIntervalRules.lastMealOf(nutritionState.todayLogs);
  final nextMealAt = MealIntervalRules.nextSuggestedAt(lastMealAt);
  final inWindow = MealIntervalRules.isInNotificationWindow(
    lastMealAt: lastMealAt,
    now: now,
  );

  final minutesUntil =
      nextMealAt == null ? 0 : nextMealAt.difference(now).inMinutes;

  return NextMealState(
    nextMealAt: nextMealAt,
    inNotificationWindow: inWindow,
    minutesUntilNext: minutesUntil,
    cheatDayActive: cheatDay.isActiveToday,
  );
});
