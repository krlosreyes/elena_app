import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/food_suggestion.dart';

// ─────────────────────────────────────────────────────────────
// REPOSITORY: User-Scoped Nutrition Suggestions
// ─────────────────────────────────────────────────────────────
class FoodSuggestionsRepository {
  final FirebaseFirestore _db;

  FoodSuggestionsRepository(this._db);

  /// Helper for user-specific subcollection
  CollectionReference<Map<String, dynamic>> _userCol(String userId) =>
      _db.collection('users').doc(userId).collection('user_food_suggestions');

  /// Fetches daily suggestions for a specific user and category.
  /// Uses LRU rotation (sort by last_shown ASC).
  Future<List<FoodSuggestion>> getSuggestionsByCategory({
    required String userId,
    required String category,
  }) async {
    try {
      final query = await _userCol(userId)
          .where('category', isEqualTo: category)
          .orderBy('last_shown', descending: false)
          .limit(10)
          .get();

      if (query.docs.isEmpty) return [];

      final allItems = query.docs
          .map((d) => FoodSuggestion.fromFirestore(d))
          .toList();

      // Return a shuffled subset of the top 10 least recently shown
      allItems.shuffle();
      final count = allItems.length.clamp(0, 5); 
      return allItems.take(count).toList();
    } catch (e) {
      debugPrint('❌ getSuggestionsByCategory Error (User: $userId, Cat: $category): $e');
      return [];
    }
  }

  /// Updates last_shown timestamp to rotate suggestions
  Future<void> markAsShown(String userId, List<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_userCol(userId).doc(id), {
        'last_shown': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit().catchError((e) => debugPrint('⚠️ markAsShown error: $e'));
  }

  /// Overwrites the user's personalized food pool
  Future<void> savePersonalizedPool(String userId, List<FoodSuggestion> pool) async {
    try {
      final batch = _db.batch();
      
      // Clear existing suggestions to start fresh (or merge if preferred, here we overwrite for the 'onboarding' feel)
      final existing = await _userCol(userId).get();
      for (var doc in existing.docs) {
        batch.delete(doc.reference);
      }

      for (final item in pool) {
        final docRef = _userCol(userId).doc(item.foodId);
        batch.set(docRef, item.toFirestore());
      }

      await batch.commit();
      debugPrint('✅ Personalized Pool Saved for $userId (${pool.length} items)');
    } catch (e) {
      debugPrint('❌ savePersonalizedPool Error: $e');
      rethrow;
    }
  }

  // ── Add suggestion to daily_logs (Mapping to DailyLog model) ────────────────────────────
  Future<void> addToDaily({
    required String uid,
    required FoodSuggestion suggestion,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyRef =
        _db.collection('users').doc(uid).collection('daily_logs').doc(today);

    final entry = {
      'id': suggestion.foodId,
      'name': suggestion.name,
      'type': suggestion.category.label.toLowerCase(),
      'calories': suggestion.macros.kcal,
      'protein': suggestion.macros.protein,
      'carbs': suggestion.macros.carbs,
      'fats': suggestion.macros.fat,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _db.runTransaction((tx) async {
      final snap = await tx.get(dailyRef);
      final existing = snap.exists && snap.data() != null
          ? Map<String, dynamic>.from(snap.data()!)
          : <String, dynamic>{};

      final meals =
          List<Map<String, dynamic>>.from(existing['mealEntries'] ?? []);
      meals.add(entry);

      final newCal = ((existing['calories'] as num?) ?? 0).toInt() +
          suggestion.macros.kcal;
      final newProt = ((existing['proteinGrams'] as num?) ?? 0).toInt() +
          suggestion.macros.protein;
      final newCarb = ((existing['carbsGrams'] as num?) ?? 0).toInt() +
          suggestion.macros.carbs;
      final newFat =
          ((existing['fatGrams'] as num?) ?? 0).toInt() + suggestion.macros.fat;

      tx.set(
          dailyRef,
          {
            ...existing,
            'id': today,
            'mealEntries': meals,
            'calories': newCal,
            'proteinGrams': newProt,
            'carbsGrams': newCarb,
            'fatGrams': newFat,
          },
          SetOptions(merge: true));
    });
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final foodSuggestionsRepositoryProvider =
    Provider<FoodSuggestionsRepository>((ref) {
  return FoodSuggestionsRepository(FirebaseFirestore.instance);
});

final categorySuggestionsProvider =
    FutureProvider.family.autoDispose<List<FoodSuggestion>, String>((ref, category) async {
  // Use a different mechanism to get UID if needed, but we can't easily ref.watch(auth) inside a family without complexity.
  // For now, assume the caller passes or we use the latest state.
  // Actually, we can watch it here.
  
  // NOTE: In production, you'd want to handle the loading/null state of the user.
  return []; // Placeholder - will be wired in the UI or a higher service
});
