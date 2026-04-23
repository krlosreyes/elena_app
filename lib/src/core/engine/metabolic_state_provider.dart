import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/engine/metabolic_state_builder.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/shared/providers/sleep_provider.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_interval.dart';


// ─────────────────────────────────────────────────────────────────────────────
// metabolicStateProvider
// ─────────────────────────────────────────────────────────────────────────────
//
// SPEC-00 INVARIANT:
// Este provider NUNCA debe depender de streakProvider.
// StreakNotifier consume MetabolicState via MetabolicStateBuilder (ref.read)
// para evitar ciclos.
// Cualquier ref.listen/ref.watch a streakProvider desde aquí rompe la
// arquitectura y genera un ciclo infinito.
// ─────────────────────────────────────────────────────────────────────────────

/// Provider central que construye el MetabolicState en tiempo real
/// escuchando los providers existentes de cada pilar.
///
/// Flujo reactivo:
///   fastingProvider ─────┐
///   globalSleepProvider ─┤
///   clockProvider ───────┤
///   hydrationProvider ───┼──► metabolicStateProvider ──► MetabolicState
///   exerciseProvider ────┤
///   nutritionProvider ───┘
///
/// NO depende de:
/// - orchestratorProvider (MetabolicState es input del orchestrator, no al revés)
/// - streakProvider (evita ciclo circular — ver SPEC-00 INVARIANT)
///
/// weeklyAdherence se inyecta como 0.0 aquí. StreakNotifier usa
/// MetabolicStateBuilder.build() directamente con la adherencia real.
final metabolicStateProvider = Provider<MetabolicState>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  
  // SPEC-34: Inyectar pulso temporal optimizado (cada 10s)
  // Esto evita recomputar scores pesados cada segundo, reduciendo carga en UI.
  final now = ref.watch(metabolicPulseProvider).value ?? DateTime.now();

  
  final fasting = ref.watch(fastingProvider);
  final sleepHours = ref.watch(sleepDurationProvider);
  final exercise = ref.watch(exerciseProvider);
  final nutrition = ref.watch(nutritionProvider);
  final hydration = ref.watch(hydrationProvider);

  final user = userAsync.valueOrNull;
  if (user == null) return MetabolicState.empty();

  // Calcular maxFastingHoursToday desde el estado activo + completados
  // Usamos el 'now' del clock para precisión absoluta en tiempo real
  double maxFastingHoursToday = 0.0;

  if (fasting.isActive && fasting.startTime != null) {
    maxFastingHoursToday = now.difference(fasting.startTime!).inSeconds / 3600.0;
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
    weeklyAdherence: 0.0,
  );
});

/// Calculador de IMR reactivo basado en el estado metabólico.
/// Actualiza el score central de forma optimizada (cada 10s).
final imrProvider = Provider<IMRv2Result>((ref) {
  final state = ref.watch(metabolicStateProvider);
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return IMRv2Result(
    totalScore: 0,
    structureScore: 0,
    metabolicScore: 0,
    behaviorScore: 0,
    circadianAlignment: 0,
    zone: 'N/A',
    description: 'Cargando...',
  );

  final engine = ref.watch(scoreEngineProvider);
  
  return engine.calculateIMR(
    user,
    fastingHours: state.fastingHoursRaw,
    weeklyAdherence: 0.0, // Nota: La adherencia semanal se integra en StreakNotifier
    exerciseMin: state.exerciseMinutesRaw,
    sleepHours: state.sleepHoursRaw,
    lastMealTime: state.lastMealTime,
    nutritionScore: state.nutritionScoreRaw,
  );
});


