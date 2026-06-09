// SPEC-194 inc2b — wiring Riverpod del motor de coaching.
//
// Glue delgado y SOLO-LECTURA sobre providers existentes (weekly coaching,
// goals, engagement) + CircadianEngine. La lógica vive en las funciones puras
// ya testeadas (builder, generadores, scorer). Nada existente cambia → cero
// regresión; estos providers no se instancian hasta que la UI (inc3) los watch.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/engine/circadian_engine.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_provider.dart';
import 'package:elena_app/src/features/adaptive/application/adaptive_engine.dart';
import 'package:elena_app/src/features/analysis/application/weekly_coaching_provider.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';
import 'package:elena_app/src/features/coaching/application/adaptive_generator.dart';
import 'package:elena_app/src/features/coaching/application/circadian_generator.dart';
import 'package:elena_app/src/features/coaching/application/coaching_completion_service.dart';
import 'package:elena_app/src/features/coaching/application/coaching_fatigue_notifier.dart';
import 'package:elena_app/src/features/coaching/application/coaching_feedback_generator.dart';
import 'package:elena_app/src/features/coaching/application/orchestrator_generator.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_feedback.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/coaching/application/coaching_snapshot_builder.dart';
import 'package:elena_app/src/features/coaching/application/weak_pillar_generator.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_snapshot.dart';
import 'package:elena_app/src/features/coaching/domain/scoring/coaching_scorer.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';

/// Estado del usuario para el motor de coaching (input del scorer).
final coachingSnapshotProvider = Provider.autoDispose<CoachingSnapshot>((ref) {
  final now = DateTime.now();
  final weekly = ref.watch(weeklyCoachingProvider).valueOrNull;
  final activeGoalTypes =
      ref.watch(goalsProvider).values.where((g) => g.isActive).map((g) => g.type);
  final engagement = ref.watch(engagementProvider).level;
  // Adenda §8: factor circadiano en vivo (el mismo que entra al IMR).
  final liveCircadianScore =
      ref.watch(metabolicStateProvider).circadianAlignment;
  // RF-2.5: inputs anti-fatiga desde el store persistente (antes vacíos →
  // el motor nunca suprimía acciones ignoradas para un usuario real).
  final fatigue = ref.watch(coachingFatigueProvider);

  return CoachingSnapshotBuilder.build(
    currentPhase: CircadianEngine.currentPhase(now),
    weekly: weekly,
    activeGoalTypes: activeGoalTypes,
    engagement: engagement,
    minutesToIntestinalLock: CircadianEngine.timeUntilLock(now).inMinutes,
    minutesToSleepOnset: CircadianEngine.timeUntilSleepOnset(now).inMinutes,
    liveCircadianScore: liveCircadianScore,
    ignoredStreakByActionId: fatigue.ignoredStreakByActionId,
    shownTodayActionIds: fatigue.shownTodayActionIds,
  );
});

/// Candidatos de las fuentes activas (MVP: pilar débil + circadiano).
/// Las demás fuentes (orchestrator, adaptive) se suman en SPEC-194.next.
final coachingCandidatesProvider =
    Provider.autoDispose<List<CoachingAction>>((ref) {
  final now = DateTime.now();
  final weekly = ref.watch(weeklyCoachingProvider).valueOrNull;
  final phase = CircadianEngine.currentPhase(now);
  final minutesToLock = CircadianEngine.timeUntilLock(now).inMinutes;

  return [
    if (weekly != null) ...WeakPillarGenerator.generate(weekly),
    ...CircadianGenerator.generate(phase, minutesToIntestinalLock: minutesToLock),
    ...AdaptiveGenerator.generate(ref.watch(adaptiveProvider)),
    ...OrchestratorGenerator.generate(
      ref.watch(orchestratorProvider).recommendations,
    ),
  ];
});

/// La "siguiente mejor acción" (+ secundaria opcional) que consume la UI.
final coachingSelectionProvider =
    Provider.autoDispose<CoachingSelection>((ref) {
  final snapshot = ref.watch(coachingSnapshotProvider);
  final candidates = ref.watch(coachingCandidatesProvider);
  return CoachingScorer.select(candidates, snapshot);
});

/// SPEC-194 RF-194-05 — feedback de cierre. Null si no hay cierre sin leer o
/// si no había una recomendación activa que reflejar. `improved` se deriva del
/// delta cycle-over-cycle del pilar recomendado (weekly cycle-aware).
final coachingClosureFeedbackProvider =
    Provider.autoDispose<CoachingFeedback?>((ref) {
  if (!ref.watch(hasUnreadCycleClosureProvider)) return null;

  final action = ref.read(coachingCompletionProvider).activeAction;
  if (action == null) return null;

  final completed = ref.read(coachingCompletionProvider).isCompleted(action.id);
  final weekly = ref.watch(weeklyCoachingProvider).valueOrNull;
  final delta = weekly == null ? null : _deltaForPillar(weekly, action.pillar);

  // Adenda §7: lectura circadiana del cierre.
  final closed = ref.watch(lastClosedMetabolicCycleProvider).valueOrNull;

  return CoachingFeedbackGenerator.generate(
    recommendedPillar: action.pillar,
    completed: completed,
    improved: delta == null ? null : delta > 0,
    circadianClosedBeforeLock: _closedBeforeLock(closed),
  );
});

/// Adenda §7: ¿la ventana de comida cerró ANTES del bloqueo intestinal (21:30)?
/// Solo es señal fiable cuando el cierre fue por inicio explícito del siguiente
/// ayuno (`manualNextFasting`) — ahí `closedAt` ≈ el cierre real de la ventana.
/// Para cierres automáticos (fallbacks) o ciclo abierto → null (sin lectura).
bool? _closedBeforeLock(MetabolicCycle? c) {
  final closedAt = c?.closedAt;
  if (c == null || closedAt == null) return null;
  if (c.closureReason != ClosureReason.manualNextFasting) return null;
  final local = closedAt.toUtc().add(Duration(minutes: c.tzOffsetMinutes));
  final minutesOfDay = local.hour * 60 + local.minute;
  const lockMinutes = 21 * 60 + 30; // 21:30
  return minutesOfDay < lockMinutes;
}

double? _deltaForPillar(WeeklyCoachingInsight w, Pillar p) => switch (p) {
      Pillar.fasting => w.fastingDelta,
      Pillar.sleep => w.sleepDelta,
      Pillar.hydration => w.hydrationDelta,
      Pillar.exercise => w.exerciseDelta,
      Pillar.nutrition => w.mealsDelta,
    };
