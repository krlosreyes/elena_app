import 'package:elena_app/src/features/nutrition/domain/entities/food_suggestion.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/metabolic_profile.dart';
import 'package:elena_app/src/features/nutrition/domain/services/recommendation_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INTEGRATION EXAMPLE: How to use RecommendationEngine in your repository/provider
// ─────────────────────────────────────────────────────────────────────────────

// STEP 1: In your FoodRepository, add this method
class FoodRepositoryExample {
  /// Get meal recommendations adapted to user's metabolic state.
  ///
  /// Implements the full pipeline:
  /// 1. Fetch meals from Firestore 'user_food_suggestions'
  /// 2. Filter by ingredient match (≥70%)
  /// 3. Score each meal with adaptive algorithm
  /// 4. Rank by score (descending)
  /// 5. Return sorted recommendations
  Future<List<ScoredMeal>> getAdaptiveRecommendations({
    required MetabolicProfile profile,
    required List<String> userSelectedFoodIds,
  }) async {
    try {
      // ──────────────────────────────────────────────────────────────────────
      // 1. FETCH: Get all meals from Firestore
      // ──────────────────────────────────────────────────────────────────────
      final mealDocs = await firestore
          .collection('user_food_suggestions')
          .limit(100) // Adjust as needed
          .get();

      final allMeals = mealDocs.docs
          .map((doc) => FoodSuggestion.fromFirestore(doc))
          .toList();

      // ──────────────────────────────────────────────────────────────────────
      // 2. FILTER: Keep only meals with ≥70% ingredient overlap
      // ──────────────────────────────────────────────────────────────────────
      final filteredMeals = RecommendationEngine.filterByIngredientMatch(
        allMeals,
        userSelectedFoodIds,
      );

      if (filteredMeals.isEmpty) {
        // Fallback: Return top-scored meals without filtering
        debugPrint(
          '[Recommendations] No meals matched user foods. Using all meals.',
        );
        // Could use allMeals or return empty
      }

      // ──────────────────────────────────────────────────────────────────────
      // 3. SCORE: Calculate adaptive score for each meal
      // ──────────────────────────────────────────────────────────────────────
      final scores = <String, AdaptiveScore>{};

      for (final meal in filteredMeals.isNotEmpty ? filteredMeals : allMeals) {
        final score = RecommendationEngine.calculateMealScore(
          meal: meal,
          bodyFatPercentage: profile.bodyFatPercentage,
          lastMonthBodyFat: profile.previousMonthBodyFatPercentage,
          userGender: profile.user.gender, // 'M' or 'F'
          healthCondition:
              profile.user.healthCondition ??
              'none', // 'overweight', 'sarcopenia', etc.
        );
        scores[meal.foodId] = score;

        // Debug: Log scoring decisions
        debugPrint(
          '[Recommendation Score] ${meal.name}: ${score.adaptiveScore.toStringAsFixed(1)} pts',
        );
      }

      // ──────────────────────────────────────────────────────────────────────
      // 4. RANK: Sort by adaptive score (descending)
      // ──────────────────────────────────────────────────────────────────────
      final rankedMeals = RecommendationEngine.rankMealsByAdaptiveScore(
        meals: filteredMeals.isNotEmpty ? filteredMeals : allMeals,
        scores: scores,
      );

      // ──────────────────────────────────────────────────────────────────────
      // 5. RETURN: Sorted list ready for UI
      // ──────────────────────────────────────────────────────────────────────
      debugPrint(
        '[Recommendations] Ranked ${rankedMeals.length} meals successfully',
      );

      return rankedMeals;
    } catch (e) {
      debugPrint('[Error] Failed to get adaptive recommendations: $e');
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: In your Riverpod provider, use it like this
// ─────────────────────────────────────────────────────────────────────────────

/*
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Create a provider for adaptive meal recommendations
final adaptiveMealRecommendationsProvider =
    FutureProvider.family<List<ScoredMeal>, void>((ref, _) async {
  // Get dependencies
  final profile = await ref.watch(metabolicProfileProvider.future);
  final userFoods = ref.watch(userSelectedFoodsProvider);
  final repository = ref.watch(foodRepositoryProvider);

  // Fetch adaptive recommendations
  return repository.getAdaptiveRecommendations(
    profile: profile,
    userSelectedFoodIds: userFoods,
  );
});

// Usage in UI:
// final recommendations = ref.watch(adaptiveMealRecommendationsProvider);
// recommendations.whenData((meals) {
//   for (final scored in meals.take(5)) {
//     print('${scored.meal.name}: ${scored.score.adaptiveScore}');
//   }
// });
*/

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3: Display in UI Widget
// ─────────────────────────────────────────────────────────────────────────────

/*
class MealRecommendationWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = 
        ref.watch(adaptiveMealRecommendationsProvider);

    return recommendationsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (meals) {
        if (meals.isEmpty) {
          return const Text('No recommendations available');
        }

        return ListView.builder(
          itemCount: meals.take(5).length, // Show top 5
          itemBuilder: (context, index) {
            final scored = meals[index];
            return MealRecommendationCard(
              mealName: scored.meal.name,
              adaptiveScore: scored.score.adaptiveScore,
              baseScore: scored.score.baseScore,
              macros: scored.meal.macros,
              reasoning: scored.score.reasoning,
              bonuses: scored.score.bonusesApplied,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MealRecommendationCard Widget
// ─────────────────────────────────────────────────────────────────────────────

class MealRecommendationCard extends StatelessWidget {
  final String mealName;
  final double adaptiveScore;
  final double baseScore;
  final FoodMacros macros;
  final String reasoning;
  final List<String> bonuses;

  const MealRecommendationCard({
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
            // ── Meal Name + Score ──────────────────────────────────────────
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

            // ── Score Progress Bar ──────────────────────────────────────────
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

            // ── Macros ──────────────────────────────────────────────────────
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

            // ── Reasoning ───────────────────────────────────────────────────
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

            const SizedBox(height: 8),

            // ── Bonuses Applied ────────────────────────────────────────────
            if (bonuses.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 100) return const Color(0xFF00FF00); // Green
    if (score >= 80) return const Color(0xFF90EE90); // Light green
    if (score >= 60) return const Color(0xFFFFFF00); // Yellow
    return const Color(0xFFFF6347); // Red
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
*/

// ─────────────────────────────────────────────────────────────────────────────
// Example Firestore Document Structure (user_food_suggestions)
// ─────────────────────────────────────────────────────────────────────────────

/*
{
  "id": "pollo-asado-001",
  "name": "Pollo Asado",
  "tags": ["pollo", "proteína", "baja-grasa", "asado"],
  "macros": {
    "p": 35,
    "c": 2,
    "g": 5,
    "kcal": 165
  },
  "category": "principal",
  "createdAt": "2026-03-01T10:00:00Z",
  "updatedAt": "2026-03-01T10:00:00Z"
}
*/

// ─────────────────────────────────────────────────────────────────────────────
// Testing the Integration
// ─────────────────────────────────────────────────────────────────────────────

/*
void main() async {
  // Setup
  final profile = MetabolicProfile(
    user: UserModel(...),
    bodyFatPercentage: 28.0,
    previousMonthBodyFatPercentage: 30.0,
    // ... other fields
  );

  final userFoods = ['pollo', 'huevos', 'brócoli', 'salmon'];
  final repo = FoodRepositoryExample();

  // Execute
  final recommendations = await repo.getAdaptiveRecommendations(
    profile: profile,
    userSelectedFoodIds: userFoods,
  );

  // Verify
  print('Top 3 Recommendations:');
  for (final (index, scored) in recommendations.take(3).indexed) {
    print('${index + 1}. ${scored.meal.name} (${scored.score.adaptiveScore} pts)');
    print('   Reasoning: ${scored.score.reasoning}');
    print('---');
  }
}
*/
