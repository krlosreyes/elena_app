import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/presentation/goal_icons.dart';

/// SPEC-15 + SPEC-168.0.C: sección "Mis objetivos" del Road Map de
/// Avance Personal (Progreso). Una card por goal activo, con barra de
/// progreso inicio→meta y el valor actual calculado según el tipo.
///
/// SPEC-119: extraído de `progress_screen.dart` (ARCH-03). Ya vivía
/// como `ConsumerWidget` independiente — mudanza mecánica.
///
/// PERF-01: antes observaba 4 providers completos
/// (`currentUserStreamProvider`, `streakProvider`, `exerciseProvider`,
/// `hydrationProvider`) para leer un único campo de cada uno dentro de
/// `current0()`. Se cambiaron a `.select()`:
///   - user: solo se leen `weight` y `bodyFatPercentage` → se
///     seleccionan como tupla (ambos son `double?`, comparables por
///     valor).
///   - streak: solo `weeklyAdherence` (double).
///   - exercise: solo `todayMinutes` (int).
///   - hydration: solo `currentAmountLiters` (double).
/// `sleepProvider` se dejó con watch completo: el campo usado es
/// `lastLog?.duration`, un objeto anidado sin garantía de then
/// igualdad por valor, así que seleccionarlo no aporta beneficio real
/// y se prefirió no tocarlo por seguridad.
class GoalProgressSection extends ConsumerWidget {
  const GoalProgressSection({super.key, required this.goals});

  final List<UserGoal> goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (weight, bodyFatPercentage) = ref.watch(
      currentUserStreamProvider.select(
        (asyncUser) => (
          asyncUser.valueOrNull?.weight,
          asyncUser.valueOrNull?.bodyFatPercentage,
        ),
      ),
    );
    final weeklyAdherence = ref
        .watch(streakProvider.select((s) => s.weeklyAdherence));
    final sleepState = ref.watch(sleepProvider);
    final todayMinutes =
        ref.watch(exerciseProvider.select((s) => s.todayMinutes));
    final currentAmountLiters = ref
        .watch(hydrationProvider.select((s) => s.currentAmountLiters));

    double current0(GoalType type) {
      switch (type) {
        case GoalType.weightTarget:
          return weight ?? 0;
        case GoalType.bodyFatTarget:
          return bodyFatPercentage ?? 0;
        case GoalType.fastingDaysPerWeek:
          return (weeklyAdherence * 7).clamp(0.0, 7.0);
        case GoalType.exerciseMinPerDay:
          return todayMinutes.toDouble();
        case GoalType.sleepHoursPerNight:
          return sleepState.lastLog?.duration.inMinutes != null
              ? sleepState.lastLog!.duration.inMinutes / 60.0
              : 0;
        case GoalType.hydrationLitersPerDay:
          return currentAmountLiters;
        case GoalType.nutritionADominantPercent:
          // SPEC-168.0.C: currentValue del pilar Nutrición se calcula en
          // el dashboard de goals con el cocienteA semanal real. Aquí, en
          // el progress screen legacy, no tenemos ese provider — usamos 0
          // como fallback seguro (el progreso se mostrará en el goals
          // dashboard real, no acá).
          return 0;
      }
    }

    return Column(
      children: goals.map((goal) {
        final double current = current0(goal.type);
        final double prog = goal.progress(current);
        final Color c = goal.pillarColor;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(goalIcon(goal.type),
                        size: 16, color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${(prog * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: c,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: prog,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                                color: c.withValues(alpha: 0.4), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inicio: ${goal.startValue.toStringAsFixed(1)} ${goal.unit}',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    Text(
                      'Meta: ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                      style: TextStyle(
                          fontSize: 9,
                          color: c.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
