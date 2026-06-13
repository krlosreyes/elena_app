// SPEC-119 (refactor god widget) — card del pilar Comidas extraída de
// dashboard_screen.dart, con su banner de bloqueo durante ayuno y helpers.
// El cambio de pilar (ir a Ayuno) se delega al padre vía `onGoToFasting`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/meals_locked_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_card_ui.dart';
import 'package:elena_app/src/features/nutrition/application/cociente_a_service.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/presentation/plate_ratio_sheet.dart';

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
    final progress = state.progressPercentage;
    final pct = (progress * 100).round();
    const cocienteService = CocienteAService();
    final cocienteA = cocienteService.calculate(state.todayLogs);
    final cocientePct = (cocienteA * 100).round();
    final lastLog = state.todayLogs.isNotEmpty ? state.todayLogs.last : null;

    final card = PillarCardUi.shell(
      // Título vacío: la card se identifica por el badge de comidas.
      title: '',
      badge: '${state.mealsLoggedToday}/${state.targetMeals} comidas',
      accent: accent,
      children: [
        if (isFastingActive) ...[
          _mealsLockedBanner(),
          const SizedBox(height: 14),
        ],
        Opacity(
          opacity: isFastingActive ? 0.45 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillarCardUi.progressBar(progress, accent),
              const SizedBox(height: 6),
              PillarCardUi.completionLabel(pct),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PillarCardUi.miniStat('Próxima', state.nextMealLabel, accent,
                      big: true),
                  PillarCardUi.miniStat('En', _estimateNextMealIn(state), accent,
                      big: true),
                  PillarCardUi.miniStat('Cociente A', '$cocientePct%',
                      _cocienteAColor(cocienteA),
                      big: true),
                ],
              ),
              // ── Composición del último plato ────────────────────────
              if (lastLog != null) ...[
                const SizedBox(height: 14),
                _LastPlateCard(log: lastLog, accent: accent),
              ],
              const SizedBox(height: 18),
              PillarCardUi.primaryButton(
                label: 'Registrar ${state.nextMealLabel}',
                icon: Icons.restaurant_rounded,
                color: accent,
                onPressed: isFastingActive || state.isSaving
                    ? null
                    : () => PlateRatioSheet.show(context),
              ),
              // ── Editar / Eliminar último plato ──────────────────────
              if (lastLog != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PillarCardUi.secondaryButton(
                        label: 'Editar plato',
                        icon: Icons.edit_outlined,
                        onPressed: isFastingActive
                            ? null
                            : () => PlateRatioSheet.show(
                                  context,
                                  label: lastLog.label,
                                  initialMealTime: lastLog.timestamp,
                                  logToReplaceId: lastLog.id,
                                  initialPlateItemIds: lastLog.plateItemIds,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PillarCardUi.secondaryButton(
                        label: 'Eliminar',
                        icon: Icons.delete_outline_rounded,
                        onPressed: isFastingActive
                            ? null
                            : () => ref
                                .read(nutritionProvider.notifier)
                                .removeLastMeal(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (!isFastingActive) return card;

    // Con ayuno activo: el tap (los botones están disabled y no consumen
    // el evento) abre el diálogo educativo; si confirma, sube al padre.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final goToFasting = await MealsLockedDuringFastingDialog.show(context);
        if (goToFasting == true) onGoToFasting();
      },
      child: card,
    );
  }

  /// SPEC-105: banner siempre opaco encima de la card cuando hay ayuno activo.
  Widget _mealsLockedBanner() {
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
          const Icon(
            Icons.lock_clock_rounded,
            color: AppColors.metabolicGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pausado durante ayuno activo — termina tu ayuno '
              'para registrar comidas.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SPEC-137: color del Cociente A para el mini-stat de Hoy.
  Color _cocienteAColor(double cociente) {
    if (cociente >= 0.75) return AppColors.statusGood;
    if (cociente >= 0.50) return AppColors.accent;
    if (cociente >= 0.25) return AppColors.statusWarn;
    return AppColors.statusBad;
  }

  /// SPEC-137 E.5: tiempo hasta la próxima comida sugerida (lastMeal + 3h).
  String _estimateNextMealIn(NutritionState state) {
    if (state.mealsLoggedToday >= state.targetMeals) return '—';
    final lastMealAt = MealIntervalRules.lastMealOf(state.todayLogs);
    final nextAt = MealIntervalRules.nextSuggestedAt(lastMealAt);
    if (nextAt == null) return '—';
    final diff = nextAt.difference(DateTime.now());
    if (diff.isNegative) return 'Ahora';
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
