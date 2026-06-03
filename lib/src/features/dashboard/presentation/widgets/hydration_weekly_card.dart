// SPEC-161: HydrationWeeklyCard — hidratación semanal en Pilares.
//
// Estructura coherente con SleepQualityCard (SPEC-159) y MealsRatioCard
// (SPEC-158): header + headline + 7 filas + insight + empty state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/last_week_hydration_provider.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_weekly_insight.dart';

const Color _kHydrationAccent = Color(0xFF38BDF8);

class HydrationWeeklyCard extends ConsumerWidget {
  const HydrationWeeklyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBreakdown = ref.watch(lastWeekHydrationProvider);
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
          color: _kHydrationAccent,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: Text(
        'No pudimos cargar tu hidratación.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContent(HydrationWeeklyBreakdown b) {
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
          for (final d in b.days) _buildDayRow(d, b.targetLitersPerDay),
          const SizedBox(height: 12),
          _buildInsightBlock(b),
        ],
      ],
    );
  }

  Widget _buildHeader(HydrationWeeklyBreakdown b) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TU HIDRATACIÓN',
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

  Widget _buildHeadline(HydrationWeeklyBreakdown b) {
    final pct = (b.percentAvg * 100).round();
    final color = _colorForTier(b.tier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${b.litersAvg.toStringAsFixed(1)}L',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'promedio',
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
          '$pct% del target (${b.targetLitersPerDay.toStringAsFixed(1)}L)',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(HydrationDayEntry d, double target) {
    final pct = (d.percentVsTarget.clamp(0.0, 2.0) * 100).round();
    final color = _accentForPct(d.percentVsTarget);
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
          SizedBox(width: 100, child: _buildDiscreteBar(d.percentVsTarget, color)),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              '${d.liters.toStringAsFixed(1)}L',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$pct%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscreteBar(double pct, Color color) {
    const buckets = 10;
    // 10 buckets = 100% target.
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

  Widget _buildInsightBlock(HydrationWeeklyBreakdown b) {
    final m = HydrationCoachingMessage.forTier(b.tier);
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
          Icon(Icons.water_drop_outlined, color: accent, size: 18),
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
        'Registrá tu hidratación para ver tu patrón semanal.',
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
    if (pct >= 0.80) return _kHydrationAccent;
    if (pct >= 0.60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _colorForTier(HydrationInsightTier t) {
    switch (t) {
      case HydrationInsightTier.optimal:
        return AppColors.metabolicGreen;
      case HydrationInsightTier.adequate:
        return _kHydrationAccent;
      case HydrationInsightTier.low:
        return const Color(0xFFF59E0B);
      case HydrationInsightTier.severelyLow:
        return const Color(0xFFEF4444);
      case HydrationInsightTier.empty:
        return Colors.grey;
    }
  }
}
