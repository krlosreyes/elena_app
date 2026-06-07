// SPEC-194 inc2 — tests de la capa application pura (sin Riverpod):
// generadores (weak-pillar, circadiano) y snapshot builder.

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';
import 'package:elena_app/src/features/coaching/application/circadian_generator.dart';
import 'package:elena_app/src/features/coaching/application/coaching_snapshot_builder.dart';
import 'package:elena_app/src/features/coaching/application/weak_pillar_generator.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

WeeklyCoachingInsight _insight({
  WeakPillar? weakest,
  double fasting = 0.9,
  double sleep = 0.2,
  double hydration = 0.5,
  double exercise = 0.8,
  double meals = 0.6,
  int daysWithData = 7,
}) {
  return WeeklyCoachingInsight(
    fastingAvg: fasting,
    sleepAvg: sleep,
    hydrationAvg: hydration,
    exerciseAvg: exercise,
    mealsAvg: meals,
    fastingDelta: null,
    sleepDelta: null,
    hydrationDelta: null,
    exerciseDelta: null,
    mealsDelta: null,
    weakest: weakest,
    daysWithData: daysWithData,
    rangeStart: DateTime(2026, 6, 1),
    rangeEnd: DateTime(2026, 6, 7),
  );
}

void main() {
  group('WeakPillarGenerator', () {
    test('genera la acción del pilar más débil reusando su copy', () {
      final actions = WeakPillarGenerator.generate(_insight(weakest: WeakPillar.sleep));
      expect(actions, hasLength(1));
      expect(actions.first.pillar, Pillar.sleep);
      expect(actions.first.id, 'weak_pillar_sleep');
      expect(actions.first.actionText, WeakPillar.sleep.suggestedAction);
    });

    test('sin pilar débil → sin candidatos', () {
      expect(WeakPillarGenerator.generate(_insight(weakest: null)), isEmpty);
    });

    test('meals mapea al pilar de nutrición', () {
      final actions = WeakPillarGenerator.generate(_insight(weakest: WeakPillar.meals));
      expect(actions.first.pillar, Pillar.nutrition);
    });
  });

  group('CircadianGenerator', () {
    test('motorFuerza → oportunidad de ejercicio', () {
      final actions = CircadianGenerator.generate(CircadianPhase.motorFuerza);
      expect(actions.any((a) => a.pillar == Pillar.exercise), isTrue);
    });

    test('bloqueo intestinal cercano → override duro de cerrar cocina', () {
      final actions = CircadianGenerator.generate(
        CircadianPhase.creatividad,
        minutesToIntestinalLock: 30,
      );
      final close = actions.firstWhere((a) => a.id == 'circadian_close_kitchen');
      expect(close.urgencyKind, ActionUrgencyKind.deadlineHard);
      expect(close.minutesToDeadline, 30);
      expect(close.pillar, Pillar.nutrition);
      expect(close.circadianImpact, 1.0);
    });

    test('fase sueño sin lock → sin candidatos', () {
      expect(CircadianGenerator.generate(CircadianPhase.sueno), isEmpty);
    });
  });

  group('CoachingSnapshotBuilder', () {
    test('engagement neutro → período de gracia', () {
      final snap = CoachingSnapshotBuilder.build(
        currentPhase: CircadianPhase.alerta,
        weekly: null,
        activeGoalTypes: const [],
        engagement: EngagementLevel.neutro,
      );
      expect(snap.isGracePeriod, isTrue);
    });

    test('mapea pilar más débil y segundo más débil por promedio', () {
      final snap = CoachingSnapshotBuilder.build(
        currentPhase: CircadianPhase.creatividad,
        weekly: _insight(weakest: WeakPillar.sleep),
        activeGoalTypes: const [],
        engagement: EngagementLevel.bueno,
      );
      expect(snap.weakestPillar, Pillar.sleep);
      // avgs: sleep .2 (weakest), hydration .5 (segundo), ...
      expect(snap.secondWeakestPillar, Pillar.hydration);
    });

    test('goalPillars ignora metas de composición corporal', () {
      final snap = CoachingSnapshotBuilder.build(
        currentPhase: CircadianPhase.alerta,
        weekly: null,
        activeGoalTypes: const [
          GoalType.sleepHoursPerNight,
          GoalType.weightTarget,
        ],
        engagement: EngagementLevel.bueno,
      );
      expect(snap.goalPillars, {Pillar.sleep});
    });
  });
}
