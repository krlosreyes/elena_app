// SPEC-141 §RF-141-12 (2026-06-05): provider derivado del IMR
// longitudinal en vivo.
//
// Combina los 3 inputs canónicos:
//   1. `currentUserStreamProvider` → UserModel (estructura)
//   2. `metabolicStateProvider` → MetabolicState (ya consumido por
//      imrProvider, incluye metabolicCoherence)
//   3. `streakProvider.history` → List<StreakEntry> (behaviorTrend +
//      adherenceTrend)
//
// Y delega el cómputo a `ScoreEngine.calculateLongitudinalIMR` (función
// pura agregada en SPEC-141 Bloque A).
//
// Importante: este provider expone el IMR longitudinal EN VIVO. La
// "cadencia semanal" de SPEC-141 v1.1 §RF-141-12 NO aplica al cálculo
// (es cheap, sin red), aplica solo a la PERSISTENCIA en Firestore.
// La persistencia con cadencia y gatillos va al `WeeklyImrSnapshotService`
// que se introduce en SPEC-141 Bloque C.
//
// Diseño: provider familiar al `imrProvider` legacy (mismo patrón
// Riverpod, mismo shape `IMRv2Result`), pero los campos `longitudinalScore`,
// `subscoreBehaviorTrend`, `subscoreAdherence`, `subscoreCoherence` ahora
// se pueblan. Consumidores legacy del IMR diario siguen funcionando
// porque los campos legacy (`totalScore`, `zone`, etc.) se preservan.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// SPEC-141: provider derivado del IMR longitudinal. Live (sin
/// cadencia semanal — esa solo aplica a persistencia).
final longitudinalImrProvider = Provider<IMRv2Result>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return IMRv2Result.empty();
  final state = ref.watch(metabolicStateProvider);
  final history = ref.watch(streakProvider).history;
  return ScoreEngine().calculateLongitudinalIMR(user, state, history);
});
