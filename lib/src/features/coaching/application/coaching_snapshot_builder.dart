// SPEC-194 inc2: ensambla el CoachingSnapshot desde inputs ya resueltos.
// Función pura (sin Riverpod) → 100% testeable. El provider (inc2b) le pasa
// los valores leídos de los providers existentes.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';
import 'package:elena_app/src/features/coaching/application/coaching_mappers.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_snapshot.dart';
import 'package:elena_app/src/features/coaching/domain/fasting_check_in.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

class CoachingSnapshotBuilder {
  const CoachingSnapshotBuilder._();

  static CoachingSnapshot build({
    required CircadianPhase currentPhase,
    required WeeklyCoachingInsight? weekly,
    required Iterable<GoalType> activeGoalTypes,
    required EngagementLevel engagement,
    int? minutesToIntestinalLock,
    int? minutesToSleepOnset,
    double? liveCircadianScore,
    Map<String, int> ignoredStreakByActionId = const {},
    Set<String> shownTodayActionIds = const {},
    FastingFeeling? lastFeeling,
  }) {
    final Pillar? weakest = weekly?.weakest == null
        ? null
        : CoachingMappers.fromWeakPillar(weekly!.weakest!);

    return CoachingSnapshot(
      currentPhase: currentPhase,
      weakestPillar: weakest,
      secondWeakestPillar: _secondWeakest(weekly, weakest),
      goalPillars: CoachingMappers.goalPillars(activeGoalTypes),
      minutesToIntestinalLock: minutesToIntestinalLock,
      minutesToSleepOnset: minutesToSleepOnset,
      liveCircadianScore: liveCircadianScore,
      ignoredStreakByActionId: ignoredStreakByActionId,
      shownTodayActionIds: shownTodayActionIds,
      // Período de gracia: engagement neutro (<3 días de datos).
      isGracePeriod: engagement == EngagementLevel.neutro,
      // SPEC-232: último sentimiento reportado en el ciclo.
      lastFeeling: lastFeeling,
    );
  }

  /// Segundo pilar más débil = el de menor promedio (excluyendo el más débil).
  static Pillar? _secondWeakest(WeeklyCoachingInsight? w, Pillar? weakest) {
    if (w == null || w.isEmpty) return null;
    final byAvg = <Pillar, double>{
      Pillar.fasting: w.fastingAvg,
      Pillar.sleep: w.sleepAvg,
      Pillar.hydration: w.hydrationAvg,
      Pillar.exercise: w.exerciseAvg,
      Pillar.nutrition: w.mealsAvg,
    };
    final sorted = byAvg.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final e in sorted) {
      if (e.key != weakest) return e.key;
    }
    return null;
  }
}
