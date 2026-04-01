import 'package:elena_app/src/features/nutrition/domain/entities/food_suggestion.dart';
import 'package:elena_app/src/features/nutrition/domain/services/recommendation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecommendationEngine', () {
    // ────────────────────────────────────────────────────────────────────────
    // TEST 1: Baseline Score Calculation
    // ────────────────────────────────────────────────────────────────────────
    group('Baseline Score', () {
      test('High protein food scores higher', () {
        final highProteinMeal = FoodSuggestion(
          foodId: 'test_1',
          name: 'High Protein',
          tags: ['protein'],
          macros: FoodMacros(protein: 30, carbs: 5, fat: 8, kcal: 200),
          category: FoodCategory.principal,
          preferencesMatch: true,
        );

        final score = RecommendationEngine.calculateMealScore(
          meal: highProteinMeal,
          bodyFatPercentage: 20.0,
          lastMonthBodyFat: null,
          userGender: 'M',
          healthCondition: 'none',
        );

        // Baseline should be > 70 for high protein
        expect(score.baseScore, greaterThan(70.0));
      });

      test('High carb food receives penalty', () {
        final highCarbMeal = FoodSuggestion(
          foodId: 'test_2',
          name: 'High Carb',
          tags: ['carbs'],
          macros: FoodMacros(protein: 10, carbs: 60, fat: 5, kcal: 300),
          category: FoodCategory.principal,
          preferencesMatch: true,
        );

        final score = RecommendationEngine.calculateMealScore(
          meal: highCarbMeal,
          bodyFatPercentage: 20.0,
          lastMonthBodyFat: null,
          userGender: 'M',
          healthCondition: 'none',
        );

        // Baseline should be < 60 for high carbs
        expect(score.baseScore, lessThan(60.0));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 2: Body Fat Threshold
    // ────────────────────────────────────────────────────────────────────────
    group('Body Fat Thresholds', () {
      test('Men threshold is 25%', () {
        final meal = FoodSuggestion(
          foodId: 'test_3',
          name: 'Test Meal',
          tags: [],
          macros: FoodMacros(protein: 20, carbs: 10, fat: 10, kcal: 200),
          category: FoodCategory.principal,
        );

        // Man at 25% body fat (at threshold)
        final scoreAt = RecommendationEngine.calculateMealScore(
          meal: meal,
          bodyFatPercentage: 25.0,
          lastMonthBodyFat: null,
          userGender: 'M',
          healthCondition: 'none',
        );

        // Man at 26% body fat (above threshold)
        final scoreAbove = RecommendationEngine.calculateMealScore(
          meal: meal,
          bodyFatPercentage: 26.0,
          lastMonthBodyFat: null,
          userGender: 'M',
          healthCondition: 'none',
        );

        // Above threshold should potentially score higher
        expect(scoreAbove.isAboveBodyFatThreshold, isTrue);
      });

      test('Women threshold is 32%', () {
        final meal = FoodSuggestion(
          foodId: 'test_4',
          name: 'Test Meal',
          tags: [],
          macros: FoodMacros(protein: 20, carbs: 10, fat: 10, kcal: 200),
          category: FoodCategory.principal,
        );

        // Woman at 32% body fat (at threshold)
        final scoreAt = RecommendationEngine.calculateMealScore(
          meal: meal,
          bodyFatPercentage: 32.0,
          lastMonthBodyFat: null,
          userGender: 'F',
          healthCondition: 'none',
        );

        // Woman at 33% body fat (above threshold)
        final scoreAbove = RecommendationEngine.calculateMealScore(
          meal: meal,
          bodyFatPercentage: 33.0,
          lastMonthBodyFat: null,
          userGender: 'F',
          healthCondition: 'none',
        );

        expect(scoreAbove.isAboveBodyFatThreshold, isTrue);
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 3: Low Carb Bonus (Dynamic Adaptation)
    // ────────────────────────────────────────────────────────────────────────
    group('Low Carb Bonus - Plateau Detection', () {
      test('Progressing: Low carb gets +20', () {
        final lowCarbMeal = FoodSuggestion(
          foodId: 'test_5',
          name: 'Low Carb',
          tags: [],
          macros: FoodMacros(
            protein: 28,
            carbs: 5, // < 10g trigger
            fat: 12,
            kcal: 220,
          ),
          category: FoodCategory.principal,
        );

        // Woman with improving body fat (30% -> 29%)
        final score = RecommendationEngine.calculateMealScore(
          meal: lowCarbMeal,
          bodyFatPercentage: 29.0, // Below threshold, no bonus
          lastMonthBodyFat: 30.0,
          userGender: 'F',
          healthCondition: 'none',
        );

        // Since body fat is below threshold, bonus shouldn't apply
        // But let's test above threshold
        final scoreAboveThreshold = RecommendationEngine.calculateMealScore(
          meal: lowCarbMeal,
          bodyFatPercentage: 35.0, // ABOVE threshold
          lastMonthBodyFat: 36.0, // Improving (1% improvement)
          userGender: 'F',
          healthCondition: 'none',
        );

        // Should contain "Low Carb Bonus: +20" in bonuses
        expect(
          scoreAboveThreshold.bonusesApplied.any(
            (b) => b.contains('Low Carb Bonus: +20'),
          ),
          isTrue,
        );
      });

      test('Plateau: Low carb gets +30 (increased)', () {
        final lowCarbMeal = FoodSuggestion(
          foodId: 'test_6',
          name: 'Low Carb',
          tags: [],
          macros: FoodMacros(protein: 28, carbs: 5, fat: 12, kcal: 220),
          category: FoodCategory.principal,
        );

        // Woman with PLATEAUED body fat (35% -> 34.8%, < 1% improvement)
        final score = RecommendationEngine.calculateMealScore(
          meal: lowCarbMeal,
          bodyFatPercentage: 34.8,
          lastMonthBodyFat: 35.0, // Only 0.2% improvement = plateau
          userGender: 'F',
          healthCondition: 'none',
        );

        // Should contain "Low Carb Bonus: +30" (plateau mode)
        expect(
          score.bonusesApplied.any((b) => b.contains('Low Carb Bonus: +30')),
          isTrue,
        );
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 4: High Protein Bonus
    // ────────────────────────────────────────────────────────────────────────
    group('High Protein Bonus', () {
      test('Protein > 25g gets +15 when above body fat threshold', () {
        final highProteinMeal = FoodSuggestion(
          foodId: 'test_7',
          name: 'High Protein',
          tags: [],
          macros: FoodMacros(
            protein: 35, // > 25g trigger
            carbs: 5,
            fat: 12,
            kcal: 280,
          ),
          category: FoodCategory.principal,
        );

        final score = RecommendationEngine.calculateMealScore(
          meal: highProteinMeal,
          bodyFatPercentage: 35.0, // ABOVE threshold
          lastMonthBodyFat: null,
          userGender: 'F',
          healthCondition: 'none',
        );

        expect(
          score.bonusesApplied.any(
            (b) => b.contains('High Protein Bonus: +15'),
          ),
          isTrue,
        );
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 5: Caloric Density Penalty
    // ────────────────────────────────────────────────────────────────────────
    group('Caloric Density Penalty', () {
      test('Calories > 500 gets -10 when above body fat threshold', () {
        final highCaloreMeal = FoodSuggestion(
          foodId: 'test_8',
          name: 'High Calorie',
          tags: [],
          macros: FoodMacros(
            protein: 20,
            carbs: 30,
            fat: 20,
            kcal: 550, // > 500 trigger
          ),
          category: FoodCategory.principal,
        );

        final score = RecommendationEngine.calculateMealScore(
          meal: highCaloreMeal,
          bodyFatPercentage: 35.0, // ABOVE threshold
          lastMonthBodyFat: null,
          userGender: 'F',
          healthCondition: 'none',
        );

        expect(
          score.bonusesApplied.any(
            (b) => b.contains('Caloric Density Penalty: -10'),
          ),
          isTrue,
        );
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 6: Health Condition Adjustments
    // ────────────────────────────────────────────────────────────────────────
    group('Health Condition Adjustments', () {
      test('Sarcopenia: Protein > 35g gets +20', () {
        final mealHighProtein = FoodSuggestion(
          foodId: 'test_9',
          name: 'Very High Protein',
          tags: [],
          macros: FoodMacros(
            protein: 40, // > 35g trigger
            carbs: 8,
            fat: 10,
            kcal: 250,
          ),
          category: FoodCategory.principal,
        );

        final score = RecommendationEngine.calculateMealScore(
          meal: mealHighProtein,
          bodyFatPercentage: 22.0, // Below threshold
          lastMonthBodyFat: null,
          userGender: 'M',
          healthCondition: 'sarcopenia',
        );

        expect(
          score.bonusesApplied.any(
            (b) => b.contains('Sarcopenia Protocol: +20'),
          ),
          isTrue,
        );
      });

      test('Overweight: Low carbs + high protein get bonuses', () {
        final meal = FoodSuggestion(
          foodId: 'test_10',
          name: 'Weight Loss Meal',
          tags: [],
          macros: FoodMacros(protein: 32, carbs: 4, fat: 8, kcal: 200),
          category: FoodCategory.principal,
        );

        final score = RecommendationEngine.calculateMealScore(
          meal: meal,
          bodyFatPercentage: 28.0,
          lastMonthBodyFat: null,
          userGender: 'F',
          healthCondition: 'overweight',
        );

        // Should have overweight bonuses
        final overweightBonuses = score.bonusesApplied
            .where((b) => b.contains('Overweight Protocol'))
            .length;
        expect(overweightBonuses, greaterThan(0));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 7: Ingredient Matching (70% threshold)
    // ────────────────────────────────────────────────────────────────────────
    group('Ingredient Match Filtering', () {
      test('Meal with ≥70% ingredient overlap passes filter', () {
        final meals = [
          FoodSuggestion(
            foodId: 'meal_1',
            name: 'Meal 1',
            tags: ['pollo', 'brócoli', 'arroz', 'aceite'], // 4 tags
            macros: FoodMacros(protein: 25, carbs: 30, fat: 10, kcal: 350),
            category: FoodCategory.principal,
          ),
        ];

        final userFoods = [
          'pollo',
          'brócoli',
          'arroz',
        ]; // 3 matches out of 4 = 75%

        final filtered = RecommendationEngine.filterByIngredientMatch(
          meals,
          userFoods,
        );

        expect(filtered.length, equals(1)); // Should pass (75% > 70%)
      });

      test('Meal with <70% ingredient overlap is filtered out', () {
        final meals = [
          FoodSuggestion(
            foodId: 'meal_2',
            name: 'Meal 2',
            tags: ['tómate', 'cebolla', 'ajo', 'aceite'], // 4 tags
            macros: FoodMacros(protein: 5, carbs: 20, fat: 10, kcal: 150),
            category: FoodCategory.principal,
          ),
        ];

        final userFoods = ['pollo', 'brócoli', 'arroz']; // 0 matches = 0%

        final filtered = RecommendationEngine.filterByIngredientMatch(
          meals,
          userFoods,
        );

        expect(filtered.length, equals(0)); // Should be filtered out (0% < 70%)
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 8: Adaptive Score Clamping (Never Negative)
    // ────────────────────────────────────────────────────────────────────────
    group('Score Validation', () {
      test('Adaptive score is never negative', () {
        final badMeal = FoodSuggestion(
          foodId: 'test_11',
          name: 'Terrible Meal',
          tags: [],
          macros: FoodMacros(protein: 2, carbs: 100, fat: 0, kcal: 800),
          category: FoodCategory.principal,
        );

        final score = RecommendationEngine.calculateMealScore(
          meal: badMeal,
          bodyFatPercentage: 35.0,
          lastMonthBodyFat: null,
          userGender: 'F',
          healthCondition: 'none',
        );

        expect(score.adaptiveScore, greaterThanOrEqualTo(0.0));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 9: Meal Ranking
    // ────────────────────────────────────────────────────────────────────────
    group('Meal Ranking by Score', () {
      test('Meals are ranked by adaptive score (descending)', () {
        final meals = [
          FoodSuggestion(
            foodId: 'meal_low',
            name: 'Low Score Meal',
            tags: [],
            macros: FoodMacros(protein: 10, carbs: 60, fat: 5, kcal: 320),
            category: FoodCategory.principal,
          ),
          FoodSuggestion(
            foodId: 'meal_high',
            name: 'High Score Meal',
            tags: [],
            macros: FoodMacros(protein: 35, carbs: 5, fat: 12, kcal: 260),
            category: FoodCategory.principal,
          ),
        ];

        final scores = <String, AdaptiveScore>{
          'meal_low': AdaptiveScore(
            mealId: 'meal_low',
            mealName: 'Low Score Meal',
            baseScore: 40.0,
            adaptiveScore: 45.0,
            macros: meals[0].macros,
            reasoning: 'Low score',
            bonusesApplied: [],
            isAboveBodyFatThreshold: false,
          ),
          'meal_high': AdaptiveScore(
            mealId: 'meal_high',
            mealName: 'High Score Meal',
            baseScore: 85.0,
            adaptiveScore: 120.0,
            macros: meals[1].macros,
            reasoning: 'High score',
            bonusesApplied: [],
            isAboveBodyFatThreshold: true,
          ),
        };

        final ranked = RecommendationEngine.rankMealsByAdaptiveScore(
          meals: meals,
          scores: scores,
        );

        // First should be highest score
        expect(ranked[0].score.adaptiveScore, equals(120.0));
        expect(ranked[1].score.adaptiveScore, equals(45.0));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // TEST 10: Real-World Integration Scenario
    // ────────────────────────────────────────────────────────────────────────
    group('Real-World Scenario', () {
      test('Overweight woman with plateau gets best recommendations', () {
        // User profile
        const userBodyFat = 35.0;
        const lastMonthBodyFat = 35.2; // Plateau
        const userGender = 'F';
        const healthCondition = 'overweight';
        final userFoods = ['pollo', 'huevos', 'brócoli', 'salmon'];

        // Available meals
        final meals = [
          FoodSuggestion(
            foodId: 'meal_1',
            name: 'Pollo Asado',
            tags: ['pollo', 'proteína', 'baja-grasa'],
            macros: FoodMacros(protein: 35, carbs: 2, fat: 5, kcal: 165),
            category: FoodCategory.principal,
          ),
          FoodSuggestion(
            foodId: 'meal_2',
            name: 'Huevos con Brócoli',
            tags: ['huevos', 'brócoli', 'proteína'],
            macros: FoodMacros(protein: 18, carbs: 8, fat: 12, kcal: 220),
            category: FoodCategory.principal,
          ),
          FoodSuggestion(
            foodId: 'meal_3',
            name: 'Pizza Italiana', // Not in user foods
            tags: ['masa', 'queso', 'tomate'],
            macros: FoodMacros(protein: 12, carbs: 50, fat: 20, kcal: 480),
            category: FoodCategory.principal,
          ),
        ];

        // Filter
        final filtered = RecommendationEngine.filterByIngredientMatch(
          meals,
          userFoods,
        );

        // Score each filtered meal
        final scores = <String, AdaptiveScore>{};
        for (final meal in filtered) {
          scores[meal.foodId] = RecommendationEngine.calculateMealScore(
            meal: meal,
            bodyFatPercentage: userBodyFat,
            lastMonthBodyFat: lastMonthBodyFat,
            userGender: userGender,
            healthCondition: healthCondition,
          );
        }

        // Rank
        final ranked = RecommendationEngine.rankMealsByAdaptiveScore(
          meals: filtered,
          scores: scores,
        );

        // Assertions
        expect(filtered.length, equals(2)); // Pizza filtered out
        expect(ranked[0].meal.foodId, equals('meal_1')); // Pollo Asado highest
        expect(
          ranked[0].score.adaptiveScore,
          greaterThan(ranked[1].score.adaptiveScore),
        );
      });
    });
  });
}
