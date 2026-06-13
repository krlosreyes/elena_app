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
import 'package:elena_app/src/features/goals/application/pillar_goal_providers.dart';

class ExercisePillarCard extends ConsumerWidget {
  const ExercisePillarCard({super.key, required this.state});

  final ExerciseState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFF2DD4BF);
    // BUGFIX objetivos: meta desde "Mis objetivos" (SoT) con fallback.
    final goal = ref.watch(effectiveExerciseGoalProvider);
    final minutes = state.todayMinutes;
    final progress = goal > 0 ? (minutes / goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final achieved = minutes >= goal;
    final lastSession = state.history.isNotEmpty ? state.history.first : null;

    return PillarCardUi.shell(
      title: 'Sarcopenia & Resistencia',
      badge: achieved ? 'ACTIVO' : 'Ejercicio',
      accent: accent,
      children: [
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
              : () => ref
                  .read(exerciseProvider.notifier)
                  .removeLastSession(),
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
        Icon(Icons.history_rounded, size: 14, color: accent.withValues(alpha: 0.7)),
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
