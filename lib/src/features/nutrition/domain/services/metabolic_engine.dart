import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import '../entities/metabolic_profile.dart';
import '../entities/nutrition_strategy.dart';
import '../entities/metabolic_nutrition_plan.dart';

// ─────────────────────────────────────────────────────────────────────────────
// METABOLIC ENGINE — Pure Logic Core
// No side effects. No Flutter dependencies. No Riverpod.
// Input: MetabolicProfile + NutritionStrategy
// Output: MetabolicNutritionPlan
// ─────────────────────────────────────────────────────────────────────────────

class MetabolicEngine {
  // ──────────────────────────────────────────────────────────────────────────
  // MAIN ENTRY POINT
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates a full metabolic nutrition plan from a user profile.
  ///
  /// This is the single public API. All internal steps are called from here
  /// in a deterministic, ordered pipeline.
  static MetabolicNutritionPlan generate({
    required String userId,
    required MetabolicProfile profile,
    bool isTrainingDay = false,
    NutritionStrategy? strategyOverride,
  }) {
    // ── STEP 1: Strategy Selection ──────────────────────────────────────────
    final strategy =
        strategyOverride ?? NutritionStrategySelector.select(profile);

    // ── STEP 2: Caloric Target ───────────────────────────────────────────────
    final caloricTarget = _computeCaloricTarget(profile, strategy);

    // ── STEP 3: Protein ──────────────────────────────────────────────────────
    final proteinG = _computeProtein(profile, strategy, caloricTarget);

    // ── STEP 4: Fat ───────────────────────────────────────────────────────────
    final fatG = _computeFat(profile, strategy, caloricTarget, proteinG);

    // ── STEP 5: Carbs ─────────────────────────────────────────────────────────
    final carbsG = _computeCarbs(
      profile: profile,
      strategy: strategy,
      targetCalories: caloricTarget,
      proteinG: proteinG,
      fatG: fatG,
      isTrainingDay: isTrainingDay,
    );

    // ── STEP 6: Calorie Recalibration ─────────────────────────────────────────
    // After floors are applied, actual calories may differ from target.
    final actualCalories = _recalibrate(proteinG, fatG, carbsG);

    // ── STEP 7: Safety Validation ─────────────────────────────────────────────
    final safeResult = _applySafetyConstraints(
      profile: profile,
      strategy: strategy,
      targetCalories: actualCalories,
      proteinG: proteinG,
      fatG: fatG,
      carbsG: carbsG,
    );

    // ── STEP 8: Meal Distribution ────────────────────────────────────────────
    final meals = _distributeMeals(
      profile: profile,
      strategy: strategy,
      totalCalories: safeResult.calories,
      totalProteinG: safeResult.protein,
      totalFatG: safeResult.fat,
      totalCarbsG: safeResult.carbs,
      isTrainingDay: isTrainingDay,
    );

    // ── STEP 9: Adaptation Adjustments ───────────────────────────────────────
    final adaptedMeals = _applyAdaptationAdjustments(
      profile: profile,
      meals: meals,
    );

    // ── STEP 10: Fasting Alignment ────────────────────────────────────────────
    final alignedMeals = _alignToFastingWindow(
      profile: profile,
      meals: adaptedMeals,
    );

    return MetabolicNutritionPlan(
      id: const Uuid().v4(),
      userId: userId,
      calculatedAt: DateTime.now(),
      algorithmVersion: '2.0.0-metabolic',
      profile: profile,
      strategy: strategy,
      isTrainingDay: isTrainingDay,
      totalCalories: safeResult.calories.round(),
      proteinGrams: safeResult.protein.round(),
      fatGrams: safeResult.fat.round(),
      carbsGrams: safeResult.carbs.round(),
      meals: alignedMeals,
      caloricDeficitPercent:
          ((profile.tdee - safeResult.calories) / profile.tdee * 100)
              .clamp(-20.0, 40.0),
      metabolicNotes: _generateNotes(profile, strategy, safeResult),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 2: CALORIC TARGET
  // ──────────────────────────────────────────────────────────────────────────

  static double _computeCaloricTarget(
    MetabolicProfile profile,
    NutritionStrategy strategy,
  ) {
    // Base: TDEE × strategy modifier
    double target = profile.tdee * (1.0 + strategy.caloricModifier);

    // Adaptation downgrade: If metabolically adapted → reduce deficit to
    // avoid further BMR suppression (counter-intuitive but evidence-based).
    if (profile.adaptationState == AdaptationState.adapted) {
      // Bring calories closer to TDEE to restore metabolic rate.
      target = profile.tdee * 0.90; // Max 10% deficit during adaptation recovery
    } else if (profile.adaptationState == AdaptationState.metabolicallyResistant) {
      // Temporarily cycle to maintenance.
      target = profile.tdee;
    }

    // Fasting bonus: Extended fasting creates metabolic conditions that allow
    // a slightly lower target without hormonal disruption.
    final fastingBonus = profile.fastingContext.fastingMetabolicBonus;
    if (fastingBonus > 0 && strategy.caloricModifier < 0) {
      // We can safely deepen the deficit by up to fastingBonus × 200 kcal
      target -= fastingBonus * 100; // Conservative: 50% of max bonus
    }

    return target;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 3: PROTEIN
  // ──────────────────────────────────────────────────────────────────────────

  static double _computeProtein(
    MetabolicProfile profile,
    NutritionStrategy strategy,
    double targetCalories,
  ) {
    // Protein is always calculated from LEAN MASS, not total weight.
    double proteinG =
        profile.leanMassKg * strategy.proteinDirective.gPerKgLeanMass;

    // Muscle preservation bonus for metabolically adapted users:
    // Increase protein by 15% to counteract elevated cortisol-driven catabolism.
    if (profile.adaptationState != AdaptationState.normal) {
      proteinG *= 1.15;
    }

    // Age-related sarcopenia prevention (≥50 years → additional 10%):
    // Basado en evidencia de umbral leucina para MPS en adultos mayores.
    if (profile.age >= 50) {
      proteinG *= 1.10;
    }

    // High Intensity Training Inference:
    // If a high-intensity workout was performed in the last 24h, increase protein
    // targets by 20% to optimize muscle protein synthesis (MPS) and recovery.
    if (profile.recentHighIntensityWorkout) {
      proteinG *= 1.20;
    }

    // Hard cap: 40% of total calories max from protein
    // (beyond this, no additional benefit + renal load concern)
    final proteinCaloricCap = (targetCalories * 0.40) / 4.0;
    if (proteinG > proteinCaloricCap) {
      proteinG = proteinCaloricCap;
    }

    return proteinG;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 4: FAT
  // ──────────────────────────────────────────────────────────────────────────

  static double _computeFat(
    MetabolicProfile profile,
    NutritionStrategy strategy,
    double targetCalories,
    double proteinG,
  ) {
    // Strategy-driven fat percentage of calories
    double fatG;

    if (strategy.fatDirective.targetCaloriePercent != null) {
      fatG = (targetCalories * strategy.fatDirective.targetCaloriePercent!) / 9.0;
    } else {
      // Minimum floor as primary calculation
      fatG = profile.totalWeightKg * strategy.fatDirective.minGPerKgBodyweight;
    }

    // Hormonal safety floor (CRITICAL for women, PCOS, amenorrhea):
    final hormonalFloor = profile.hasHormonalRisk
        ? profile.totalWeightKg * 0.9 // Higher floor for hormonal risks
        : profile.totalWeightKg * strategy.fatDirective.minGPerKgBodyweight;

    fatG = math.max(fatG, hormonalFloor);
    fatG = math.max(fatG, strategy.safetyConstraints.minFatFloorG);

    // Keto mode: fat must cover remaining calories after protein
    if (profile.fastingContext.experience == FastingExperience.advanced &&
        profile.metabolicFlexibility == MetabolicFlexibility.high) {
      // If in potential keto adaptation, allocate more fat
      final residualForFatAndCarbs =
          targetCalories - (proteinG * 4.0);
      if (residualForFatAndCarbs > 0) {
        final ketoFat = (residualForFatAndCarbs * 0.75) / 9.0;
        fatG = math.max(fatG, ketoFat);
      }
    }

    return fatG;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 5: CARBS
  // ──────────────────────────────────────────────────────────────────────────

  static double _computeCarbs({
    required MetabolicProfile profile,
    required NutritionStrategy strategy,
    required double targetCalories,
    required double proteinG,
    required double fatG,
    required bool isTrainingDay,
  }) {
    // 1. Check absolute ceiling (keto/insulin reset)
    if (strategy.carbDirective.absoluteCarbCeilingG != null) {
      return strategy.carbDirective.absoluteCarbCeilingG!;
    }

    // 2. Carb cycling: training day vs rest day
    if (strategy.carbDirective.cyclingMode == CarbCyclingMode.lowHigh) {
      if (isTrainingDay &&
          strategy.carbDirective.trainingDayCarbTargetG != null) {
        return strategy.carbDirective.trainingDayCarbTargetG!;
      }
      return strategy.carbDirective.restDayCarbCeilingG;
    }

    // 3. Residual calculation (after protein and fat allocated)
    final proteinCals = proteinG * 4.0;
    final fatCals = fatG * 9.0;
    final residual = targetCalories - proteinCals - fatCals;
    double carbsG = residual / 4.0;

    // 4. Insulin sensitivity adjustment:
    // Insulin resistant → hard cap even if residual is higher
    if (profile.insulinSensitivity == InsulinSensitivity.resistant) {
      carbsG = math.min(carbsG, 80.0);
    } else if (profile.insulinSensitivity == InsulinSensitivity.impaired) {
      carbsG = math.min(carbsG, 130.0);
    }

    // 5. Metabolic flexibility adjustment:
    // High flexibility → higher carb tolerance even in deficit
    if (profile.metabolicFlexibility == MetabolicFlexibility.high) {
      carbsG = math.min(
        carbsG,
        isTrainingDay ? 250.0 : 150.0,
      );
    }

    // 6. Strategy ceiling check
    carbsG = math.min(carbsG, strategy.carbDirective.restDayCarbCeilingG * 1.5);

    // 7. Minimum carbs floor (30g — brain/RBC glucose minimum)
    carbsG = math.max(carbsG, 30.0);

    return carbsG;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 6: RECALIBRATION
  // ──────────────────────────────────────────────────────────────────────────

  static double _recalibrate(double proteinG, double fatG, double carbsG) {
    return (proteinG * 4.0) + (fatG * 9.0) + (carbsG * 4.0);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 7: SAFETY VALIDATION
  // ──────────────────────────────────────────────────────────────────────────

  static _MacroResult _applySafetyConstraints({
    required MetabolicProfile profile,
    required NutritionStrategy strategy,
    required double targetCalories,
    required double proteinG,
    required double fatG,
    required double carbsG,
  }) {
    final constraints = strategy.safetyConstraints;

    // Apply floors
    double safeProtein = math.max(proteinG, constraints.minProteinFloor);
    double safeFat = math.max(fatG, constraints.minFatFloorG);
    double safeCarbs = math.max(carbsG, 30.0);

    double safeCalories = _recalibrate(safeProtein, safeFat, safeCarbs);

    // Min calorie check
    final minCalories = constraints.minCaloriesResolver(profile);
    if (safeCalories < minCalories) {
      // Priority: add calories back as carbs (last to be deficient)
      // This protects protein and fat floors.
      final deficit = minCalories - safeCalories;
      safeCarbs += deficit / 4.0;
      safeCalories = _recalibrate(safeProtein, safeFat, safeCarbs);
    }

    // TEF is NOT added as a static factor (old engine bug).
    // TEF is accounted for within the TDEE activity multiplier and
    // the strategy's caloric modifier.

    return _MacroResult(
      calories: safeCalories,
      protein: safeProtein,
      fat: safeFat,
      carbs: safeCarbs,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 8: MEAL DISTRIBUTION
  // ──────────────────────────────────────────────────────────────────────────

  static List<PlannedMeal> _distributeMeals({
    required MetabolicProfile profile,
    required NutritionStrategy strategy,
    required double totalCalories,
    required double totalProteinG,
    required double totalFatG,
    required double totalCarbsG,
    required bool isTrainingDay,
  }) {
    final freq = strategy.mealFrequency;
    final timing = strategy.timingRules;
    final meals = <PlannedMeal>[];

    // Distribute protein: FIRST meal priority (mTOR activation, satiety anchoring)
    final meal1Protein = totalProteinG * timing.firstMealProteinPercent;
    final remainingProtein = totalProteinG - meal1Protein;

    // Carb distribution: workout-centric
    double meal2Carbs = 0.0;
    double meal3Carbs = 0.0;

    if (isTrainingDay) {
      // Backloading or pre-workout priority
      if (timing.carbohydrateBackloading) {
        // 70% carbs in last meal (backloading for overnight glycogen)
        meal3Carbs = totalCarbsG * timing.workoutCarbPercent;
        meal2Carbs = totalCarbsG - meal3Carbs;
      } else {
        // 60% in pre/post-workout meal
        meal2Carbs = totalCarbsG * timing.workoutCarbPercent;
        meal3Carbs = totalCarbsG - meal2Carbs;
      }
    } else {
      // Even distribution on rest days with slight morning bias
      meal2Carbs = totalCarbsG * 0.50;
      meal3Carbs = totalCarbsG - meal2Carbs;
    }

    // Fat: even distribution (fat satiates, no performance timing benefit)
    final fatPerMeal = totalFatG / freq.mealsPerDay;

    // Build meals based on frequency
    if (freq.mealsPerDay == 1) {
      // OMAD
      meals.add(PlannedMeal(
        index: 1,
        label: 'Comida Única (OMAD)',
        calories: totalCalories.round(),
        proteinG: totalProteinG.round(),
        fatG: totalFatG.round(),
        carbsG: totalCarbsG.round(),
        timingNote: 'Dentro de tu ventana de alimentación de 1h.',
        priority: MealPriority.primary,
      ));
    } else if (freq.mealsPerDay == 2) {
      // 16:8, 18:6
      final meal2Protein = remainingProtein;
      final meal1Carbs = math.max(0.0, totalCarbsG - meal2Carbs);
      final meal1Cals = (meal1Protein * 4 + fatPerMeal * 9 + meal1Carbs * 4);
      final meal2Cals = (meal2Protein * 4 + fatPerMeal * 9 + meal2Carbs * 4);

      meals.add(PlannedMeal(
        index: 1,
        label: '1ª Comida (Romper Ayuno)',
        calories: meal1Cals.round(),
        proteinG: meal1Protein.round(),
        fatG: fatPerMeal.round(),
        carbsG: meal1Carbs.round(),
        timingNote:
            'Primera comida al romper el ayuno. Prioriza proteína '
            'completa (≥30g) para activar mTOR. Grasas saludables para '
            'cortisol suave en la apertura de ventana.',
        priority: MealPriority.primary,
      ));

      meals.add(PlannedMeal(
        index: 2,
        label: '2ª Comida (Cierre de Ventana)',
        calories: meal2Cals.round(),
        proteinG: meal2Protein.round(),
        fatG: fatPerMeal.round(),
        carbsG: meal2Carbs.round(),
        timingNote:
            'Cierre de ventana. '
            '${isTrainingDay ? "Máximo de carbohidratos hoy (entrenamiento). " : ""}'
            'Terminar ${timing.stopEatingHoursBeforeSleep.toStringAsFixed(0)}h '
            'antes de dormir.',
        priority: isTrainingDay ? MealPriority.anabolic : MealPriority.closing,
      ));
    } else {
      // 3 meals
      final meal2Protein = remainingProtein * 0.50;
      final meal3Protein = remainingProtein * 0.50;
      final meal1Carbs = math.max(
          0.0, totalCarbsG - meal2Carbs - meal3Carbs);
      final meal1Cals = (meal1Protein * 4 + fatPerMeal * 9 + meal1Carbs * 4);
      final meal2Cals = (meal2Protein * 4 + fatPerMeal * 9 + meal2Carbs * 4);
      final meal3Cals = (meal3Protein * 4 + fatPerMeal * 9 + meal3Carbs * 4);

      meals.add(PlannedMeal(
        index: 1,
        label: '1ª Comida',
        calories: meal1Cals.round(),
        proteinG: meal1Protein.round(),
        fatG: fatPerMeal.round(),
        carbsG: meal1Carbs.round(),
        timingNote: 'Alta proteína para anclar saciedad. Bajos carbohidratos '
            'para mantener insulina baja en la mañana.',
        priority: MealPriority.primary,
      ));

      meals.add(PlannedMeal(
        index: 2,
        label: isTrainingDay ? "Pre/Post-Workout" : "2ª Comida",
        calories: meal2Cals.round(),
        proteinG: meal2Protein.round(),
        fatG: fatPerMeal.round(),
        carbsG: meal2Carbs.round(),
        timingNote: isTrainingDay
            ? 'Ventana peri-entrenamiento: carbohidratos para performance '
                'y refill glucogénico.'
            : 'Comida central del día.',
        priority: isTrainingDay ? MealPriority.anabolic : MealPriority.secondary,
      ));

      meals.add(PlannedMeal(
        index: 3,
        label: '3ª Comida (Cierre)',
        calories: meal3Cals.round(),
        proteinG: meal3Protein.round(),
        fatG: fatPerMeal.round(),
        carbsG: meal3Carbs.round(),
        timingNote:
            'Cierre de ventana ${timing.stopEatingHoursBeforeSleep.toStringAsFixed(0)}h '
            'antes de dormir. Prioriza calidad sobre cantidad.',
        priority: MealPriority.closing,
      ));
    }

    return meals;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 9: ADAPTATION ADJUSTMENTS
  // ──────────────────────────────────────────────────────────────────────────

  static List<PlannedMeal> _applyAdaptationAdjustments({
    required MetabolicProfile profile,
    required List<PlannedMeal> meals,
  }) {
    if (profile.adaptationState == AdaptationState.normal) return meals;

    // For adapted/resistant: Recommend a re-feed protocol hint
    // We add a note to the last meal (will trigger a UI badge later)
    return meals.map((meal) {
      if (meal.index == meals.length) {
        return meal.copyWith(
          timingNote: meal.timingNote +
              '\n⚠️ Adaptación Metabólica detectada: considera un día de '
              're-alimentación (refeed) esta semana con +200–300 kcal en '
              'carbohidratos para restaurar leptina.',
        );
      }
      return meal;
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 10: FASTING WINDOW ALIGNMENT
  // ──────────────────────────────────────────────────────────────────────────

  static List<PlannedMeal> _alignToFastingWindow({
    required MetabolicProfile profile,
    required List<PlannedMeal> meals,
  }) {
    final ctx = profile.fastingContext;
    if (ctx.protocol == FastingProtocol.none) return meals;

    return meals.map((meal) {
      String fastingNote = '';
      if (meal.index == 1) {
        fastingNote =
            '\n🕐 Ventana de Alimentación: ${ctx.feedingWindowHours.toStringAsFixed(0)}h '
            '(Protocolo ${ctx.fastingWindowHours.toStringAsFixed(0)}:${ctx.feedingWindowHours.toStringAsFixed(0)})';
      }
      if (ctx.trainingTiming == TrainingTiming.fasted &&
          meal.priority == MealPriority.anabolic) {
        fastingNote += '\n💪 Entrenamiento en Ayunas: Maximiza oxidación de '
            'grasa y GH. Esta comida es tu recuperación post-ejercicio.';
      }
      if (fastingNote.isEmpty) return meal;
      return meal.copyWith(
          timingNote: meal.timingNote + fastingNote);
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 11: NOTES GENERATION
  // ──────────────────────────────────────────────────────────────────────────

  static List<String> _generateNotes(
    MetabolicProfile profile,
    NutritionStrategy strategy,
    _MacroResult result,
  ) {
    final notes = <String>[];
    final deficit = profile.tdee - result.calories;
    final deficitPct = (deficit / profile.tdee * 100);

    if (deficit > 0) {
      notes.add(
          'Déficit calórico: ${deficit.round()} kcal/día (${deficitPct.toStringAsFixed(1)}% del TDEE).');
    } else if (deficit < 0) {
      notes.add(
          'Superávit calórico: ${(-deficit).round()} kcal/día para ganancia controlada.');
    }

    if (profile.insulinSensitivity == InsulinSensitivity.resistant) {
      notes.add(
          '⚠️ Resistencia a la insulina detectada. Carbohidratos limitados a '
          '${result.carbs.round()}g. Priorizar 30 min de caminata post-prandial.');
    }
    if (profile.adaptationState == AdaptationState.adapted) {
      notes.add(
          '🔄 Adaptación metabólica: el plan incluye ajuste de calorías para '
          'evitar mayor supresión del BMR. Considera un refeed semanal.');
    }
    if (profile.fastingContext.protocol != FastingProtocol.none) {
      notes.add(
          '⏱️ Ayuno ${profile.fastingContext.fastingWindowHours.toStringAsFixed(0)}h activo: '
          'los macros están distribuidos en ${strategy.mealFrequency.mealsPerDay} '
          'comidas dentro de tu ventana de ${profile.fastingContext.feedingWindowHours.toStringAsFixed(0)}h.');
    }
    if (profile.age >= 50) {
      notes.add(
          '🛡️ Protocolo anti-sarcopénico activado (+10% proteína): ${result.protein.round()}g/día '
          'para umbral leucínico elevado en adultos ≥50 años.');
    }

    return notes;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal result transfer object (not exposed outside engine)
// ─────────────────────────────────────────────────────────────────────────────
class _MacroResult {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const _MacroResult({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}
