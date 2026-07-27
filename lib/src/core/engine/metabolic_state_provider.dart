import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/engine/metabolic_state_builder.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
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
  // SPEC-209: fuente única de sueño — sleepProvider (antes: globalSleepProvider).
  // Elimina la doble suscripción Firestore y el bug de datos del usuario
  // anterior tras logout.
  final sleepState = ref.watch(sleepProvider);
  final sleepHours = sleepState.lastLog != null
      ? sleepState.lastLog!.duration.inMinutes / 60.0
      : 0.0;
  // SPEC-69: el último log alimenta dimensiones multidimensionales
  // (gap metabólico, latencia, despertares, percepción subjetiva) al
  // SleepQualityCalculator. Si es null, se usa solo `sleepHours`.
  final lastSleepLog = sleepState.lastLog;
  final exercise = ref.watch(exerciseProvider);
  final nutrition = ref.watch(nutritionProvider);
  final hydration = ref.watch(hydrationProvider);

  // SPEC-52 RF-52-04: weeklyAdherence real desde StreakNotifier.
  // `select` evita reconstruir cuando otros campos del StreakState cambian.
  final weeklyAdherence =
      ref.watch(streakProvider.select((s) => s.weeklyAdherence));
  // SPEC-53: calidad continua de los últimos 7 días, ya promediada por
  // StreakEngine sobre dailyQualityScore (SPEC-65).
  final weeklyQualityScore =
      ref.watch(streakProvider.select((s) => s.weeklyQualityScore));

  final user = userAsync.valueOrNull;
  if (user == null) return MetabolicState.empty();

  // Calcular maxFastingHoursToday desde el estado activo.
  // SPEC-52.1: el bloque que iteraba `todayFastingIntervalsProvider` se
  // eliminó porque ese provider nunca existió en el repo (deuda baseline).
  // Si en el futuro se requiere recuperar la duración de ayunos completados
  // hoy, será una SPEC dedicada con un repository de intervalos.
  //
  // I-01 (auditoría 2026-07-27): el valor se REDONDEA a la centésima de
  // hora (36 s). Sin redondeo, cada pulso de 10 s producía un
  // `fastingHoursRaw` distinto en el sexto decimal, `MetabolicState`
  // dejaba de ser igual al anterior pese a que nada observable había
  // cambiado, y toda la cadena reactiva —incluido el recálculo completo
  // del IMR— se disparaba 6 veces por minuto durante las 16 h del ayuno.
  //
  // La resolución que queda (36 s) es muy superior a la que necesita
  // cualquier consumidor del score: la sigmoide metabólica está centrada
  // en 14 h con ancho 1,5 h, así que 36 s son ruido. El cronómetro visible
  // del ayuno NO depende de este valor —se dibuja con su propio reloj—,
  // de modo que la cuenta atrás sigue viéndose fluida.
  double maxFastingHoursToday = 0.0;
  if (fasting.isActive && fasting.startTime != null) {
    final horasExactas = now.difference(fasting.startTime!).inSeconds / 3600.0;
    maxFastingHoursToday = (horasExactas * 100).roundToDouble() / 100;
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
    weeklyQualityScore: weeklyQualityScore,
    lastSleepLog: lastSleepLog,
    // SPEC-72.9: el reloj se inyecta — el builder no llama DateTime.now()
    // internamente. Aquí pasamos el pulso de 10s para que el state sea
    // determinista entre builds consecutivos del mismo tick.
    now: now,
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
