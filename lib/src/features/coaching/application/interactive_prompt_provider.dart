// SPEC-199 Fase A → SPEC-233: providers del prompt interactivo in-app.
//
// Refactorizado de solo-hidratación a los 5 pilares vía
// InteractivePromptOrchestrator. El provider antiguo
// `interactiveHydrationPromptProvider` se mantiene como alias backward-compat
// y devuelve solo el prompt si es de hidratación (para consumidores legacy).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/coaching/application/check_in_provider.dart';
import 'package:elena_app/src/features/coaching/application/interactive_prompt_orchestrator.dart';
import 'package:elena_app/src/features/coaching/domain/actionable_prompt.dart';
import 'package:elena_app/src/features/fasting/application/eating_window_provider.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/fasting/domain/eating_window_state.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Id del prompt que el usuario pospuso ("Ahora no") en esta sesión. Mientras
/// coincida con el prompt vigente, la tarjeta se oculta. Como el id incluye el
/// bucket de hora, al cambiar de hora reaparece naturalmente.
final dismissedHydrationPromptProvider = StateProvider<String?>((ref) => null);

/// SPEC-233: conteo de dismisses por prompt id hoy (anti-fatiga rotacional).
/// Si un prompt se descarta ≥2 veces, el orchestrator lo baja de prioridad.
final dismissCountTodayProvider =
    StateProvider<Map<String, int>>((ref) => const {});

// ─────────────────────────────────────────────────────────────────────────────
// Provider principal: prompt multi-pilar
// ─────────────────────────────────────────────────────────────────────────────

/// Prompt interactivo del pilar más relevante del momento. Reemplaza la tarjeta
/// de solo-hidratación con un carrusel rotativo decidido por el orchestrator.
final interactivePromptProvider = Provider<PillarPrompt?>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null || user.id.isEmpty) return null;

  final now = DateTime.now();
  final wakeHour = user.profile.wakeUpTime.hour;
  final sleepHour = user.profile.sleepTime.hour;

  // ── Inputs de cada pilar ──────────────────────────────────────────────────

  // Hidratación.
  final hydration = ref.watch(hydrationProvider);
  DateTime? lastGlassAt;
  for (final log in hydration.history) {
    if (lastGlassAt == null || log.timestamp.isAfter(lastGlassAt)) {
      lastGlassAt = log.timestamp;
    }
  }
  final sinceLastGlass =
      lastGlassAt == null ? null : now.difference(lastGlassAt);

  // Ayuno.
  final fastingState = ref.watch(fastingProvider);
  final fastingActive = fastingState.isActive;
  final protocolReached = fastingActive &&
      fastingState.startTime != null &&
      now.difference(fastingState.startTime!).inHours >=
          fastingState.targetHours;
  final fastingDuration = fastingState.startTime != null
      ? now.difference(fastingState.startTime!)
      : null;

  // Ejercicio: meta = 30 min (default).
  final exercise = ref.watch(exerciseProvider);
  final exerciseGoalReached = exercise.todayMinutes >= 30;

  // Nutrición: ventana de alimentación abierta + última comida.
  final ew = ref.watch(eatingWindowProvider);
  final eatingWindowOpen =
      ew != null && ew.status == EatingWindowStatus.withinWindow;
  final nutrition = ref.watch(nutritionProvider);
  DateTime? lastMealAt;
  for (final log in nutrition.todayLogs) {
    if (lastMealAt == null || log.timestamp.isAfter(lastMealAt)) {
      lastMealAt = log.timestamp;
    }
  }
  final sinceLastMeal =
      lastMealAt == null ? null : now.difference(lastMealAt);

  // Sueño: ¿ya registró hoy? lastLog != null indica que hay log del día.
  final sleepState = ref.watch(sleepProvider);
  final sleepLogged = sleepState.lastLog != null;

  // Check-in emocional (SPEC-232): ya resuelto por su propio provider.
  final checkIn = ref.watch(interactiveCheckInPromptProvider);

  // Anti-fatiga.
  final dismissCount = ref.watch(dismissCountTodayProvider);

  // ── Orquestación ──────────────────────────────────────────────────────────

  final result = InteractivePromptOrchestrator.evaluate(
    hydrationGoalReached: hydration.isGoalReached,
    sinceLastGlass: sinceLastGlass,
    fastingActive: fastingActive,
    protocolReached: protocolReached,
    fastingDuration: fastingDuration,
    exerciseGoalReached: exerciseGoalReached,
    eatingWindowOpen: eatingWindowOpen,
    sinceLastMeal: sinceLastMeal,
    sleepLogged: sleepLogged,
    checkInPrompt: checkIn,
    now: now,
    wakeHour: wakeHour,
    sleepHour: sleepHour,
    dismissCountToday: dismissCount,
  );
  if (result == null) return null;

  // Respetar el "Ahora no" de esta sesión (legacy hydration dismiss +
  // dismiss genérico).
  final dismissed = ref.watch(dismissedHydrationPromptProvider);
  if (dismissed == result.prompt.id) return null;

  return result;
});

// ─────────────────────────────────────────────────────────────────────────────
// Backward-compat: interactiveHydrationPromptProvider (legacy consumers)
// ─────────────────────────────────────────────────────────────────────────────

/// Legacy: devuelve el prompt solo si es de hidratación. Consumido por
/// widgets que aún no migraron a `interactivePromptProvider`.
final interactiveHydrationPromptProvider = Provider<ActionablePrompt?>((ref) {
  final pillarPrompt = ref.watch(interactivePromptProvider);
  if (pillarPrompt == null) return null;
  if (pillarPrompt.pillar != PromptPillar.hydration) return null;
  return pillarPrompt.prompt;
});
