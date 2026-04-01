import '../entities/metabolic_state.dart';

class MetabolicLogic {
  static double calculateVolumeAdjustment(MetabolicState state) {
    double factor = 1.0;

    // 1. Sleep Impact
    if (state.sleepHours < 6.0) {
      factor *= 0.8; // Significant reduction
    } else if (state.sleepHours < 7.0) {
      factor *= 0.9; // Slight reduction
    } else if (state.sleepHours > 8.5) {
      factor *= 1.05; // Bonus for great sleep
    }

    // 2. Soreness Impact (1-5)
    if (state.sorenessLevel >= 4) {
      factor *= 0.7; // Heavy reduction
    } else if (state.sorenessLevel == 3) {
      factor *= 0.9;
    }

    // 3. Nutrition/Energy Bonus
    if (state.nutritionStatus == 'fed' && state.energyLevel >= 8) {
      factor *= 1.1;
    }

    // Safety clamps
    if (factor < 0.5) factor = 0.5;
    if (factor > 1.5) factor = 1.5;

    return factor;
  }

  static String determineRoutineType(MetabolicState state) {
    if (state.sleepHours < 6.0 || state.sorenessLevel >= 4) {
      return 'Esencial'; // Low volume/intensity
    } else if (state.energyLevel >= 8 && state.nutritionStatus == 'fed') {
      return 'Potencia'; // High intensity
    } else {
      return 'Definición'; // Moderate/Standard
    }
  }

  static String generateInsightMessage(MetabolicState state, String userName) {
    final routineType = determineRoutineType(state);

    // Copywriting Persuasivo (Mensajes de Elena)
    return "$userName, he diseñado tu rutina '$routineType' de 6 ejercicios. Según tu descanso y energía de hoy, he ajustado el volumen para que tus fibras se recuperen al 100%. En los ejercicios sin peso, concéntrate en la lentitud del movimiento; ahí está la clave de tu metabolismo hoy.";
  }
}
