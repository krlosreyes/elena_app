import 'dart:math' as math;
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
}

class ScoreEngine {
  IMRv2Result calculateIMR(UserModel user, {
    required double fastingHours,
    required double weeklyAdherence,
    required double exerciseMin,
    required double sleepHours,
    required DateTime lastMealTime,
    // SPEC-04: Score nutricional 0.0-1.0 calculado por NutritionNotifier.
    // Default 0.0 cuando no hay comidas registradas aún en el día.
    double nutritionScore = 0.0,
  }) {
    final bool isMale = user.gender.toUpperCase() == 'M' || user.gender.toUpperCase() == 'MALE';

    // 1. ESTRUCTURA (50%)
    double s1 = 0.5;
    if (user.waistCircumference != null && user.waistCircumference! > 0) {
      double whtr = user.waistCircumference! / user.height;
      s1 = ((0.60 - whtr) / 0.15).clamp(0.0, 1.0);
    }
    double hMeter = user.height / 100;
    double leanMass = user.weight * (1 - (user.bodyFatPercentage / 100));
    double ffmi = leanMass / math.pow(hMeter, 2);
    double baseFFMI = isMale ? 16.0 : 14.0;
    double rangeFFMI = isMale ? 6.0 : 5.0;
    double s2 = ((ffmi - baseFFMI) / rangeFFMI).clamp(0.0, 1.0);
    double structureBlock = (0.65 * s1) + (0.35 * s2);

    // 2. METABOLISMO (25%)
    double s4 = 1 / (1 + math.exp(-(fastingHours - 14) / 1.5));
    double etrfBonus = (lastMealTime.hour < 18) ? 1.15 : 1.0;
    double metabolicBlock = ((0.70 * s4) + (0.30 * weeklyAdherence.clamp(0.0, 1.0))) * etrfBonus;

    // 3. CONDUCTA Y CIRCADIANO (25%)
    double circadianScore = 1.0;
    
    // CORRECCIÓN TÉCNICA: Manejo de nulos para lastMealGoal
    final DateTime? goal = user.profile.lastMealGoal;

    if (lastMealTime.hour >= 22 && lastMealTime.minute >= 30 || lastMealTime.hour > 22) {
      // Penalización por comer después del bloqueo intestinal
      circadianScore = 0.5;
    } else if (goal != null && lastMealTime.isBefore(goal)) {
      // Bonus por comer antes de la meta establecida (eTRF)
      circadianScore = 1.1;
    }
    
    double sSleep = (sleepHours >= 7 && sleepHours <= 9) ? 1.0 : 0.6;
    double sExercise = (exerciseMin / 60).clamp(0.0, 1.2);
    // SPEC-04: Pesos del bloque Conducta ajustados para incluir nutrición.
    // Circadiano 35% + Sueño 25% + Ejercicio 25% + Nutrición 15% = 100%
    double behaviorBlock = (0.35 * circadianScore.clamp(0.0, 1.0))
        + (0.25 * sSleep)
        + (0.25 * sExercise)
        + (0.15 * nutritionScore.clamp(0.0, 1.0));

    double raw = (0.50 * structureBlock) + (0.25 * metabolicBlock.clamp(0.0, 1.0)) + (0.25 * behaviorBlock);
    int score = (raw * 100).round().clamp(0, 100);

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
    if (s < 40) return "DETERIORADO";
    if (s < 60) return "INESTABLE";
    if (s < 75) return "FUNCIONAL";
    if (s < 90) return "EFICIENTE";
    return "OPTIMIZADO";
  }

  String _getDescription(int s, double circadian) {
    if (circadian < 0.7) return "Alerta: Ingesta nocturna detectada. Esto bloquea la reparación celular.";
    if (s < 60) return "Prioridad: Reducción de grasa visceral y ajuste de ritmos.";
    return "Estado metabólico funcional con margen de mejora.";
  }
}

final scoreEngineProvider = Provider<ScoreEngine>((ref) => ScoreEngine());