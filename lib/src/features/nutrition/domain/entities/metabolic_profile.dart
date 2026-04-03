import 'package:elena_app/src/domain/logic/elena_brain.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VALUE OBJECTS
// ─────────────────────────────────────────────────────────────────────────────

/// Goal arch – determines the caloric direction and phase priority.
enum MetabolicGoal {
  aggressiveFatLoss, // High-deficit, insulin sensitive, adequate lean mass
  fatLoss, // Moderate deficit
  recomposition, // Maintenance calories, training-driven composition shift
  maintenance, // Energy balance, lifestyle optimization
  reverseDieting, // Controlled caloric increase after prolonged deficit
  muscleGain, // Lean surplus, anabolic window optimization
}

/// How the body is responding to the current energy environment.
enum AdaptationState {
  normal, // BMR/TDEE match expected values
  adapted, // Prolonged deficit → reduced NEAT/BMR (≥8 weeks at deficit)
  metabolicallyResistant, // Fat loss stalled despite deficit (≥4 weeks plateau)
}

/// Estimated insulin sensitivity from proxy markers (no CGM required).
/// Derived from WHtR, pathologies, BF%, and fasting protocol.
enum InsulinSensitivity {
  resistant, // WHtR > 0.55 or T2D/PCOS/MetS diagnosis
  impaired, // WHtR 0.50–0.55 or pre-diabetes markers
  normal, // WHtR < 0.50, no risk markers
  sensitive, // Active faste > 14h, fit, low BF%
}

/// Metabolic flexibility = ability to switch between fat and carb oxidation.
/// Low = insulin-dependant, poor fat oxidation. High = adapted faster.
enum MetabolicFlexibility {
  low, // Snacking frequent, high carb dependency, low fasting experience
  medium, // Some fasting experience, moderate carb cycling tolerance
  high, // Keto-adapted / experienced faster / low BF%
}

/// Fasting protocol classification.
enum FastingProtocol {
  none, // 12:12 or less (baseline, no therapeutic effect)
  mild, // 13:11 – 14:10
  standard16_8, // 16:8 (primary metabolic reset protocol)
  extended18_6, // 18:6
  omad, // ~23:1 – One Meal a Day
  extended24plus, // >24h therapeutic fasting (medical supervision advised)
}

/// Training timing relative to the feeding window.
enum TrainingTiming {
  fasted, // Within last 2h of fast (catecholamine peak, FFA mobilization)
  breakingFast, // 0–1h after first meal (low insulin, glycogen not yet refilled)
  fed, // Mid or late feeding window (high substrate availability)
  evening, // Late feeding, close to sleep onset
}

// ─────────────────────────────────────────────────────────────────────────────
// FASTING CONTEXT
// ─────────────────────────────────────────────────────────────────────────────

/// Encapsulates everything the engine needs to know about the fasting dimension.
class FastingContext {
  /// Derived from the user's average fasting hours.
  final FastingProtocol protocol;

  /// Fasting window in hours (e.g., 16.0 for 16:8).
  final double fastingWindowHours;

  /// Feeding window in hours (e.g., 8.0 for 16:8).
  final double feedingWindowHours;

  /// User's fasting experience level.
  final FastingExperience experience;

  /// How training is timed relative to feeding.
  final TrainingTiming trainingTiming;

  /// Whether the user is currently in a fasting state (real-time).
  final bool isCurrentlyFasting;

  /// Hours elapsed in current fasting period (for glucose/ketone estimation).
  final double currentFastingElapsedHours;

  const FastingContext({
    required this.protocol,
    required this.fastingWindowHours,
    required this.feedingWindowHours,
    required this.experience,
    required this.trainingTiming,
    this.isCurrentlyFasting = false,
    this.currentFastingElapsedHours = 0.0,
  });

