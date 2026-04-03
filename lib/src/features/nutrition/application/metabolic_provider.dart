import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/empty_preferences_error.dart';
import '../../../shared/domain/models/user_food_preferences.dart';
import '../../../shared/domain/models/user_model.dart';
import '../../profile/application/user_controller.dart';
import '../../profile/data/user_repository.dart';
import '../data/repositories/food_suggestions_repository.dart';
import '../domain/entities/food_suggestion.dart';
import '../domain/entities/meal.dart';
import '../domain/services/recommendation_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// METABOLIC MINUTA PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
//
// Connects the user's biological state (weight, body fat %, pathologies)
// with their food preferences to generate a daily scored minuta via
// RecommendationEngine.
//
// Watches:
//   • currentUserStreamProvider  → weight, body fat, gender, pathologies
//   • userFoodPreferencesProvider → selected food IDs per category
//
// Emits:
//   • AsyncValue<List<Meal>> — loading while algorithm runs
//   • EmptyPreferencesError   — if user has 0 food selections
// ─────────────────────────────────────────────────────────────────────────────

/// The main provider for the daily metabolic minuta.
final metabolicMinutaProvider =
    StateNotifierProvider<MetabolicMinutaNotifier, AsyncValue<List<Meal>>>(
        (ref) {
  return MetabolicMinutaNotifier(ref);
});

class MetabolicMinutaNotifier extends StateNotifier<AsyncValue<List<Meal>>> {
  final Ref _ref;

  MetabolicMinutaNotifier(this._ref) : super(const AsyncValue.loading()) {
    // React to user profile changes (weight, body fat, pathologies)
    _ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider,
        (prev, next) {
      _onUserOrPreferencesChanged();
    });

