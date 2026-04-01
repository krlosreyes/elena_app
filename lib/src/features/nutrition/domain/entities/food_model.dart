import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOOD MODEL — Sovereign Master Database Entity
// Metamorphosis Real Protocol — 4-Node Architecture
// ─────────────────────────────────────────────────────────────────────────────
//
// 4-NODE STRUCTURE:
// 1. metadata: {id, name, nameLowercase, category, search_tags}
// 2. content: {calories, proteins, fats, net_carbs, serving}
// 3. app_integration: {imr_score, svg_node, tip}
// 4. quiz: {impact, level}
//
// All nutritional values are per 100g for standardization.
// Document ID in Firestore: slug (e.g., 'sardinas-atlanticas')

class FoodModel {
  // NODE 1: METADATA
  final String id; // Slug: 'sardinas-atlanticas'
  final String name; // Display name: 'Sardinas (Atlánticas)'
  final String nameLowercase; // Auto-generated: 'sardinas (atlánticas)'
  final String category; // Category: 'Proteína 🐟'
  final List<String> searchTags; // ['sardina', 'pez', 'omega-3', 'calcio']

  // NODE 2: CONTENT (Nutritional values per 100g)
  final double protein; // grams
  final double fat; // grams
  final double netCarbs; // grams
  final double calories; // kcal
  final double serving; // Reference serving in grams (default: 100g)

  // NODE 3: APP INTEGRATION
  final int imrScore; // Metabolic Resilience Score (1-10)
  final String? svgNode; // SVG visualization (optional)
  final String tip; // Nutricional tip: "Omega-3 y Calcio puro"

  // NODE 4: QUIZ
  final String
  impact; // Impact category: 'sarcopenia', 'inflamación', 'energía'
  final int level; // Difficulty level (1-3)

