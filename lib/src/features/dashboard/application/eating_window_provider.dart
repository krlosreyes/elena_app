// SPEC-95: provider que computa el `EatingWindowState` reactivo.
//
// Combina:
//   - lastFastingIntervalProvider (último FastingInterval persistido)
//   - currentUserStreamProvider   (protocolo + firstMealGoal)
//   - nutritionProvider           (18-jul: primer registro real de hoy)
//   - metabolicPulseProvider      (refresca cada 10s, no cada segundo)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart'
    show lastFastingIntervalProvider;
import 'package:elena_app/src/features/dashboard/domain/eating_window_state.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart'
    show nutritionProvider;
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Provider derivado: `EatingWindowState` actualizado al ritmo del
/// metabolic pulse (10s). Devuelve `null` mientras los inputs siguen
/// cargando — el caller debe manejar ese caso.
final eatingWindowProvider = Provider<EatingWindowState?>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return null;

  final interval = ref.watch(lastFastingIntervalProvider).valueOrNull;

  // 18-jul (repro Carlos): un usuario nuevo que registra su primer
  // desayuno espera que el anillo/hitos de comida arranquen EN esa hora
  // real, no en `firstMealGoal` del onboarding ni en un horario "óptimo"
  // teórico. `nutritionProvider.todayLogs` ya es cycle-aware (Día
  // Metabólico) — reusamos esa misma ventana en vez de recalcularla acá.
  // Ver doc completa en `EatingWindowState.compute`.
  final todayLogs = ref.watch(nutritionProvider).todayLogs;
  final firstMealLoggedToday = MealIntervalRules.firstMealOf(todayLogs);

  // Watcheamos el pulse para refrescar el cómputo cada 10s sin tener
  // que recalcular en cada frame.
  ref.watch(metabolicPulseProvider);

  final now = DateTime.now();
  final state = EatingWindowState.compute(
    lastInterval: interval,
    user: user,
    now: now,
    firstMealLoggedToday: firstMealLoggedToday,
  );

  // PROD-04 fix (21-jul, auditoría técnica): `windowStart` puede ser una
  // PROYECCIÓN teórica (`isProjected`, sin ayuno cerrado ni comida
  // registrada). Si `now` ya superó esa proyección, mostrarla pintaría
  // un "recorrido" fabricado para un usuario que no registró nada — el
  // caso reportado por Carlos el mismo día del alta de cuenta. Se
  // devuelve `null` en ese caso, igual que cuando los providers siguen
  // cargando (`circadian_clock.dart` ya omite la capa cuando es null).
  // Si `now` todavía no llega a la proyección, sí se expone: es una
  // cuenta regresiva honesta hacia una meta futura, no progreso
  // inventado.
  if (state.isProjected && !now.isBefore(state.windowStart)) {
    return null;
  }
  return state;
});
