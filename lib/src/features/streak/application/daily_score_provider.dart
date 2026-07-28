// SPEC-140: providers que exponen el "Score del Día" al UI.
//
// El score es un entero 0-100 derivado del `dailyQualityScore` continuo
// del `StreakEntry` del día actual. Resuelve la pregunta del usuario
// "por qué el score no llega a 100 cuando hago todo perfecto" — esta
// métrica SÍ llega a 100 cuando los 5 pilares están al máximo.
//
// Diferencia explícita con el IMR (Análisis screen, badge de Perfil):
//   - Score del Día: motivacional, alcanza 100, refleja "cómo viví hoy".
//   - IMR: longitudinal (SPEC-141 post-implementación), refleja "estado
//     metabólico de fondo", se mueve en semanas/meses.
//
// La lógica matemática vive en funciones puras `_computeDailyScore` y
// `_computeDailyScoreDelta` para testing sin Riverpod. Los providers
// son wrappers thin que watchean `streakProvider`.
//
// SPEC-171 (2026-06-04): se agregan `displayDailyScoreProvider` y
// `displayDailyScoreDeltaProvider` que anclan al ciclo metabólico
// cuando hay uno abierto con protocolo conocido. El header del
// Dashboard usa los `display*`; el `dailyScoreProvider` legacy se
// mantiene intacto porque lo consume el evaluador del ciclo (sino
// se generaría dependencia circular). Detalle: `docs/SPEC-171`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// SPEC-215: ya no importa NotificationScheduler para obtener horas de protocolo.
import 'package:elena_app/src/features/metabolic_cycle/application/cycle_score_computer.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/shared/utils/fasting_protocol.dart';

/// SPEC-140: cómputo puro del Score del Día desde la entrada de hoy.
/// Expuesto público para tests directos sin necesidad de ProviderContainer.
int computeDailyScore(StreakEntry? today) {
  if (today == null) return 0;
  return (today.dailyQualityScore * 100).round().clamp(0, 100);
}

/// SPEC-140: cómputo puro del delta vs ayer. Retorna `null` cuando no
/// hay día previo en el historial.
///
/// El `history` debe estar ordenado descendente (igual que el shape
/// que produce `StreakNotifier` — index 0 = hoy, index 1 = ayer).
int? computeDailyScoreDelta(List<StreakEntry> history) {
  if (history.length < 2) return null;
  final todayScore = (history.first.dailyQualityScore * 100).round();
  final yesterdayScore = (history[1].dailyQualityScore * 100).round();
  return todayScore - yesterdayScore;
}

/// SPEC-140: Score del Día expuesto como entero 0-100. Reactivo al
/// `streakProvider`.
final dailyScoreProvider = Provider<int>((ref) {
  final streak = ref.watch(streakProvider);
  return computeDailyScore(streak.todayEntry);
});

/// SPEC-140: delta del Score del Día vs ayer. `null` si no hay día previo.
final dailyScoreDeltaProvider = Provider<int?>((ref) {
  final streak = ref.watch(streakProvider);
  return computeDailyScoreDelta(streak.history);
});

// ────────────────────────────────────────────────────────────────────────
// SPEC-171 (2026-06-04): providers de DISPLAY anclados al ciclo metabólico.
//
// Si hay ciclo abierto con protocolo conocido (no 'Ninguno'), el header
// del Dashboard muestra el score del ciclo en vivo via
// CycleScoreComputer. Sino, cae al provider legacy (calendárico).
//
// El delta cíclico se compara contra `lastClosedMetabolicCycleProvider`
// (el último ciclo cerrado persistido), no contra el `StreakEntry` de
// ayer.
// ────────────────────────────────────────────────────────────────────────

/// SPEC-171 §RF-171-02: Score del Día anclado al ciclo. Fallback al
/// calendárico cuando no hay ciclo o el protocolo es 'Ninguno'.
final displayDailyScoreProvider = Provider<int>((ref) {
  final cycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;
  final cycleHours =
      cycle == null ? null : fastingHoursForProtocol(cycle.fastingProtocol);

  if (cycle == null || cycleHours == null) {
    return ref.watch(dailyScoreProvider);
  }

  final today = ref.watch(streakProvider).todayEntry;
  return CycleScoreComputer.compute(
    fastingMagnitude: today?.fastingMagnitude,
    sleepQualityScore: today?.sleepQualityScore,
    hydrationMagnitude: today?.hydrationMagnitude,
    exerciseMagnitude: today?.exerciseMagnitude,
    nutritionMagnitude: today?.nutritionMagnitude,
  );
});

/// SPEC-171 §RF-171-03: delta vs último ciclo cerrado. `null` si no hay
/// ciclo cerrado previo persistido. En modo legacy (sin ciclo) cae a
/// `dailyScoreDeltaProvider`.
final displayDailyScoreDeltaProvider = Provider<int?>((ref) {
  final cycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;
  final cycleHours =
      cycle == null ? null : fastingHoursForProtocol(cycle.fastingProtocol);

  if (cycle == null || cycleHours == null) {
    return ref.watch(dailyScoreDeltaProvider);
  }

  final lastClosed = ref.watch(lastClosedMetabolicCycleProvider).valueOrNull;
  final lastScore = lastClosed?.dailyScore;
  if (lastScore == null) return null;

  final currentScore = ref.watch(displayDailyScoreProvider);
  return currentScore - lastScore;
});
