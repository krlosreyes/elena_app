import '../services/recommendation_engine.dart';
import 'food_suggestion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MEAL — A scored food item for the daily minuta (metabolic plan)
// ─────────────────────────────────────────────────────────────────────────────

class Meal {
  final FoodSuggestion suggestion;
  final AdaptiveScore score;
  final MealSlot slot;

  const Meal({
    required this.suggestion,
    required this.score,
    required this.slot,
  });

  String get name => suggestion.name;
  String get foodId => suggestion.foodId;
  SuggestionMacros get macros => suggestion.macros;
  double get adaptiveScore => score.adaptiveScore;
  String get reasoning => score.reasoning;
}

/// Time-slot for a meal within the daily minuta
enum MealSlot {
  ruptura, // Fasting break
  principal, // Main meal
  snack, // Strategic snack (optional)
}

extension MealSlotX on MealSlot {
  String get label => switch (this) {
        MealSlot.ruptura => 'Ruptura de Ayuno',
        MealSlot.principal => 'Comida Principal',
        MealSlot.snack => 'Snack Estratégico',
      };
}
