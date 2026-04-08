import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/shared/domain/models/meal_log.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/metabolic_hub_provider.dart';
import '../../../core/services/analytics_service.dart';
import '../../authentication/data/auth_repository.dart';
import '../../health/data/health_repository.dart';
import '../data/repositories/meal_repository_impl.dart';

part 'meal_controller.g.dart';

@riverpod
Stream<List<MealLog>> recentMeals(RecentMealsRef ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(mealRepositoryProvider);
  return repository.watchRecentMeals(user.uid);
}

@riverpod
class MealController extends _$MealController {
  @override
  void build() {}

  Future<bool> registerMeal({
    required String name,
    required MealType type,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return false;

    // 🔬 METABOLIC GUARD: Check if next meal is locked
    final hub = ref.read(metabolicHubProvider);
    final nextMealIndex = hub.actualMeals;

    // 1. Check if we already reached max meals for the protocol
    if (nextMealIndex >= hub.expectedMeals) {
      debugPrint(
        '⚠️ [MEAL CONTROLLER] Protocol full: $nextMealIndex/${hub.expectedMeals}',
      );
      return false;
    }

    // 2. Check if the specific milestone is reached (Fasting break or inter-meal gap)
    final isLocked =
        nextMealIndex > 0 &&
        nextMealIndex < hub.mealMilestones.length &&
        !hub.mealMilestones[nextMealIndex].isReached;

    if (isLocked) {
      debugPrint(
        '⚠️ [MEAL CONTROLLER] Locked: Milestone at ${hub.mealMilestones[nextMealIndex].absoluteHour} not reached.',
      );
      return false;
    }

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

    try {
      await ref.read(mealRepositoryProvider).saveMeal(meal);

      // Sincronizar con DailyLog para disparar actualización del IMR
      await ref.read(healthRepositoryProvider).logNutrition(user.uid, {
        'id': meal.id,
        'userId': user.uid,
        'name': meal.name,
        'type': meal.type.name,
        'calories': meal.calories,
        'protein': meal.proteinGrams,
        'carbs': meal.carbsGrams,
        'fats': meal.fatGrams,
        'timestamp': meal.timestamp.toIso8601String(),
      });

      await NotificationService.schedulePostPrandialWalking(meal.timestamp);

      AnalyticsService.logMealLogged();

      debugPrint(
        '✅ [MealController] Successfully registered meal: ${meal.name}',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [MealController] Error registering meal: $e');
      return false;
    }
  }

  Future<void> deleteMeal(String mealId) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    await ref.read(mealRepositoryProvider).deleteMeal(user.uid, mealId);
  }
}
