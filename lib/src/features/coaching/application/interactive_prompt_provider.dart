// SPEC-199 Fase A (RF-199-04/05) — providers del prompt interactivo in-app.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/coaching/application/predictive_trigger_engine.dart';
import 'package:elena_app/src/features/coaching/domain/actionable_prompt.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Id del prompt que el usuario pospuso ("Ahora no") en esta sesión. Mientras
/// coincida con el prompt vigente, la tarjeta se oculta. Como el id incluye el
/// bucket de hora, al cambiar de hora reaparece naturalmente.
final dismissedHydrationPromptProvider = StateProvider<String?>((ref) => null);

/// Prompt de hidratación a mostrar in-app, o `null` si se suprime por contexto
/// (meta cumplida, ventana de sueño, vaso reciente) o si fue pospuesto.
final interactiveHydrationPromptProvider = Provider<ActionablePrompt?>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null || user.id.isEmpty) return null;

  final hydration = ref.watch(hydrationProvider);

  // Último vaso registrado (timestamp más reciente del historial).
  DateTime? lastGlassAt;
  for (final log in hydration.history) {
    if (lastGlassAt == null || log.timestamp.isAfter(lastGlassAt)) {
      lastGlassAt = log.timestamp;
    }
  }
  final now = DateTime.now();
  final since = lastGlassAt == null ? null : now.difference(lastGlassAt);

  final prompt = PredictiveTriggerEngine.hydrationPrompt(
    goalReached: hydration.isGoalReached,
    now: now,
    sinceLastGlass: since,
    wakeHour: user.profile.wakeUpTime.hour,
    sleepHour: user.profile.sleepTime.hour,
  );
  if (prompt == null) return null;

  // Respetar el "Ahora no" de esta hora.
  if (ref.watch(dismissedHydrationPromptProvider) == prompt.id) return null;

  return prompt;
});
