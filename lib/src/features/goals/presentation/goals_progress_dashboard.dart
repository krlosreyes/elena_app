// SPEC-154: GoalsProgressDashboard — progreso visible de objetivos
// activos del usuario en la pantalla Análisis.
//
// Estructura:
//   header "TUS OBJETIVOS" + CTA "Editar"
//   por cada goal activo: emoji + label + barra 7 niveles + % + valores + mensaje
//   empty state con CTA al GoalSetupScreen si no hay goals activos

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/goals/application/goals_progress_provider.dart';
import 'package:elena_app/src/features/goals/domain/goal_progress_snapshot.dart';
import 'package:elena_app/src/features/goals/presentation/goal_setup_screen.dart';

class GoalsProgressDashboard extends ConsumerWidget {
  const GoalsProgressDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSnapshots = ref.watch(goalsProgressProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: asyncSnapshots.when(
        loading: () => _buildLoading(),
        error: (_, __) => _buildError(),
        data: (snapshots) => _buildContent(context, snapshots),
      ),
    );
  }

  // ─── Estados ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.metabolicGreen,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: Text(
        'No pudimos cargar tus objetivos.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<GoalProgressSnapshot> snapshots,
  ) {
    if (snapshots.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, hasGoals: true),
        const SizedBox(height: 16),
        for (int i = 0; i < snapshots.length; i++) ...[
          _buildSnapshotRow(snapshots[i]),
          if (i < snapshots.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
        ],
      ],
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, {required bool hasGoals}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TUS OBJETIVOS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (hasGoals)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _navigateToSetup(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Text(
                    'Editar',
                    style: TextStyle(
                      color: AppColors.metabolicGreen.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.metabolicGreen,
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── Snapshot row ───────────────────────────────────────────────────

  Widget _buildSnapshotRow(GoalProgressSnapshot s) {
    final goal = s.goal;
    final accent = goal.pillarColor;
    final pct = (s.progress.clamp(0.0, 1.0) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea 1: emoji + label a la izquierda, % a la derecha.
        Row(
          children: [
            Text(
              goal.emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                goal.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Línea 2: barra de progreso discreta.
        _buildDiscreteBar(s.progress, accent),
        const SizedBox(height: 6),
        // Línea 3: start → target con unidad.
        Text(
          '${_formatValue(s.goal.startValue, goal.type)} → '
          '${_formatValue(s.goal.targetValue, goal.type)} '
          '${goal.unit}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        // Línea 4: mensaje motivacional.
        Text(
          s.motivationalMessage,
          style: TextStyle(
            color: s.isAchieved
                ? AppColors.metabolicGreen
                : Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Formato de valor según unidad. Peso y grasa con decimal; el resto
  /// como entero (excepto sueño que usa 0.5h).
  String _formatValue(double v, dynamic type) {
    final typeName = type.toString().split('.').last;
    switch (typeName) {
      case 'weightTarget':
      case 'hydrationLitersPerDay':
        return v.toStringAsFixed(1);
      case 'sleepHoursPerNight':
        return ((v * 2).round() / 2).toStringAsFixed(1);
      case 'bodyFatTarget':
        return v.toStringAsFixed(1);
      default:
        return v.round().toString();
    }
  }

  Widget _buildDiscreteBar(double progress, Color accent) {
    const buckets = 7;
    final filled = (progress.clamp(0.0, 1.0) * buckets).round();
    return Row(
      children: List.generate(buckets, (i) {
        final isFilled = i < filled;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 8,
            decoration: BoxDecoration(
              color: isFilled ? accent : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, hasGoals: false),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Text(
                    'Definí tu plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Sin objetivos no hay ruta clara. Elena puede sugerirte 6 '
                'basados en tu estado actual.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToSetup(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.metabolicGreen.withValues(alpha: 0.18),
                    foregroundColor: AppColors.metabolicGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            AppColors.metabolicGreen.withValues(alpha: 0.40),
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  child: const Text('Configurar mis objetivos'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GoalSetupScreen(),
      ),
    );
  }
}
