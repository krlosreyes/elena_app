import 'package:elena_app/src/shared/domain/models/meal_log.dart';

abstract class MealRepository {
  Future<void> saveMeal(MealLog meal);
  Future<List<MealLog>> getRecentMeals(String userId, {int limit = 5});
  Stream<List<MealLog>> watchRecentMeals(String userId, {int limit = 5});
  Future<void> deleteMeal(String userId, String mealId);
}
