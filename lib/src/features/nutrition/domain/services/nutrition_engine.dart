import 'package:uuid/uuid.dart';

import '../entities/nutrition_plan.dart';

/// @Deprecated("2.0.0")
/// This class has been deprecated due to a critical bug in protein calculation:
/// - BUG: Uses total weight instead of lean mass for protein calculation
/// - IMPACT: Results in +33% protein overfeeding (198g vs 148.5g for 90kg @ 25% BF)
/// - REPLACEMENT: Use MetabolicEngine.generate() instead
///
/// This deprecation was added on 2026-03-30. The class will be removed in v2.0.0.
/// Monitor usage in server logs and IDE warnings for 1 month before removal.
///
/// Related Analysis: See SAFE_REFACTOR_ANALYSIS.md for detailed bug documentation
class NutritionEngine {
  /// Calculates a comprehensive Nutrition Plan based on user metrics.
  ///
  /// [weightKg]: Current body weight in kg.
  /// [bodyFatPercentage]: Body fat percentage (0.0 - 100.0). E.g., 20.0 for 20%.
  /// [activityLevel]: 'sedentary', 'light', 'moderate', 'active', 'athlete'.
  /// [gender]: 'male' or 'female' (used for calorie floor safety guards).
  /// [goal]: 'lose_fat', 'maintain', 'muscle_gain'.
  NutritionPlan calculatePlan({
    required String userId,
    required double weightKg,
    required double bodyFatPercentage,
    required String activityLevel,
    required String gender,
    required String goal, // 'lose_fat', 'maintain', 'muscle_gain'
  }) {
    // 1. Calculate Body Composition
    final fatMassKg = weightKg * (bodyFatPercentage / 100);
    final fatFreeMassKg = weightKg - fatMassKg;

    // 2. Base Metabolic Rate (BMR) - Katch-McArdle Formula
    // BMR = 370 + (21.6 * Lean Body Mass in kg)
    final bmr = 370 + (21.6 * fatFreeMassKg);

    // 3. Total Daily Energy Expenditure (TDEE)
    final activityMultiplier = _getActivityMultiplier(activityLevel);
    double tdee = bmr * activityMultiplier;

    // 4. Thermic Effect of Food (TEF) - Estimated at 10%
    tdee = tdee * 1.10;

    // 5. Goal Adjustment
    double targetCalories = tdee;
    if (goal == 'lose_fat') {
      targetCalories -= 500; // Standard deficit
    } else if (goal == 'muscle_gain') {
      targetCalories += 300; // Lean surplus
    }

    // 6. Safety Guards (Calorie Floor)
    final minCalories = gender.toLowerCase() == 'male' ? 1500.0 : 1200.0;
    if (targetCalories < minCalories) {
      targetCalories = minCalories;
    }

    // 7. Macro Calculation
    // Protein: 2.0g to 2.2g per kg of TOTAL weight (for active individuals in deficit)
    // Capping at 2.5g/kg for safety.
    double proteinPerKg = 2.0;
    if (goal == 'muscle_gain') proteinPerKg = 2.2;
    if (bodyFatPercentage > 30) {
      proteinPerKg =
          1.6; // Adjust for higher BF to avoid over-prescription based on total weight
    }

    double proteinGrams = weightKg * proteinPerKg;
    // Safety Cop: Max 2.5g/kg
    if (proteinGrams > weightKg * 2.5) proteinGrams = weightKg * 2.5;

    // Fat: Minimum 0.8g per kg (Standard recommendation for hormonal health)
    // Or 0.6g/kg absolute floor from prompt rules
    double fatPerKg = 0.8;
    double fatGrams = weightKg * fatPerKg;
    // Ensure min 0.6g/kg strict floor
    if (fatGrams < weightKg * 0.6) fatGrams = weightKg * 0.6;

    // Carbs: Remainder
    final proteinCals = proteinGrams * 4;
    final fatCals = fatGrams * 9;
    final remainingCals = targetCalories - (proteinCals + fatCals);

    // If remaining cals is negative (edge case with low cals/high protein), adjust fat/protein or accept slight overage?
    // For strict math, we assume user follows priorities.
    // If remaining < 0, simple cap: we assume TDEE floor protected us mostly, but let's clamp carbs to 50g min.
    double carbsGrams = remainingCals / 4;
    if (carbsGrams < 50) {
      carbsGrams = 50;
      // Recalculate total calories to respect macro floors
      targetCalories = (proteinGrams * 4) + (fatGrams * 9) + (carbsGrams * 4);
    }

    // 8. Visual Plate Logic
    // Standard Elena Plate: 50% Veggies, 25% Protein, 25% Carbs
    // We can adjust this slightly based on the calculated ratios if needed,
    // but the Prompt requested the "Visual Model 50/25/25".
    // We will keep it static unless specific conditions met (e.g. Keto, which isn't requested yet).
    const visualPlate = VisualPlate(
      vegetablesPercent: 0.50,
      proteinPercent: 0.25,
      carbsPercent: 0.25,
      carbsType: 'complex_low_gi',
    );

    return NutritionPlan(
      id: const Uuid().v4(),
      userId: userId,
      calculatedAt: DateTime.now(),
      baseMetrics: BaseMetrics(
        weightKg: weightKg,
        bodyFatPercentage: bodyFatPercentage,
        fatFreeMassKg: fatFreeMassKg,
        bmr: bmr,
        tdee: tdee,
        activityMultiplier: activityMultiplier,
      ),
      macroTargets: MacroTargets(
        totalCalories: targetCalories.round(),
        proteinGrams: proteinGrams.round(),
        fatGrams: fatGrams.round(),
        carbsGrams: carbsGrams.round(),
      ),
      visualPlate: visualPlate,
      weeklyAdjustment: const WeeklyAdjustment(),
    );
  }

  double _getActivityMultiplier(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'active':
        return 1.725;
      case 'athlete':
        return 1.9;
      default:
        return 1.2;
    }
  }
}
