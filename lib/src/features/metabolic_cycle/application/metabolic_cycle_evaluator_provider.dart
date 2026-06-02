// SPEC-149 §RF-149-04 + §RF-149-06: provider side-effect que evalúa el
// ciclo metabólico continuamente y dispara cierre cuando aplica.
//
// Escucha dos fuentes:
//   1. metabolicPulseProvider (cada 10s) — chequeo periódico de los
//      triggers pasivos (fallback3hAfterWindow, fallbackAbsolute,
//      fallbackCalendar, fallbackSleepDetected).
//   2. fastingProvider — transición a isActive=true detecta inicio
//      explícito de nuevo ayuno (trigger manualNextFasting).
//
// Side-effect-only. Para que ejecute, el Dashboard hace `ref.watch`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/application/eating_window_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_service.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final metabolicCycleEvaluatorProvider = Provider<void>((ref) {
  // Tick periódico cada 10s.
  ref.listen<AsyncValue<DateTime>>(
    metabolicPulseProvider,
    (_, next) {
      next.whenData((now) => _evaluate(ref, now));
    },
  );

  // Transición isActive false→true del ayuno: el usuario explícitamente
  // inició un nuevo ciclo. Disparamos evaluación con flag.
  ref.listen<FastingState>(
    fastingProvider,
    (previous, next) {
      if (previous != null && !previous.isActive && next.isActive) {
        _evaluate(
          ref,
          DateTime.now(),
          newFastingTriggered: true,
          newFastingAt: next.startTime,
        );
      }
    },
  );
});

Future<void> _evaluate(
  Ref ref,
  DateTime now, {
  bool newFastingTriggered = false,
  DateTime? newFastingAt,
}) async {
  final account = ref.read(authStateProvider).value;
  if (account == null) return;

  final user = ref.read(currentUserStreamProvider).valueOrNull;
  if (user == null) return;

  final streak = ref.read(streakProvider);
  final today = streak.todayEntry;

  // Magnitudes del día actual (StreakEntry). Si no hay, todo en 0.
  final magnitudes = CycleMagnitudes(
    fastingMagnitude: today?.fastingMagnitude ?? 0,
    sleepQualityScore: today?.sleepQualityScore ?? 0,
    hydrationMagnitude: today?.hydrationMagnitude ?? 0,
    exerciseMagnitude: today?.exerciseMagnitude ?? 0,
    nutritionMagnitude: today?.nutritionMagnitude ?? 0,
  );

  final pillarsCompleted = CyclePillarsCompleted(
    fasting: today?.fastingCompleted ?? false,
    sleep: today?.sleepCompleted ?? false,
    hydration: today?.hydrationCompleted ?? false,
    exercise: today?.exerciseLogged ?? false,
    nutrition: today?.nutritionLogged ?? false,
  );

  final dailyScore = ref.read(dailyScoreProvider);
  final eatingWindow = ref.read(eatingWindowProvider);
  final sleepState = ref.read(sleepProvider);

  // Sleep detectado tras última comida: si sleepState tiene un log con
  // fellAsleep populado, lo marcamos como detectado. Conservador para
  // evitar disparos espurios.
  final sleepDetected = sleepState.lastLog != null;

  final input = MetabolicCycleEvaluationInput(
    now: now,
    currentProtocol: user.fastingProtocol,
    currentDailyScore: dailyScore,
    currentMagnitudes: magnitudes,
    currentPillarsCompleted: pillarsCompleted,
    expectedWindowCloseTime: eatingWindow?.windowEnd,
    lastMealTime: null, // Reservado para Bloque E (lectura de nutrition).
    sleepDetectedAfterLastMeal: sleepDetected,
    newFastingStartedExplicitly: newFastingTriggered,
    newFastingStartedAt: newFastingAt,
    actualWindowClosedAt: null,
    recentInsightIds: const {},
    tzOffsetMinutes: now.timeZoneOffset.inMinutes,
  );

  try {
    await ref
        .read(metabolicCycleServiceProvider)
        .evaluateAndApply(userId: account.uid, input: input);
  } catch (e) {
    AppLogger.warning('[metabolicCycleEvaluator] eval falló: $e', e);
  }
}
