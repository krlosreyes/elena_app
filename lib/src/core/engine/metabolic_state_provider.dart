import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/engine/metabolic_state_builder.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_interval.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/providers/sleep_provider.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// metabolicStateProvider — SPEC-52
// ─────────────────────────────────────────────────────────────────────────────
//
// SPEC-52 cambia el contrato: ahora SI consume `streakProvider.weeklyAdherence`
// vía `select`. El comentario previo del invariante "NUNCA depender de
// streakProvider" fue verificado y descartado: StreakNotifier no consume
// metabolicStateProvider, por lo tanto NO hay ciclo. Riverpod resuelve el
// orden de dependencias correctamente.
//
// Flujo reactivo:
//   fastingProvider ─────┐
//   globalSleepProvider ─┤
//   metabolicPulseProvider┤
//   hydrationProvider ───┼──► metabolicStateProvider ──► MetabolicState
//   exerciseProvider ────┤
//   nutritionProvider ───┤
//   streakProvider ──────┘ (sólo weeklyAdherence vía select)
// ─────────────────────────────────────────────────────────────────────────────

/// Provider central que construye el MetabolicState en tiempo real.
final metabolicStateProvider = Provider<MetabolicState>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);

  // SPEC-34: pulso optimizado a 10s para no recomputar scores cada segundo.
  final now = ref.watch(metabolicPulseProvider).value ?? DateTime.now();

  final fasting = ref.watch(fastingProvider);
  final sleepHours = ref.watch(sleepDurationProvider);
  final exercise = ref.watch(exerciseProvider);
  final nutrition = ref.watch(nutritionProvider);
  final hydration = ref.watch(hydrationProvider);

  // SPEC-52 RF-52-04: weeklyAdherence real desde StreakNotifier.
  // `select` evita reconstruir cuando otros campos del StreakState cambian.
  final weeklyAdherence =
      ref.watch(streakProvider.select((s) => s.weeklyAdherence));

  final user = userAsync.valueOrNull;
  if (user == null) return MetabolicState.empty();

  // Calcular maxFastingHoursToday desde el estado activo + completados.
  double maxFastingHoursToday = 0.0;

  if (fasting.isActive && fasting.startTime != null) {
    maxFastingHoursToday =
        now.difference(fasting.startTime!).inSeconds / 3600.0;
  }

  final todayIntervals =
      ref.watch(todayFastingIntervalsProvider).valueOrNull ?? [];
  for (final interval in todayIntervals) {
    if (interval.isFasting && interval.endTime != null) {
      final duration = interval.endTime!.difference(interval.startTime);
      final hours = duration.inSeconds / 3600.0;
      if (hours > maxFastingHoursToday) {
        maxFastingHoursToday = hours;
      }
    }
  }

  return MetabolicStateBuilder.build(
    user: user,
    fasting: fasting,
    sleepHours: sleepHours,
    exercise: exercise,
    nutrition: nutrition,
    hydration: hydration,
    maxFastingHoursToday: maxFastingHoursToday,
    weeklyAdherence: weeklyAdherence,
  );
});

/// SPEC-52: calculador de IMR reactivo. Una sola fuente de verdad para
/// el score visible al usuario en cualquier pantalla. Reemplaza las 5
/// invocaciones directas a `engine.calculateIMR(...)` que cada pantalla
/// hacía con sus propios defaults.
final imrProvider = Provider<IMRv2Result>((ref) {
  final state = ref.watch(metabolicStateProvider);
  final user = ref.watch(currentUserStreamProvider).valueOrNull;

  // Si user es null o el state está vacío (lastMealTime null), score cero.
  if (user == null || state.lastMealTime == null) {
    return IMRv2Result.empty();
  }

  final engine = ref.watch(scoreEngineProvider);
  return engine.calculateIMR(user, state);
});
