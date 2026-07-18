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

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/daily_reset_service.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/application/eating_window_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/core/services/notification_router.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/cycle_score_computer.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_service.dart';
import 'package:elena_app/src/features/metabolic_cycle/data/metabolic_cycle_repository_impl.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart'
    show displayDailyScoreProvider;
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/utils/fasting_protocol.dart';

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

  // SPEC-225 (2026-06-15): snapshot pre-cierre de StreakState.
  //
  // Problema: cuando el usuario inicia un nuevo ayuno, StreakNotifier
  // escucha fastingProvider y llama _evaluateToday() ANTES de que el
  // evaluador del ciclo capture el snapshot. Esto establece
  // fastingMagnitude = 0 (nuevo ayuno recién iniciado = 0s de duración),
  // y el ciclo se guarda con score incorrecto.
  //
  // Solución: aprovechar la cascada de Riverpod. Cuando fastingProvider
  // cambia, StreakNotifier actualiza su estado (streakProvider cambia) →
  // los listeners de streakProvider se disparan con (previous = streak
  // correcto, next = streak reseteado) → luego corre nuestro listener de
  // fastingProvider. Guardamos `previous` en una variable local para
  // pasarla a _evaluate como snapshot pre-cierre.
  StreakState? preClosureStreakSnapshot;
  ref.listen<StreakState>(
    streakProvider,
    (previous, next) {
      if (previous != null) preClosureStreakSnapshot = previous;
    },
    fireImmediately: false,
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
          // SPEC-225: pasar el streak del ciclo que cierra — ya contiene
          // las magnitudes correctas antes de que se reseteen.
          preClosureStreak: preClosureStreakSnapshot,
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
  // SPEC-225: streak capturado antes de que StreakNotifier resetee
  // fastingMagnitude al iniciar el nuevo ayuno.
  StreakState? preClosureStreak,
}) async {
  final account = ref.read(authStateProvider).value;
  if (account == null) return;

  final user = ref.read(currentUserStreamProvider).valueOrNull;
  if (user == null) return;

  // SPEC-225 (2026-06-15): al cerrar por nuevo ayuno, usar el StreakEntry
  // del ciclo que CIERRA, no el del ciclo recién abierto.
  //
  // Cuando el usuario toca "Iniciar ayuno", StreakNotifier._evaluateToday()
  // ya corrió y puso fastingMagnitude = 0 (el nuevo ayuno tiene duración 0).
  // Si leemos streakProvider ahora, capturamos ese 0 en lugar del progreso
  // real del día que terminó. preClosureStreak preserva el estado anterior.
  final StreakState streakForSnapshot = (newFastingTriggered && preClosureStreak != null)
      ? preClosureStreak
      : ref.read(streakProvider);
  final today = streakForSnapshot.todayEntry;

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

  // SPEC-BUG (2026-06-13): usar displayDailyScoreProvider (cycle-aware,
  // CycleScoreComputer) en lugar del legacy dailyScoreProvider (calendario).
  // El Dashboard muestra displayDailyScoreProvider; el ciclo debe guardar
  // el MISMO valor que el usuario ve, no un cálculo diferente.
  //
  // SPEC-225 (2026-06-15): cuando cerramos por nuevo ayuno, el
  // displayDailyScoreProvider ya refleja el nuevo ciclo (fastingMagnitude=0).
  // Recalculamos desde las magnitudes del preClosureStreak usando el mismo
  // CycleScoreComputer para garantizar consistencia con lo que el usuario vio.
  final int dailyScore;
  if (newFastingTriggered && preClosureStreak != null) {
    dailyScore = CycleScoreComputer.compute(
      fastingMagnitude: today?.fastingMagnitude,
      sleepQualityScore: today?.sleepQualityScore,
      hydrationMagnitude: today?.hydrationMagnitude,
      exerciseMagnitude: today?.exerciseMagnitude,
      nutritionMagnitude: today?.nutritionMagnitude,
    );
    AppLogger.debug(
      '[metabolicCycleEvaluator] snapshot pre-cierre: '
      'score=$dailyScore '
      'fasting=${today?.fastingMagnitude?.toStringAsFixed(2)} '
      'hydration=${today?.hydrationMagnitude?.toStringAsFixed(2)} '
      'exercise=${today?.exerciseMagnitude?.toStringAsFixed(2)} '
      'nutrition=${today?.nutritionMagnitude?.toStringAsFixed(2)} '
      'sleep=${today?.sleepQualityScore?.toStringAsFixed(2)}',
    );
  } else {
    // ref.read evita dependencia reactiva — sin riesgo de ciclo.
    dailyScore = ref.read(displayDailyScoreProvider);
  }

  // SPEC-227 + HOTFIX SCORE (2026-06-23): stampear liveScore como el valor
  // ACTUAL del Score del Día, no como high water mark.
  //
  // El HWM anterior (math.max) fue diseñado para que el score de cierre
  // reflejara "el mejor momento del ciclo". El problema: también inflaba
  // el score en la UI cuando nutritionMagnitude bajaba (ver fix en
  // streak_notifier.dart). Con el fix del nutritionMagnitude, el
  // displayDailyScoreProvider ya es coherente con lo que el usuario ve en
  // cada PillarCard. El liveScore en Firestore debe reflejar el estado real
  // del ciclo, no el pico histórico.
  //
  // Solo en pulsos periódicos — en el path manualNextFasting SPEC-225 ya
  // captura el score correcto desde preClosureStreak.
  //
  // Firestore escribe en caché local al instante (SPEC-206), por lo que
  // fetchOpenCycle() del service leerá liveScore correcto incluso offline.
  if (!newFastingTriggered) {
    final openCycleSnap =
        ref.read(currentMetabolicCycleProvider).valueOrNull;
    if (openCycleSnap != null) {
      if (openCycleSnap.liveScore != dailyScore) {
        unawaited(
          ref
              .read(metabolicCycleRepositoryProvider)
              .updateLiveScore(
                  account.uid, openCycleSnap.cycleId, dailyScore)
              .catchError((Object e) {
            AppLogger.debug(
                '[evaluator] updateLiveScore falló (offline?): $e');
          }),
        );
      }
    }
  }

  final eatingWindow = ref.read(eatingWindowProvider);
  final sleepState = ref.read(sleepProvider);
  final nutritionState = ref.read(nutritionProvider);

  // SPEC-174 (2026-06-04): timestamp de la última comida del usuario.
  // Activa el trigger `fallbackSleepDetected` (resolver:75) que antes
  // jamás disparaba porque pasábamos `lastMealTime: null` hardcoded.
  // `todayLogs` ya viene cycle-aware post SPEC-149.2 (filtrado por
  // ventana del ciclo abierto). El `lastOrNull?.timestamp` da el
  // momento exacto de la última comida dentro del ciclo en curso.
  final lastMealTime = nutritionState.todayLogs.isEmpty
      ? null
      : nutritionState.todayLogs.last.timestamp;

  // SPEC-245 BUG-FIX (2026-07-07): `sleepDetected` requiere que el sueño
  // más reciente haya comenzado DESPUÉS de la última comida del ciclo.
  //
  // Bug original: `lastLog != null` siempre era true cuando había cualquier
  // log histórico, pero era un falso positivo — podía ser sueño de la noche
  // anterior. Tras SPEC-245 (import de etapas Apple Watch más agresivo),
  // `lastLog` siempre existe → `fallbackSleepDetected` se disparaba durante
  // el día al acumular 2h desde la última comida, cerrando el ciclo y
  // mandando la notificación "Tu día metabólico cerró" a deshora.
  //
  // Fix: solo marcar como detectado si `fellAsleep > lastMealTime`. Esto
  // garantiza semántica correcta: el usuario comió, luego se fue a dormir
  // → fin del ciclo. Si no hubo comida en el ciclo (`lastMealTime = null`),
  // el trigger queda desactivado (usuario en ayuno completo — no cerrar).
  final lastSleepLog = sleepState.lastLog;
  final sleepDetected = lastSleepLog != null &&
      lastMealTime != null &&
      lastSleepLog.fellAsleep.isAfter(lastMealTime);

  // SPEC-229 BUG-B: Guard contra fallback3hAfterWindow prematuro.
  //
  // Problema: cuando hay ayuno activo, EatingWindowState.compute() devuelve
  // un windowEnd basado en el schedule ÓPTIMO de HOY (e.g., hoy 6pm para
  // 16:8). Pero si el usuario inició ayuno a las 5pm, la ventana de
  // alimentación de ESTE ciclo aún no abrió — abrirá mañana tras completar
  // 16h de ayuno. Sin embargo, el resolver ve now(9pm) - windowEnd(6pm) = 3h
  // → dispara fallback3hAfterWindow → cierre prematuro a las ~6h de ciclo.
  //
  // Fix: si el ciclo lleva menos tiempo que targetFastingHours, la ventana
  // de alimentación del ciclo ACTUAL no ha iniciado → windowEnd no aplica.
  // Anulamos effectiveWindowClose para que el resolver no dispare el fallback.
  DateTime? effectiveWindowClose = eatingWindow?.windowEnd;
  final openCycleForGuard =
      ref.read(currentMetabolicCycleProvider).valueOrNull;
  if (openCycleForGuard != null && effectiveWindowClose != null) {
    final targetHours =
        fastingHoursForProtocol(openCycleForGuard.fastingProtocol);
    if (targetHours != null &&
        now.difference(openCycleForGuard.startedAt) <
            Duration(hours: targetHours)) {
      AppLogger.debug(
        '[evaluator] SPEC-229-B: ciclo tiene '
        '${now.difference(openCycleForGuard.startedAt).inHours}h, '
        'target=${targetHours}h → ignorando windowEnd stale',
      );
      effectiveWindowClose = null;
    }
  }

  // SPEC-245 (2026-07-07): Guard adicional contra fallback3hAfterWindow
  // durante ayunos extendidos voluntarios.
  //
  // Problema: un usuario haciendo un ayuno de 33h con protocolo OMAD (23h)
  // supera el targetFastingHours guard anterior. A las 26h (23h + 3h grace)
  // el fallback3hAfterWindow dispara y corta el ciclo aunque el usuario
  // aún está en su ayuno consciente.
  //
  // Fix: si fastingProvider.isActive = true, el usuario está explícitamente
  // en ayuno → la ventana de alimentación definitivamente no aplica todavía.
  // Anulamos effectiveWindowClose independientemente de la duración del ciclo.
  if (effectiveWindowClose != null) {
    final fastingState = ref.read(fastingProvider);
    if (fastingState.isActive) {
      AppLogger.debug(
        '[evaluator] SPEC-245: ayuno activo → ignorando windowEnd '
        '(ayuno extendido voluntario)',
      );
      effectiveWindowClose = null;
    }
  }

  final input = MetabolicCycleEvaluationInput(
    now: now,
    currentProtocol: user.fastingProtocol,
    currentDailyScore: dailyScore,
    currentMagnitudes: magnitudes,
    currentPillarsCompleted: pillarsCompleted,
    expectedWindowCloseTime: effectiveWindowClose,
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
    // 18-jul: triggerDailyReset ya NO acepta flushClosingDay — ese flush
    // es exclusivamente calendárico (daily_summary legacy, SPEC-138/
    // SPEC-192.1) y vive en DailyResetNotifier.triggerCalendarSafetyNet,
    // separado del reset de pilares+racha. Flushear daily_summary desde
    // acá (a media tarde, con el cierre de un ciclo) lo dejaría
    // incompleto — son dos relojes distintos a propósito.
    if (result.hasClosure && result.hasOpening) {
      AppLogger.info(
        '[metabolicCycleEvaluator] cierre cíclico detectado — '
        'reseteando pilares in-memory para el nuevo ciclo',
      );
      await ref.read(dailyResetProvider.notifier).triggerDailyReset();
    }

    // SPEC-202.2: si el cierre fue por iniciar el próximo ayuno (acción
    // consciente), exponerlo como "momento" para que el Dashboard lo presente
    // de inmediato — el feedback del día anterior ligado al gesto, no como
    // tarjeta pasiva que aparece desconectada en la mañana.
    final closed = result.closed;
    if (closed != null &&
        closed.closureReason == ClosureReason.manualNextFasting &&
        closed.feedback != null) {
      ref.read(cycleClosureMomentProvider.notifier).state = closed;
    }

    // SPEC-235: notificación push al cierre AUTOMÁTICO del ciclo metabólico.
    // manualNextFasting queda excluido — el usuario lo inició conscientemente
    // y ya ve feedback visual; una notificación redundante genera ruido.
    final closureReason = closed?.closureReason;
    if (closureReason != null &&
        closureReason != ClosureReason.manualNextFasting) {
      // SPEC-241 Bug 300: scheduleAt +60s en vez de showImmediate.
      // showImmediate() falla si la app volvió de background o fue terminada.
      // Con +60s el sistema operativo agenda la notificación de forma
      // confiable, incluso si la app cierra inmediatamente después.
      unawaited(
        NotificationService.scheduleAt(
          id: NotificationIds.autoCycleClosure,
          title: 'Tu día metabólico cerró',
          body: _autoCycleClosureBody(closureReason),
          scheduledTime: DateTime.now().add(const Duration(seconds: 60)),
          repeatsDaily: false,
          payload: NotificationRouter.circadianPayload(),
        ).catchError((Object e) {
          AppLogger.debug('[evaluator] SPEC-241 notif falló: $e');
        }),
      );
    }
  } catch (e) {
    AppLogger.warning('[metabolicCycleEvaluator] eval falló: $e', e);
  }
}

/// SPEC-235: copia cálida por motivo de cierre automático.
/// Tono: humano, empático, sin culpa. Ver feedback_notification_tone.md.
String _autoCycleClosureBody(ClosureReason reason) {
  switch (reason) {
    case ClosureReason.fallback3hAfterWindow:
      return 'Cerraste bien tu ventana. Mañana seguimos sumando 💪';
    case ClosureReason.fallbackSleepDetected:
      return 'Detectamos que te fuiste a descansar. ¡Buen cierre del día!';
    case ClosureReason.fallbackAbsolute:
      return 'El día metabólico cerró. Mañana es otra oportunidad. 🌅';
    case ClosureReason.fallbackCalendar:
      return 'Nuevo día, nueva energía. Tu ciclo de ayer ya cerró.';
    case ClosureReason.protocolChanged:
      return 'Actualizaste tu protocolo. El ciclo anterior cerró automáticamente.';
    case ClosureReason.manualNextFasting:
      // No debería llegar aquí — filtrado antes de llamar a este helper.
      return '';
  }
}
