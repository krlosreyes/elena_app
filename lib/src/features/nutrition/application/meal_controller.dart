import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../authentication/data/auth_repository.dart';
import 'package:elena_app/src/shared/domain/models/meal_log.dart';
import '../data/repositories/meal_repository_impl.dart';
import '../../health/data/health_repository.dart';

import 'package:elena_app/src/core/services/notification_service.dart';

part 'meal_controller.g.dart';

@riverpod
Stream<List<MealLog>> recentMeals(Ref ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(mealRepositoryProvider);
  return repository.watchRecentMeals(user.uid);
}

@riverpod
class MealController extends _$MealController {
  @override
  void build() {}

  Future<void> registerMeal({
    required String name,
    required MealType type,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final meal = MealLog(
      id: const Uuid().v4(),
      userId: user.uid,
      name: name,
      type: type,
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      timestamp: DateTime.now(),
    );

    await ref.read(mealRepositoryProvider).saveMeal(meal);

    // Sincronizar con DailyLog para disparar actualización del IED
    final healthRepo = ref.read(healthRepositoryProvider);
    await healthRepo.logNutrition(user.uid, {
      'id': meal.id,
      'name': meal.name,
      'type': meal.type.name,
      'calories': meal.calories,
      'protein': meal.proteinGrams,
      'carbs': meal.carbsGrams,
      'fats': meal.fatGrams,
      'timestamp': meal.timestamp.toIso8601String(),
    });

    await NotificationService.schedulePostPrandialWalking(meal.timestamp);
  }

  Future<void> deleteMeal(String mealId) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    await ref.read(mealRepositoryProvider).deleteMeal(user.uid, mealId);
  }
}
