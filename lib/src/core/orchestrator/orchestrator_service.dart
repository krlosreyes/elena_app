import 'package:elena_app/src/core/orchestrator/models/orchestrator_state.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/foundation.dart';

/// SPEC-34: Motor de sincronización central.
/// Valida transiciones entre pilares y calcula el estado metabólico óptimo.
class OrchestratorService {
  /// Calcula el estado actual basado en pilares activos.
  ///
  /// Parámetros:
  /// - user: modelo del usuario con profile circadiano
  /// - fastingHours: duración actual del ayuno
  /// - lastMealTime: timestamp de última comida
  /// - exerciseMinutesToday: minutos de ejercicio hoy
  /// - sleepRecoveryScore: score de recuperación (0-1)
  /// - hydrationMlToday: mililitros de agua bebidos hoy
  /// - hydrationGoalMl: objetivo dinámico de hidratación
  static OrchestratorState calculateState({
    required UserModel user,
    required double fastingHours,
    required DateTime? lastMealTime,
    required double exerciseMinutesToday,
    required double sleepRecoveryScore,
    required double hydrationMlToday,
    required int hydrationGoalMl,
  }) {
    final now = DateTime.now();
    final circadianPhase = CircadianRules.getPhaseName(now);

    final fastingPhase = OrchestratorService.determineFastingPhase(fastingHours);
    final hoursSinceLastMeal = lastMealTime == null
        ? fastingHours
        : now.difference(lastMealTime).inMinutes / 60.0;

    // Calcular si es seguro ejercitar ahora
    final canExerciseNow = OrchestratorService.canExerciseNow(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      sleepRecoveryScore: sleepRecoveryScore,
    );

    // Calcular si es seguro comer ahora
    final (canEatNow, minutesToWindowClose) = OrchestratorService.canEatNow(
      user: user,
      now: now,
      circadianPhase: circadianPhase,
    );

    // Calcular recomendación de ejercicio
    final (recommendedType, recommendedIntensity) = OrchestratorService.getExerciseRecommendation(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      sleepRecoveryScore: sleepRecoveryScore,
    );

    // Validar violaciones
    final violations = OrchestratorService.detectSyncViolations(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      exerciseMinutesToday: exerciseMinutesToday,
      sleepRecoveryScore: sleepRecoveryScore,
      hoursSinceLastMeal: hoursSinceLastMeal,
      hydrationMlToday: hydrationMlToday,
      hydrationGoalMl: hydrationGoalMl,
    );

    // Calcular score de coherencia metabólica
    final metabolicCoherence = OrchestratorService.calculateMetabolicCoherence(
      fastingPhase: fastingPhase,
      circadianPhase: circadianPhase,
      sleepRecoveryScore: sleepRecoveryScore,
      canEatNow: canEatNow,
      canExerciseNow: canExerciseNow,
      violationCount: violations.length,
    );

    // Multiplicadores de seguridad
    final exerciseSafetyMultiplier = OrchestratorService.getExerciseSafetyMultiplier(fastingPhase);
    final nutritionPhaseMultiplier =
        OrchestratorService.getNutritionPhaseMultiplier(circadianPhase);

    // Sugerencia principal
    final primaryActionSuggestion =
        OrchestratorService.generatePrimaryActionSuggestion(canEatNow, canExerciseNow);

    // Construir estado
    return OrchestratorState(
      lastUpdated: now,
      currentFastingPhase: fastingPhase,
      currentCircadianPhase: circadianPhase,
      fastedHours: fastingHours,
      canExerciseNow: canExerciseNow,
      canEatNow: canEatNow,
      exerciseRecommendedType: recommendedType,
      exerciseRecommendedIntensity: recommendedIntensity,
      isOptimalForFasting: OrchestratorService.isOptimalForFasting(
        fastingPhase: fastingPhase,
        sleepRecoveryScore: sleepRecoveryScore,
      ),
      metabolicCoherence: metabolicCoherence,
      activeSyncViolations: violations,
      primaryActionSuggestion: primaryActionSuggestion,
      hoursSinceLastMeal: hoursSinceLastMeal,
      minutesToWindowClose: minutesToWindowClose,
      sleepRecoveryScore: sleepRecoveryScore,
      exerciseSafetyMultiplier: exerciseSafetyMultiplier,
      nutritionPhaseMultiplier: nutritionPhaseMultiplier,
    );
  }

  /// RF-34-02: Determina si es seguro hacer ejercicio ahora.
  static bool canExerciseNow({
    required String fastingPhase,
    required String circadianPhase,
    required double sleepRecoveryScore,
  }) {
    // No ejercitar en Autofagia profunda + dormir mal
    if (fastingPhase == 'AUTOFAGIA' && sleepRecoveryScore < 0.4) {
      return false;
    }
    // Sí es seguro en otras fases
    return true;
  }

  /// Determina si es seguro comer ahora.
  /// Retorna (canEat, minutosHastaWindowClose)
  static (bool, int?) canEatNow({
    required UserModel user,
    required DateTime now,
    required String circadianPhase,
  }) {
    final firstMeal = user.profile.firstMealGoal;
    final lastMeal = user.profile.lastMealGoal;

    if (firstMeal == null || lastMeal == null) {
      // Sin ventana definida, asumir siempre puedes comer
      return (true, null);
    }

    final withinWindow = now.isAfter(firstMeal) && now.isBefore(lastMeal);
    final minutesUntilClose = lastMeal.difference(now).inMinutes;

    return (withinWindow, minutesUntilClose);
  }

