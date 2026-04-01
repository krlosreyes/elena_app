import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_logger.dart';
import '../data/repositories/food_repository.dart' as old_repo;
import '../domain/entities/food_model.dart';

part 'food_service.g.dart';

/// 🏗️ FOOD SERVICE - Centralizado para Clean Architecture
///
/// Reemplaza queries dispersas en widgets.
/// Proporciona interfaz limpia y testeable.
class FoodService {
  final old_repo.FoodRepository _repository;

  FoodService(this._repository);

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
}

/// 📱 Riverpod Providers para FoodService
///
/// Proporcionan acceso singleton a FoodService en toda la app

@riverpod
old_repo.FoodRepository foodRepository(FoodRepositoryRef ref) {
  return old_repo.FoodRepositoryImpl(FirebaseFirestore.instance);
}

@riverpod
FoodService foodService(FoodServiceRef ref) {
  final repository = ref.watch(foodRepositoryProvider);
  return FoodService(repository);
}

/// ✅ Obtener comidas por categoría (Future)
@riverpod
Future<List<FoodModel>> foodsByCategory(ref, String category) async {
  final service = ref.watch(foodServiceProvider);
  return await service.getFoodsByCategory(category);
}

/// ✅ Buscar comida (AsyncValue)
@riverpod
Future<FoodModel?> searchFood(ref, String query) async {
  final service = ref.watch(foodServiceProvider);
  return await service.searchFood(query);
}
