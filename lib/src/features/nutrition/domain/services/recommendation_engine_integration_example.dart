import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/food_suggestion.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/metabolic_profile.dart';
import 'package:elena_app/src/features/nutrition/domain/services/recommendation_engine.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INTEGRATION EXAMPLE: How to use RecommendationEngine in your repository/provider
// ─────────────────────────────────────────────────────────────────────────────

// Placeholder for Firestore (in real code, injection is preferred)
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// STEP 1: In your FoodRepository, add this method
class FoodRepositoryExample {
  /// Get meal recommendations adapted to user's metabolic state.
  Future<List<ScoredMeal>> getAdaptiveRecommendations({
    required MetabolicProfile profile,
    required List<String> userSelectedFoodIds,
  }) async {
    try {
      // 1. FETCH: Get all meals from Firestore
      final mealDocs = await _firestore
          .collection('user_food_suggestions')
          .limit(100)
          .get();

      final allMeals = mealDocs.docs
          .map((doc) => FoodSuggestion.fromFirestore(doc))
          .toList();

      // 2. FILTER: Keep only meals with ≥70% ingredient overlap
      final filteredMeals = RecommendationEngine.filterByIngredientMatch(
        allMeals,
        userSelectedFoodIds,
      );

      if (filteredMeals.isEmpty) {
        debugPrint(
          '[Recommendations] No meals matched user foods. Using all meals.',
        );
      }

      // 3. SCORE: Calculate adaptive score for each meal
      final scores = <String, AdaptiveScore>{};

      for (final meal in filteredMeals.isNotEmpty ? filteredMeals : allMeals) {
        final score = RecommendationEngine.calculateMealScore(
          meal: meal,
          bodyFatPercentage: profile.bodyFatPercent,
          lastMonthBodyFat: null, // MetabolicProfile currently does not store history
          userGender: profile.gender,
          healthCondition: profile.hasMetabolicRisk ? 'metabolic_syndrome' : 'none',
        );
        scores[meal.foodId] = score;

        debugPrint(
          '[Recommendation Score] ${meal.name}: ${score.adaptiveScore.toStringAsFixed(1)} pts',
        );
      }

      // 4. RANK: Sort by adaptive score (descending)
      final rankedMeals = RecommendationEngine.rankMealsByAdaptiveScore(
        meals: filteredMeals.isNotEmpty ? filteredMeals : allMeals,
        scores: scores,
      );

      return rankedMeals;
    } catch (e) {
      debugPrint('[Error] Failed to get adaptive recommendations: $e');
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: UI Components using the adaptive engine
// ─────────────────────────────────────────────────────────────────────────────

class MealRecommendationCard extends StatelessWidget {
  final String mealName;
  final double adaptiveScore;
  final double baseScore;
  final SuggestionMacros macros;
  final String reasoning;
  final List<String> bonuses;

  const MealRecommendationCard({
    super.key,
    required this.mealName,
    required this.adaptiveScore,
    required this.baseScore,
    required this.macros,
    required this.reasoning,
    required this.bonuses,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mealName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _scoreColor(adaptiveScore),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${adaptiveScore.toStringAsFixed(1)} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base: ${baseScore.toStringAsFixed(1)} → Adaptive: ${adaptiveScore.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: math.min(adaptiveScore / 130.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _scoreColor(adaptiveScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MacroChip(label: 'P', value: '${macros.protein}g'),
                _MacroChip(label: 'C', value: '${macros.carbs}g'),
                _MacroChip(label: 'F', value: '${macros.fat}g'),
                _MacroChip(label: 'Cal', value: '${macros.kcal}'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reasoning,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (bonuses.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '✨ Bonuses Applied:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              for (final bonus in bonuses)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '  • $bonus',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 100) return const Color(0xFF00FF00);
    if (score >= 80) return const Color(0xFF90EE90);
    if (score >= 60) return const Color(0xFFFFFF00);
    return const Color(0xFFFF6347);
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;

  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