  /// Recomendación de tipo de ejercicio basada en estado metabólico y circadiano.
  /// Retorna (tipo, intensidad%)
  static (String?, int) getExerciseRecommendation({
    required String fastingPhase,
    required String circadianPhase,
    required double sleepRecoveryScore,
  }) {
    // Si sleep recovery malo, solo LISS baja
    if (sleepRecoveryScore < 0.4) {
      return ('LISS', 35);
    }

    // En Autofagia: LISS o STRENGTH, no HIIT
    if (fastingPhase == 'AUTOFAGIA') {
      return (sleepRecoveryScore > 0.6 ? 'STRENGTH' : 'LISS', 50);
    }

    // Por fase circadiana
    switch (circadianPhase) {
      case 'ALERTA': // 6-9 AM: cortisol alto, bueno para STRENGTH
        return ('STRENGTH', 75);
      case 'ENERGÍA': // 9-14:00: bueno para HIIT
        return ('HIIT', 80);
      case 'CREPÚSCULO': // 14-18:00: suave
        return ('LISS', 60);
      case 'SUEÑO': // 18-22:00: muy suave
        return ('LISS', 30);
      case 'LIMPIEZA': // 22:00-6:00: no ejercitar
        return (null, 0);
      default:
        return ('LISS', 50);
    }
  }

  /// Detecta violaciones de sincronización.
  static List<String> detectSyncViolations({
    required String fastingPhase,
    required String circadianPhase,
    required double exerciseMinutesToday,
    required double sleepRecoveryScore,
    required double hoursSinceLastMeal,
    required double hydrationMlToday,
    required int hydrationGoalMl,
  }) {
    final List<String> violations = [];

    // Violación: Deshidratación en ayuno profundo
    if (fastingPhase == 'AUTOFAGIA' &&
        hydrationMlToday < (hydrationGoalMl * 0.6)) {
      violations.add(
          'Riesgo deshidratación en Autofagia: bebiste ${hydrationMlToday.toStringAsFixed(0)}mL (objetivo ${(hydrationGoalMl * 1.25).toStringAsFixed(0)}mL)');
    }

    // Violación: Sleep recovery bajo en fase LIMPIEZA
    if (circadianPhase == 'LIMPIEZA' && sleepRecoveryScore < 0.5) {
      violations.add(
          'Recovery bajo: ${(sleepRecoveryScore * 100).toStringAsFixed(0)}%. Recomendado dormir 22:00-06:00 (fase SUEÑO/LIMPIEZA).');
    }

    // Violación: Mucho ejercicio en Autofagia
    if (fastingPhase == 'AUTOFAGIA' && exerciseMinutesToday > 60) {
      violations.add(
          'Ejercicio intenso en Autofagia profunda (${exerciseMinutesToday.toStringAsFixed(0)} min). Riesgo catabolismo muscular.');
    }

    return violations;
  }

  /// Calcula score de coherencia metabólica (0-1).
  static double calculateMetabolicCoherence({
    required String fastingPhase,
    required String circadianPhase,
    required double sleepRecoveryScore,
    required bool canEatNow,
    required bool canExerciseNow,
    required int violationCount,
  }) {
    var baseScore = 1.0;

    // Reducir por violaciones
    baseScore -= (violationCount * 0.15).clamp(0, 0.6);

    // Reducir si sleep recovery bajo
    if (sleepRecoveryScore < 0.5) {
      baseScore -= 0.2;
    }

    // Reducir si hay restricciones
    if (!canEatNow || !canExerciseNow) {
      baseScore -= 0.1;
    }

    return baseScore.clamp(0.0, 1.0);
  }

  /// Multiplicador de seguridad para ejercicio según fase de ayuno.
  static double getExerciseSafetyMultiplier(String fastingPhase) {
    return switch (fastingPhase) {
      'ALERTA' => 1.0,
      'GLUCONEOGÉNESIS' => 0.95,
      'CETOSIS' => 0.85,
      'AUTOFAGIA' => 0.6, // Alto riesgo de catabolismo
      _ => 1.0,
    };
  }

  /// Multiplicador de nutrición según fase circadiana.
  static double getNutritionPhaseMultiplier(String circadianPhase) {
    return switch (circadianPhase) {
      'ALERTA' => 0.8, // Malo comer carbs en ALERTA
      'ENERGÍA' => 1.0, // Óptimo
      'CREPÚSCULO' => 0.9, // Tolerable
      'SUEÑO' => 0.7, // Malo
      'LIMPIEZA' => 0.6, // Muy malo
      _ => 1.0,
    };
  }

  /// Determina si es óptimo continuar en ayuno.
  static bool isOptimalForFasting({
    required String fastingPhase,
    required double sleepRecoveryScore,
  }) {
    // Óptimo si estamos en Cetosis o Autofagia Y sleep recovery bueno
    final isInKetosis = fastingPhase == 'CETOSIS' || fastingPhase == 'AUTOFAGIA';
    return isInKetosis && sleepRecoveryScore > 0.6;
  }

  /// Detecta la fase actual del ayuno.
  static String determineFastingPhase(double fastingHours) {
    return switch (fastingHours) {
      < 4 => 'ALERTA',
      < 8 => 'GLUCONEOGÉNESIS',
      < 12 => 'CETOSIS',
      _ => 'AUTOFAGIA',
    };
  }

  /// Genera la sugerencia principal de acción.
  static String? generatePrimaryActionSuggestion(
    bool canEatNow,
    bool canExerciseNow,
  ) {
    if (canEatNow && !canExerciseNow) {
      return 'Ahora es óptimo para comer. El ejercicio es subóptimo.';
    } else if (!canEatNow && canExerciseNow) {
      return 'Ahora es bueno para ejercitar. No es ventana de comida.';
    } else if (!canEatNow && !canExerciseNow) {
      return 'Ahora no es óptimo para comer ni ejercitar. Descansa.';
    }
    // Si ambos son posibles
    return null;
  }
}
