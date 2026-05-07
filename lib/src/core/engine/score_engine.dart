// SPEC-52: ScoreEngine consume MetabolicState (firma unificada).
//
// Antes: calculateIMR recibia 6 parametros sueltos (UserModel + fastingHours
// + weeklyAdherence + exerciseMin + sleepHours + lastMealTime + nutritionScore)
// y cada callsite en UI ensamblaba esos parametros con defaults distintos
// (lastMealTime defaulteado a now, sleepHours a 7.0 vs 0.0, etc.).
//
// Ahora: calculateIMR recibe (UserModel, MetabolicState). Una sola fuente de
// verdad. Los defaults dispersos se eliminan: si no hay datos, MetabolicState
// es .empty() y el imrProvider devuelve un score cero sin invocar al engine.

import 'dart:math' as math;

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IMRv2Result {
  final int totalScore;
  final double structureScore;
  final double metabolicScore;
  final double behaviorScore;
  final double circadianAlignment;
  final String zone;
  final String description;

  IMRv2Result({
    required this.totalScore,
    required this.structureScore,
    required this.metabolicScore,
    required this.behaviorScore,
    required this.circadianAlignment,
    required this.zone,
    required this.description,
  });

  /// Resultado vacío para cuando no hay datos suficientes (estado inicial,
  /// usuario aún cargando, etc.). SPEC-60: sin DateTime.now().
  factory IMRv2Result.empty() => IMRv2Result(
        totalScore: 0,
        structureScore: 0,
        metabolicScore: 0,
        behaviorScore: 0,
        circadianAlignment: 0,
        zone: 'N/A',
        description: 'Cargando...',
      );
}

class ScoreEngine {
  /// SPEC-52: nueva firma. Recibe el MetabolicState completo en lugar de
  /// 6 parámetros sueltos. Si `state.lastMealTime` es null, retorna
  /// `IMRv2Result.empty()` (la lógica circadiana requiere ese DateTime).
  IMRv2Result calculateIMR(UserModel user, MetabolicState state) {
    final lastMealTime = state.lastMealTime;
    if (lastMealTime == null) return IMRv2Result.empty();

    final bool isMale =
        user.gender.toUpperCase() == 'M' || user.gender.toUpperCase() == 'MALE';

    // 1. ESTRUCTURA (50%)
    double s1 = 0.5;
    if (user.waistCircumference != null && user.waistCircumference! > 0) {
      final double whtr = user.waistCircumference! / user.height;
      s1 = ((0.60 - whtr) / 0.15).clamp(0.0, 1.0);
    }
    final double hMeter = user.height / 100;
    final double leanMass = user.weight * (1 - (user.bodyFatPercentage / 100));
    final double ffmi = leanMass / math.pow(hMeter, 2);
    final double baseFFMI = isMale ? 16.0 : 14.0;
    final double rangeFFMI = isMale ? 6.0 : 5.0;
    final double s2 = ((ffmi - baseFFMI) / rangeFFMI).clamp(0.0, 1.0);
    final double structureBlock = (0.65 * s1) + (0.35 * s2);

    // 2. METABOLISMO (25%)
    final double fastingHours = state.fastingHoursRaw;
    final double weeklyAdherence = state.weeklyAdherence;
    final double s4 = 1 / (1 + math.exp(-(fastingHours - 14) / 1.5));
    final double etrfBonus = (lastMealTime.hour < 18) ? 1.15 : 1.0;
    final double metabolicBlock =
        ((0.70 * s4) + (0.30 * weeklyAdherence.clamp(0.0, 1.0))) * etrfBonus;

    // 3. CONDUCTA Y CIRCADIANO (25%)
    double circadianScore = 1.0;

    // SPEC-59: comparación lineal en minutos totales desde medianoche.
    final DateTime? goal = user.profile.lastMealGoal;
    final int mealMinutes = lastMealTime.hour * 60 + lastMealTime.minute;

    if (mealMinutes >= CircadianRules.intestinalLockMinutes) {
      // Penalización por comer en o después del bloqueo intestinal (22:30).
      circadianScore = 0.5;
    } else if (goal != null && lastMealTime.isBefore(goal)) {
      // Bonus eTRF por comer antes de la meta establecida.
      circadianScore = 1.1;
    }

    final double sleepHours = state.sleepHoursRaw;
    final double sSleep = (sleepHours >= 7 && sleepHours <= 9) ? 1.0 : 0.6;
    final double exerciseMin = state.exerciseMinutesRaw;
    final double sExercise = (exerciseMin / 60).clamp(0.0, 1.2);
    final double nutritionScore = state.nutritionScoreRaw;
    // SPEC-67: hidratación entra al bloque Conducta. El campo state.hydrationLevel
    // ya viene normalizado 0.0-1.0 desde MetabolicStateBuilder
    // (currentAmountLiters / dailyGoalLiters).
    final double sHydration = state.hydrationLevel.clamp(0.0, 1.0);

    // SPEC-04 + SPEC-67: Pesos del bloque Conducta — Circadiano 28% +
    // Sueño 20% + Ejercicio 20% + Nutrición 12% + Hidratación 20%.
    // Suma = 100%. Hidratación recibe peso alto porque la deshidratación
    // afecta sistémicamente todos los procesos metabólicos (la calibración
    // bibliográfica completa se documentará en SPEC-70 R2 final con
    // referencias ACSM/EFSA/NHANES).
    final double behaviorBlock = (0.28 * circadianScore.clamp(0.0, 1.0)) +
        (0.20 * sSleep) +
        (0.20 * sExercise) +
        (0.12 * nutritionScore.clamp(0.0, 1.0)) +
        (0.20 * sHydration);

    final double raw = (0.50 * structureBlock) +
        (0.25 * metabolicBlock.clamp(0.0, 1.0)) +
        (0.25 * behaviorBlock);
    final int score = (raw * 100).round().clamp(0, 100);

    return IMRv2Result(
      totalScore: score,
      structureScore: structureBlock,
      metabolicScore: metabolicBlock.clamp(0.0, 1.0),
      behaviorScore: behaviorBlock,
      circadianAlignment: circadianScore.clamp(0.0, 1.0),
      zone: _getZone(score),
      description: _getDescription(score, circadianScore),
    );
  }

  String _getZone(int s) {
    if (s < 40) return 'DETERIORADO';
    if (s < 60) return 'INESTABLE';
    if (s < 75) return 'FUNCIONAL';
    if (s < 90) return 'EFICIENTE';
    return 'OPTIMIZADO';
  }

  String _getDescription(int s, double circadian) {
    if (circadian < 0.7) {
      return 'Alerta: Ingesta nocturna detectada. Esto bloquea la reparación celular.';
    }
    if (s < 60) return 'Prioridad: Reducción de grasa visceral y ajuste de ritmos.';
    return 'Estado metabólico funcional con margen de mejora.';
  }
}

final scoreEngineProvider = Provider<ScoreEngine>((ref) => ScoreEngine());
