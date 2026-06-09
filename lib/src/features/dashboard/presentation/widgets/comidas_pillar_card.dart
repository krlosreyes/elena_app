// SPEC-119 (refactor god widget) — card del pilar Comidas extraída de
// dashboard_screen.dart, con su banner de bloqueo durante ayuno y helpers.
// El cambio de pilar (ir a Ayuno) se delega al padre vía `onGoToFasting`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/meals_locked_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_card_ui.dart';
import 'package:elena_app/src/features/nutrition/application/cociente_a_service.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
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
    final aDominantCount = cocienteService.aDominantCount(state.todayLogs);

    final card = PillarCardUi.shell(
      title: 'Nutrición Científica',
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
              const SizedBox(height: 16),
              PillarCardUi.benefitChip(
                accent: accent,
                text: state.windowAdherence >= 0.5
                    ? '✓ Comidas dentro de ventana circadiana — alineación con ritmo metabólico óptima'
                    : 'Mantén tus comidas dentro de la ventana circadiana para alinear tu ritmo metabólico.',
              ),
              const SizedBox(height: 18),
              PillarCardUi.primaryButton(
                label: 'Registrar ${state.nextMealLabel}',
                icon: Icons.restaurant_rounded,
                color: accent,
                onPressed: isFastingActive || state.isSaving
                    ? null
                    : () => PlateRatioSheet.show(context),
              ),
              const SizedBox(height: 10),
              PillarCardUi.secondaryButton(
                label: 'Deshacer última comida registrada',
                icon: Icons.undo_rounded,
                onPressed: isFastingActive || state.todayLogs.isEmpty
                    ? null
                    : () =>
                        ref.read(nutritionProvider.notifier).removeLastMeal(),
              ),
              const SizedBox(height: 10),
              PillarCardUi.secondaryButton(
                label: aDominantCount == 0
                    ? 'Ver semana →'
                    : 'Ver semana → · $aDominantCount A-dominantes hoy',
                icon: Icons.calendar_view_week_rounded,
                onPressed: () => context.push('/nutrition/weekly'),
              ),
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