    // React to food preference changes (selected foods)
    _ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider,
        (prev, next) {
      final uid = next.valueOrNull?.uid;
      if (uid != null) {
        _ref.listen<AsyncValue<UserFoodPreferences>>(
          userFoodPreferencesProvider(uid),
          (prevPrefs, nextPrefs) => _onUserOrPreferencesChanged(),
        );
      }
    });

    // Initial generation
    _onUserOrPreferencesChanged();
  }

  /// Core trigger: whenever user profile or preferences change, regenerate.
  Future<void> _onUserOrPreferencesChanged() async {
    final userAsync = _ref.read(currentUserStreamProvider);

    final user = userAsync.valueOrNull;
    if (user == null) {
      // User not loaded yet — stay in loading
      state = const AsyncValue.loading();
      return;
    }

    // Read preferences
    UserFoodPreferences prefs;
    try {
      prefs = await _ref
          .read(userRepositoryProvider)
          .getUserFoodPreferences(user.uid);
    } catch (e) {
      prefs = UserFoodPreferences.empty();
    }

    // Guard: no selections → EmptyPreferencesError
    if (prefs.allSelectedIds.isEmpty) {
      state = AsyncValue.error(
        const EmptyPreferencesError(),
        StackTrace.current,
      );
      return;
    }

    // Generate the daily minuta
    state = const AsyncValue.loading();

    try {
      final meals = await generateDailyMinuta(
        user: user,
        preferences: prefs,
      );

      if (meals.isEmpty) {
        state = AsyncValue.error(
          const EmptyPreferencesError(
            'No se encontraron alimentos disponibles para tu perfil. '
            'Revisa tus preferencias.',
          ),
          StackTrace.current,
        );
        return;
      }

      state = AsyncValue.data(meals);

      // ── Persistencia de Last Shown ──────────────────────────────────────
      _persistLastShown(user.uid, meals);
    } catch (e, st) {
      debugPrint('❌ [MetabolicMinuta] Error generando minuta: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// 🧠 Generates the daily minuta by scoring the user's food pool
  /// against their metabolic state via RecommendationEngine.
  Future<List<Meal>> generateDailyMinuta({
    required UserModel user,
    required UserFoodPreferences preferences,
  }) async {
    final suggestionsRepo = _ref.read(foodSuggestionsRepositoryProvider);

    // 1. Fetch user's personalized food pool from Firestore
    final List<FoodSuggestion> pool = [];

    for (final category in [
      FoodCategory.ruptura,
      FoodCategory.principal,
      FoodCategory.snack,
    ]) {
      final items = await suggestionsRepo.getSuggestionsByCategory(
        userId: user.uid,
        category: category.label,
      );
      pool.addAll(items);
    }

    if (pool.isEmpty) return [];

    // 2. Filter by ingredient match (≥30% overlap with user preferences)
    final filtered = RecommendationEngine.filterByIngredientMatch(
      pool,
      preferences.allSelectedIds,
    );

    if (filtered.isEmpty) return [];

    // 3. Score each meal via Adaptive Metabolic Scoring
    final Map<String, AdaptiveScore> scores = {};

    final bodyFat = user.currentFatPercentage ?? 25.0;
    final healthCondition =
        user.pathologies.isNotEmpty ? user.pathologies.first : 'general';

    for (final suggestion in filtered) {
      final score = RecommendationEngine.calculateMealScore(
        meal: suggestion,
        bodyFatPercentage: bodyFat,
        lastMonthBodyFat: null, // TODO: wire historical body fat tracking
        userGender: user.gender,
        healthCondition: healthCondition,
      );
      scores[suggestion.foodId] = score;
    }

    // 4. Rank by adaptive score
    final ranked = RecommendationEngine.rankMealsByAdaptiveScore(
      meals: filtered,
      scores: scores,
    );

    // 5. Distribute into meal slots
    final meals = _distributeIntoSlots(ranked);

    debugPrint(
      '✅ [MetabolicMinuta] Generated ${meals.length} meals '
      '(bodyFat: ${bodyFat.toStringAsFixed(1)}%, condition: $healthCondition)',
    );

    return meals;
  }

  /// Distribute ranked scored meals into slots (ruptura, principal, snack).
  List<Meal> _distributeIntoSlots(List<ScoredMeal> ranked) {
    final meals = <Meal>[];
    Meal? ruptura;
    Meal? principal;
    Meal? snack;

    for (final scored in ranked) {
      final slot = _slotFromCategory(scored.meal.category);
      final meal = Meal(
        suggestion: scored.meal,
        score: scored.score,
        slot: slot,
      );

      switch (slot) {
        case MealSlot.ruptura:
          ruptura ??= meal;
        case MealSlot.principal:
          principal ??= meal;
        case MealSlot.snack:
          snack ??= meal;
      }

      // Stop early once all slots are filled
      if (ruptura != null && principal != null && snack != null) break;
    }

    // Build ordered list: ruptura → principal → snack
    if (ruptura != null) meals.add(ruptura);
    if (principal != null) meals.add(principal);
    if (snack != null) meals.add(snack);

    // If we couldn't fill all slots, add remaining by score
    if (meals.length < 3) {
      for (final scored in ranked) {
        if (meals.any((m) => m.foodId == scored.meal.foodId)) continue;
        meals.add(Meal(
          suggestion: scored.meal,
          score: scored.score,
          slot: MealSlot.principal,
        ));
        if (meals.length >= 3) break;
      }
    }

    return meals;
  }

  MealSlot _slotFromCategory(FoodCategory category) {
    return switch (category) {
      FoodCategory.ruptura => MealSlot.ruptura,
      FoodCategory.principal => MealSlot.principal,
      FoodCategory.snack => MealSlot.snack,
    };
  }

  /// Persist last_shown timestamp for displayed meals in Firestore.
  Future<void> _persistLastShown(String uid, List<Meal> meals) async {
    try {
      final ids = meals.map((m) => m.foodId).toList();
      await _ref.read(foodSuggestionsRepositoryProvider).markAsShown(uid, ids);

      debugPrint(
        '📝 [MetabolicMinuta] Persisted last_shown for ${ids.length} items',
      );
    } catch (e) {
      // Non-critical: log but don't crash
      debugPrint('⚠️ [MetabolicMinuta] Failed to persist last_shown: $e');
    }
  }

  /// Force refresh (pull-to-refresh or manual trigger)
  Future<void> refresh() => _onUserOrPreferencesChanged();
}
