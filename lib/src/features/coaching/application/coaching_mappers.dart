// SPEC-194 inc2: mapeos puros entre tipos existentes y el dominio de coaching.
// Sin Riverpod — funciones estáticas testeables.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

class CoachingMappers {
  const CoachingMappers._();

  /// WeakPillar (análisis semanal) → Pillar (SOURCE OF TRUTH). `meals` mapea
  /// al pilar de nutrición.
  static Pillar fromWeakPillar(WeakPillar w) => switch (w) {
        WeakPillar.fasting => Pillar.fasting,
        WeakPillar.sleep => Pillar.sleep,
        WeakPillar.hydration => Pillar.hydration,
        WeakPillar.exercise => Pillar.exercise,
        WeakPillar.meals => Pillar.nutrition,
      };

  /// GoalType → Pillar. Las metas de composición corporal (peso/%grasa) no
  /// mapean a un pilar conductual de los 5 → null (se ignoran en goalPillars).
  static Pillar? fromGoalType(GoalType g) => switch (g) {
        GoalType.fastingDaysPerWeek => Pillar.fasting,
        GoalType.exerciseMinPerDay => Pillar.exercise,
        GoalType.sleepHoursPerNight => Pillar.sleep,
        GoalType.hydrationLitersPerDay => Pillar.hydration,
        GoalType.nutritionADominantPercent => Pillar.nutrition,
        GoalType.weightTarget => null,
        GoalType.bodyFatTarget => null,
      };

  /// Conjunto de pilares ligados a metas activas del usuario.
  static Set<Pillar> goalPillars(Iterable<GoalType> activeGoalTypes) {
    final out = <Pillar>{};
    for (final g in activeGoalTypes) {
      final p = fromGoalType(g);
      if (p != null) out.add(p);
    }
    return out;
  }
}