  // METADATA & TRACKING
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodModel({
    required this.id,
    required this.name,
    required this.nameLowercase,
    required this.category,
    required this.searchTags,
    required this.protein,
    required this.fat,
    required this.netCarbs,
    required this.calories,
    required this.serving,
    required this.imrScore,
    this.svgNode,
    required this.tip,
    required this.impact,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate macro ratio (useful for meal planning)
  MacroRatio get macroRatio {
    final totalCalories = (protein * 4) + (fat * 9) + (netCarbs * 4);
    return MacroRatio(
      proteinPercent: totalCalories > 0
          ? (protein * 4) / totalCalories * 100
          : 0,
      fatPercent: totalCalories > 0 ? (fat * 9) / totalCalories * 100 : 0,
      carbsPercent: totalCalories > 0
          ? (netCarbs * 4) / totalCalories * 100
          : 0,
    );
  }

  /// Calculate macros for a given weight
  FoodMacros calculateMacros(double weightG) {
    final multiplier = weightG / serving;
    return FoodMacros(
      protein: protein * multiplier,
      fat: fat * multiplier,
      carbs: netCarbs * multiplier,
      calories: calories * multiplier,
    );
  }

  /// Create from JSON (API compatibility)
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      nameLowercase:
          (json['nameLowercase'] as String?) ??
          (json['name'] as String? ?? 'unknown').toLowerCase(),
      category: json['category'] as String? ?? 'other',
      searchTags:
          (json['searchTags'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      netCarbs: (json['netCarbs'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      serving: (json['serving'] as num?)?.toDouble() ?? 100.0,
      imrScore: (json['imrScore'] as num?)?.toInt() ?? 5,
      svgNode: json['svgNode'] as String?,
      tip: json['tip'] as String? ?? 'Sin descripción',
      impact: json['impact'] as String? ?? 'general',
      level: (json['level'] as num?)?.toInt() ?? 1,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to JSON (Firestore serialization)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameLowercase': nameLowercase, // Auto-generated for search index
      'category': category,
      'searchTags': searchTags,
      'protein': protein,
      'fat': fat,
      'netCarbs': netCarbs,
      'calories': calories,
      'serving': serving,
      'imrScore': imrScore,
      'svgNode': svgNode,
      'tip': tip,
      'impact': impact,
      'level': level,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Convert to Firestore-safe format with auto-generated lowercase name
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'nameLowercase': name.toLowerCase(), // Auto-generated for indexed search
      'category': category,
      'searchTags': searchTags,
      'protein': protein,
      'fat': fat,
      'netCarbs': netCarbs,
      'calories': calories,
      'serving': serving,
      'imrScore': imrScore,
      'svgNode': svgNode,
      'tip': tip,
      'impact': impact,
      'level': level,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create from Firestore document (factory constructor)
  /// SUPPORTS BOTH STRUCTURES:
  /// 1. 4-NODE ARCHITECTURE: { "metadata": {...}, "content": {...}, "app_integration": {...}, "quiz": {...} }
  /// 2. FLAT STRUCTURE: { "id": "...", "name": "...", "category": "...", ... }
  factory FoodModel.fromFirestore(Map<String, dynamic> data) {
    // Try to extract from 4-node structure first
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as Map<String, dynamic>? ?? {};
    final appIntegration =
        data['app_integration'] as Map<String, dynamic>? ?? {};
    final quiz = data['quiz'] as Map<String, dynamic>? ?? {};

    // Extract metadata node data (or fall back to root level)
    final String id =
        (metadata['id'] as String?) ?? (data['id'] as String?) ?? '';
    final String name =
        (metadata['name'] as String?) ?? (data['name'] as String?) ?? 'Unknown';
    final String nameLowercase =
        (metadata['nameLowercase'] as String?) ??
        (data['nameLowercase'] as String?) ??
        name.toLowerCase();
    final String category =
        (metadata['category'] as String?) ??
        (data['category'] as String?) ??
        'General';

    // Extract search tags (try 'tags' key in metadata first, then 'searchTags' at root)
    List<String> searchTags = [];
    if (metadata['tags'] is List) {
      searchTags = (metadata['tags'] as List<dynamic>).cast<String>().toList();
    } else if (data['searchTags'] is List) {
      searchTags = (data['searchTags'] as List<dynamic>)
          .cast<String>()
          .toList();
    }

    // Extract content node data (or fall back to root level)
    final double calories =
        (content['calories'] as num?)?.toDouble() ??
        (data['calories'] as num?)?.toDouble() ??
        0.0;
    final double protein =
        (content['proteins'] as num?)?.toDouble() ??
        (data['protein'] as num?)?.toDouble() ??
        0.0;
    final double fat =
        (content['fats'] as num?)?.toDouble() ??
        (data['fat'] as num?)?.toDouble() ??
        0.0;
    final double netCarbs =
        (content['net_carbs'] as num?)?.toDouble() ??
        (data['netCarbs'] as num?)?.toDouble() ??
        0.0;

    // Extract serving (handle both 'serving' as string or number)
    double serving = 100.0;
    final servingValue = content['serving'] ?? data['serving'];
    if (servingValue is num) {
      serving = servingValue.toDouble();
    } else if (servingValue is String) {
      // Try to parse if it's "100g" format
      final numStr = servingValue.replaceAll(RegExp(r'[^0-9.]'), '');
      serving = double.tryParse(numStr) ?? 100.0;
    }

    // Extract app_integration node data (or fall back to root level)
    final int imrScore =
        (appIntegration['imr_score'] as num?)?.toInt() ??
        (data['imrScore'] as num?)?.toInt() ??
        5;
    final String? svgNode =
        (appIntegration['svg_node'] as String?) ?? (data['svgNode'] as String?);
    final String tip =
        (appIntegration['tip'] as String?) ??
        (data['tip'] as String?) ??
        'Sin descripción';

    // Extract quiz node data (or fall back to root level)
    final String impact =
        (quiz['impact'] as String?) ?? (data['impact'] as String?) ?? 'general';

    // Handle level (can be string like "Excelente" or int)
    int level = 1;
    final levelValue = quiz['level'] ?? data['level'];
    if (levelValue is num) {
      level = levelValue.toInt();
    } else if (levelValue is String) {
      // Map string values to numeric levels
      final levelMap = {
        'bajo': 1,
        'medio': 2,
        'alto': 3,
        'basico': 1,
        'intermedio': 2,
        'avanzado': 3,
        'excelente': 3,
      };
      level = levelMap[levelValue.toLowerCase()] ?? 1;
    }

    debugPrint('[DEBUG] 📖 FoodModel.fromFirestore():');
    debugPrint('  ID: $id, Name: $name, Category: $category');
    debugPrint('  IMR Score: $imrScore, Tip: $tip');

    return FoodModel(
      id: id,
      name: name,
      nameLowercase: nameLowercase,
      category: category,
      searchTags: searchTags,
      protein: protein,
      fat: fat,
      netCarbs: netCarbs,
      calories: calories,
      serving: serving,
      imrScore: imrScore,
      svgNode: svgNode,
      tip: tip,
      impact: impact,
      level: level,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a modified copy (copyWith pattern)
  FoodModel copyWith({
    String? id,
    String? name,
    String? nameLowercase,
    String? category,
    List<String>? searchTags,
    double? protein,
    double? fat,
    double? netCarbs,
    double? calories,
    double? serving,
    int? imrScore,
    String? svgNode,
    String? tip,
    String? impact,
    int? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLowercase: nameLowercase ?? this.nameLowercase,
      category: category ?? this.category,
      searchTags: searchTags ?? this.searchTags,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      netCarbs: netCarbs ?? this.netCarbs,
      calories: calories ?? this.calories,
      serving: serving ?? this.serving,
      imrScore: imrScore ?? this.imrScore,
      svgNode: svgNode ?? this.svgNode,
      tip: tip ?? this.tip,
      impact: impact ?? this.impact,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'FoodModel(id: $id, name: $name, imr: $imrScore)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Macro ratio percentages
class MacroRatio {
  final double proteinPercent;
  final double fatPercent;
  final double carbsPercent;

  MacroRatio({
    required this.proteinPercent,
    required this.fatPercent,
    required this.carbsPercent,
  });
}

/// Calculated macros for a portion
class FoodMacros {
  final double protein;
  final double fat;
  final double carbs;
  final double calories;

  FoodMacros({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
  });

  @override
  String toString() =>
      'FoodMacros(P: ${protein.toStringAsFixed(1)}g, F: ${fat.toStringAsFixed(1)}g, C: ${carbs.toStringAsFixed(1)}g, Cal: ${calories.toStringAsFixed(0)}kcal)';
}
