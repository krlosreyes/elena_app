import 'package:cloud_firestore/cloud_firestore.dart';
import 'metabolic_profile.dart';
import 'nutrition_strategy.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OUTPUT MODEL: MetabolicNutritionPlan
// Replaces the old NutritionPlan model.
// Rich output that includes strategy context, meal distribution, and notes.
// ─────────────────────────────────────────────────────────────────────────────

class MetabolicNutritionPlan {
  final String id;
  final String userId;
  final DateTime calculatedAt;
  final String algorithmVersion;

  // ── Metabolic context (why this plan exists) ──
  final MetabolicProfile profile;
  final NutritionStrategy strategy;
  final bool isTrainingDay;

  // ── Daily targets ──
  final int totalCalories;
  final int proteinGrams;
  final int fatGrams;
  final int carbsGrams;

  // ── Meal-level breakdown ──
  final List<PlannedMeal> meals;

  // ── Telemetry ──
  final double caloricDeficitPercent;
  final List<String> metabolicNotes;

  const MetabolicNutritionPlan({
    required this.id,
    required this.userId,
    required this.calculatedAt,
    required this.algorithmVersion,
    required this.profile,
    required this.strategy,
    required this.isTrainingDay,
    required this.totalCalories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.meals,
    required this.caloricDeficitPercent,
    required this.metabolicNotes,
  });

  // ── Derived helpers ──

  double get proteinCalories => proteinGrams * 4.0;
  double get fatCalories => fatGrams * 9.0;
  double get carbCalories => carbsGrams * 4.0;

  double get proteinPercent =>
      totalCalories > 0 ? (proteinCalories / totalCalories * 100) : 0;
  double get fatPercent =>
      totalCalories > 0 ? (fatCalories / totalCalories * 100) : 0;
  double get carbPercent =>
      totalCalories > 0 ? (carbCalories / totalCalories * 100) : 0;

  bool get isInDeficit => caloricDeficitPercent > 0;
  bool get isInSurplus => caloricDeficitPercent < 0;

  /// VisualPlate representation (for the existing UI)
  Map<String, double> get visualPlate => {
        'protein': proteinPercent / 100,
        'fat': fatPercent / 100,
        'carbs': carbPercent / 100,
      };

  /// Converts to a Firestore-compatible map (for persistence).
  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'user_id': userId,
        'calculated_at': Timestamp.fromDate(calculatedAt),
        'algorithm_version': algorithmVersion,
        'strategy_name': strategy.name,
        'goal': profile.goal.name,
        'is_training_day': isTrainingDay,
        'total_calories': totalCalories,
        'protein_grams': proteinGrams,
        'fat_grams': fatGrams,
        'carbs_grams': carbsGrams,
        'caloric_deficit_percent': caloricDeficitPercent,
        'metabolic_notes': metabolicNotes,
        'meals': meals.map((m) => m.toMap()).toList(),
        // Profile snapshot for audit trail
        'profile_snapshot': {
          'body_fat_percent': profile.bodyFatPercent,
          'lean_mass_kg': profile.leanMassKg,
          'bmr': profile.bmr,
          'tdee': profile.tdee,
          'insulin_sensitivity': profile.insulinSensitivity.name,
          'metabolic_flexibility': profile.metabolicFlexibility.name,
          'adaptation_state': profile.adaptationState.name,
          'fasting_protocol': profile.fastingContext.protocol.name,
        },
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// PLANNED MEAL
// ─────────────────────────────────────────────────────────────────────────────

enum MealPriority {
  primary, // First meal, protein anchor
  secondary, // Mid-day
  anabolic, // Peri-workout
  closing, // Last meal, wind-down
}

class PlannedMeal {
  final int index;
  final String label;
  final int calories;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final String timingNote;
  final MealPriority priority;

  const PlannedMeal({
    required this.index,
    required this.label,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.timingNote,
    required this.priority,
  });

  PlannedMeal copyWith({
    String? label,
    int? calories,
    int? proteinG,
    int? fatG,
    int? carbsG,
    String? timingNote,
    MealPriority? priority,
  }) =>
      PlannedMeal(
        index: index,
        label: label ?? this.label,
        calories: calories ?? this.calories,
        proteinG: proteinG ?? this.proteinG,
        fatG: fatG ?? this.fatG,
        carbsG: carbsG ?? this.carbsG,
        timingNote: timingNote ?? this.timingNote,
        priority: priority ?? this.priority,
      );

  Map<String, dynamic> toMap() => {
        'index': index,
        'label': label,
        'calories': calories,
        'protein_g': proteinG,
        'fat_g': fatG,
        'carbs_g': carbsG,
        'timing_note': timingNote,
        'priority': priority.name,
      };

  double get proteinPercent =>
      calories > 0 ? (proteinG * 4 / calories * 100) : 0;
  double get fatPercent =>
      calories > 0 ? (fatG * 9 / calories * 100) : 0;
  double get carbPercent =>
      calories > 0 ? (carbsG * 4 / calories * 100) : 0;
}
