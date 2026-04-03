import '../../../../core/science/metabolic_engine.dart' as core_science;
import '../entities/metabolic_state.dart';

// TODO: Remove in Phase 4 – duplicated metabolic logic
// MetabolicLogic.calculateVolumeAdjustment and determineRoutineType duplicate
// energy/recovery scoring already available in UserHealthState (energyScore,
// recoveryScore). Phase 4: consume UserHealthState instead of raw MetabolicState.
// Moved to DecisionEngine in Phase 3
// DEPRECATED: Use core/science/metabolic_engine.dart instead
@Deprecated('DEPRECATED: Use core/science/metabolic_engine.dart instead')
class MetabolicLogic {
  static double calculateVolumeAdjustment(MetabolicState state) {
    final zone = _resolveZone(state);
    final factorByZone = switch (zone) {
      core_science.MetabolicZone.autophagy => 0.75,
      core_science.MetabolicZone.fatBurning => 0.90,
      core_science.MetabolicZone.sugarBurning => 1.00,
      core_science.MetabolicZone.deepKetosis => 0.85,
    };

    final sorenessPenalty =
        state.sorenessLevel >= 4 ? 0.8 : (state.sorenessLevel == 3 ? 0.9 : 1.0);
    final energyBonus = state.energyLevel >= 8 ? 1.05 : 1.0;

    final factor = factorByZone * sorenessPenalty * energyBonus;
    return factor.clamp(0.5, 1.3);
  }

  static String determineRoutineType(MetabolicState state) {
    final zone = _resolveZone(state);

    if (state.sleepHours < 6.0 || state.sorenessLevel >= 4) {
      return 'Esencial'; // Low volume/intensity
    }

    if (zone == core_science.MetabolicZone.fatBurning ||
        zone == core_science.MetabolicZone.autophagy) {
      return 'Definición';
    }

    if (state.energyLevel >= 8 && state.nutritionStatus == 'fed') {
      return 'Potencia'; // High intensity
    }

    return 'Definición'; // Moderate/Standard
  }

  static String generateInsightMessage(MetabolicState state, String userName) {
    final routineType = determineRoutineType(state);
    final glucoseEstimate = _estimatedGlucoseFromState(state);
    final movementPrescription =
        core_science.MetabolicEngine.getExercisePrescription(glucoseEstimate);

    // Copywriting Persuasivo (Mensajes de Elena)
    return "$userName, he diseñado tu rutina '$routineType' de 6 ejercicios. Según tu descanso y energía de hoy, he ajustado el volumen para que tus fibras se recuperen al 100%. $movementPrescription";
  }

  static core_science.MetabolicZone _resolveZone(MetabolicState state) {
    // Training check-in does not provide elapsed fasting hours directly.
    // We infer a conservative fasting duration from nutrition status.
    final inferredHours = state.nutritionStatus == 'fasted' ? 14 : 8;
    return core_science.MetabolicEngine.calculateZone(
      Duration(hours: inferredHours),
    );
  }

  static double _estimatedGlucoseFromState(MetabolicState state) {
    final energyPenalty = (10 - state.energyLevel).clamp(0.0, 9.0);
    final sorenessPenalty = state.sorenessLevel.clamp(1, 5) * 2.5;
    return (95 + energyPenalty * 4 + sorenessPenalty).clamp(80.0, 180.0);
  }
}
