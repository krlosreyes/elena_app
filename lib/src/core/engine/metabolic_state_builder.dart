import 'dart:math' as math;

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// Construye un [MetabolicState] a partir de los estados de cada pilar.
///
/// El builder es la FUENTE DE VERDAD de toda normalización.
/// Recibe estados crudos de los providers y calcula internamente:
/// - sleepQuality (desde horas de sueño)
/// - hydrationLevel (desde litros / goal)
/// - glycemicLoad (desde comidas + ventana)
/// - exerciseLoad (desde minutos)
/// - circadianAlignment (desde lastMealTime vs goal)
/// - glycogenLevel (desde horas de ayuno)
/// - metabolicCoherence (desde datos de todos los pilares)
///
/// NO depende del Orchestrator. NO delega normalización a otros providers.
class MetabolicStateBuilder {
  const MetabolicStateBuilder._();

  /// Construye el MetabolicState completo.
  ///
  /// Parámetros:
  /// - [user]: UserModel con perfil circadiano.
  /// - [fasting]: Estado actual del FastingNotifier.
  /// - [sleepHours]: Horas de sueño del día (desde sleepDurationProvider).
  /// - [exercise]: Estado actual del ExerciseNotifier.
  /// - [nutrition]: Estado actual del NutritionNotifier.
  /// - [hydration]: Estado actual del HydrationNotifier.
  /// - [maxFastingHoursToday]: Máximo de horas de ayuno hoy (activo o completado).
  /// - [weeklyAdherence]: Adherencia semanal pre-calculada por StreakEngine.
  static MetabolicState build({
    required UserModel user,
    required FastingState fasting,
    required double sleepHours,
    required ExerciseState exercise,
    required NutritionState nutrition,
    required HydrationState hydration,
    required double maxFastingHoursToday,
    required double weeklyAdherence,
  }) {
    final now = DateTime.now();

    // ── fastingHours (normalizado via sigmoid) ───────────────────────────
    // Misma sigmoid que ScoreEngine: 1/(1+e^(-(h-14)/1.5))
    final double fastingNormalized =
        1.0 / (1.0 + math.exp(-(maxFastingHoursToday - 14) / 1.5));

    // ── glycogenLevel (inverso de progreso de ayuno) ─────────────────────
    // Derivado directamente de las horas de ayuno.
    // No depende del Orchestrator — usa la misma lógica de fases.
    final double glycogenLevel =
        _glycogenFromHours(maxFastingHoursToday);

    // ── circadianAlignment ───────────────────────────────────────────────
    // Compara lastMealTime con lastMealGoal del perfil circadiano.
    final DateTime stableLastMeal = fasting.startTime ??
        user.profile.lastMealGoal ??
        DateTime(now.year, now.month, now.day, 20, 0);
    final double circadianAlignment =
        _calculateCircadianAlignment(stableLastMeal, user.profile.lastMealGoal);

    // ── sleepQuality ─────────────────────────────────────────────────────
    // Calculado desde horas de sueño con curva piecewise biológica.
    // NO delegamos a sleepAdherence del provider.
    final double sleepQuality = _normalizeSleep(sleepHours);

    // ── exerciseLoad ─────────────────────────────────────────────────────
    // Normalización: (minutos / 60).clamp(0, 1.0)
    final double exerciseLoad =
        (exercise.todayMinutes / 60.0).clamp(0.0, 1.0);

    // ── glycemicLoad ─────────────────────────────────────────────────────
    // Calculado desde datos base de nutrición.
    // Fórmula: 60% adherencia de comidas + 40% adherencia de ventana.
    // NO usamos nutrition.nutritionScore (puede tener ajuste de orchestrator).
    final double mealRatio =
        (nutrition.mealsLoggedToday / nutrition.targetMeals.clamp(1, 10))
            .clamp(0.0, 1.0);
    final double glycemicLoad =
        (0.60 * mealRatio) + (0.40 * nutrition.windowAdherence);

    // ── hydrationLevel ───────────────────────────────────────────────────
    // Calculado desde litros actuales / goal.
    // NO delegamos a hydration.progressPercentage.
    final double hydrationLevel = hydration.dailyGoalLiters > 0
        ? (hydration.currentAmountLiters / hydration.dailyGoalLiters)
            .clamp(0.0, 1.0)
        : 0.0;

    // ── metabolicCoherence ───────────────────────────────────────────────
    // Calculado localmente desde los datos de todos los pilares.
    // NO depende del Orchestrator.
    final double metabolicCoherence = _calculateCoherence(
      sleepHours: sleepHours,
      hydrationLevel: hydrationLevel,
      circadianAlignment: circadianAlignment,
      exerciseLoad: exerciseLoad,
      fastingHours: maxFastingHoursToday,
    );

    return MetabolicState(
      // Normalizados
      fastingHours: fastingNormalized,
      glycogenLevel: glycogenLevel,
      circadianAlignment: circadianAlignment,
      sleepQuality: sleepQuality,
      exerciseLoad: exerciseLoad,
      glycemicLoad: glycemicLoad,
      hydrationLevel: hydrationLevel,
      metabolicCoherence: metabolicCoherence,
      // Crudos (para ScoreEngine)
      fastingHoursRaw: maxFastingHoursToday,
      sleepHoursRaw: sleepHours,
      exerciseMinutesRaw: exercise.todayMinutes.toDouble(),
      nutritionScoreRaw: glycemicLoad, // El builder es la fuente de verdad
      weeklyAdherence: weeklyAdherence,
      lastMealTime: stableLastMeal,
      timestamp: now,
    );
  }

