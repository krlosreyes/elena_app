// BUGFIX objetivos (2026-06-07) — fuente de verdad de las metas de pilar.
//
// La card "Mis objetivos" (goalsProvider) es la SoT. Los pilares deben
// regirse por ella, con FALLBACK al valor del UserModel/default cuando el
// usuario no fijó ese objetivo. Funciones puras → testeables.

import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class PillarGoalResolver {
  const PillarGoalResolver._();

  /// Minutos de ejercicio diarios. Goal activo > UserModel (default 20).
  static int exerciseMinutes(GoalsMap goals, UserModel user) {
    final g = goals[GoalType.exerciseMinPerDay];
    if (g != null && g.isActive && g.targetValue > 0) {
      return g.targetValue.round();
    }
    return user.exerciseGoalMinutes;
  }

  /// Litros de hidratación diarios. Goal activo > fórmula por peso (35 ml/kg).
  static double hydrationLiters(GoalsMap goals, UserModel user) {
    final g = goals[GoalType.hydrationLitersPerDay];
    if (g != null && g.isActive && g.targetValue > 0) {
      return g.targetValue;
    }
    final w = user.weight > 0 ? user.weight : 75.0;
    return double.parse((w * 0.035).toStringAsFixed(2));
  }
}
