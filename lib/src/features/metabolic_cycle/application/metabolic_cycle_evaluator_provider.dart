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
import 'package:elena_app/src/core/services/daily_reset_service.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/application/eating_window_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_service.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final metabolicCycleEvaluatorProvider = Provider<void>((ref) {
  // SPEC-174 (2026-06-04): primer tick INMEDIATO al montar el provider.
  // `metabolicPulseProvider` (`Stream.periodic` cada 10s) no emite valor
  // inicial — antes el evaluator esperaba 10s tras montar para evaluar.
  // Si el usuario abría con un ciclo cerrable pendiente y cerraba la
  // app en <10s, no se disparaba el cierre. `Future.microtask` da tiempo
  // a Riverpod a completar el setup antes de leer providers.
  Future.microtask(() => _evaluate(ref, DateTime.now()));

  // Tick periódico cada 10s.
  ref.listen<AsyncValue<DateTime>>(
    metabolicPulseProvider,
    (_, next) {
      next.whenData((now) => _evaluate(ref, now));
    },
  );

  // Transición isActive false→true del ayuno.
  //
  // SPEC-183 (2026-06-05): la transición SOLO debe crear ciclo
  // metabólico nuevo si fue causada por acción consciente del usuario
  // (`activationSource == userInitiated`). El bootstrap del
  // FastingNotifier al arrancar la app también dispara una transición
  // false→true al restaurar state desde Firestore, pero esa NO debe
  // crear ciclo automático (causa el bug del ciclo huérfano con
  // `startedAt = horaDeBoot`).
  ref.listen<FastingState>(
    fastingProvider,
    (previous, next) {
      final transitioned =
          previous != null && !previous.isActive && next.isActive;
      final isUserInitiated =
          next.activationSource == FastingActivationSource.userInitiated;
      if (transitioned && isUserInitiated) {
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
  final nutritionState = ref.read(nutritionProvider);

  // Sleep detectado tras última comida: si sleepState tiene un log con
  // fellAsleep populado, lo marcamos como detectado. Conservador para
  // evitar disparos espurios.
  final sleepDetected = sleepState.lastLog != null;

  // SPEC-174 (2026-06-04): timestamp de la última comida del usuario.
  // Activa el trigger `fallbackSleepDetected` (resolver:75) que antes
  // jamás disparaba porque pasábamos `lastMealTime: null` hardcoded.
  // `todayLogs` ya viene cycle-aware post SPEC-149.2 (filtrado por
  // ventana del ciclo abierto). El `lastOrNull?.timestamp` da el
  // momento exacto de la última comida dentro del ciclo en curso.
  final lastMealTime = nutritionState.todayLogs.isEmpty
      ? null
      : nutritionState.todayLogs.last.timestamp;

  final input = MetabolicCycleEvaluationInput(
    now: now,
    currentProtocol: user.fastingProtocol,
    currentDailyScore: dailyScore,
    currentMagnitudes: magnitudes,
    currentPillarsCompleted: pillarsCompleted,
    expectedWindowCloseTime: eatingWindow?.windowEnd,
    lastMealTime: lastMealTime,
    sleepDetectedAfterLastMeal: sleepDetected,
    newFastingStartedExplicitly: newFastingTriggered,
    newFastingStartedAt: newFastingAt,
    actualWindowClosedAt: null,
    recentInsightIds: const {},
    tzOffsetMinutes: now.timeZoneOffset.inMinutes,
  );

  try {
    final result = await ref
        .read(metabolicCycleServiceProvider)
        .evaluateAndApply(userId: account.uid, input: input);

    // SPEC-149.1 Bug 1b: si el ciclo cerró Y abrió uno nuevo, resetear
    // los pilares in-memory para que el contador del nuevo ciclo arranque
    // visualmente en 0. El ancla del reset deja de ser solo medianoche
    // calendárica — ahora también el momento del cierre del ciclo, sea
    // la hora que sea.
    //
    // flushClosingDay: false porque daily_summary (SPEC-138) sigue siendo
    // por día calendárico. Flushearlo a media tarde lo dejaría incompleto.
    if (result.hasClosure && result.hasOpening) {
      AppLogger.info(
        '[metabolicCycleEvaluator] cierre cíclico detectado — '
        'reseteando pilares in-memory para el nuevo ciclo',
      );
      await ref
          .read(dailyResetProvider.notifier)
          .triggerDailyReset(flushClosingDay: false);
    }
  } catch (e) {
    AppLogger.warning('[metabolicCycleEvaluator] eval falló: $e', e);
  }
}
