import 'dart:math' as math;

/// Encapsulates the core macro calculation logic based on lean mass,
/// fasting window, and insulin sensitivity.
///
/// This calculator is agnostic to the full MetabolicProfile and focuses on:
/// 1. Lean mass as the anchor for protein
/// 2. Fasting protocol intensity as a modifier
/// 3. Insulin sensitivity as a carb tolerance limiter
class MacroCalculator {
  // ──────────────────────────────────────────────────────────────────────────
  // INPUT MODELS
  // ──────────────────────────────────────────────────────────────────────────

  /// Input parameters for macro calculation.
  final double leanMassKg;
  final double totalWeightKg;
  final double tdee;
  final double fastingWindowHours;
  final InsulinSensitivityLevel insulinSensitivity;

  MacroCalculator({
    required this.leanMassKg,
    required this.totalWeightKg,
    required this.tdee,
    required this.fastingWindowHours,
    required this.insulinSensitivity,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculate complete macro targets for a given caloric target.
  MacroResult calculateMacros({
    required double caloricTarget,
    bool isTrainingDay = false,
    double proteinMultiplier = 2.2, // g/kg lean mass (default)
    double? fatTargetPercent, // Override for fat as % of calories
  }) {
    // Step 1: Protein (based on lean mass)
    final proteinGrams = _calculateProtein(proteinMultiplier);

    // Step 2: Fat (based on fasting window and insulin sensitivity)
    final fatGrams = _calculateFat(
      caloricTarget: caloricTarget,
      proteinGrams: proteinGrams,
      fatTargetPercent: fatTargetPercent,
    );

    // Step 3: Carbs (residual, adjusted by insulin sensitivity)
    final carbsGrams = _calculateCarbs(
      caloricTarget: caloricTarget,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      isTrainingDay: isTrainingDay,
    );

    // Step 4: Validate and return
    return _validateMacros(
      caloricTarget: caloricTarget,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbsGrams: carbsGrams,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 1: PROTEIN CALCULATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculate protein based on lean mass.
  ///
  /// Using lean mass as anchor prevents overfeeding protein in higher BF%.
  /// Default: 2.2 g/kg (upper evidence-based range for muscle preservation).
  double _calculateProtein(double gPerKgLeanMass) {
    final baseProtein = leanMassKg * gPerKgLeanMass;

    // Fasting bonus: Extended fasting creates favorable conditions for
    // muscle preservation at slightly lower protein intake.
    // However, we maintain HIGH protein to leverage increased amino acid
    // sensitivity during feeding window.
    final fastingIntensity = _fastingIntensityScore();
    if (fastingIntensity > 0.5) {
      // High fasting: protein slightly elevated to maximize MPS window
      return baseProtein * 1.08;
    }

    return baseProtein;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 2: FAT CALCULATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculate fat based on fasting window and insulin sensitivity.
  ///
  /// Logic:
  /// - Extended fasting → higher fat (adaptive fuel, metabolic flexibility)
  /// - Insulin sensitive → lower fat floor (higher carb tolerance)
  /// - Insulin resistant → higher fat floor (lower carb tolerance)
  double _calculateFat({
    required double caloricTarget,
    required double proteinGrams,
    required double? fatTargetPercent,
  }) {
    // If explicit fat target provided, use it
    if (fatTargetPercent != null) {
      return (caloricTarget * fatTargetPercent) / 9.0;
    }

    // Base: 1.0 g/kg bodyweight (evidence-based minimum for hormones)
    var fatGrams = totalWeightKg * 1.0;

    // Fasting modifier: Extended fasting → higher fat adaptation
    final fastingIntensity = _fastingIntensityScore();
    if (fastingIntensity > 0.3) {
      // 16:8+ fasting: fat can be elevated for metabolic flexibility
      fatGrams =
          totalWeightKg * (1.0 + (fastingIntensity * 0.3)); // 1.0 – 1.3 g/kg
    }

    // Insulin sensitivity modifier
    switch (insulinSensitivity) {
      case InsulinSensitivityLevel.resistant:
        // IR: higher fat, lower carbs (fat adaptability preferred)
        fatGrams = totalWeightKg * 1.3;
        break;
      case InsulinSensitivityLevel.impaired:
        // Impaired: moderate increase
        fatGrams = totalWeightKg * 1.15;
        break;
      case InsulinSensitivityLevel.normal:
        // Normal: standard 1.0 – 1.3 depending on fasting
        break;
      case InsulinSensitivityLevel.sensitive:
        // Sensitive: lower fat, higher carbs tolerance
        fatGrams = totalWeightKg * 0.9;
        break;
    }

    // Soft cap: 40% of calories from fat (relaxed for fasting adaptation)
    final fatCaloricCap = (caloricTarget * 0.40) / 9.0;
    fatGrams = math.min(fatGrams, fatCaloricCap);

    // Hard floor: 30g minimum (essential fatty acid absorption, hormone synthesis)
    fatGrams = math.max(fatGrams, 30.0);

    return fatGrams;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 3: CARBS CALCULATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculate carbs (residual after protein + fat, adjusted by insulin sensitivity).
  ///
  /// Insulin sensitivity is the primary lever for carb tolerance:
  /// - Sensitive: higher carb ceiling
  /// - Resistant: lower carb ceiling + preference for fat adaptation
  double _calculateCarbs({
    required double caloricTarget,
    required double proteinGrams,
    required double fatGrams,
    required bool isTrainingDay,
  }) {
    // Residual calculation
    final proteinCalories = proteinGrams * 4.0;
    final fatCalories = fatGrams * 9.0;
    final residualCalories = caloricTarget - proteinCalories - fatCalories;
    var carbsGrams = (residualCalories / 4.0).clamp(0.0, double.infinity);

    // Insulin sensitivity adjustment
    final carbCeiling = _carbCeilingByInsulinSensitivity(isTrainingDay);
    carbsGrams = math.min(carbsGrams, carbCeiling);

    // Fasting bonus: Extended fasting → lower minimum carb requirement
    // (body uses fat/ketones more efficiently)
    final fastingIntensity = _fastingIntensityScore();
    if (fastingIntensity > 0.4) {
      // Carb floor relaxed: 20g minimum (vs. typical 30g)
      carbsGrams = math.max(carbsGrams, 20.0);
    } else {
      // Standard: 30g minimum (brain glucose + RBC requirements)
      carbsGrams = math.max(carbsGrams, 30.0);
    }

    return carbsGrams;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER: INSULIN SENSITIVITY → CARB CEILING
  // ──────────────────────────────────────────────────────────────────────────

  /// Return carb ceiling based on insulin sensitivity and training day status.
  double _carbCeilingByInsulinSensitivity(bool isTrainingDay) {
    switch (insulinSensitivity) {
      case InsulinSensitivityLevel.resistant:
        // IR: keep carbs low (< 80g/day, < 100g on training day)
        return isTrainingDay ? 100.0 : 80.0;
      case InsulinSensitivityLevel.impaired:
        // Impaired: moderate (< 130g/day, < 160g on training day)
        return isTrainingDay ? 160.0 : 130.0;
      case InsulinSensitivityLevel.normal:
        // Normal: flexible (< 200g/day, < 280g on training day)
        return isTrainingDay ? 280.0 : 200.0;
      case InsulinSensitivityLevel.sensitive:
        // Sensitive: high tolerance (< 250g/day, < 350g on training day)
        return isTrainingDay ? 350.0 : 250.0;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER: FASTING WINDOW → INTENSITY SCORE
  // ──────────────────────────────────────────────────────────────────────────

  /// Return a fasting intensity score (0.0 – 1.0) based on fasting window.
  ///
  /// Score increases non-linearly:
  /// - < 13h: 0.0 (no fasting effect)
  /// - 13–16h: 0.1–0.3 (mild)
  /// - 16–18h: 0.3–0.5 (standard)
  /// - 18–20h: 0.5–0.7 (extended)
  /// - > 20h: 0.7–1.0 (advanced)
  double _fastingIntensityScore() {
    if (fastingWindowHours < 13.0) return 0.0;
    if (fastingWindowHours < 15.0) return 0.1;
    if (fastingWindowHours < 16.0) return 0.25;
    if (fastingWindowHours < 18.0) return 0.5;
    if (fastingWindowHours < 20.0) return 0.65;
    if (fastingWindowHours < 24.0) return 0.80;
    return 1.0; // 24h+ (OMAD or extended)
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 4: VALIDATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Validate and return macro result, applying final safety checks.
  MacroResult _validateMacros({
    required double caloricTarget,
    required double proteinGrams,
    required double fatGrams,
    required double carbsGrams,
  }) {
    // Floor all values
    final p = math.max(proteinGrams, 20.0);
    final f = math.max(fatGrams, 20.0);
    final c = math.max(carbsGrams, 0.0);

    // Recalculate actual calories
    final actualCalories = (p * 4.0) + (f * 9.0) + (c * 4.0);

    // Validate sanity: actual should be within 10% of target
    final deviation = (actualCalories - caloricTarget).abs() / caloricTarget;
    if (deviation > 0.1) {
      // Attempt rebalancing: reduce fattest macro (usually carbs)
      if (c > 30.0) {
        final carbAdjustment = (caloricTarget - (p * 4.0) - (f * 9.0)) / 4.0;
        return MacroResult(
          proteinGrams: p,
          fatGrams: f,
          carbsGrams: math.max(carbAdjustment, 0.0),
          targetCalories: caloricTarget.toInt(),
          actualCalories:
              (p * 4.0) + (f * 9.0) + (math.max(carbAdjustment, 0.0) * 4.0),
        );
      }
    }

    return MacroResult(
      proteinGrams: p,
      fatGrams: f,
      carbsGrams: c,
      targetCalories: caloricTarget.toInt(),
      actualCalories: actualCalories,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OUTPUT MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// Result of macro calculation.
class MacroResult {
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final int targetCalories;
  final double actualCalories;

  MacroResult({
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.targetCalories,
    required this.actualCalories,
  });

  /// Return macro distribution percentages.
  MacroDistribution get distribution {
    final total = actualCalories;
    return MacroDistribution(
      proteinPercent: ((proteinGrams * 4.0) / total) * 100,
      fatPercent: ((fatGrams * 9.0) / total) * 100,
      carbsPercent: ((carbsGrams * 4.0) / total) * 100,
    );
  }

  /// Round to nearest integer for nutrition labels.
  MacroResult rounded() => MacroResult(
        proteinGrams: proteinGrams.round().toDouble(),
        fatGrams: fatGrams.round().toDouble(),
        carbsGrams: carbsGrams.round().toDouble(),
        targetCalories: targetCalories,
        actualCalories: actualCalories,
      );

  @override
  String toString() => 'MacroResult(P: ${proteinGrams.toStringAsFixed(1)}g, '
      'F: ${fatGrams.toStringAsFixed(1)}g, '
      'C: ${carbsGrams.toStringAsFixed(1)}g, '
      'Cal: ${actualCalories.toStringAsFixed(0)}/$targetCalories)';
}

/// Macro distribution percentages.
class MacroDistribution {
  final double proteinPercent;
  final double fatPercent;
  final double carbsPercent;

  MacroDistribution({
    required this.proteinPercent,
    required this.fatPercent,
    required this.carbsPercent,
  });

  @override
  String toString() =>
      'MacroDistribution(P: ${proteinPercent.toStringAsFixed(1)}%, '
      'F: ${fatPercent.toStringAsFixed(1)}%, '
      'C: ${carbsPercent.toStringAsFixed(1)}%)';
}

// ─────────────────────────────────────────────────────────────────────────────
// INSULIN SENSITIVITY ENUM
// ─────────────────────────────────────────────────────────────────────────────

/// Simplified insulin sensitivity classification for macro calculations.
///
/// Based on:
/// - Waist-to-Height Ratio (WHtR) cutoffs
/// - Fasting protocols and experience
/// - Pathological markers (diabetes, PCOS, MetS)
/// - Body fat percentage
enum InsulinSensitivityLevel {
  /// WHtR > 0.55 or T2D/PCOS/MetS diagnosis
  /// → Carbs: < 80g/day, high fat/keto orientation
  resistant,

  /// WHtR 0.50–0.55 or pre-diabetes markers
  /// → Carbs: < 130g/day, moderate fat elevation
  impaired,

  /// WHtR < 0.50, no risk markers, typical BF%
  /// → Carbs: flexible (200g/day), standard fat
  normal,

  /// Active fasting (>14h), fit physique, low BF%
  /// → Carbs: high tolerance (250g+/day), lower fat
  sensitive,
}
