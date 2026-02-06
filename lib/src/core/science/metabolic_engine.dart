/// Represents the current state of insulin in the body.
///
/// Insulin is the primary anabolic hormone. Correctly managing its curves
/// is critical for metabolic flexibility.
enum InsulinState {
  /// Baseline fasting levels. Optimal for fat oxidation.
  low,

  /// Rapidly rising levels after high-GI intake.
  spiking,

  /// Sustained elevated levels. Inhibits lipolysis.
  high,

  /// Rapid drop leading to reactive hypoglycemia and cravings.
  crashing,
}

/// Defines the primary metabolic substrate being used for energy.
enum MetabolicZone {
  /// Primarily running on glucose/glycogen.
  sugarBurning,

  /// Shift towards fatty acid oxidation (Lipolysis).
  fatBurning,

  /// Cellular repair processes activated (e.g. mTOR suppression).
  autophagy,

  /// High concentration of ketone bodies (Beta-hydroxybutyrate).
  deepKetosis,
}

/// Represents the user's circadian rhythm phase.
///
/// Circadian biology dictates hormonal sensitivity (e.g. Cortisol/Melatonin).
enum CircadianPhase {
  /// High insulin sensitivity, cortisol peak. Ideal for carbohydrates if needed.
  morningSensitivity,

  /// Natural energy dip.
  afternoonDip,

  /// Melatonin secretion begins. Insulin sensitivity drops.
  melatoninRise,

  /// Glymphatic system active. Recovery.
  deepSleep,
}

/// Core engine for metabolic logic and rules validation.
///
/// This service provides pure functions to determine metabolic states and
/// generate prescriptions based on physiological inputs.
abstract class MetabolicEngine {
  /// Calculates the current metabolic zone based on fasting duration.
  ///
  /// *   < 12h: [MetabolicZone.sugarBurning] - Glycogen stores are active.
  /// *   12h - 16h: [MetabolicZone.fatBurning] - Lipolysis increases as insulin drops.
  /// *   > 16h: [MetabolicZone.autophagy] - Cellular cleanup begins.
  static MetabolicZone calculateZone(Duration fastingTime) {
    if (fastingTime.inHours > 16) {
      return MetabolicZone.autophagy;
    } else if (fastingTime.inHours > 12) {
      return MetabolicZone.fatBurning;
    } else {
      return MetabolicZone.sugarBurning;
    }
  }

  /// Provides an exercise prescription based on current glucose levels.
  ///
  /// *   > 140 mg/dL: Suggests immediate movement to activate GLUT4 transporters
  ///     independent of insulin, lowering blood sugar.
  static String getExercisePrescription(double currentGlucose) {
    if (currentGlucose > 140) {
      return 'High glucose detected. Recommend 15 min walk or 3 sets of squats to activate GLUT4 and lower blood sugar independently of insulin.';
    }
    return 'Glucose levels stable. Maintenance activity recommended.';
  }

  /// Determines if a meal time is compatible with optimal sleep hygiene.
  ///
  /// Eating too close to bedtime keeps core body temperature high and insulin elevated,
  /// which interferes with Melatonin release and Deep Sleep quality.
  ///
  /// Returns `false` if the meal is within 2 hours of bedtime.
  static bool isMealSafeForSleep(DateTime mealTime, DateTime bedtime) {
    final difference = bedtime.difference(mealTime);
    // Unsafe if less than 2 hours (120 minutes) before bed.
    return difference.inMinutes >= 120;
  }
}