  // ── Helpers privados ─────────────────────────────────────────────────────

  /// Estima nivel de glucógeno directamente desde horas de ayuno.
  /// Mapeo biológico:
  /// - 0-4h (post-absorción): glucógeno casi lleno → 0.9
  /// - 4-8h (gluconeogénesis): depleción parcial → 0.6
  /// - 8-12h (cetosis temprana): depleción significativa → 0.3
  /// - 12h+ (autofagia): reservas mínimas → 0.1
  static double _glycogenFromHours(double hours) {
    if (hours < 4) return 0.9;
    if (hours < 8) return 0.6;
    if (hours < 12) return 0.3;
    return 0.1;
  }

  /// Normaliza calidad de sueño desde horas.
  /// Curva piecewise basada en evidencia:
  /// - 0h → 0.0
  /// - <7h → escala lineal hasta 0.85
  /// - 7-9h → zona óptima (1.0)
  /// - >9h → penalización leve por exceso
  static double _normalizeSleep(double hours) {
    if (hours <= 0) return 0.0;
    if (hours < 7) return (hours / 7.0) * 0.85;
    if (hours <= 9) return 1.0;
    // > 9h: penalización gradual, mínimo 0.6
    return (1.0 - ((hours - 9) / 5.0)).clamp(0.6, 1.0);
  }

  /// Calcula circadianAlignment: penalización gradual (SPEC-26).
  static double _calculateCircadianAlignment(
    DateTime lastMealTime,
    DateTime? lastMealGoal,
  ) {
    if (lastMealGoal != null) {
      if (lastMealTime.isAfter(lastMealGoal)) {
        final minutesLate = lastMealTime.difference(lastMealGoal).inMinutes;
        return (1.0 - (minutesLate / 120.0)).clamp(0.0, 1.0);
      } else if (lastMealTime.isBefore(lastMealGoal)) {
        return 1.0; // Bonus eTRF se aplica en ScoreEngine, aquí es 1.0
      }
      return 1.0;
    }

    // Sin goal: penalización por ingesta nocturna (después de 22:30)
    if (lastMealTime.hour > 22 ||
        (lastMealTime.hour == 22 && lastMealTime.minute >= 30)) {
      return 0.5;
    }
    return 1.0;
  }

  /// Calcula coherencia metabólica desde los datos de pilares.
  /// Mide qué tan bien alineados están los pilares entre sí.
  ///
  /// Base 1.0, se reduce por inconsistencias detectadas:
  /// - Sueño insuficiente (<6.5h): penaliza coherencia sistémica.
  /// - Deshidratación (<50% goal): afecta todos los procesos.
  /// - Desalineación circadiana: indica disrupción de ritmos.
  /// - Ejercicio sin descanso adecuado: riesgo de catabolismo.
  static double _calculateCoherence({
    required double sleepHours,
    required double hydrationLevel,
    required double circadianAlignment,
    required double exerciseLoad,
    required double fastingHours,
  }) {
    var score = 1.0;

    // Sueño insuficiente penaliza coherencia global
    if (sleepHours < 6.5) {
      score -= 0.20;
    }

    // Deshidratación significativa
    if (hydrationLevel < 0.5) {
      score -= 0.15;
    }

    // Desalineación circadiana (comida fuera de ventana)
    if (circadianAlignment < 0.7) {
      score -= 0.15;
    }

    // Ejercicio intenso (>1h) con sueño pobre (<6h) = incoherencia
    if (exerciseLoad > 0.8 && sleepHours < 6.0) {
      score -= 0.10;
    }

    // Ayuno prolongado (>16h) sin hidratación adecuada = riesgo
    if (fastingHours > 16 && hydrationLevel < 0.6) {
      score -= 0.10;
    }

    return score.clamp(0.0, 1.0);
  }
}
