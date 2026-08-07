// 20-jul: sección "Tu avance de hoy" en la pantalla de Objetivos.
//
// Carlos pidió que el usuario tenga claro qué le sugiere Elena Y cómo
// va avanzando hoy contra eso. `ProfileGoalsSection` (que vive en esta
// misma pantalla) ya cubre la primera parte — lista las metas
// configuradas. Le faltaba la segunda: nunca mostraba cuánto llevás
// HOY. Esta sección la agrega, para los 5 pilares diarios (ayuno,
// sueño, hidratación, ejercicio, nutrición) — deliberadamente NO
// incluye peso/grasa corporal (son metas de composición corporal a
// más largo plazo, no "objetivos del día").
//
// Fuente de los valores: exactamente los mismos providers que ya
// alimentan los anillos del Dashboard (`DashboardPillarsRow`) — se
// reutiliza esa lógica en vez de reimplementarla, para no reintroducir
// bugs ya resueltos ahí (ventana de sueño anclada al ciclo, ayuno con
// closedProgressToday, etc.).
//
// Esta pantalla es también el destino de la notificación diaria de
// "tus 5 objetivos de hoy" (ver notification_scheduler.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_providers.dart';
import 'package:elena_app/src/features/nutrition/application/meal_plan_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/minuta_adherence_score.dart';
import 'package:elena_app/src/features/streak/domain/fasting_schedule.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class TodaysProgressSection extends ConsumerWidget {
  const TodaysProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Ayuno ──────────────────────────────────────────────────────────
    final fastingState = ref.watch(fastingProvider);
    final currentProtocol =
        ref.watch(currentUserStreamProvider).valueOrNull?.fastingProtocol ??
            'Ninguno';
    final isFastingRestDay = FastingSchedule.isRestDay(
      date: DateTime.now(),
      protocol: currentProtocol,
      goals: ref.watch(goalsProvider),
    );
    final fastingProgress =
        isFastingRestDay ? 1.0 : fastingState.progressPercentage;
    final fastingSubtitle = isFastingRestDay
        ? 'Día de descanso programado'
        : '${fastingState.duration.inHours}h de ${fastingState.targetHours}h · protocolo ${fastingState.fastingProtocol}';

    // ── Sueño ──────────────────────────────────────────────────────────
    final cycleSleep = ref.watch(currentCycleSleepProvider);
    final sleepTargetH = ref.watch(effectiveSleepGoalProvider);
    final sleepHoursToday =
        cycleSleep == null ? 0.0 : cycleSleep.duration.inMinutes / 60.0;
    final sleepProgress = cycleSleep == null
        ? 0.0
        : (cycleSleep.duration.inMinutes / (sleepTargetH * 60)).clamp(0.0, 1.0);

    // ── Hidratación ───────────────────────────────────────────────────
    final hydration = ref.watch(hydrationProvider);

    // ── Ejercicio ─────────────────────────────────────────────────────
    final exercise = ref.watch(exerciseProvider);
    final exerciseGoal = ref.watch(effectiveExerciseGoalProvider).clamp(1, 240);
    final exerciseProgress =
        (exercise.todayMinutes / exerciseGoal.toDouble()).clamp(0.0, 1.0);

    // ── Nutrición ─────────────────────────────────────────────────────
    final nutrition = ref.watch(nutritionProvider);
    // SPEC-274: la barra refleja la ADHERENCIA a la Minuta cuando el
    // usuario ya la usa (marcó ≥1 comida); si no, cae al score por calidad
    // de plato de siempre (cero cambio para no adoptantes).
    final mealPlan = ref.watch(mealPlanNotifierProvider);
    final nutritionProgress = MinutaAdherenceScore.effective(
      fallbackScore: nutrition.nutritionScore,
      plan: mealPlan.plan,
    );

    final rows = <_PillarProgress>[
      _PillarProgress(
        icon: Icons.timer_rounded,
        color: AppColors.metabolicGreen,
        label: 'Ayuno',
        subtitle: fastingSubtitle,
        progress: fastingProgress,
      ),
      _PillarProgress(
        icon: Icons.nightlight_round,
        color: const Color(0xFF818CF8),
        label: 'Sueño',
        subtitle:
            '${sleepHoursToday.toStringAsFixed(1)}h de ${sleepTargetH.toStringAsFixed(1)}h sugeridas',
        progress: sleepProgress,
      ),
      _PillarProgress(
        icon: Icons.water_drop_rounded,
        color: Colors.blueAccent,
        label: 'Hidratación',
        subtitle:
            '${hydration.currentFormatted}L de ${hydration.goalFormatted}L sugeridos',
        progress: hydration.progressPercentage,
      ),
      _PillarProgress(
        icon: Icons.fitness_center_rounded,
        color: Colors.tealAccent,
        label: 'Ejercicio',
        subtitle: '${exercise.todayMinutes} min de $exerciseGoal min sugeridos',
        progress: exerciseProgress,
      ),
      // FIX (25-jul-2026, mismo hallazgo que en el Dashboard — Carlos:
      // "pesa más la cantidad de comidas que el tipo de comida"): esta
      // barra ("Tu avance de hoy" en Objetivos) tenía el mismo problema
      // que dashboard_pillars_row.dart y comidas_pillar_card.dart —
      // `progressPercentage` es puro conteo, ciego a calidad. El
      // subtítulo sigue mostrando el conteo (está claramente etiquetado
      // como tal), pero la barra ahora refleja `nutritionScore`
      // (calidad-ponderado), consistente con las otras dos pantallas.
      _PillarProgress(
        icon: Icons.restaurant_rounded,
        color: Colors.orangeAccent,
        label: 'Nutrición',
        subtitle:
            '${nutrition.mealsLoggedToday} de ${nutrition.targetMeals} comidas sugeridas',
        progress: nutritionProgress,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Text(
              'Tu avance de hoy',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: AppColors.borderSubtle,
              ),
            _buildRow(rows[i]),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRow(_PillarProgress p) {
    final pct = (p.progress.clamp(0.0, 1.0) * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(p.icon, size: 16, color: p.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: p.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(p.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarProgress {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final double progress;

  const _PillarProgress({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.progress,
  });
}
