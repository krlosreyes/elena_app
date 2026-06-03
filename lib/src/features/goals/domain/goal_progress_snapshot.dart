// SPEC-154: snapshot del progreso de un objetivo activo. Lo consume
// el GoalsProgressDashboard.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/goals/domain/user_goal.dart';

class GoalProgressSnapshot {
  /// El objetivo subyacente.
  final UserGoal goal;

  /// Valor actual medido para este tipo de objetivo.
  final double currentValue;

  /// Progreso 0..1 calculado por `goal.progress(currentValue)`.
  final double progress;

  /// Mensaje derivado del progreso (5 ramas según §2.4 de SPEC-154).
  final String motivationalMessage;

  const GoalProgressSnapshot({
    required this.goal,
    required this.currentValue,
    required this.progress,
    required this.motivationalMessage,
  });

  /// True si el goal está terminado (progress >= 1.0).
  bool get isAchieved => progress >= 1.0;

  /// True si el goal está casi listo (progress >= 0.85).
  bool get isAlmostThere => progress >= 0.85 && progress < 1.0;
}
