// SPEC-273 — Pantalla de la Minuta Diaria + ciclo diario.
//
// Muestra el plan del día en tarjetas (desayuno/almuerzo/cena) con sus
// porciones de mano y el "por qué" (rationale), y captura la adherencia con
// un tap: Comí esto / Lo cambié / Me lo salté. Si el usuario aún no
// completó su intake, ofrece configurarlo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/meal_plan_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_intake_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/intake_resurvey_policy.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_match_service.dart';

const Color _amber = AppColors.pillarNutricion;

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mealPlanNotifierProvider);
    final intakeState = ref.watch(nutritionIntakeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tu minuta de hoy',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Editar mis preferencias',
            icon: const Icon(Icons.tune, color: AppColors.textSecondary),
            onPressed: () => context.push('/nutrition/intake'),
          ),
          if (state.hasPlan)
            IconButton(
              tooltip: 'Regenerar',
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: () =>
                  ref.read(mealPlanNotifierProvider.notifier).regenerate(),
            ),
        ],
      ),
      body: SafeArea(
        child: _body(context, ref, state, intakeState),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    MealPlanState state,
    NutritionIntakeState intakeState,
  ) {
    // Sin intake completo → invitar a configurarlo.
    if (!intakeState.isLoading && !intakeState.isComplete) {
      return _EmptyIntake(onConfigure: () => context.push('/nutrition/intake'));
    }
    if (state.isLoading || (state.isGenerating && !state.hasPlan)) {
      return const Center(
        child: CircularProgressIndicator(color: _amber),
      );
    }
    final plan = state.plan;
    if (plan == null || plan.meals.isEmpty) {
      return _EmptyIntake(onConfigure: () => context.push('/nutrition/intake'));
    }

    final intake = intakeState.intake;
    final resurveyDue = intake != null &&
        const IntakeResurveyPolicy()
            .isDue(updatedAt: intake.updatedAt, now: DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        if (resurveyDue) ...[
          _ResurveyBanner(onUpdate: () => context.push('/nutrition/intake')),
          const SizedBox(height: 12),
        ],
        _PlanHeader(plan: plan),
        const SizedBox(height: 16),
        for (final entry in plan.meals)
          _MealCard(
            entry: entry,
            fastingActive: ref.watch(fastingProvider).isActive,
            onMark: (mark) => ref
                .read(mealPlanNotifierProvider.notifier)
                .markAdherence(entry.slot, mark),
            onPickAlternative: (item) => _showAlternatives(
                context, ref, entry.slot, item, intakeState.intake),
            onChangeDish: () =>
                _showChangeDish(context, ref, entry.slot, intakeState.intake),
            onAddFood: () =>
                _showAddFood(context, ref, entry.slot, intakeState.intake),
          ),
        const SizedBox(height: 8),
        const Text(
          'Cambiamos lo que menos te ayuda, poco a poco. Mañana, otra minuta.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _PlanHeader extends StatelessWidget {
  final MealPlan plan;
  const _PlanHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    final total = plan.meals.fold<double>(0, (a, m) => a + m.targetProteinG);
    final window = (plan.windowFirst.isNotEmpty && plan.windowLast.isNotEmpty)
        ? '${plan.windowFirst}–${plan.windowLast}'
        : 'Tu ventana de comidas';
    final done = plan.adherentCount;
    final totalMeals = plan.meals.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: _amber, size: 20),
              const SizedBox(width: 8),
              Text(
                window,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Proteína objetivo del día: ~${total.round()} g  ·  '
            '$done/$totalMeals cumplidas',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de comida ────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final MealPlanEntry entry;
  final ValueChanged<AdherenceMark> onMark;
  final void Function(PlanItem item)? onPickAlternative;
  final VoidCallback? onChangeDish;
  final VoidCallback? onAddFood;
  final bool fastingActive;
  const _MealCard({
    required this.entry,
    required this.onMark,
    this.onPickAlternative,
    this.onChangeDish,
    this.onAddFood,
    this.fastingActive = false,
  });

  static String _slotLabel(MealSlot s) => switch (s) {
        MealSlot.breakfast => 'Desayuno',
        MealSlot.lunch => 'Almuerzo',
        MealSlot.dinner => 'Cena',
        MealSlot.other => 'Otra comida',
      };

  @override
  Widget build(BuildContext context) {
    // SPEC-285: la comida es un PLATO (receta), no una lista de alimentos
    // sueltos. Nombre + resumen arriba; ingredientes y preparación se
    // despliegan; abajo las acciones (cambiar plato / agregar) y el ciclo.
    final recipe =
        entry.recipeId == null ? null : RecipeCatalog.byId(entry.recipeId!);
    final dishName =
        recipe?.name ?? 'Tu plato de ${_slotLabel(entry.slot).toLowerCase()}';
    final subtitle = recipe != null
        ? '${recipe.prepMinutes} min · '
            '${recipe.servings == 1 ? '1 porción' : '${recipe.servings} porciones'}'
        : '${entry.items.length} ingredientes';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.adherence != null
              ? _amber.withValues(alpha: 0.4)
              : AppColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _slotLabel(entry.slot),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (entry.targetProteinG > 0)
                Text(
                  '~${entry.targetProteinG.round()} g proteína',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dishName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _DishDetails(
            entry: entry,
            recipe: recipe,
            onPickAlternative: onPickAlternative,
          ),
          if (entry.rationale.isNotEmpty &&
              !entry.rationale.startsWith('Receta sugerida')) ...[
            const SizedBox(height: 8),
            Text(
              entry.rationale,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (onChangeDish != null)
                Expanded(
                  child: _DishActionButton(
                    label: 'Cambiar plato',
                    icon: Icons.restaurant_menu,
                    onTap: onChangeDish!,
                  ),
                ),
              if (onChangeDish != null && onAddFood != null)
                const SizedBox(width: 8),
              if (onAddFood != null)
                Expanded(
                  child: _DishActionButton(
                    label: 'Agregar algo',
                    icon: Icons.add,
                    onTap: onAddFood!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // SPEC-290: durante el ayuno se puede ver/cambiar/agregar (alistar),
          // pero NO marcar que comiste — eso abre con tu ventana.
          if (fastingActive)
            const _FastingMealHint()
          else
            _AdherenceRow(current: entry.adherence, onMark: onMark),
        ],
      ),
    );
  }
}

/// SPEC-290: aviso en la comida cuando hay ayuno activo — en vez del ciclo
/// Comí/Cambié/Me salté (que abre con la ventana de alimentación).
class _FastingMealHint extends StatelessWidget {
  const _FastingMealHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusGood.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusGood.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded,
              size: 16, color: AppColors.statusGood),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'En ayuno. Déjala lista; podrás marcarla cuando abra tu ventana.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// SPEC-285: sección desplegable con los ingredientes (editables) y la
/// preparación del plato.
class _DishDetails extends StatelessWidget {
  final MealPlanEntry entry;
  final Recipe? recipe;
  final void Function(PlanItem item)? onPickAlternative;
  const _DishDetails({
    required this.entry,
    required this.recipe,
    this.onPickAlternative,
  });

  @override
  Widget build(BuildContext context) {
    final seasonings = recipe == null
        ? const <RecipeIngredient>[]
        : recipe!.ingredients
            .where((i) => i.foodId == null || i.foodId!.isEmpty)
            .toList();
    final canEdit = onPickAlternative != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          iconColor: _amber,
          collapsedIconColor: AppColors.textSecondary,
          title: const Text(
            'Ver ingredientes y preparación',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            _dishSectionLabel('Ingredientes'),
            for (final item in entry.items)
              _PlanItemRow(
                item: item,
                onTap: (!canEdit || item.foodId.isEmpty)
                    ? null
                    : () => onPickAlternative!(item),
              ),
            for (final ing in seasonings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 6, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(ing.text,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            if (canEdit && entry.items.any((i) => i.foodId.isNotEmpty))
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Toca un ingrediente para cambiarlo.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ),
            if (recipe != null && recipe!.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              _dishSectionLabel('Preparación'),
              for (var i = 0; i < recipe!.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${i + 1}. ${recipe!.steps[i]}',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _dishSectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _amber,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );

class _DishActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DishActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _amber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _amber.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: _amber),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: _amber, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recetas (bottom sheet) ─────────────────────────────────────────────────

class _RecipesSheet extends StatelessWidget {
  final String title;
  final List<RecipeMatch> matches;

  /// SPEC-285: si se pasa, cada receta muestra "Elegir este plato" para
  /// cambiar la comida de la minuta por esa receta.
  final ValueChanged<Recipe>? onChoose;

  /// Id de la receta actualmente en la minuta (para marcarla).
  final String? currentRecipeId;
  const _RecipesSheet({
    required this.title,
    required this.matches,
    this.onChoose,
    this.currentRecipeId,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.82;
    final heading =
        onChoose != null ? 'Cambiar tu $title' : 'Recetas para tu $title';
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              heading,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text(
                'Aún no tenemos recetas que encajen con tus preferencias. '
                'Prueba editar tus alimentos o restricciones.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            )
          else
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                children: [
                  for (final m in matches)
                    _RecipeTile(
                      match: m,
                      onChoose: onChoose,
                      isCurrent: m.recipe.id == currentRecipeId,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final RecipeMatch match;
  final ValueChanged<Recipe>? onChoose;
  final bool isCurrent;
  const _RecipeTile({
    required this.match,
    this.onChoose,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = match.recipe;
    final subtitle = '${r.prepMinutes} min · ${r.servings} '
        '${r.servings == 1 ? 'porción' : 'porciones'}'
        '${match.overlap > 0 ? ' · usas ${match.overlap} de tus ingredientes' : ''}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? _amber.withValues(alpha: 0.5)
              : AppColors.borderDefault,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          iconColor: _amber,
          collapsedIconColor: AppColors.textMuted,
          title: Row(
            children: [
              Flexible(
                child: Text(
                  r.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                const Text('Actual',
                    style: TextStyle(color: _amber, fontSize: 11)),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          children: [
            _sectionLabel('Ingredientes'),
            for (final ing in r.ingredients)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• ${ing.text}',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35)),
              ),
            const SizedBox(height: 10),
            _sectionLabel('Preparación'),
            for (var i = 0; i < r.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${i + 1}. ${r.steps[i]}',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ),
            if (onChoose != null && !isCurrent) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    onChoose!(r);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Elegir este plato',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: _amber,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
}

// ─── Cambiar plato / Agregar (SPEC-285/287) ─────────────────────────────────

void _showChangeDish(
  BuildContext context,
  WidgetRef ref,
  MealSlot slot,
  NutritionIntake? intake,
) {
  if (intake == null) return;
  final matches =
      const RecipeMatchService().match(intake: intake, slot: slot, limit: 10);
  String? current;
  final plan0 = ref.read(mealPlanNotifierProvider).plan;
  if (plan0 != null) {
    for (final m in plan0.meals) {
      if (m.slot == slot) {
        current = m.recipeId;
        break;
      }
    }
  }
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgBase,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _RecipesSheet(
      title: _MealCard._slotLabel(slot),
      matches: matches,
      currentRecipeId: current,
      onChoose: (recipe) => ref
          .read(mealPlanNotifierProvider.notifier)
          .chooseRecipe(slot, recipe.id),
    ),
  );
}

/// Alimentos que se pueden agregar a una comida: primero lo que el usuario ya
/// come (su repertorio), luego opciones sanas del catálogo, excluyendo lo que
/// ya está en el plato.
List<Food> _addFoodOptions(NutritionIntake? intake, Set<String> already) {
  final userIds = <String>{};
  if (intake != null) {
    for (final m in intake.meals) {
      for (final it in m.items) {
        final id = it.foodId;
        if (id != null && id.isNotEmpty) userIds.add(id);
      }
    }
  }
  int byQ(Food a, Food b) => b.qualityScore.compareTo(a.qualityScore);
  final userFoods = userIds
      .map(FoodCatalog.byId)
      .whereType<Food>()
      .where((f) => !already.contains(f.id))
      .toList()
    ..sort(byQ);
  final catalog = FoodCatalog.all
      .where((f) =>
          !already.contains(f.id) &&
          !userIds.contains(f.id) &&
          f.qualityScore >= 50)
      .toList()
    ..sort(byQ);
  return [...userFoods, ...catalog.take(20)];
}

void _showAddFood(
  BuildContext context,
  WidgetRef ref,
  MealSlot slot,
  NutritionIntake? intake,
) {
  final plan = ref.read(mealPlanNotifierProvider).plan;
  final already = <String>{
    ...?plan?.meals
        .where((m) => m.slot == slot)
        .expand((m) => m.items)
        .map((i) => i.foodId),
  };
  final userIds = <String>{
    if (intake != null)
      for (final m in intake.meals)
        for (final it in m.items)
          if (it.foodId != null && it.foodId!.isNotEmpty) it.foodId!,
  };
  final options = _addFoodOptions(intake, already);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgBase,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _AddFoodSheet(
      options: options,
      userIds: userIds,
      onPick: (food) => ref
          .read(mealPlanNotifierProvider.notifier)
          .addExtraFood(slot, food.id),
    ),
  );
}

class _AddFoodSheet extends StatelessWidget {
  final List<Food> options;
  final Set<String> userIds;
  final ValueChanged<Food> onPick;
  const _AddFoodSheet({
    required this.options,
    required this.userIds,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.72;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              'Agregar a esta comida',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Suma algo que vas a comer y no está en el plato. Se guarda en tu minuta.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              children: [
                for (final f in options)
                  ListTile(
                    dense: true,
                    onTap: () {
                      onPick(f);
                      Navigator.of(context).pop();
                    },
                    title: Text(
                      f.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14.5),
                    ),
                    subtitle: Text(
                      f.portionLabel,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                    trailing: userIds.contains(f.id)
                        ? const Text('Ya lo comes',
                            style: TextStyle(color: _amber, fontSize: 11))
                        : const Icon(Icons.add, size: 18, color: _amber),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  final PlanItem item;

  /// SPEC-280: si se pasa, tocar el ítem abre alternativas para cambiarlo.
  final VoidCallback? onTap;
  const _PlanItemRow({required this.item, this.onTap});

  static String _portionLabel(HandPortion p) => switch (p) {
        HandPortion.palm => 'palma',
        HandPortion.fist => 'puño',
        HandPortion.thumb => 'pulgar',
        HandPortion.cupped => 'puñado',
        HandPortion.tablespoon => 'cucharada',
      };

  static Color _roleColor(PlanItemRole r) => switch (r) {
        PlanItemRole.protein => AppColors.statusBad,
        PlanItemRole.veg => AppColors.statusGood,
        PlanItemRole.fat => _amber,
        PlanItemRole.other => AppColors.textMuted,
      };

  /// SPEC-283: micro-tip por alimento desde los metadatos del Atlas
  /// (nota de calidad > uso ideal > subgrupo de vegetal > micros).
  static String? _foodTip(Food? f) {
    if (f == null) return null;
    if (f.qualityNote != null && f.qualityNote!.trim().isNotEmpty) {
      return f.qualityNote;
    }
    if (f.idealUse != null && f.idealUse!.trim().isNotEmpty) {
      return f.idealUse;
    }
    if (f.vegGroup != null && f.vegGroup != VegGroup.other) {
      return f.vegGroup!.label;
    }
    if (f.micros.isNotEmpty) return f.micros.take(2).join(' · ');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final food = FoodCatalog.byId(item.foodId);
    final name = food?.name ?? item.foodId;
    final tip = _foodTip(food);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _roleColor(item.role),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ),
                    if (item.origin != PlanItemOrigin.fromUser) ...[
                      const SizedBox(width: 6),
                      _OriginTag(origin: item.origin),
                    ],
                  ],
                ),
                if (tip != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: _amber.withValues(alpha: 0.85),
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            // SPEC-279: medida concreta y entendible por alimento (taza,
            // ½ taza, unidad, gramos, scoop) en vez de palma/puño/pulgar.
            food?.portionLabel ?? _portionLabel(item.portion),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.swap_horiz, size: 18, color: _amber),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}

// ─── Alternativas por alimento (SPEC-280) ───────────────────────────────────

bool _isVegFood(Food f) =>
    f.category == FoodCategory.carb && f.qualityScore >= 70;

bool _matchesRole(Food f, PlanItemRole role) => switch (role) {
      PlanItemRole.protein => f.category == FoodCategory.protein,
      PlanItemRole.veg => _isVegFood(f),
      PlanItemRole.fat => f.category == FoodCategory.fat,
      PlanItemRole.other => f.category == FoodCategory.carb && !_isVegFood(f),
    };

/// Alternativas para un alimento del plato: primero lo que el usuario ya come
/// (de su intake) del mismo rol, luego opciones sanas del catálogo.
List<Food> _alternativesFor(PlanItem item, NutritionIntake? intake) {
  final userIds = <String>{};
  if (intake != null) {
    for (final m in intake.meals) {
      for (final it in m.items) {
        final id = it.foodId;
        if (id != null && id.isNotEmpty) userIds.add(id);
      }
    }
  }
  int byQ(Food a, Food b) => b.qualityScore.compareTo(a.qualityScore);

  final userFoods = userIds
      .map(FoodCatalog.byId)
      .whereType<Food>()
      .where((f) => _matchesRole(f, item.role) && f.id != item.foodId)
      .toList()
    ..sort(byQ);

  final catalog = FoodCatalog.all
      .where((f) =>
          _matchesRole(f, item.role) &&
          f.id != item.foodId &&
          !userIds.contains(f.id))
      .toList()
    ..sort(byQ);

  return [...userFoods, ...catalog.take(10)].take(16).toList();
}

void _showAlternatives(
  BuildContext context,
  WidgetRef ref,
  MealSlot slot,
  PlanItem item,
  NutritionIntake? intake,
) {
  final options = _alternativesFor(item, intake);
  final userIds = <String>{
    if (intake != null)
      for (final m in intake.meals)
        for (final it in m.items)
          if (it.foodId != null && it.foodId!.isNotEmpty) it.foodId!,
  };
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgBase,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _AlternativesSheet(
      current: item,
      options: options,
      userIds: userIds,
      onPick: (food) {
        ref.read(mealPlanNotifierProvider.notifier).chooseAlternative(
              slot,
              item.foodId,
              PlanItem(
                foodId: food.id,
                role: item.role,
                portion: item.portion,
                origin: PlanItemOrigin.fromUser,
              ),
            );
      },
    ),
  );
}

class _AlternativesSheet extends StatelessWidget {
  final PlanItem current;
  final List<Food> options;
  final Set<String> userIds;
  final ValueChanged<Food> onPick;
  const _AlternativesSheet({
    required this.current,
    required this.options,
    required this.userIds,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final currentFood = FoodCatalog.byId(current.foodId);
    final maxH = MediaQuery.of(context).size.height * 0.72;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              'Cambiar ${currentFood?.name ?? current.foodId}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Elige otra opción para esta comida. Se guarda en tu minuta.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              children: [
                for (final f in options)
                  ListTile(
                    dense: true,
                    onTap: () {
                      onPick(f);
                      Navigator.of(context).pop();
                    },
                    title: Text(
                      f.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14.5),
                    ),
                    subtitle: Text(
                      f.portionLabel,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                    trailing: userIds.contains(f.id)
                        ? const Text('Ya lo comes',
                            style: TextStyle(color: _amber, fontSize: 11))
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// SPEC-276: etiqueta que explica un alimento que no venía de tus
/// preferencias — "Nuevo" (rol que te faltaba) o "Mejora" (cambio sano).
class _OriginTag extends StatelessWidget {
  final PlanItemOrigin origin;
  const _OriginTag({required this.origin});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (origin) {
      PlanItemOrigin.upgrade => ('Mejora', AppColors.statusGood),
      PlanItemOrigin.newSuggestion => ('Nuevo', _amber),
      PlanItemOrigin.fromUser => ('', AppColors.textMuted),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AdherenceRow extends StatelessWidget {
  final AdherenceMark? current;
  final ValueChanged<AdherenceMark> onMark;
  const _AdherenceRow({required this.current, required this.onMark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AdherenceButton(
          label: 'Comí esto',
          icon: Icons.check_circle_outline,
          selected: current == AdherenceMark.ate,
          color: AppColors.statusGood,
          onTap: () => onMark(AdherenceMark.ate),
        ),
        const SizedBox(width: 8),
        _AdherenceButton(
          label: 'Lo cambié',
          icon: Icons.swap_horiz,
          selected: current == AdherenceMark.changed,
          color: _amber,
          onTap: () => onMark(AdherenceMark.changed),
        ),
        const SizedBox(width: 8),
        _AdherenceButton(
          label: 'Me salté',
          icon: Icons.close,
          selected: current == AdherenceMark.skipped,
          color: AppColors.textMuted,
          onTap: () => onMark(AdherenceMark.skipped),
        ),
      ],
    );
  }
}

class _AdherenceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _AdherenceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.18) : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.borderDefault,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18, color: selected ? color : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Banner de re-encuesta (SPEC-275) ───────────────────────────────────────

class _ResurveyBanner extends StatelessWidget {
  final VoidCallback onUpdate;
  const _ResurveyBanner({required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_repeat, color: _amber, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ya pasó un tiempo. Actualiza cómo comes hoy para que tu minuta '
              'evolucione contigo.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onUpdate,
            child: const Text('Actualizar',
                style: TextStyle(color: _amber, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Estado vacío (sin intake) ──────────────────────────────────────────────

class _EmptyIntake extends StatelessWidget {
  final VoidCallback onConfigure;
  const _EmptyIntake({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu, color: _amber, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Aún no tenemos tu minuta',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuéntanos cómo comes hoy y armamos tu plan diario, cambiando '
              'poco a poco lo que menos te ayuda.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onConfigure,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Configurar mi minuta',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
