import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────
// Category enum
// ─────────────────────────────────────────────────────────────
enum FoodCategory { ruptura, principal, snack }

extension FoodCategoryX on FoodCategory {
  String get label => switch (this) {
        FoodCategory.ruptura => 'Ruptura',
        FoodCategory.principal => 'Principal',
        FoodCategory.snack => 'Snack',
      };

  static FoodCategory fromString(String s) => switch (s.toLowerCase()) {
        'ruptura' => FoodCategory.ruptura,
        'principal' => FoodCategory.principal,
        _ => FoodCategory.snack,
      };
}

// ─────────────────────────────────────────────────────────────
// Macros sub-object
// ─────────────────────────────────────────────────────────────
class SuggestionMacros {
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams (key: 'g' in Firestore)
  final double kcal;

  const SuggestionMacros({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.kcal,
  });

  factory SuggestionMacros.fromMap(Map<String, dynamic> m) => SuggestionMacros(
        protein: (m['p'] as num? ?? 0).toDouble(),
        carbs: (m['c'] as num? ?? 0).toDouble(),
        fat: (m['g'] as num? ?? 0).toDouble(),
        kcal: (m['kcal'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'p': protein,
        'c': carbs,
        'g': fat,
        'kcal': kcal,
      };
}

// ─────────────────────────────────────────────────────────────
// FoodSuggestion
// ─────────────────────────────────────────────────────────────
class FoodSuggestion {
  final String foodId;
  final String name;
  final List<String> tags;
  final SuggestionMacros macros;
  final FoodCategory category;
  final DateTime? lastShown;
  final bool preferencesMatch;
  final String? sourceMasterId;

  const FoodSuggestion({
    required this.foodId,
    required this.name,
    required this.tags,
    required this.macros,
    required this.category,
    this.lastShown,
    this.preferencesMatch = true,
    this.sourceMasterId,
  });

  factory FoodSuggestion.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FoodSuggestion(
      foodId: doc.id,
      name: d['name'] as String? ?? '',
      tags: List<String>.from(d['tags'] ?? []),
      macros: SuggestionMacros.fromMap(d['macros'] as Map<String, dynamic>? ?? {}),
      category: FoodCategoryX.fromString(d['category'] as String? ?? 'snack'),
      lastShown: (d['last_shown'] as Timestamp?)?.toDate(),
      preferencesMatch: (d['preferences_match'] as bool?) ?? true,
      sourceMasterId: d['source_master_id'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'food_id': foodId,
        'name': name,
        'tags': tags,
        'macros': macros.toMap(),
        'category': category.label,
        'last_shown': lastShown != null ? Timestamp.fromDate(lastShown!) : null,
        'preferences_match': preferencesMatch,
        'source_master_id': sourceMasterId,
      };
}
