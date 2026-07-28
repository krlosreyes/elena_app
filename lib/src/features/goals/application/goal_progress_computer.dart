// SPEC-154: motor puro del GoalsProgressDashboard.
//
// Dos responsabilidades:
//   1. `buildCurrentValues(user, weekDocs)` → mapea cada tipo de goal
//      al valor actual que el usuario tiene HOY en ese eje.
//   2. `compute(goal, currentValue)` → arma el snapshot con progreso
//      + mensaje motivacional según §2.4 de SPEC-154.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/goals/domain/goal_progress_snapshot.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class GoalProgressComputer {
  GoalProgressComputer._();

  /// Umbral de "ayuno completado" — un día cuenta para el goal de
  /// `fastingDaysPerWeek` si el `fastingProgress` del daily_summary
  /// alcanzó al menos 95% del target.
  static const double kFastingCompletedThreshold = 0.95;

  /// Estima los litros diarios que el usuario consume promedio en la
  /// semana, derivado del hydrationProgress y el goal de hidratación
  /// del usuario. El daily_summary persiste el progreso normalizado,
  /// no los litros absolutos — los reconstruimos multiplicando por la
  /// meta diaria que aplica al usuario (35ml × peso).
  static double _hydrationGoalLitersOf(UserModel user) {
    final base = (user.weight * 0.035);
    if (base <= 0) return 2.5; // fallback razonable
    return base;
  }

  // ─── Mapeo currentValue por tipo ──────────────────────────────────

  /// Construye el mapa GoalType → currentValue a partir del UserModel
  /// y los daily_summary de la última semana.
  ///
  /// Para peso/grasa: directo del UserModel.
  /// Para ayuno/ejercicio/sueño/hidratación: promedios o conteos sobre
  /// los daily_summary de la semana.
  static Map<GoalType, double> buildCurrentValues({
    required UserModel user,
    required List<DailySummaryDoc> weekDocs,
  }) {
    final hydroGoal = _hydrationGoalLitersOf(user);
    final exerciseGoalMin = user.exerciseGoalMinutes.clamp(1, 240).toDouble();

    int fastingCompletedDays = 0;
    double sumExerciseMin = 0;
    double sumSleepHours = 0;
    double sumHydroLiters = 0;
    int sleepDocsCount = 0;
    int hydroDocsCount = 0;
    int exerciseDocsCount = 0;

    for (final d in weekDocs) {
      if (d.fastingProgress >= kFastingCompletedThreshold) {
        fastingCompletedDays++;
      }
      // exerciseProgress es 0..1, multiplicar por la meta del usuario
      // reconstruye los minutos.
      sumExerciseMin += d.exerciseProgress.clamp(0.0, 1.0) * exerciseGoalMin;
      exerciseDocsCount++;
      // sleepProgress es 0..1 derivado de duración 0..8h + calidad opcional.
      // Para reconstruir horas usamos 8h como base (mismo cálculo del
      // dailySummaryProvider).
      sumSleepHours += d.sleepProgress.clamp(0.0, 1.0) * 8.0;
      sleepDocsCount++;
      sumHydroLiters += d.hydrationProgress.clamp(0.0, 1.0) * hydroGoal;
      hydroDocsCount++;
    }

    final exerciseAvg =
        exerciseDocsCount == 0 ? 0.0 : sumExerciseMin / exerciseDocsCount;
    final sleepAvg = sleepDocsCount == 0 ? 0.0 : sumSleepHours / sleepDocsCount;
    final hydroAvg =
        hydroDocsCount == 0 ? 0.0 : sumHydroLiters / hydroDocsCount;

    return {
      GoalType.weightTarget: user.weight,
      GoalType.bodyFatTarget: user.bodyFatPercentage ?? 0,
      GoalType.fastingDaysPerWeek: fastingCompletedDays.toDouble(),
      GoalType.exerciseMinPerDay: exerciseAvg,
      GoalType.sleepHoursPerNight: sleepAvg,
      GoalType.hydrationLitersPerDay: hydroAvg,
    };
  }

  // ─── Snapshot ──────────────────────────────────────────────────────

  /// Construye el snapshot completo de un goal.
  static GoalProgressSnapshot compute({
    required UserGoal goal,
    required double currentValue,
  }) {
    final progress = goal.progress(currentValue);
    final message = _motivationalMessage(
      goal: goal,
      currentValue: currentValue,
      progress: progress,
    );
    return GoalProgressSnapshot(
      goal: goal,
      currentValue: currentValue,
      progress: progress,
      motivationalMessage: message,
    );
  }

  /// SPEC-154 §2.4: 5 ramas del mensaje según progreso.
  static String _motivationalMessage({
    required UserGoal goal,
    required double currentValue,
    required double progress,
  }) {
    if (progress >= 1.0) {
      return '✅ Objetivo alcanzado. Considera uno nuevo.';
    }

    if (progress >= 0.85) {
      return _almostThereMessage(goal, currentValue);
    }

    if (progress >= 0.50) {
      return 'Más de la mitad. Sigue así.';
    }

    if (progress < 0.10) {
      return 'Estás arrancando. El primer paso es lo más difícil.';
    }

    // 0.10..0.50
    final pct = (progress * 100).round();
    return '$pct% recorrido.';
  }

  static String _almostThereMessage(UserGoal goal, double currentValue) {
    final gap = (goal.targetValue - currentValue).abs();
    switch (goal.type) {
      case GoalType.weightTarget:
        return 'Casi llegas. Faltan ${_round1(gap)} kg.';
      case GoalType.bodyFatTarget:
        return 'Casi llegas. Faltan ${_round1(gap)}%.';
      case GoalType.fastingDaysPerWeek:
        return 'Casi llegas. Suma ${gap.round()} día más.';
      case GoalType.exerciseMinPerDay:
        return 'Casi llegas. Suma ${gap.round()} min más por día.';
      case GoalType.sleepHoursPerNight:
        return 'Casi llegas. Suma ${_round1(gap)}h más por noche.';
      case GoalType.hydrationLitersPerDay:
        return 'Casi llegas. Suma ${(gap * 1000).round()} ml más por día.';
      case GoalType.nutritionADominantPercent:
        return 'Casi llegas. Suma ${gap.round()}% A-dominante más por semana.';
    }
  }

  static String _round1(double v) => v.toStringAsFixed(1);
}
