// SPEC-273 — Orquesta la Minuta del día y el ciclo diario.
//
// Escucha al usuario activo y al intake; cuando ambos están listos, se
// suscribe al plan de HOY (`mealPlans/{yyyy-MM-dd}`). Si no existe y el
// intake está completo, lo GENERA (MealPlanFactory) y lo persiste una vez.
// Expone `markAdherence` (el tap del ciclo: Comí / Cambié / Me salté) y
// `regenerate` (rehacer la minuta del día), ambos offline-first.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/nutrition/application/meal_plan_factory.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_intake_notifier.dart';
import 'package:elena_app/src/features/nutrition/data/meal_plan_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────

class MealPlanState {
  final MealPlan? plan;
  final bool isLoading;

  /// True si el motor está generando/guardando la minuta del día.
  final bool isGenerating;

  const MealPlanState({
    this.plan,
    this.isLoading = true,
    this.isGenerating = false,
  });

  bool get hasPlan => plan != null;

  MealPlanState copyWith({
    MealPlan? plan,
    bool? isLoading,
    bool? isGenerating,
    bool clearPlan = false,
  }) {
    return MealPlanState(
      plan: clearPlan ? null : (plan ?? this.plan),
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────

class MealPlanNotifier extends StateNotifier<MealPlanState> {
  MealPlanNotifier(this._ref) : super(const MealPlanState()) {
    _init();
  }

  final Ref _ref;
  static const MealPlanFactory _factory = MealPlanFactory();

  final String _todayId = MealPlan.dateId(DateTime.now());
  UserModel? _user;
  NutritionIntake? _intake;
  bool _intakeReady = false;
  String? _subscribedUid;
  bool _generating = false;
  StreamSubscription<MealPlan?>? _sub;

  /// SPEC-280.1: marca de tiempo del intake con el que estamos alineados.
  /// Si llega un intake con otra marca (el usuario editó sus preferencias),
  /// re-generamos la minuta para que se adapte.
  DateTime? _seenIntakeStamp;

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) {
          _user = user;
          if (user == null) {
            _teardown();
            if (mounted) state = const MealPlanState(isLoading: false);
            return;
          }
          _ensureSubscribed(user.id);
        });
      },
      fireImmediately: true,
    );

    _ref.listen<NutritionIntakeState>(
      nutritionIntakeNotifierProvider,
      (previous, next) {
        _intake = next.intake;
        _intakeReady = !next.isLoading;
        _handleIntakeChange();
      },
      fireImmediately: true,
    );
  }

  /// Reacciona a cambios del intake: genera si aún no hay plan, o re-genera
  /// si el usuario EDITÓ sus preferencias (marca de tiempo distinta).
  void _handleIntakeChange() {
    final intake = _intake;
    final user = _user;
    if (intake == null || !_intakeReady) return;
    final stamp = intake.updatedAt;
    final userEdited = _seenIntakeStamp != null && stamp != _seenIntakeStamp;
    _seenIntakeStamp = stamp;
    if (user == null || !intake.isComplete) return;
    if (!state.hasPlan) {
      _maybeGenerate();
      return;
    }
    if (userEdited) _regenerateFrom(user, intake);
  }

  /// Rehace y persiste la minuta a partir del intake dado (adaptación tras
  /// editar preferencias). Offline-first.
  void _regenerateFrom(UserModel user, NutritionIntake intake) {
    final plan = _buildFor(user, intake);
    if (mounted) {
      state = state.copyWith(plan: plan, isGenerating: false, isLoading: false);
    }
    final repo = _ref.read(mealPlanRepositoryProvider);
    unawaited(repo.savePlan(user.id, plan).catchError((Object e) {
      AppLogger.warning(
          'meal_plan: regen tras editar preferencias falló: $e');
    }));
  }

  void _teardown() {
    _sub?.cancel();
    _sub = null;
    _subscribedUid = null;
  }

  void _ensureSubscribed(String uid) {
    if (_subscribedUid == uid) return;
    _teardown();
    _subscribedUid = uid;
    final repo = _ref.read(mealPlanRepositoryProvider);
    _sub = repo.watchPlan(uid, _todayId).listen(
      (plan) {
        if (!mounted) return;
        state = state.copyWith(
          plan: plan,
          isLoading: false,
          clearPlan: plan == null,
        );
        if (plan == null) _maybeGenerate();
      },
      onError: (Object e) {
        AppLogger.warning('meal_plan: stream error (transitorio): $e');
      },
    );
  }

  /// Genera y persiste la minuta de hoy si: hay usuario, el intake ya cargó
  /// y está completo, aún no hay plan y no hay una generación en curso.
  void _maybeGenerate() {
    if (_generating) return;
    final user = _user;
    final intake = _intake;
    if (user == null || intake == null || !_intakeReady) return;
    if (!intake.isComplete) return;
    if (state.hasPlan) return;

    _generating = true;
    if (mounted) state = state.copyWith(isGenerating: true, isLoading: false);

    final plan = _buildFor(user, intake);
    // Optimista: el stream reconciliará cuando Firestore emita.
    if (mounted) {
      state = state.copyWith(plan: plan, isGenerating: false, isLoading: false);
    }
    final repo = _ref.read(mealPlanRepositoryProvider);
    unawaited(repo.savePlan(user.id, plan).catchError((Object e) {
      AppLogger.warning('meal_plan: savePlan falló: $e');
    }).whenComplete(() => _generating = false));
  }

  MealPlan _buildFor(UserModel user, NutritionIntake intake) {
    return _factory.build(
      intake: intake,
      heightCm: user.height,
      gender: user.gender,
      pal: user.activityLevel,
      windowFirst: _fmt(user.profile.firstMealGoal),
      windowLast: _fmt(user.profile.lastMealGoal),
    );
  }

  /// Marca la adherencia de una comida (Comí / Cambié / Me salté).
  Future<void> markAdherence(MealSlot slot, AdherenceMark mark) async {
    final current = state.plan;
    final user = _user;
    if (current == null || user == null) return;

    final updated = current.markAdherence(slot, mark);
    if (mounted) state = state.copyWith(plan: updated);

    final repo = _ref.read(mealPlanRepositoryProvider);
    unawaited(repo.savePlan(user.id, updated).catchError((Object e) {
      AppLogger.warning('meal_plan: markAdherence save falló: $e');
    }));
  }

  /// SPEC-280: el usuario elige otra opción para un alimento del plato; se
  /// guarda en la minuta del día (offline-first).
  Future<void> chooseAlternative(
      MealSlot slot, String oldFoodId, PlanItem newItem) async {
    final current = state.plan;
    final user = _user;
    if (current == null || user == null) return;

    final updated = current.replaceItem(slot, oldFoodId, newItem);
    if (identical(updated, current)) return;
    if (mounted) state = state.copyWith(plan: updated);

    final repo = _ref.read(mealPlanRepositoryProvider);
    unawaited(repo.savePlan(user.id, updated).catchError((Object e) {
      AppLogger.warning('meal_plan: chooseAlternative save falló: $e');
    }));
  }

  /// SPEC-284: el usuario cambia el PLATO completo de una comida por otra
  /// receta del recetario. Reemplaza receta + ingredientes y limpia la marca
  /// de adherencia (es un plato distinto). Offline-first.
  Future<void> chooseRecipe(MealSlot slot, String recipeId) async {
    final current = state.plan;
    final user = _user;
    if (current == null || user == null) return;
    final recipe = RecipeCatalog.byId(recipeId);
    if (recipe == null) return;

    final updated = current.setMealRecipe(
      slot,
      recipe.id,
      _itemsFromRecipe(recipe),
      rationale: 'Receta sugerida: ${recipe.name}.',
    );
    if (identical(updated, current)) return;
    if (mounted) state = state.copyWith(plan: updated);

    final repo = _ref.read(mealPlanRepositoryProvider);
    unawaited(repo.savePlan(user.id, updated).catchError((Object e) {
      AppLogger.warning('meal_plan: chooseRecipe save falló: $e');
    }));
  }

  /// SPEC-287: agrega a una comida un alimento que no estaba en la minuta.
  /// Offline-first.
  Future<void> addExtraFood(MealSlot slot, String foodId) async {
    final current = state.plan;
    final user = _user;
    if (current == null || user == null) return;
    final f = FoodCatalog.byId(foodId);
    if (f == null) return;

    final updated = current.addItem(
      slot,
      PlanItem(
        foodId: f.id,
        role: _roleForFood(f),
        portion: HandPortion.fist,
        origin: PlanItemOrigin.fromUser,
      ),
    );
    if (identical(updated, current)) return;
    if (mounted) state = state.copyWith(plan: updated);

    final repo = _ref.read(mealPlanRepositoryProvider);
    unawaited(repo.savePlan(user.id, updated).catchError((Object e) {
      AppLogger.warning('meal_plan: addExtraFood save falló: $e');
    }));
  }

  /// Alimentos centrales de la receta (los que existen en el catálogo) como
  /// `PlanItem` editables. Los ingredientes de texto libre viven en la receta.
  List<PlanItem> _itemsFromRecipe(Recipe recipe) {
    final seen = <String>{};
    final items = <PlanItem>[];
    for (final ing in recipe.ingredients) {
      final id = ing.foodId;
      if (id == null || id.isEmpty) continue;
      if (!seen.add(id)) continue;
      final f = FoodCatalog.byId(id);
      if (f == null) continue;
      items.add(PlanItem(
        foodId: id,
        role: _roleForFood(f),
        portion: _portionForRole(_roleForFood(f)),
        origin: PlanItemOrigin.fromUser,
      ));
    }
    return items;
  }

  PlanItemRole _roleForFood(Food f) {
    if (f.category == FoodCategory.protein) return PlanItemRole.protein;
    if (f.category == FoodCategory.carb && f.qualityScore >= 70) {
      return PlanItemRole.veg;
    }
    if (f.category == FoodCategory.fat) return PlanItemRole.fat;
    return PlanItemRole.other;
  }

  HandPortion _portionForRole(PlanItemRole role) => switch (role) {
        PlanItemRole.protein => HandPortion.palm,
        PlanItemRole.veg => HandPortion.fist,
        PlanItemRole.fat => HandPortion.thumb,
        PlanItemRole.other => HandPortion.cupped,
      };

  /// Rehace la minuta del día desde el intake actual (botón "Regenerar").
  Future<void> regenerate() async {
    final user = _user;
    final intake = _intake;
    if (user == null || intake == null || !intake.isComplete) return;

    final plan = _buildFor(user, intake);
    if (mounted) state = state.copyWith(plan: plan);

    final repo = _ref.read(mealPlanRepositoryProvider);
    unawaited(repo.savePlan(user.id, plan).catchError((Object e) {
      AppLogger.warning('meal_plan: regenerate save falló: $e');
    }));
  }

  static String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final mealPlanNotifierProvider =
    StateNotifierProvider<MealPlanNotifier, MealPlanState>((ref) {
  return MealPlanNotifier(ref);
});
