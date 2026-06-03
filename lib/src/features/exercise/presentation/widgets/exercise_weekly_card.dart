// SPEC-161: ExerciseWeeklyCard — ejercicio semanal en Pilares.
//
// Patrón coherente con SleepQualityCard, MealsRatioCard,
// HydrationWeeklyCard: header + headline + 7 filas + insight.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/exercise/application/exercise_weekly_computer.dart';
import 'package:elena_app/src/features/exercise/application/last_week_exercise_provider.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_weekly_insight.dart';

const Color _kExerciseAccent = Color(0xFF14B8A6);

class ExerciseWeeklyCard extends ConsumerWidget {
  const ExerciseWeeklyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBreakdown = ref.watch(lastWeekExerciseProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: asyncBreakdown.when(
        loading: _buildLoading,
        error: (_, __) => _buildError(),
        data: _buildContent,
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _kExerciseAccent,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: Text(
        'No pudimos cargar tu ejercicio.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContent(ExerciseWeeklyBreakdown b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(b),
        const SizedBox(height: 14),
        if (b.isEmpty)
          _buildEmptyState()
        else ...[
          _buildHeadline(b),
          const SizedBox(height: 16),
          for (final d in b.days) _buildDayRow(d, b.targetMinutesPerDay),
          const SizedBox(height: 12),
          _buildInsightBlock(b),
        ],
      ],
    );
  }

  Widget _buildHeader(ExerciseWeeklyBreakdown b) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TU EJERCICIO',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '7 DÍAS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline(ExerciseWeeklyBreakdown b) {
    final pct = (b.percentAvg * 100).round();
    final color = _colorForTier(b.tier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${b.minutesAvg.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                height: 1.0,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'min · promedio',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$pct% del target (${b.targetMinutesPerDay} min/día)',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(ExerciseDayEntry d, int target) {
    final pct = d.percentVsTarget;
    final color = _accentForPct(pct);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              _dayShort(d.date.weekday),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: _buildDiscreteBar(pct, color)),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${d.minutes} min',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (d.predominantType != null) ...[
            const SizedBox(width: 6),
            Text(
              d.predominantType!.shortLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscreteBar(double pct, Color color) {
    const buckets = 10;
    final filled = (pct.clamp(0.0, 1.0) * buckets).round();
    return Row(
      children: List.generate(buckets, (i) {
        final isFilled = i < filled;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 6,
            decoration: BoxDecoration(
              color: isFilled ? color : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInsightBlock(ExerciseWeeklyBreakdown b) {
    final m = ExerciseCoachingMessage.forTier(b.tier);
    if (m == null) return const SizedBox.shrink();
    final accent = _colorForTier(b.tier);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fitness_center_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.headline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m.action,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m.citation,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        'Registrá tu ejercicio para ver tu patrón semanal.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static const _daysShort = [
    'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom',
  ];

  String _dayShort(int weekday) => _daysShort[(weekday - 1).clamp(0, 6)];

  Color _accentForPct(double pct) {
    if (pct >= 1.0) return AppColors.metabolicGreen;
    if (pct >= 0.80) return _kExerciseAccent;
    if (pct >= 0.50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _colorForTier(ExerciseInsightTier t) {
    switch (t) {
      case ExerciseInsightTier.meetsTarget:
        return AppColors.metabolicGreen;
      case ExerciseInsightTier.aboveTarget:
        return _kExerciseAccent;
      case ExerciseInsightTier.low:
        return const Color(0xFFF59E0B);
      case ExerciseInsightTier.sedentary:
        return const Color(0xFFEF4444);
      case ExerciseInsightTier.empty:
        return Colors.grey;
    }
  }
}
