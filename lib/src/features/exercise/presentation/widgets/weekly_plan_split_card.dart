// Propuesta módulo Ejercicio (2026-07-21), Fase 3: vista del split
// semanal generado por WeeklyExercisePlanEngine — 6 días fuerza/cardio
// + 1 descanso, con el momento del día recomendado por sesión.
//
// Se muestra SOLO si el usuario ya tiene un plan (perfil de ejercicio
// completo + composición corporal calculable). Si no, no se renderiza
// nada — el ExerciseWeeklyCard existente sigue funcionando igual que
// antes para esos usuarios (comportamiento aditivo, sin regresión).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/exercise/application/weekly_exercise_plan_providers.dart';
import 'package:elena_app/src/features/exercise/domain/weekly_exercise_plan.dart';

const Color _kFuerzaColor = Color(0xFF14B8A6);
const Color _kCardioColor = Color(0xFF38BDF8);
const Color _kDescansoColor = Colors.grey;

class WeeklyPlanSplitCard extends ConsumerWidget {
  const WeeklyPlanSplitCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(weeklyExercisePlanProvider);
    if (plan == null) return const SizedBox.shrink();

    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TU PLAN DE LA SEMANA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Zona ${plan.zoneLabel}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.fuerzaCount} fuerza · ${plan.cardioCount} cardio · '
            '1 descanso',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          for (final day in plan.days) _buildDayRow(day, today),
        ],
      ),
    );
  }

  Widget _buildDayRow(PlanDayEntry day, DateTime today) {
    final isToday = day.weekday == today.weekday;
    final color = switch (day.type) {
      PlanSessionType.fuerza => _kFuerzaColor,
      PlanSessionType.cardio => _kCardioColor,
      PlanSessionType.descanso => _kDescansoColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border:
            isToday ? Border.all(color: color.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              day.weekdayShortLabel,
              style: TextStyle(
                color: isToday
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              _dayLabel(day),
              style: TextStyle(
                color: Colors.white.withValues(alpha: isToday ? 0.95 : 0.75),
                fontSize: 12.5,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (day.recommendedPhase != null)
            Text(
              _phaseWindowLabel(day.recommendedPhase!),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  String _dayLabel(PlanDayEntry day) {
    switch (day.type) {
      case PlanSessionType.fuerza:
        return 'Fuerza · ${day.durationMinutes} min';
      case PlanSessionType.cardio:
        final tag = day.cardioIntensity?.label ?? 'Cardio';
        return '$tag · ${day.durationMinutes} min';
      case PlanSessionType.descanso:
        return 'Descanso';
    }
  }

  /// Ventana horaria de la fase — misma tabla que
  /// core/orchestrator/biological_phases.dart (comentario de fases).
  String _phaseWindowLabel(CircadianPhase phase) {
    switch (phase) {
      case CircadianPhase.motorFuerza:
        return '15-20h';
      case CircadianPhase.cognitivo:
        return '9-13h';
      case CircadianPhase.receso:
        return '13-15h';
      case CircadianPhase.alerta:
        return '6-9h';
      case CircadianPhase.creatividad:
        return '20-22:30h';
      case CircadianPhase.sueno:
        return '';
    }
  }
}
