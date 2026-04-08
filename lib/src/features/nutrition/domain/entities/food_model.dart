import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'food_suggestion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOOD MODEL — Sovereign Master Database Entity
// Metamorphosis Real Protocol — 4-Node Architecture
// ─────────────────────────────────────────────────────────────────────────────
//
// 4-NODE STRUCTURE:
// 1. metadata: {name, category, imrScore, tags}
// 2. content: {tip, impact, level}
// 3. app_integration: {macros: {p, g, c, kcal}, food_id}
// 4. quiz: {last_reviewed}
//
// All nutritional values are per 100g for standardization.
// Document ID in Firestore: slug (e.g., 'sardinas-atlanticas')

class FoodModel {
  // NODE 1: METADATA
  final String id; // Slug: 'sardinas-atlanticas'
  final String name; // Display name: 'Sardinas (Atlánticas)'
  final String category; // Category: 'Proteína'
  final List<String> searchTags;

  // NODE 2: CONTENT
  final double protein; // grams (path: app_integration.macros.p)
  final double fat; // grams (path: app_integration.macros.g)
  final double netCarbs; // grams (path: app_integration.macros.c)
  final double calories; // kcal (path: app_integration.macros.kcal)
  final String tip; // Nutricional tip (path: content.tip)

  // NODE 3: APP INTEGRATION
  final double imrScore; // Metabolic Resilience (path: metadata.imrScore)
  final String? svgNode;

  // NODE 4: QUIZ
  final String impact;
  final int level;