  /// Derives a FastingContext from a UserModel and optional real-time data.
  factory FastingContext.fromUser(
    UserModel user, {
    bool isCurrentlyFasting = false,
    double currentElapsedHours = 0.0,
    TrainingTiming trainingTiming = TrainingTiming.fed,
  }) {
    final fastingHours = ElenaBrain.calculateFastingHours(
      user.usualFirstMealTime,
      user.usualLastMealTime,
    );
    final feedingHours = 24.0 - fastingHours;

    return FastingContext(
      protocol: _classifyProtocol(fastingHours),
      fastingWindowHours: fastingHours,
      feedingWindowHours: feedingHours,
      experience: user.fastingExperience,
      trainingTiming: trainingTiming,
      isCurrentlyFasting: isCurrentlyFasting,
      currentFastingElapsedHours: currentElapsedHours,
    );
  }

  static FastingProtocol _classifyProtocol(double hours) {
    if (hours < 13) return FastingProtocol.none;
    if (hours < 15) return FastingProtocol.mild;
    if (hours < 17) return FastingProtocol.standard16_8;
    if (hours < 20) return FastingProtocol.extended18_6;
    if (hours < 23) return FastingProtocol.omad;
    return FastingProtocol.extended24plus;
  }

  /// Metabolic bonus from fasting (0.0 – 1.0). Used to boost fat oxidation scores.
  double get fastingMetabolicBonus {
    switch (protocol) {
      case FastingProtocol.none:
        return 0.0;
      case FastingProtocol.mild:
        return 0.10;
      case FastingProtocol.standard16_8:
        return 0.25;
      case FastingProtocol.extended18_6:
        return 0.35;
      case FastingProtocol.omad:
        return 0.45;
      case FastingProtocol.extended24plus:
        return 0.55;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METABOLIC PROFILE (Core Domain Entity)
// ─────────────────────────────────────────────────────────────────────────────

/// The metabolic fingerprint of the user. ALL engine logic stems from this.
/// This is NOT a Firestore model – it is a computed domain entity built
/// fresh for every plan generation cycle.
class MetabolicProfile {
  // ── Body Composition ──
  final double totalWeightKg;
  final double bodyFatPercent; // 0.0 – 100.0
  final double leanMassKg; // = totalWeight × (1 − BF%)
  final double fatMassKg;

  // ── Metabolic State ──
  final double bmr; // Katch-McArdle when BF% available
  final double tdee; // BMR × activity multiplier
  final double activityMultiplier;

  // ── Indices ──
  final double bmi;
  final double whtr; // Waist-to-Height Ratio (central adiposity proxy)
  final double whr; // Waist-to-Hip Ratio (metabolic risk)
  final InsulinSensitivity insulinSensitivity;
  final MetabolicFlexibility metabolicFlexibility;

  // ── Clinical ──
  final AdaptationState adaptationState;
  final bool hasMetabolicRisk; // Diabetes, PCOS, MetS, etc.
  final bool hasHormonalRisk; // Conditions requiring fat floor adjustment
  final int age;
  final Gender gender;

  // ── Goal ──
  final MetabolicGoal goal;
  final double? targetWeightKg;
  final double? targetFatPercent;

  // ── Training ──
  final bool recentHighIntensityWorkout;

  // ── Fasting ──
  final FastingContext fastingContext;

  const MetabolicProfile({
    required this.totalWeightKg,
    required this.bodyFatPercent,
    required this.leanMassKg,
    required this.fatMassKg,
    required this.bmr,
    required this.tdee,
    required this.activityMultiplier,
    required this.bmi,
    required this.whtr,
    required this.whr,
    required this.insulinSensitivity,
    required this.metabolicFlexibility,
    required this.adaptationState,
    required this.hasMetabolicRisk,
    required this.hasHormonalRisk,
    required this.age,
    required this.gender,
    required this.goal,
    required this.fastingContext,
    this.recentHighIntensityWorkout = false,
    this.targetWeightKg,
    this.targetFatPercent,
  });

  bool get isMale => gender == Gender.male;
  bool get isFemale => gender == Gender.female;
  bool get isInsulinImpaired =>
      insulinSensitivity == InsulinSensitivity.resistant ||
      insulinSensitivity == InsulinSensitivity.impaired;

  /// Builds a full MetabolicProfile from a UserModel and optional overrides.
  factory MetabolicProfile.fromUser(
    UserModel user, {
    MetabolicGoal? goalOverride,
    AdaptationState adaptationState = AdaptationState.normal,
    FastingContext? fastingContext,
    TrainingTiming trainingTiming = TrainingTiming.fed,
    bool isCurrentlyFasting = false,
    double currentFastingElapsedHours = 0.0,
    bool recentHighIntensityWorkout = false,
  }) {
    final isMale = user.gender == Gender.male;

    // ── 1. Body Composition ──
    // TODO: Remove in Phase 4 – duplicated metabolic logic
    // Direct calls to ElenaBrain.calculateBodyFat/calculateBMR/calculateBMI/
    // calculateWHtR/calculateWHR should delegate to core/science/MetabolicEngine.
    final bf = ElenaBrain.calculateBodyFat(
          heightCm: user.heightCm,
          waistCm: user.waistCircumferenceCm,
          neckCm: user.neckCircumferenceCm,
          hipCm: user.hipCircumferenceCm,
          isMale: isMale,
        ) ??
        _estimateBFFromBmi(user);

    final lean = user.currentWeightKg * (1 - (bf / 100));
    final fat = user.currentWeightKg - lean;

    // ── 2. BMR / TDEE ──
    final bmr = ElenaBrain.calculateBMR(user);
    final mult = _activityMultiplier(user.activityLevel);
    final tdee = bmr * mult;

    // ── 3. Risk Assessment ──
    const metabolicRiskKeys = [
      'diabetes',
      'prediabetes',
      'diabetes_t2',
      'insulin_resistance',
      'pcos',
      'metabolicSyndrome',
      'obesity',
      'fatty_liver'
    ];
    const hormonalRiskKeys = [
      'hypothyroid',
      'pcos',
      'amenorrhea',
      'adrenal_insufficiency'
    ];
    final hasMR = user.pathologies.any((p) => metabolicRiskKeys.contains(p));
    final hasHR = user.pathologies.any((p) => hormonalRiskKeys.contains(p));

    // ── 4. Indices ──
    final bmi = ElenaBrain.calculateBMI(user.currentWeightKg, user.heightCm);
    final whtr =
        ElenaBrain.calculateWHtR(user.waistCircumferenceCm, user.heightCm);
    final whr = ElenaBrain.calculateWHR(
        user.waistCircumferenceCm, user.hipCircumferenceCm);

    // ── 5. Insulin Sensitivity (from proxy markers) ──
    final insulin = _estimateInsulinSensitivity(
      whtr: whtr,
      bf: bf,
      hasMetabolicRisk: hasMR,
      fastingHours: ElenaBrain.calculateFastingHours(
        user.usualFirstMealTime,
        user.usualLastMealTime,
      ),
      snacking: user.snackingHabit,
      experience: user.fastingExperience,
    );

    // ── 6. Metabolic Flexibility ──
    final flex = _estimateFlexibility(
      insulin,
      user.snackingHabit,
      user.fastingExperience,
      user.dietaryPreference,
      bf,
    );

    // ── 7. Goal Derivation ──
    final goal = goalOverride ?? _deriveGoal(user, bmi, whtr, bf);

    // ── 8. Fasting Context ──
    final fCtx = fastingContext ??
        FastingContext.fromUser(
          user,
          isCurrentlyFasting: isCurrentlyFasting,
          currentElapsedHours: currentFastingElapsedHours,
          trainingTiming: trainingTiming,
        );

    // ── 7b. HIIT Inference (last 24h) ──
    final hiitFromUser = user.lastHighIntensityWorkoutAt != null &&
        DateTime.now().difference(user.lastHighIntensityWorkoutAt!).inHours <
            24;
    final hiitDetected = recentHighIntensityWorkout || hiitFromUser;

    return MetabolicProfile(
      totalWeightKg: user.currentWeightKg,
      bodyFatPercent: bf,
      leanMassKg: lean,
      fatMassKg: fat,
      bmr: bmr,
      tdee: tdee,
      activityMultiplier: mult,
      bmi: bmi,
      whtr: whtr,
      whr: whr,
      insulinSensitivity: insulin,
      metabolicFlexibility: flex,
      adaptationState: adaptationState,
      hasMetabolicRisk: hasMR,
      hasHormonalRisk: hasHR,
      age: user.age,
      gender: user.gender,
      goal: goal,
      fastingContext: fCtx,
      recentHighIntensityWorkout: hiitDetected,
      targetWeightKg: user.targetWeightKg,
      targetFatPercent: user.targetFatPercentage,
    );
  }

  // ── Private derivation helpers ──

  static double _estimateBFFromBmi(UserModel user) {
    // Deurenberg equation – fallback when circumference data is absent
    final bmi = ElenaBrain.calculateBMI(user.currentWeightKg, user.heightCm);
    final sex = user.gender == Gender.male ? 1.0 : 0.0;
    return ((1.20 * bmi) + (0.23 * user.age) - (10.8 * sex) - 5.4)
        .clamp(5.0, 50.0);
  }

  static double _activityMultiplier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 1.20;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.heavy:
        return 1.725;
    }
  }

  static InsulinSensitivity _estimateInsulinSensitivity({
    required double whtr,
    required double bf,
    required bool hasMetabolicRisk,
    required double fastingHours,
    required SnackingHabit snacking,
    required FastingExperience experience,
  }) {
    if (hasMetabolicRisk || whtr > 0.57 || bf > 40) {
      return InsulinSensitivity.resistant;
    }
    if (whtr > 0.50 || bf > 30 || snacking == SnackingHabit.frequent) {
      return InsulinSensitivity.impaired;
    }
    if (fastingHours >= 16 && experience != FastingExperience.beginner) {
      return InsulinSensitivity.sensitive;
    }
    return InsulinSensitivity.normal;
  }

  static MetabolicFlexibility _estimateFlexibility(
    InsulinSensitivity insulin,
    SnackingHabit snacking,
    FastingExperience experience,
    DietaryPreference diet,
    double bf,
  ) {
    if (insulin == InsulinSensitivity.resistant ||
        snacking == SnackingHabit.frequent) {
      return MetabolicFlexibility.low;
    }
    if (diet == DietaryPreference.keto ||
        experience == FastingExperience.advanced ||
        bf < 15) {
      return MetabolicFlexibility.high;
    }
    return MetabolicFlexibility.medium;
  }

  static MetabolicGoal _deriveGoal(
    UserModel user,
    double bmi,
    double whtr,
    double bf,
  ) {
    // User-declared goal takes priority
    switch (user.healthGoal) {
      case HealthGoal.fatLoss:
        // Choose intensity based on excess fat
        if (bf > 35 || bmi > 30) return MetabolicGoal.aggressiveFatLoss;
        return MetabolicGoal.fatLoss;
      case HealthGoal.muscleGain:
        // If user has excess fat, recomp is safer than bulk
        if (bf > 20 && user.gender == Gender.male) {
          return MetabolicGoal.recomposition;
        }
        if (bf > 30 && user.gender == Gender.female) {
          return MetabolicGoal.recomposition;
        }
        return MetabolicGoal.muscleGain;
      case HealthGoal.metabolicHealth:
        return MetabolicGoal.maintenance;
      case null:
        // Infer from anthropometry
        if (bmi > 30 || whtr > 0.55) return MetabolicGoal.fatLoss;
        if (bmi < 18.5) return MetabolicGoal.muscleGain;
        return MetabolicGoal.maintenance;
    }
  }

  /// Estimated current glucose based on fasting hours (if currently fasting).
  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Delegates to ElenaBrain.estimateGlucose – consolidate in core/science.
  double? get estimatedCurrentGlucose {
    if (!fastingContext.isCurrentlyFasting) return null;
    return ElenaBrain.estimateGlucose(
        fastingContext.currentFastingElapsedHours);
  }

  /// Estimated current ketone level.
  // TODO: Remove in Phase 4 – duplicated metabolic logic
  // Delegates to ElenaBrain.estimateKetones – consolidate in core/science.
  double? get estimatedCurrentKetones {
    if (!fastingContext.isCurrentlyFasting) return null;
    return ElenaBrain.estimateKetones(
        fastingContext.currentFastingElapsedHours);
  }
}
