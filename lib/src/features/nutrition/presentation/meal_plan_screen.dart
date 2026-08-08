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
import 'package:elena_app/src/features/nutrition/application/meal_plan_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_intake_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/intake_resurvey_policy.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

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
            onMark: (mark) => ref
                .read(mealPlanNotifierProvider.notifier)
                .markAdherence(entry.slot, mark),
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
  const _MealCard({required this.entry, required this.onMark});

  static String _slotLabel(MealSlot s) => switch (s) {
        MealSlot.breakfast => 'Desayuno',
        MealSlot.lunch => 'Almuerzo',
        MealSlot.dinner => 'Cena',
        MealSlot.other => 'Otra comida',
      };

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (entry.targetProteinG > 0)
                Text(
                  '~${entry.targetProteinG.round()} g proteína',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in entry.items) _PlanItemRow(item: item),
          if (entry.rationale.isNotEmpty) ...[
            const SizedBox(height: 6),
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
          const SizedBox(height: 14),
          _AdherenceRow(current: entry.adherence, onMark: onMark),
        ],
      ),
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  final PlanItem item;
  const _PlanItemRow({required this.item});

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

  @override
  Widget build(BuildContext context) {
    final food = FoodCatalog.byId(item.foodId);
    final name = food?.name ?? item.foodId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
            child: Row(
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
          ),
          Text(
            _portionLabel(item.portion),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
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
            color: selected ? color.withValues(alpha: 0.18) : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.borderDefault,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? color : AppColors.textSecondary),
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
