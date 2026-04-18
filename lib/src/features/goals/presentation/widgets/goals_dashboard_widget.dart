// SPEC-14: Objetivos del Usuario — Widget compacto para el dashboard
// Muestra los objetivos activos con barra de progreso vs valor actual.
// Al tocar "Editar" navega a /goals/setup.
// Si no hay goals activos, muestra un CTA para configurarlos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

class GoalsDashboardWidget extends ConsumerWidget {
  const GoalsDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final activeGoals = goals.values.where((g) => g.isActive).toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));

    if (activeGoals.isEmpty) {
      return _EmptyCTA(onTap: () => context.push('/goals/setup'));
    }

    // Valores actuales de los proveedores
    final userAsync     = ref.watch(currentUserStreamProvider);
    final sleepState    = ref.watch(sleepProvider);
    final hydration     = ref.watch(hydrationProvider);
    final exercise      = ref.watch(exerciseProvider);
    final streakState   = ref.watch(streakProvider);

    final user = userAsync.valueOrNull;

    double _current(GoalType type) {
      switch (type) {
        case GoalType.weightTarget:
          return user?.weight ?? 0;
        case GoalType.bodyFatTarget:
          return user?.bodyFatPercentage ?? 0;
        case GoalType.fastingDaysPerWeek:
          // weeklyAdherence (0.0–1.0) × 7 días = días efectivos estimados
          return (streakState.weeklyAdherence * 7).clamp(0.0, 7.0);
        case GoalType.exerciseMinPerDay:
          return exercise.todayMinutes.toDouble();
        case GoalType.sleepHoursPerNight:
          return sleepState.lastLog?.duration.inMinutes != null
              ? sleepState.lastLog!.duration.inMinutes / 60.0
              : 0;
        case GoalType.hydrationLitersPerDay:
          return hydration.currentAmountLiters;
      }
    }

    String _formatValue(GoalType type, double value) {
      switch (type) {
        case GoalType.weightTarget:          return '${value.toStringAsFixed(1)} kg';
        case GoalType.bodyFatTarget:         return '${value.toStringAsFixed(0)}%';
        case GoalType.fastingDaysPerWeek:    return '${value.toStringAsFixed(0)} días';
        case GoalType.exerciseMinPerDay:     return '${value.toStringAsFixed(0)} min';
        case GoalType.sleepHoursPerNight:    return '${value.toStringAsFixed(1)} h';
        case GoalType.hydrationLitersPerDay: return '${value.toStringAsFixed(1)} L';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      'MIS OBJETIVOS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/goals/setup'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Editar',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF1ABC9C).withOpacity(0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Goal rows ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: activeGoals.map((goal) {
                final double current = _current(goal.type);
                final double prog    = goal.progress(current);
                final Color c        = goal.pillarColor;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila: emoji + label + current/target
                      Row(
                        children: [
                          Text(goal.emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              goal.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                          // Valor actual / objetivo
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _formatValue(goal.type, current),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: c,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${_formatValue(goal.type, goal.targetValue)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Barra de progreso
                      Stack(
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: prog,
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Porcentaje de progreso
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(prog * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 8,
                            color: c.withOpacity(0.6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA cuando no hay objetivos configurados ─────────────────────────────────

class _EmptyCTA extends StatelessWidget {
  const _EmptyCTA({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF1ABC9C).withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1ABC9C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🎯', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Define tus objetivos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Elena personalizará tu plan con base en tus metas.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.45),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF1ABC9C).withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
