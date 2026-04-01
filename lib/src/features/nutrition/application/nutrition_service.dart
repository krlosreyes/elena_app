import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../authentication/data/auth_repository.dart';
import '../../fasting/application/fasting_controller.dart';
import '../../profile/application/user_controller.dart';
import '../data/repositories/nutrition_repository_impl.dart';
import '../domain/entities/metabolic_nutrition_plan.dart';
import '../domain/entities/metabolic_profile.dart';
import '../domain/entities/nutrition_strategy.dart';
import '../domain/repositories/nutrition_repository.dart';
import '../domain/services/metabolic_engine.dart';

part 'nutrition_service.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
NutritionRepository nutritionRepository(Ref ref) {
  return NutritionRepositoryImpl(FirebaseFirestore.instance);
}

// ─────────────────────────────────────────────────────────────────────────────
// USE CASE: GenerateNutritionPlan
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class NutritionService extends _$NutritionService {
  @override
  AsyncValue<MetabolicNutritionPlan?> build() {
    return const AsyncValue.data(null);
  }

  // ── PRIVATE HELPER: Build MetabolicProfile from user data ────────────────────

  /// Extracts and builds the MetabolicProfile from user data and current state.
  /// This helper reduces duplication between generatePlan() and other methods.
  ///
  /// Responsibility: Single source of truth for profile construction.
  Future<MetabolicProfile> _buildProfile({
    required AdaptationState adaptationState,
    required TrainingTiming trainingTiming,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Retrieve the full user profile
    final userModel = await ref
        .read(currentUserStreamProvider.future)
        .timeout(const Duration(seconds: 5));
    if (userModel == null) throw Exception('Perfil de usuario no encontrado');

    // Retrieve live fasting state if available
    final fastingState = ref.read(fastingControllerProvider).valueOrNull;

    final isCurrentlyFasting = fastingState?.isFasting ?? false;
    final elapsedHours =
        fastingState != null ? fastingState.elapsed.inSeconds / 3600.0 : 0.0;

    // Build the MetabolicProfile — the single source of truth
    return MetabolicProfile.fromUser(
      userModel,
      adaptationState: adaptationState,
      trainingTiming: trainingTiming,
      isCurrentlyFasting: isCurrentlyFasting,
      currentFastingElapsedHours: elapsedHours,
    );
  }

  // ── UC-1: Generate plan from the full metabolic context ────────────────────

  Future<MetabolicNutritionPlan> generatePlan({
    bool isTrainingDay = false,
    AdaptationState adaptationState = AdaptationState.normal,
    TrainingTiming trainingTiming = TrainingTiming.fed,
    NutritionStrategy? strategyOverride,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Build the MetabolicProfile using the helper
      final profile = await _buildProfile(
        adaptationState: adaptationState,
        trainingTiming: trainingTiming,
      );

      // Run the engine (pure function, no side effects)
      final plan = MetabolicEngine.generate(
        userId: user.uid,
        profile: profile,
        isTrainingDay: isTrainingDay,
        strategyOverride: strategyOverride,
      );

      // Persist to Firestore
      await ref
          .read(nutritionRepositoryProvider)
          .saveMetabolicPlan(user.uid, plan);

      state = AsyncValue.data(plan);
      return plan;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ── UC-2: Adjust plan based on progress ────────────────────────────────────

  Future<MetabolicNutritionPlan> adjustPlanFromProgress({
    required double currentWeightKg,
    required bool isProgressStalled,
    bool isTrainingDay = false,
  }) async {
    // Determine adaptation state from progress signals
    final adaptationState = isProgressStalled
        ? AdaptationState.metabolicallyResistant
        : AdaptationState.normal;

    return generatePlan(
      isTrainingDay: isTrainingDay,
      adaptationState: adaptationState,
    );
  }

  // ── UC-3: Sync plan with fasting state ─────────────────────────────────────

  /// Re-generates the plan when the fasting protocol changes.
  /// Called from: FastingController when phase transitions occur.
  Future<void> syncWithFasting() async {
    final current = state.valueOrNull;
    if (current == null) {
      await generatePlan();
      return;
    }

    final fastingState = ref.read(fastingControllerProvider).valueOrNull;
    if (fastingState == null) return;

    // Determine training timing from fasting context
    TrainingTiming timing = TrainingTiming.fed;
    if (fastingState.isFasting &&
        fastingState.elapsed.inHours >= (fastingState.plannedHours - 2)) {
      timing = TrainingTiming.fasted;
    } else if (fastingState.isFeeding && fastingState.elapsed.inMinutes <= 60) {
      timing = TrainingTiming.breakingFast;
    }

    await generatePlan(
      isTrainingDay: current.isTrainingDay,
      trainingTiming: timing,
    );
  }

  // ── Convenience: Get current plan or generate ────────────────────────────

  Future<MetabolicNutritionPlan> getOrGenerate() async {
    final current = state.valueOrNull;
    if (current != null) return current;
    return generatePlan();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAM PROVIDER: Active Plan (from Firestore)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<MetabolicNutritionPlan?> activeMetabolicPlan(Ref ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value(null);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.watchMetabolicPlan(user.uid);
}

// ─────────────────────────────────────────────────────────────────────────────
// DERIVED PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Quick access to today's macro targets (used by dashboard)
@riverpod
({int calories, int protein, int fat, int carbs})? todayMacroTargets(Ref ref) {
  final plan = ref.watch(activeMetabolicPlanProvider).valueOrNull;
  if (plan == null) return null;
  return (
    calories: plan.totalCalories,
    protein: plan.proteinGrams,
    fat: plan.fatGrams,
    carbs: plan.carbsGrams,
  );
}

/// Strategy name for display in UI
@riverpod
String activeStrategyName(Ref ref) {
  final plan = ref.watch(activeMetabolicPlanProvider).valueOrNull;
  return plan?.strategy.name ?? 'Sin plan activo';
}
