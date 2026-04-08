import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_logger.dart';
import '../../../shared/domain/models/user_model.dart';
import '../../profile/data/user_repository.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/food_suggestions_repository.dart';
import '../domain/entities/food_model.dart';
import '../domain/entities/food_suggestion.dart';
import '../domain/services/recommendation_engine.dart';
import 'food_provider.dart';

part 'food_service.g.dart';

/// 🏗️ FOOD SERVICE - Centralizado para Clean Architecture
///
/// Reemplaza queries dispersas en widgets.
/// Proporciona interfaz limpia y testeable.
class FoodService {
  final FoodRepository _repository;
  final FoodSuggestionsRepository _suggestionsRepo;
  final UserRepository _userRepo;

  FoodService(this._repository, this._suggestionsRepo, this._userRepo);

  /// ✅ Obtener comidas por categoría
  Future<List<FoodModel>> getFoodsByCategory(String category) async {
    try {
      AppLogger.debug('Obteniendo comidas de categoría: $category');
      return await _repository.getFoodsByCategory(category);
    } catch (e) {
      AppLogger.error('Error obteniendo comidas: $e');
      rethrow;
    }
  }

  /// ✅ Buscar comida por nombre
  Future<FoodModel?> searchFood(String query) async {
    try {
      AppLogger.debug('Buscando comida: $query');
      return await _repository.getFoodMetadata(query);
    } catch (e) {
      AppLogger.error('Error buscando comida: $e');
      rethrow;
    }
  }

  /// 🧠 Adaptive Metabolic Seeding
  /// Generates a personalized 20-item pool for the user based on onboarding selection
  /// and Adaptive Metabolic Scoring.
  Future<void> generatePersonalizedPool(
      String userId, List<String> selectedFoodIds) async {
    try {
      AppLogger.info(
          'Iniciando Seeding Personalizado para el usuario: $userId');

      // 1. Get User Profile for scoring context
      final user = await _userRepo.getUser(userId);
      if (user == null) throw Exception('Usuario no encontrado');

      // 2. Fetch all master food templates
      final masterFoods = await _repository.getAllFoods();
      if (masterFoods.isEmpty) {
        AppLogger.warning('No se encontraron alimentos en el Master DB');
        return;
      }

      // 3. Prepare Scoring Logic
      final List<MapEntry<FoodModel, double>> scoredFoods = [];

      for (final food in masterFoods) {
        // Convert FoodModel to a temporary FoodSuggestion for the engine
        final tempSuggestion = FoodSuggestion(
          foodId: food.id,
          name: food.name,
          tags: food.searchTags,
          macros: SuggestionMacros(
            protein: food.protein,
            carbs: food.netCarbs,
            fat: food.fat,
            kcal: food.calories,
          ),
          category: _mapCategory(food.category),
          preferencesMatch: selectedFoodIds.contains(food.id),
        );

        // Calculate score
        final adaptiveScore = RecommendationEngine.calculateMealScore(
          meal: tempSuggestion,
          bodyFatPercentage: user.currentFatPercentage ?? 25.0,
          lastMonthBodyFat: null, // We don't have history here yet
          userGender: user.gender,
          healthCondition:
              user.pathologies.isNotEmpty ? user.pathologies.first : 'general',
        );

        scoredFoods.add(MapEntry(food, adaptiveScore.adaptiveScore));
      }

      // 4. Sort and pick top 20
      scoredFoods.sort((a, b) => b.value.compareTo(a.value));
      final topFoods = scoredFoods.take(20).toList();

      // 5. Convert to final FoodSuggestions and save
      final List<FoodSuggestion> pool = topFoods.map((entry) {
        final food = entry.key;
        return FoodSuggestion(
          foodId: food.id,
          name: food.name,
          tags: food.searchTags,
          macros: SuggestionMacros(
            protein: food.protein,
            carbs: food.netCarbs,
            fat: food.fat,
            kcal: food.calories,
          ),
          category: _mapCategory(food.category),
          sourceMasterId: food.id,
          preferencesMatch: selectedFoodIds.contains(food.id),
        );
      }).toList();

      await _suggestionsRepo.savePersonalizedPool(userId, pool);
      AppLogger.info('✅ Seeding completado: 20 items generados.');
    } catch (e, stack) {
      AppLogger.error('Error en generatePersonalizedPool: $e', e, stack);
      rethrow;
    }
  }

  FoodCategory _mapCategory(String masterCategory) {
    // Map master category labels to the suggestion enum
    final cat = masterCategory.toLowerCase();
    if (cat.contains('proteína') ||
        cat.contains('grasas') ||
        cat.contains('res')) {
      return FoodCategory.principal;
    }
    if (cat.contains('snack') || cat.contains('huevo')) {
      return FoodCategory.snack;
    }
    return FoodCategory.ruptura;
  }
}

/// 📱 Riverpod Provider para FoodService
/// Los providers de foodRepository, foodsByCategory y searchFood están
/// definidos canónicamente en food_provider.dart (importado arriba).

@riverpod
FoodService foodService(FoodServiceRef ref) {
  final repository = ref.watch(foodRepositoryProvider);
  final suggestionsRepo = ref.watch(foodSuggestionsRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return FoodService(repository, suggestionsRepo, userRepo);
}
