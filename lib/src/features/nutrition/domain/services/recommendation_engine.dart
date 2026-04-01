import 'dart:math' as math;

import '../entities/food_suggestion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADAPTIVE METABOLIC SCORING SYSTEM
// ─────────────────────────────────────────────────────────────────────────────
// Core Algorithm:
// 1. Input: User metabolic state (bodyFat%, BMI, health condition) + available foods
// 2. Dynamic Scoring: Adjust bonuses based on body fat percentage and progress
// 3. Query: Filter meals from 'user_food_suggestions' with ≥70% ingredient match
// 4. Output: Ranked List<FoodSuggestion> with adaptive reasoning
// ─────────────────────────────────────────────────────────────────────────────

class RecommendationEngine {
  // ──────────────────────────────────────────────────────────────────────────
  // MAIN ENTRY POINT: Adaptive Meal Scoring
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculate adaptive score for a meal based on user metabolic state.
  ///
  /// Input Variables:
  ///   - meal: FoodSuggestion with macros
  ///   - bodyFatPercentage: Current body fat % (e.g., 28.5 for women, 25 for men)
  ///   - lastMonthBodyFat: Previous month's body fat % (for trend detection)
  ///   - userGender: 'M' or 'F' (affects body fat thresholds)
  ///   - healthCondition: e.g., 'overweight', 'sarcopenia', 'metabolic_syndrome'
  ///
  /// Output:
  ///   - AdaptiveScore with score, reasoning, and metadata
  static AdaptiveScore calculateMealScore({
    required FoodSuggestion meal,
    required double bodyFatPercentage,
    required double? lastMonthBodyFat,
    required String userGender, // 'M' or 'F'
    required String healthCondition,
  }) {
    // ──────────────────────────────────────────────────────────────────────
    // STEP 1: BASELINE SCORE
    // ──────────────────────────────────────────────────────────────────────
    double baseScore = _calculateBaseScore(meal);

    // ──────────────────────────────────────────────────────────────────────
    // STEP 2: DETERMINE BODY FAT THRESHOLD
    // ──────────────────────────────────────────────────────────────────────
    final bodyFatThreshold = _getBodyFatThreshold(userGender);
    final isAboveThreshold = bodyFatPercentage > bodyFatThreshold;

    // ──────────────────────────────────────────────────────────────────────
    // STEP 3: ADAPTIVE BONUSES (Body Fat > Threshold)
    // ──────────────────────────────────────────────────────────────────────
    double adaptiveScore = baseScore;
    final List<String> bonusReasons = [];

    if (isAboveThreshold) {
      // LOW CARB BONUS: If meal.macros.c < 10g
      if (meal.macros.carbs < 10) {
        final lowCarbBonus = _calculateLowCarbBonus(
          bodyFatPercentage,
          lastMonthBodyFat,
          userGender,
        );
        adaptiveScore += lowCarbBonus;
        bonusReasons.add(
          '💚 Low Carb Bonus: +${lowCarbBonus.toStringAsFixed(1)} pts (${meal.macros.carbs}g carbs)',
        );
      }

      // HIGH PROTEIN BONUS: If meal.macros.p > 25g
      if (meal.macros.protein > 25) {
        const highProteinBonus = 15.0;
        adaptiveScore += highProteinBonus;
        bonusReasons.add(
          '💪 High Protein Bonus: +${highProteinBonus.toStringAsFixed(1)} pts (${meal.macros.protein}g protein)',
        );
      }

      // CALORIC DENSITY PENALTY: If meal.macros.kcal > 500
      if (meal.macros.kcal > 500) {
        const caloricPenalty = -10.0;
        adaptiveScore += caloricPenalty;
        bonusReasons.add(
          '⚠️ Caloric Density Penalty: ${caloricPenalty.toStringAsFixed(1)} pts (${meal.macros.kcal} kcal)',
        );
      }
    }

    // ──────────────────────────────────────────────────────────────────────
    // STEP 4: HEALTH CONDITION ADJUSTMENTS
    // ──────────────────────────────────────────────────────────────────────
    adaptiveScore += _applyHealthConditionAdjustment(
      meal,
      healthCondition,
      bonusReasons,
    );

    // ──────────────────────────────────────────────────────────────────────
    // STEP 5: GENERATE REASONING
    // ──────────────────────────────────────────────────────────────────────
    final reasoning = _generateRecommendationReasoning(
      bodyFatPercentage,
      bodyFatThreshold,
      bonusReasons,
      healthCondition,
    );

    return AdaptiveScore(
      mealId: meal.foodId,
      mealName: meal.name,
      baseScore: baseScore,
      adaptiveScore: math.max(0.0, adaptiveScore), // Never negative
      macros: meal.macros,
      reasoning: reasoning,
      bonusesApplied: bonusReasons,
      isAboveBodyFatThreshold: isAboveThreshold,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 1: BASELINE SCORE CALCULATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculate baseline nutritional score (1-100) before adaptive adjustments.
  ///
  /// Factors:
  ///   - Macro balance (protein > 20g, fats present, moderate carbs)
  ///   - Macro ratio alignment (higher protein ratio = higher score)
  ///   - Caloric efficiency (kcal per 100g)
  static double _calculateBaseScore(FoodSuggestion meal) {
    double score = 50.0; // Baseline midpoint

    // Protein bonus (critical for body composition)
    if (meal.macros.protein >= 20) {
      score += 15.0;
    } else if (meal.macros.protein >= 15) {
      score += 10.0;
    }

    // Carbs penalty (for high carb foods)
    if (meal.macros.carbs > 30) {
      score -= 8.0;
    } else if (meal.macros.carbs > 15) {
      score -= 4.0;
    }

    // Fat presence (essential for hormones)
    if (meal.macros.fat >= 3) {
      score += 5.0;
    }

    // Caloric efficiency: kcal per gram of macro nutrients
    final macroCalories =
        (meal.macros.protein * 4) +
        (meal.macros.carbs * 4) +
        (meal.macros.fat * 9);
    if (macroCalories > 0) {
      final efficiency = meal.macros.kcal / macroCalories;
      if (efficiency > 1.0) {
        score += 5.0; // Dense in calories (good for satiety)
      }
    }

    return score.clamp(0.0, 100.0);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 2: BODY FAT THRESHOLD
  // ──────────────────────────────────────────────────────────────────────────

  /// Get gender-adjusted body fat threshold.
  ///
  /// - Men: 25% (threshold for health concerns)
  /// - Women: 32% (adjusted for essential fat + hormonal differences)
  static double _getBodyFatThreshold(String userGender) {
    return userGender.toUpperCase() == 'F' ? 32.0 : 25.0;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 3: LOW CARB BONUS (ADAPTIVE)
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculate low carb bonus with PROGRESS ADAPTATION.
  ///
  /// Base: +20 points if bodyFat > threshold
  /// PLATEAU DETECTION:
  ///   - If bodyFat hasn't improved in 30 days: Increase to +30
  ///   - This encourages stricter carb restriction when progress stalls
  static double _calculateLowCarbBonus(
    double currentBodyFat,
    double? lastMonthBodyFat,
    String userGender,
  ) {
    const baseBonus = 20.0;
    const plateauBonus = 30.0;

    // If no historical data, use base bonus
    if (lastMonthBodyFat == null) {
      return baseBonus;
    }

    // Check for plateau (body fat decreased < 1%)
    final improvement = lastMonthBodyFat - currentBodyFat;
    if (improvement < 1.0) {
      // Plateau detected: increase bonus to encourage dietary strictness
      return plateauBonus;
    }

    // Progressing: maintain base bonus
    return baseBonus;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 4: HEALTH CONDITION ADJUSTMENTS
  // ──────────────────────────────────────────────────────────────────────────

  /// Apply condition-specific score adjustments.
  ///
  /// - 'overweight': Boost low-carb, high-protein foods
  /// - 'sarcopenia': Heavily boost high-protein (critical for muscle preservation)
  /// - 'metabolic_syndrome': Penalize high kcal, boost fiber (if available)
  /// - 'insulin_resistance': Boost low carb, penalize simple carbs
  static double _applyHealthConditionAdjustment(
    FoodSuggestion meal,
    String condition,
    List<String> bonusReasons,
  ) {
    double adjustment = 0.0;

    switch (condition.toLowerCase()) {
      case 'overweight':
        if (meal.macros.protein > 30) {
          adjustment += 10.0;
          bonusReasons.add('⚡ Overweight Protocol: +10 pts (protein priority)');
        }
        if (meal.macros.carbs < 5) {
          adjustment += 5.0;
          bonusReasons.add('⚡ Overweight Protocol: +5 pts (minimal carbs)');
        }

      case 'sarcopenia':
        // CRITICAL: Muscle preservation through high protein
        if (meal.macros.protein > 35) {
          adjustment += 20.0;
          bonusReasons.add(
            '💪 Sarcopenia Protocol: +20 pts (CRITICAL protein)',
          );
        } else if (meal.macros.protein > 25) {
          adjustment += 12.0;
          bonusReasons.add('💪 Sarcopenia Protocol: +12 pts (high protein)');
        }

      case 'metabolic_syndrome':
        // Penalize ultra-caloric meals
        if (meal.macros.kcal > 400) {
          adjustment -= 15.0;
          bonusReasons.add('⚠️ MetS Protocol: -15 pts (high calories)');
        }
        // Boost moderate options
        if (meal.macros.kcal < 250 && meal.macros.protein > 15) {
          adjustment += 8.0;
          bonusReasons.add('⚠️ MetS Protocol: +8 pts (moderate + protein)');
        }

      case 'insulin_resistance':
        if (meal.macros.carbs < 8) {
          adjustment += 15.0;
          bonusReasons.add('🔴 IR Protocol: +15 pts (very low carb)');
        }
        if (meal.macros.kcal > 600) {
          adjustment -= 8.0;
          bonusReasons.add('🔴 IR Protocol: -8 pts (caloric load)');
        }
    }

    return adjustment;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 5: GENERATE RECOMMENDATION REASONING
  // ──────────────────────────────────────────────────────────────────────────

  /// Generate user-facing explanation for the recommendation.
  static String _generateRecommendationReasoning(
    double currentBodyFat,
    double threshold,
    List<String> bonusReasons,
    String condition,
  ) {
    final status = currentBodyFat > threshold ? 'elevada' : 'saludable';
    final buffer = StringBuffer();

    buffer.writeln(
      '📊 Recomendado por tu nivel actual de grasa corporal ($currentBodyFat% - $status)',
    );
    buffer.writeln('para optimizar la oxidación lipídica.\n');

    if (bonusReasons.isNotEmpty) {
      buffer.writeln('✅ Razones del score:');
      for (final reason in bonusReasons) {
        buffer.writeln('   $reason');
      }
    }

    if (condition.isNotEmpty) {
      buffer.writeln('\n🎯 Optimizado para: ${_conditionLabel(condition)}');
    }

    return buffer.toString().trim();
  }

  /// Get user-friendly label for health condition.
  static String _conditionLabel(String condition) {
    return switch (condition.toLowerCase()) {
      'overweight' => 'Pérdida de Peso (Sobrepeso)',
      'sarcopenia' => 'Preservación Muscular (Sarcopenia)',
      'metabolic_syndrome' => 'Control Metabólico (Síndrome Metabólico)',
      'insulin_resistance' => 'Sensibilidad a Insulina',
      _ => 'Salud General',
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // QUERY FILTERING: Ingredient Match Validation
  // ──────────────────────────────────────────────────────────────────────────

  /// Filter meals where ≥70% of ingredients match user's selected food IDs.
  ///
  /// Input:
  ///   - meals: List of FoodSuggestion from 'user_food_suggestions'
  ///   - userSelectedFoodIds: Inventory of foods user is comfortable eating
  ///
  /// Output:
  ///   - Filtered list where each meal has ≥70% ingredient overlap
  static List<FoodSuggestion> filterByIngredientMatch(
    List<FoodSuggestion> meals,
    List<String> userSelectedFoodIds,
  ) {
    return meals.where((meal) {
      // In a real system, meals would have ingredient lists.
      // For now, we check if the meal's tags overlap with user food IDs.
      // This is a simplified heuristic.

      if (userSelectedFoodIds.isEmpty) return true; // No filter if empty

      final matchCount = meal.tags
          .where((tag) => userSelectedFoodIds.contains(tag))
          .length;
      final matchPercentage = meal.tags.isEmpty
          ? 0.0
          : (matchCount / meal.tags.length) * 100;

      return matchPercentage >= 70.0;
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FINAL RANKING: Sort by Adaptive Score
  // ──────────────────────────────────────────────────────────────────────────

  /// Rank meals by adaptive score (descending).
  ///
  /// Input:
  ///   - meals: List of FoodSuggestion
  ///   - scores: Map[mealId, AdaptiveScore]
  ///
  /// Output:
  ///   - Sorted List[FoodSuggestion] + scores ready for UI display
  static List<ScoredMeal> rankMealsByAdaptiveScore({
    required List<FoodSuggestion> meals,
    required Map<String, AdaptiveScore> scores,
  }) {
    final scored = meals
        .map(
          (meal) => ScoredMeal(
            meal: meal,
            score:
                scores[meal.foodId] ??
                AdaptiveScore.neutral(meal.foodId, meal.name),
          ),
        )
        .toList();

    // Sort by adaptive score (descending)
    scored.sort(
      (a, b) => b.score.adaptiveScore.compareTo(a.score.adaptiveScore),
    );

    return scored;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// Adaptive score for a single meal recommendation.
class AdaptiveScore {
  final String mealId;
  final String mealName;
  final double baseScore; // Before adaptive adjustments
  final double adaptiveScore; // After adaptive adjustments
  final FoodMacros macros; // From food_suggestion
  final String reasoning; // User-facing explanation
  final List<String> bonusesApplied; // Debug: which bonuses were applied
  final bool isAboveBodyFatThreshold;

  const AdaptiveScore({
    required this.mealId,
    required this.mealName,
    required this.baseScore,
    required this.adaptiveScore,
    required this.macros,
    required this.reasoning,
    required this.bonusesApplied,
    required this.isAboveBodyFatThreshold,
  });

  /// Neutral score for meals without adaptive adjustments.
  factory AdaptiveScore.neutral(String id, String name) {
    return AdaptiveScore(
      mealId: id,
      mealName: name,
      baseScore: 50.0,
      adaptiveScore: 50.0,
      macros: FoodMacros(protein: 0, carbs: 0, fat: 0, kcal: 0),
      reasoning: 'Sin datos de score disponibles',
      bonusesApplied: [],
      isAboveBodyFatThreshold: false,
    );
  }
}

/// Meal with its adaptive score (for ranking/display).
class ScoredMeal {
  final FoodSuggestion meal;
  final AdaptiveScore score;

  const ScoredMeal({required this.meal, required this.score});

  /// Convert to JSON for API/storage
  Map<String, dynamic> toJson() => {
    'meal': {
      'id': meal.foodId,
      'name': meal.name,
      'macros': meal.macros.toMap(),
    },
    'score': {
      'base': score.baseScore,
      'adaptive': score.adaptiveScore,
      'reasoning': score.reasoning,
    },
  };
}
