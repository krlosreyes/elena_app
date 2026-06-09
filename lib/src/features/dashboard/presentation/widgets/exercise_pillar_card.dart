// SPEC-119 (refactor god widget) — card del pilar Ejercicio extraída de
// dashboard_screen.dart. ConsumerWidget autocontenido; recibe el estado por
// constructor y lee la meta efectiva (SoT) vía provider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_card_ui.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
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
          onPressed: () => _pendingSnack(
            context,
            'Eliminar última sesión de ejercicio',
          ),
        ),
      ],
    );
  }

  void _pendingSnack(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName: función disponible próximamente'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
