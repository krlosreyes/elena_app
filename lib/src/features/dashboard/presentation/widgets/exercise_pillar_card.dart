// SPEC-119 (refactor god widget) — card del pilar Ejercicio extraída de
// dashboard_screen.dart. ConsumerWidget autocontenido; recibe el estado por
// constructor y lee la meta efectiva (SoT) vía provider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_card_ui.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/presentation/exercise_input_sheet.dart';
// Propuesta módulo Ejercicio (2026-07-21): banner "hoy toca X" cuando
// el usuario tiene un WeeklyExercisePlan generado. Aditivo — si no hay
// plan, `_PlanOfTheDayBanner` no pinta nada y la card se ve exactamente
// igual que antes.
import 'package:elena_app/src/features/exercise/application/weekly_exercise_plan_providers.dart';
import 'package:elena_app/src/features/exercise/domain/weekly_exercise_plan.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_providers.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_providers.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';

class ExercisePillarCard extends ConsumerWidget {
  const ExercisePillarCard({super.key, required this.state});

  final ExerciseState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFF2DD4BF);
    // SPEC-231: HealthKit activo cuando el permiso es Granted.
    final healthPerm = ref.watch(healthPermissionStatusProvider);
    final isManual = healthPerm is! HealthPermissionGranted;
    // BUGFIX objetivos: meta desde "Mis objetivos" (SoT) con fallback.
    final goal = ref.watch(effectiveExerciseGoalProvider);
    final minutes = state.todayMinutes;
    final progress = goal > 0 ? (minutes / goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final achieved = minutes >= goal;
    final lastSession = state.history.isNotEmpty ? state.history.first : null;
    // Propuesta módulo Ejercicio (2026-07-21): plan del día, si existe.
    final plan = ref.watch(weeklyExercisePlanProvider);

    return PillarCardUi.shell(
      title: 'Sarcopenia & Resistencia',
      badge: achieved ? 'ACTIVO' : 'Ejercicio',
      accent: accent,
      children: [
        if (plan != null) ...[
          _PlanOfTheDayBanner(entry: plan.entryFor(DateTime.now())),
          const SizedBox(height: 14),
          _WeeklyFuerzaStrip(plan: plan),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$minutes min',
              style: TextStyle(
                color: accent,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '/ $goal min meta',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        // Última sesión: tipo + duración
        if (lastSession != null) ...[
          const SizedBox(height: 6),
          _LastSessionRow(session: lastSession, accent: accent),
        ],
        const SizedBox(height: 10),
        PillarCardUi.progressBar(progress, accent),
        const SizedBox(height: 6),
        PillarCardUi.completionLabel(pct),
        const SizedBox(height: 16),
        PillarCardUi.benefitChip(
          accent: accent,
          text: achieved
              ? '✓ Meta cumplida — síntesis proteica muscular activa 24-48h post sesión'
              : 'Acumula minutos para activar la síntesis proteica muscular post-ejercicio.',
        ),
        const SizedBox(height: 18),
        // SPEC-231: chip visible cuando HealthKit no está activo.
        if (isManual) PillarCardUi.manualDataChip(),
        PillarCardUi.primaryButton(
          label: 'Agregar Sesión',
          icon: Icons.fitness_center_rounded,
          color: accent,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ExerciseInputSheet(),
          ),
        ),
        const SizedBox(height: 10),
        PillarCardUi.secondaryButton(
          label: 'Eliminar última sesión',
          icon: Icons.delete_outline_rounded,
          onPressed: state.history.isEmpty
              ? null
              : () => ref.read(exerciseProvider.notifier).removeLastSession(),
        ),
      ],
    );
  }
}

/// Propuesta módulo Ejercicio (2026-07-21): "hoy toca X" — reemplaza el
/// contador neutro por el día programado del plan. §4.4 de la
/// propuesta: hacer muy visible qué tipo de sesión corresponde hoy, en
/// vez de dejar que el usuario decida todo.
class _PlanOfTheDayBanner extends StatelessWidget {
  const _PlanOfTheDayBanner({required this.entry});

  final PlanDayEntry entry;

  @override
  Widget build(BuildContext context) {
    final isRest = entry.type == PlanSessionType.descanso;
    final color = isRest ? Colors.grey : const Color(0xFF2DD4BF);
    final label = switch (entry.type) {
      PlanSessionType.fuerza =>
        'Hoy toca Fuerza · ${entry.durationMinutes} min',
      PlanSessionType.cardio =>
        'Hoy toca Cardio (${entry.cardioIntensity?.label ?? ""}) · '
            '${entry.durationMinutes} min',
      PlanSessionType.descanso => 'Hoy es tu día de descanso',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(
            isRest ? Icons.self_improvement_rounded : Icons.bolt_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pedido directo de Carlos (23-jul): franja de 7 círculos pequeños
/// (L M M J V S D) que marca automáticamente qué días de la semana
/// tocan Fuerza, según el plan generado por WeeklyExercisePlanEngine.
/// Mismo criterio aditivo que `_PlanOfTheDayBanner`: vive dentro del
/// mismo `if (plan != null)` — sin plan no hay dato real que marcar.
/// Mismo color de "fuerza" que `WeeklyPlanSplitCard` (Progreso) para
/// que el usuario asocie el mismo significado en ambas pantallas.
class _WeeklyFuerzaStrip extends StatelessWidget {
  const _WeeklyFuerzaStrip({required this.plan});

  final WeeklyExercisePlan plan;

  static const _fuerzaColor = Color(0xFF14B8A6);
  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday; // ISO 1=lunes..7=domingo.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU SEMANA DE FUERZA',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final weekday = i + 1;
            final entry = plan.days.firstWhere(
              (d) => d.weekday == weekday,
              orElse: () => plan.days.first,
            );
            final isFuerza = entry.type == PlanSessionType.fuerza;
            final isToday = weekday == todayWeekday;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFuerza
                        ? _fuerzaColor
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isToday
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.12),
                      width: isToday ? 1.6 : 1,
                    ),
                  ),
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      color: isFuerza
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Fila compacta que muestra el tipo y duración de la última sesión.
class _LastSessionRow extends StatelessWidget {
  const _LastSessionRow({required this.session, required this.accent});

  final ExerciseLog session;
  final Color accent;

  String _label() {
    // Preferir el enum tipado (SPEC-68); si es null usar el string legacy.
    if (session.type != null) {
      switch (session.type!) {
        case ExerciseType.liss:
          return 'Cardio (LISS)';
        case ExerciseType.hiit:
          return 'HIIT';
        case ExerciseType.strength:
          return 'Fuerza';
        case ExerciseType.mobility:
          return 'Movilidad';
      }
    }
    // Fallback al string libre legacy
    final raw = session.activityType.trim();
    return raw.isNotEmpty ? raw : 'Ejercicio';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.history_rounded,
            size: 14, color: accent.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          'Última: ${_label()} · ${session.durationMinutes} min',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
