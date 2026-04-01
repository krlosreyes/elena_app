import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nutrition/domain/entities/food_model.dart';
import '../food_master_list.dart';

// Local-First Master Food Database Architecture
// 100% Independent - No External APIs

abstract class FoodRepository {
  /// Search for food metadata by name
  /// Local Firestore 'master_food_db' ONLY
  /// Returns NULL if not found locally
  Future<FoodModel?> getFoodMetadata(String query);

  /// Get all foods in a category
  Future<List<FoodModel>> getFoodsByCategory(String category);

  /// Get all foods from master database
  Future<List<FoodModel>> getAllFoods();

  /// Seed initial verified foods (Metamorfosis Real protocol)
  Future<void> seedInitialNutritionData();
}

class FoodRepositoryImpl implements FoodRepository {
  final FirebaseFirestore _firestore;

  static const String _masterFoodCollection = 'master_food_db';

  FoodRepositoryImpl(this._firestore);

  @override
  Future<FoodModel?> getFoodMetadata(String query) async {
    if (query.trim().isEmpty) return null;

    try {
      debugPrint('[SEARCH] Searching for food: "$query" (SOVEREIGN MASTER DB)');

      // SOVEREIGN MASTER DB: Search in Firestore 'master_food_db' using indexed query
      final localFood = await _searchSovereignDatabase(query);
      if (localFood != null) {
        debugPrint('[SEARCH] ✅ Found: ${localFood.name} (IMR: ${localFood.imrScore})');
        return localFood;
      }

      debugPrint('[SEARCH] ❌ Not found in sovereign master database: "$query"');
      return null;
    } catch (e) {
      debugPrint('[ERROR] Error in getFoodMetadata: $e');
      return null;
    }
  }

  @override
  Future<List<FoodModel>> getFoodsByCategory(String category) async {
    try {
      debugPrint('[📡 REPO] Fetching category: "$category"');

      final snapshot = await _firestore
          .collection(_masterFoodCollection)
          .where('metadata.category', isEqualTo: category)
          .get();

      debugPrint('[📡 REPO] Query returned ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ WARNING: Query returned 0 documents for category: $category');
        return [];
      }

      final results = snapshot.docs.map((doc) {
        return FoodModel.fromFirestore(doc.data());
      }).toList();

      debugPrint('[REPOSITORY] ✅ Found ${results.length} items for category: $category');
      return results;
    } catch (e) {
      debugPrint('[ERROR] Error fetching foods by category: $e');
      return [];
    }
  }

  @override
  Future<List<FoodModel>> getAllFoods() async {
    try {
      final snapshot = await _firestore.collection(_masterFoodCollection).get();
      return snapshot.docs
          .map((doc) => FoodModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[ERROR] Error fetching all foods: $e');
      return [];
    }
  }

  @override
  Future<void> seedInitialNutritionData() async {
    await FoodMasterList.seedMasterDatabase();
  }

  /// App-side search logic if full text not available
  Future<FoodModel?> _searchSovereignDatabase(String query) async {
    try {
      final normalizedQuery = query.toLowerCase().trim();
      debugPrint('[SEARCH] Querying collection: $_masterFoodCollection');

      // Optimized search: Try literal match on ID first
      final docSnapshot = await _firestore.collection(_masterFoodCollection).doc(normalizedQuery).get();
      if (docSnapshot.exists) {
        return FoodModel.fromFirestore(docSnapshot.data()!);
      }

      // Fallback: Partial name search (prefix match)
      final querySnapshot = await _firestore
          .collection(_masterFoodCollection)
          .where('metadata.nameLowercase', isGreaterThanOrEqualTo: normalizedQuery)
          .where('metadata.nameLowercase', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return FoodModel.fromFirestore(querySnapshot.docs.first.data());
      }

      // Deep scan fallback (only for small datasets or curated search)
      debugPrint('[SEARCH] No indexed match. Trying broad scan...');
      final allFoods = await _firestore.collection(_masterFoodCollection).limit(50).get();

      for (final doc in allFoods.docs) {
        final food = FoodModel.fromFirestore(doc.data());
        if (food.name.toLowerCase().contains(normalizedQuery)) {
          debugPrint('[SEARCH] Found via broad scan: ${food.name}');
          return food;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[SEARCH ERROR] Error in _searchSovereignDatabase: $e');
      return null;
    }
  }
}

// RIVERPOD PROVIDER
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepositoryImpl(FirebaseFirestore.instance);
});
