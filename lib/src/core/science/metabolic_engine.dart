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
  /// 0–12h: glucosa en sangre, glucógeno activo
  postAbsorption,

  /// 12–18h: agotamiento glucógeno, inicio cambio combustible
  glycogenDepletion,

  /// 18–24h: gluconeogénesis + quema de grasa activa, adrenalina sube
  fatBurning,

  /// 24–48h: cetosis profunda, claridad mental, GH se duplica
  deepKetosis,

  /// 48–72h: autofagia real, modo clínico, riesgo si no hay adaptación
  autophagy,

  /// 72h+: estrés metabólico extremo, restricción obligatoria en UI
  survivalMode,
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
  static MetabolicZone calculateZone(Duration fastingTime) {
    final h = fastingTime.inMinutes / 60.0;
    if (h >= 72) return MetabolicZone.survivalMode;
    if (h >= 48) return MetabolicZone.autophagy;
    if (h >= 24) return MetabolicZone.deepKetosis;
    if (h >= 18) return MetabolicZone.fatBurning;
    if (h >= 12) return MetabolicZone.glycogenDepletion;
    return MetabolicZone.postAbsorption;
  }

  static CircadianPhase getCurrentCircadianPhase({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 21 || hour < 6) return CircadianPhase.deepSleep;
    if (hour >= 18) return CircadianPhase.melatoninRise;
    if (hour >= 13) return CircadianPhase.afternoonDip;
    return CircadianPhase.morningSensitivity;
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // calculateMetaICA is identical to ElenaBrain.calculateWHtR (waist/height).
  // Phase 4: keep ONE canonical method here, remove ElenaBrain copy.
  /// Indice Cintura-Altura (metaICA)
  static double calculateMetaICA(double waistCm, double heightCm) {
    if (heightCm <= 0) return 0.0;
    return waistCm / heightCm;
  }

  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // calculateMetaICC is identical to ElenaBrain.calculateWHR (waist/hip).
  // Phase 4: keep ONE canonical method here, remove ElenaBrain copy.
  /// Indice Cintura-Cadera (metaICC)
  static double calculateMetaICC(double waistCm, double? hipCm) {
    if (hipCm == null || hipCm <= 0) return 0.0;
    return waistCm / hipCm;
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
