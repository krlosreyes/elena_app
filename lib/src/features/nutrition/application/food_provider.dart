import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/food_repository.dart';
import '../domain/entities/food_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOOD REPOSITORY PROVIDER — Riverpod State Management
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the FoodRepository singleton instance
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return FoodRepositoryImpl(firestore);
});

/// Search for food metadata by query
/// Usage: ref.watch(searchFoodProvider('pollo'))
final searchFoodProvider =
    FutureProvider.family<FoodModel?, String>((ref, query) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.getFoodMetadata(query);
});

/// Get foods by category
/// Usage: ref.watch(foodsByCategoryProvider('protein'))
final foodsByCategoryProvider =
    FutureProvider.family<List<FoodModel>, String>((ref, category) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.getFoodsByCategory(category);
});

/// Seed initial nutrition data (one-time operation)
/// Usage: await ref.read(seedNutritionDataProvider).seedInitialNutritionData()
final seedNutritionDataProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(foodRepositoryProvider);
  await repository.seedInitialNutritionData();
});

/// Get the total count of documents in 'master_food_db' for debugging
final masterFoodCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('master_food_db')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
