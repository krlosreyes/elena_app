import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/entities/nutrition_plan.dart';
import '../domain/repositories/nutrition_repository.dart';
import '../domain/services/nutrition_engine.dart';
import '../data/repositories/nutrition_repository_impl.dart';

part 'nutrition_service.g.dart';

// 1. Repository Provider
@Riverpod(keepAlive: true)
NutritionRepository nutritionRepository(NutritionRepositoryRef ref) {
  return NutritionRepositoryImpl(FirebaseFirestore.instance);
}

// 2. Engine Provider
@Riverpod(keepAlive: true)
NutritionEngine nutritionEngine(NutritionEngineRef ref) {
  return NutritionEngine();
}

// 3. Current Plan Stream Provider
@riverpod
Stream<NutritionPlan?> nutritionPlan(NutritionPlanRef ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value(null);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.watchCurrentPlan(user.uid);
}

// 4. Service / Controller for Actions
@riverpod
class NutritionService extends _$NutritionService {
  @override
  void build() {}

  /// Generates a new plan using the Engine and saves it to the Repository.
  Future<void> generateAndSavePlan({
    required double weightKg,
    required double bodyFatPercentage,
    required String activityLevel,
    required String gender,
    required String goal,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) throw Exception('User not logged in');

    final engine = ref.read(nutritionEngineProvider);
    final plan = engine.calculatePlan(
      userId: user.uid,
      weightKg: weightKg,
      bodyFatPercentage: bodyFatPercentage,
      activityLevel: activityLevel,
      gender: gender,
      goal: goal,
    );

    final repository = ref.read(nutritionRepositoryProvider);
    await repository.saveNutritionPlan(plan);
  }
}
