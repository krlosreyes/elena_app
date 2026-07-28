// SPEC-158: MealsRatioCard — distribución A:E semanal en Análisis.
//
// Estructura:
//   header "TUS PLATOS" + rango
//   % A-dominante grande + sublabel
//   stacked bar horizontal (5 segmentos proporcionales)
//   lista de 5 filas con conteos individuales
//   insight según tier (Frank Suárez + Jenkins)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/last_week_meals_ratio_provider.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/meals_ratio_breakdown.dart';

class MealsRatioCard extends ConsumerWidget {
  const MealsRatioCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBreakdown = ref.watch(lastWeekMealsRatioProvider);

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

  // ─── Estados ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      height: 200,
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
        'No pudimos cargar tus platos.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContent(MealsRatioBreakdown b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(b),
        const SizedBox(height: 14),
        if (b.isEmpty)
          _buildEmptyState()
        else ...[
          _buildHeadlinePercent(b),
          const SizedBox(height: 16),
          _buildStackedBar(b),
          const SizedBox(height: 16),
          for (final r in MealRatio.values) _buildRatioRow(r, b),
          const SizedBox(height: 14),
          _buildInsightBlock(b),
        ],
      ],
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(MealsRatioBreakdown b) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TUS PLATOS',
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

  // ─── Headline % ─────────────────────────────────────────────────────

  Widget _buildHeadlinePercent(MealsRatioBreakdown b) {
    final pct = b.aDominantPercent;
    final color = _colorForTier(b.tier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$pct%',
              style: TextStyle(
                color: color,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'A-dominantes',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${b.aDominantCount} de ${b.total} platos',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Stacked bar ────────────────────────────────────────────────────

  Widget _buildStackedBar(MealsRatioBreakdown b) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 14,
        child: Row(
          children: MealRatio.values.map((r) {
            final count = b.counts[r] ?? 0;
            if (count == 0) return const SizedBox.shrink();
            return Expanded(
              flex: count,
              child: Container(color: _colorForRatio(r)),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Lista por ratio ────────────────────────────────────────────────

  Widget _buildRatioRow(MealRatio r, MealsRatioBreakdown b) {
    final count = b.counts[r] ?? 0;
    final maxCount = b.counts.values.fold<int>(1, (m, v) => v > m ? v : m);
    final fraction = count / maxCount;
    final color = _colorForRatio(r);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Swatch.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          // Label.
          SizedBox(
            width: 60,
            child: Text(
              r.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mini barra relativa al máximo.
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Conteo numérico.
          SizedBox(
            width: 22,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Insight ────────────────────────────────────────────────────────

  Widget _buildInsightBlock(MealsRatioBreakdown b) {
    final insight = MealsRatioInsight.forTier(b.tier);
    if (insight == null) return const SizedBox.shrink();
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
          Icon(
            Icons.lightbulb_outline_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.headline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.action,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.citation,
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

  // ─── Empty state ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        'Registra tus comidas para ver tu distribución A:E semanal.',
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

  // ─── Color maps ─────────────────────────────────────────────────────

  Color _colorForRatio(MealRatio r) {
    switch (r) {
      case MealRatio.allA:
        return AppColors.metabolicGreen;
      case MealRatio.a3e1:
        return const Color(0xFF84CC16); // verde lima
      case MealRatio.a2e1:
        return const Color(0xFFEAB308); // amarillo
      case MealRatio.a1e1:
        return const Color(0xFFF97316); // naranja
      case MealRatio.allE:
        return const Color(0xFFEF4444); // rojo
    }
  }

  Color _colorForTier(MealsRatioInsightTier t) {
    switch (t) {
      case MealsRatioInsightTier.excellent:
        return AppColors.metabolicGreen;
      case MealsRatioInsightTier.good:
        return const Color(0xFF84CC16);
      case MealsRatioInsightTier.insufficient:
        return const Color(0xFFF59E0B);
      case MealsRatioInsightTier.poor:
        return const Color(0xFFEF4444);
      case MealsRatioInsightTier.empty:
        return Colors.grey;
    }
  }
}