  // METADATA & TRACKING
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodModel({
    required this.id,
    required this.name,
    required this.category,
    required this.searchTags,
    required this.protein,
    required this.fat,
    required this.netCarbs,
    required this.calories,
    required this.tip,
    required this.imrScore,
    this.svgNode,
    required this.impact,
    required this.level,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Getter for sanitized category (no emojis)
  String get displayCategory => category
      .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '')
      .trim();

  /// Getter for monochromatic icon based on category (minimalist design)
  IconData get displayIcon {
    final cat = displayCategory.toLowerCase();

    if (cat.contains('proteina') ||
        cat.contains('proteína') ||
        cat.contains('proteinas') ||
        cat.contains('proteínas')) {
      return Icons.fitness_center_rounded;
    }

    if (cat.contains('carbo') ||
        cat.contains('carbohidr') ||
        cat.contains('carbs')) {
      return Icons.bakery_dining_rounded;
    }

    if (cat.contains('grasa') ||
        cat.contains('aceite') ||
        cat.contains('lípido')) {
      return Icons.water_drop_rounded;
    }

    if (cat.contains('vege') ||
        cat.contains('verdura') ||
        cat.contains('fibra')) {
      return Icons.eco_rounded;
    }

    if (cat.contains('frut')) {
      return Icons.apple_rounded;
    }

    return Icons.circle_outlined;
  }

  /// Calculate macro ratio
  MacroRatio get macroRatio {
    final totalCalories = (protein * 4) + (fat * 9) + (netCarbs * 4);
    return MacroRatio(
      proteinPercent:
          totalCalories > 0 ? (protein * 4) / totalCalories * 100 : 0,
      fatPercent: totalCalories > 0 ? (fat * 9) / totalCalories * 100 : 0,
      carbsPercent:
          totalCalories > 0 ? (netCarbs * 4) / totalCalories * 100 : 0,
    );
  }

  /// Calculate macros for a given weight (Assuming standard 100g base)
  SuggestionMacros calculateMacros(double weightG) {
    const servingBase = 100.0;
    final multiplier = weightG / servingBase;
    return SuggestionMacros(
      protein: protein * multiplier,
      fat: fat * multiplier,
      carbs: netCarbs * multiplier,
      kcal: calories * multiplier,
    );
  }

  /// Create from Firestore document (4-node protocol)
  factory FoodModel.fromFirestore(Map<String, dynamic> data) {
    final rawMetadata = data['metadata'] as Map<String, dynamic>? ?? {};
    final rawContent = data['content'] as Map<String, dynamic>? ?? {};
    final rawAppIntegration =
        data['app_integration'] as Map<String, dynamic>? ?? {};

    // Standardized macro mapping (app_integration.macros.p/g/c/kcal)
    final macros = (rawAppIntegration['macros'] as Map<String, dynamic>?) ?? {};

    // Resolve document ID: app_integration.food_id → metadata.id → data['id']
    final resolvedId = (rawAppIntegration['food_id'] as String?) ??
        (rawMetadata['id'] as String?) ??
        (data['id'] as String?) ??
        'unknown';

    return FoodModel(
      id: resolvedId,
      name: (rawMetadata['name'] as String?) ?? 'Alimento no identificado',
      category: (rawMetadata['category'] as String?) ?? 'General',
      // Fallback: imrScore (new) -> imr_score (old)
      imrScore: (rawMetadata['imrScore'] ?? rawAppIntegration['imr_score'] ?? 0)
          .toDouble(),
      searchTags:
          (rawMetadata['tags'] as List<dynamic>?)?.cast<String>().toList() ??
              (rawMetadata['searchTags'] as List<dynamic>?)
                  ?.cast<String>()
                  .toList() ??
              const [],
      // Fallback: content.tip (new) -> app_integration.tip (old)
      tip: (rawContent['tip'] as String?) ??
          (rawAppIntegration['tip'] as String?) ??
          'Sin descripción técnica',
      impact: (rawContent['impact'] as String?) ?? 'general',
      level: (rawContent['level'] as num?)?.toInt() ?? 1,
      // Fallback: app_integration.macros.p (new) -> content.proteins (old)
      protein: (macros['p'] ?? rawContent['proteins'] ?? 0).toDouble(),
      fat: (macros['g'] ?? rawContent['fats'] ?? 0).toDouble(),
      netCarbs: (macros['c'] ?? rawContent['net_carbs'] ?? 0).toDouble(),
      calories: (macros['kcal'] ?? rawContent['calories'] ?? 0).toDouble(),
      svgNode: rawAppIntegration['svg_node'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Factory for fallback data
  factory FoodModel.defaultModel({required String id}) {
    return FoodModel(
      id: id,
      name: 'Alimento no identificado',
      category: 'General',
      searchTags: [],
      protein: 0.0,
      fat: 0.0,
      netCarbs: 0.0,
      calories: 0.0,
      tip: 'Sin descripción técnica',
      imrScore: 0.0,
      impact: 'general',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to JSON (Firestore 4-node schema serialization)
  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'id': id,
        'name': name,
        'category': category,
        'imrScore': imrScore,
        'tags': searchTags,
      },
      'content': {
        'tip': tip,
        'impact': impact,
        'level': level,
      },
      'app_integration': {
        'macros': {
          'p': protein,
          'g': fat,
          'c': netCarbs,
          'kcal': calories,
        },
        'food_id': id,
        'svg_node': svgNode,
      },
      'quiz': {
        'last_reviewed': null,
      },
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// copyWith pattern
  FoodModel copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? searchTags,
    double? protein,
    double? fat,
    double? netCarbs,
    double? calories,
    String? tip,
    double? imrScore,
    String? svgNode,
    String? impact,
    int? level,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      searchTags: searchTags ?? this.searchTags,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      netCarbs: netCarbs ?? this.netCarbs,
      calories: calories ?? this.calories,
      tip: tip ?? this.tip,
      imrScore: imrScore ?? this.imrScore,
      svgNode: svgNode ?? this.svgNode,
      impact: impact ?? this.impact,
      level: level ?? this.level,
      createdAt: createdAt,
      updatedAt: updatedAt,
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

// Deleted FoodMacros as part of SuggestionMacros standardization.
