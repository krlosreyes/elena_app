// SPEC-119 (refactor god widget) — card del pilar Comidas extraída de
// dashboard_screen.dart, con su banner de bloqueo durante ayuno y helpers.
// El cambio de pilar (ir a Ayuno) se delega al padre vía `onGoToFasting`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_card_ui.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/presentation/meal_history_sheet.dart';
import 'package:elena_app/src/features/nutrition/application/meal_plan_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/minuta_adherence_score.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

class ComidasPillarCard extends ConsumerWidget {
  const ComidasPillarCard({
    super.key,
    required this.state,
    required this.isFastingActive,
    required this.onGoToFasting,
  });

  final NutritionState state;
  final bool isFastingActive;

  /// Invocado cuando el usuario confirma "Ir a Ayuno" en el diálogo de
  /// bloqueo. El padre (dashboard) cambia el pilar seleccionado.
  final VoidCallback onGoToFasting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFFFB923C);
    // FIX (25-jul-2026, Carlos con evidencia de pantalla): esta barra y
    // el "X% completado" usaban `progressPercentage` (puro conteo de
    // comidas) — mostraban "33% completado" para un plato "1 a 1" con
    // Cociente A 0%, contradiciendo el mini-stat de al lado. Ahora usan
    // `nutritionScore` (calidad-ponderado, ver nutrition_score_calculator
    // .dart), consistente con el anillo del Dashboard (mismo fix, ver
    // dashboard_pillars_row.dart). El badge "N/M comidas" de abajo sigue
    // mostrando el conteo tal cual — está explícitamente etiquetado como
    // conteo, no se presta a confusión.
    // SPEC-274.2: refleja la adherencia a la Minuta cuando el usuario ya la
    // usa (marcó ≥1 comida); si no, cae al nutritionScore por calidad de
    // plato de siempre (guardarraíl de no-regresión).
    final progress = MinutaAdherenceScore.effective(
      fallbackScore: state.nutritionScore,
      plan: ref.watch(mealPlanNotifierProvider).plan,
    );
    final pct = (progress * 100).round();
    final lastLog = state.todayLogs.isNotEmpty ? state.todayLogs.last : null;
    // "Racha de Calidad" (25-jul-2026, diferenciador de mercado — ver
    // diagnóstico "Pilar Nutrición: dos métricas paralelas" §3.3): días
    // consecutivos con plato bien compuesto, distinto de la racha
    // principal (que exige 3+/5 pilares y es ciega a composición dentro
    // de Nutrición). Cálculo en StreakEngine.computeNutritionQualityStreak,
    // sobre nutritionMagnitude ya persistido — sin schema nuevo.
    final qualityStreak =
        ref.watch(streakProvider.select((s) => s.nutritionQualityStreak));
    // SPEC-277: la Minuta es la fuente de verdad del pilar comida.
    final mealPlan = ref.watch(mealPlanNotifierProvider).plan;
    final int minutaDone = mealPlan?.adherentCount ?? 0;
    final int minutaTotal = mealPlan?.meals.length ?? state.targetMeals;

    // SPEC-290: en ayuno YA NO se bloquea el pilar. El usuario puede ver y
    // ALISTAR lo que comerá al abrir su ventana; solo se gatea el "marcar/
    // comer" (en la Minuta). Mostramos cuánto falta para la ventana.
    final windowIn = isFastingActive
        ? ref.watch(fastingProvider).timeUntilWindowOpens
        : null;

    return PillarCardUi.shell(
      // Título vacío: la card se identifica por el badge de comidas.
      title: '',
      badge: '$minutaDone/$minutaTotal de tu minuta',
      accent: accent,
      children: [
        if (isFastingActive) ...[
          _PrepDuringFastBanner(
            remaining: windowIn,
            onGoToFasting: onGoToFasting,
          ),
          const SizedBox(height: 14),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PillarCardUi.progressBar(progress, accent),
            const SizedBox(height: 6),
            PillarCardUi.completionLabel(pct),
            const SizedBox(height: 14),
            // SPEC-286/290: "Tu próxima comida" — o, en ayuno, "Al abrir tu
            // ventana": el plato que sigue, con ingredientes + preparación,
            // siempre visible y editable para poder alistarlo.
            _NextMealCard(
              plan: mealPlan,
              accent: accent,
              fastingWindowIn: windowIn,
              onOpenMinuta: () => context.push('/nutrition/minuta'),
            ),
            if (qualityStreak > 0) ...[
              const SizedBox(height: 12),
              _QualityStreakChip(days: qualityStreak),
            ],
            if (lastLog != null) ...[
              const SizedBox(height: 14),
              _LastPlateCard(log: lastLog, accent: accent),
            ],
            const SizedBox(height: 16),
            PillarCardUi.secondaryButton(
              label: 'Ver mi minuta completa',
              icon: Icons.checklist_rounded,
              onPressed: () => context.push('/nutrition/minuta'),
            ),
            if (state.todayLogs.isNotEmpty) ...[
              const SizedBox(height: 10),
              PillarCardUi.secondaryButton(
                label: 'Ver historial (${state.mealsLoggedToday})',
                icon: Icons.history_rounded,
                onPressed: () => MealHistorySheet.show(context),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Formatea una duración corta ("2h 15m", "45 min", "ya casi").
  static String fmtDur(Duration? d) {
    if (d == null) return '';
    if (d.inMinutes <= 1) return 'ya casi';
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes} min';
  }
}

/// SPEC-290: banner durante el ayuno. NO bloquea — invita a alistar la comida
/// de después y muestra cuánto falta para que abra la ventana. Ofrece saltar
/// a la tarjeta de Ayuno.
class _PrepDuringFastBanner extends StatelessWidget {
  const _PrepDuringFastBanner({
    required this.remaining,
    required this.onGoToFasting,
  });

  final Duration? remaining;
  final VoidCallback onGoToFasting;

  @override
  Widget build(BuildContext context) {
    final left = ComidasPillarCard.fmtDur(remaining);
    final msg = (remaining == null || remaining == Duration.zero)
        ? 'En ayuno. Tu ventana está por abrir — deja lista tu próxima comida.'
        : 'En ayuno. Tu ventana abre en $left. Aprovecha para alistar lo que '
            'comerás.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu_rounded,
              color: AppColors.metabolicGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onGoToFasting,
            child: const Text(
              'Ver ayuno',
              style: TextStyle(
                color: AppColors.metabolicGreen,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SPEC-286 — "Tu próxima comida": el plato que sigue en la minuta (primera
/// comida sin marcar), con su nombre, proteína e ingredientes + preparación
/// desplegables. Los ajustes (cambiar/editar/agregar) viven en la Minuta a un
/// tap (SPEC-285), por lo que el card lleva ahí.
class _NextMealCard extends StatelessWidget {
  const _NextMealCard({
    required this.plan,
    required this.accent,
    required this.onOpenMinuta,
    this.fastingWindowIn,
  });

  final MealPlan? plan;
  final Color accent;
  final VoidCallback? onOpenMinuta;

  /// SPEC-290: si hay ayuno activo, cuánto falta para que abra la ventana.
  /// Reencuadra la tarjeta como "al abrir tu ventana" (alistar, no comer aún).
  final Duration? fastingWindowIn;

  static String _slotLabel(MealSlot s) => switch (s) {
        MealSlot.breakfast => 'Desayuno',
        MealSlot.lunch => 'Almuerzo',
        MealSlot.dinner => 'Cena',
        MealSlot.other => 'Otra comida',
      };

  @override
  Widget build(BuildContext context) {
    final meals = plan?.meals ?? const <MealPlanEntry>[];
    if (meals.isEmpty) {
      return _shell(
        context,
        title: 'TU MINUTA DE HOY',
        child: Text(
          'Configura tu minuta para ver qué comer hoy.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
        ),
      );
    }

    MealPlanEntry? next;
    for (final m in meals) {
      if (m.adherence == null) {
        next = m;
        break;
      }
    }

    if (next == null) {
      return _shell(
        context,
        title: 'TU MINUTA DE HOY',
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.statusGood, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡Completaste tu minuta de hoy! Bien ahí.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final entry = next;
    final recipe =
        entry.recipeId == null ? null : RecipeCatalog.byId(entry.recipeId!);
    final dishName =
        recipe?.name ?? 'Tu plato de ${_slotLabel(entry.slot).toLowerCase()}';
    final fasting = fastingWindowIn != null;
    final windowLeft = ComidasPillarCard.fmtDur(fastingWindowIn);
    final meta = <String>[
      if (fasting && windowLeft.isNotEmpty) 'en $windowLeft',
      _slotLabel(entry.slot),
      if (recipe != null) '${recipe.prepMinutes} min',
      if (entry.targetProteinG > 0)
        '~${entry.targetProteinG.round()} g proteína',
    ].join(' · ');

    final seasonings = recipe == null
        ? const <RecipeIngredient>[]
        : recipe.ingredients
            .where((i) => i.foodId == null || i.foodId!.isEmpty)
            .toList();

    return _shell(
      context,
      title: fasting ? 'AL ABRIR TU VENTANA' : 'TU PRÓXIMA COMIDA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dishName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            meta,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              iconColor: accent,
              collapsedIconColor: Colors.white.withValues(alpha: 0.6),
              title: Text(
                'Ver ingredientes y preparación',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: [
                _label('Ingredientes', accent),
                for (final it in entry.items) _bullet(_foodLine(it)),
                for (final ing in seasonings) _bullet(ing.text),
                if (recipe != null && recipe.steps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _label('Preparación', accent),
                  for (var i = 0; i < recipe.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('${i + 1}. ${recipe.steps[i]}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12.5,
                              height: 1.4)),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          PillarCardUi.primaryButton(
            label: fasting ? 'Alistar mi comida' : 'Ver plato y ajustar',
            icon: Icons.restaurant_menu_rounded,
            color: accent,
            onPressed: onOpenMinuta,
          ),
        ],
      ),
    );
  }

  static String _foodLine(PlanItem it) {
    final f = FoodCatalog.byId(it.foodId);
    final name = f?.name ?? it.foodId;
    final portion = f?.portionLabel;
    return portion == null || portion.isEmpty ? name : '$name — $portion';
  }

  Widget _shell(BuildContext context,
      {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _label(String text, Color accent) => Padding(
        padding: const EdgeInsets.only(bottom: 5, top: 2),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: accent.withValues(alpha: 0.9),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(
          '• $text',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
      );
}

/// Widget compacto que muestra la composición del último plato registrado.
class _LastPlateCard extends StatelessWidget {
  const _LastPlateCard({required this.log, required this.accent});

  final NutritionLog log;
  final Color accent;

  Color _ratioColor(MealRatio ratio) {
    return switch (ratio) {
      MealRatio.allA => AppColors.statusGood,
      MealRatio.a3e1 => AppColors.statusGood,
      MealRatio.a2e1 => AppColors.accent,
      MealRatio.a1e1 => AppColors.statusWarn,
      MealRatio.allE => AppColors.statusBad,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ratioColor = _ratioColor(log.ratio);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu_rounded,
                  size: 13, color: accent.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text(
                'Último: ${log.label}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ratioColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.ratio.label,
                  style: TextStyle(
                    color: ratioColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (log.hasMacros) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (log.calories != null) '${log.calories!.round()} kcal',
                if (log.protein != null) 'P: ${log.protein!.round()}g',
                if (log.carbs != null) 'C: ${log.carbs!.round()}g',
                if (log.fat != null) 'G: ${log.fat!.round()}g',
              ].join(' · '),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Racha de Calidad" (25-jul-2026) — chip discreto, solo visible cuando
/// hay al menos 1 día de racha. Distinto en tono/color del badge de
/// conteo ("N/M comidas") para que el usuario no los confunda: este es
/// el número que mide qué tan bien comió, no cuántas veces registró.
class _QualityStreakChip extends StatelessWidget {
  const _QualityStreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusGood.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusGood.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: AppColors.statusGood,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              days == 1
                  ? 'Racha de calidad: 1 día con plato bien compuesto'
                  : 'Racha de calidad: $days días con plato bien compuesto',
              style: const TextStyle(
                color: AppColors.statusGood,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
