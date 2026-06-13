// SPEC-200 / SPEC-200.1: detalle del "Score del Día".
//
// Usa closedCycleScoreSeriesProvider — el score al momento del CIERRE del
// ciclo metabólico, no el score en vivo del día actual.
//
// Filtros locales (Semana / Mes / 3M / 6M / 1A) aislados de la pantalla
// principal Progreso via ProviderScope override. Cambiar el rango acá NO
// afecta el rango global del overview.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/trend_comparison_computer.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/bar_chart_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/segmented_range_control.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/trend_comparison_card.dart';

/// Wrapper que aísla el rango temporal de esta pantalla del global.
/// El ProviderScope override crea una instancia local de analysisRangeProvider
/// que no contamina la pantalla principal de Progreso.
class DailyScoreDetailScreen extends StatelessWidget {
  const DailyScoreDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        analysisRangeProvider.overrideWith((_) => AnalysisRange.w1),
      ],
      child: const _DailyScoreDetailContent(),
    );
  }
}

class _DailyScoreDetailContent extends ConsumerStatefulWidget {
  const _DailyScoreDetailContent();

  @override
  ConsumerState<_DailyScoreDetailContent> createState() =>
      _DailyScoreDetailContentState();
}

class _DailyScoreDetailContentState
    extends ConsumerState<_DailyScoreDetailContent> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    final mode = AggregationMode.forRange(range);
    // Usa los scores de cierre de ciclo metabólico.
    final seriesAsync = ref.watch(closedCycleScoreSeriesProvider);
    final series = seriesAsync.valueOrNull ??
        MetricSeries(label: 'Score del día', unit: '', points: const []);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkResponse(
                  onTap: () => context.pop(),
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Score del día',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 18),
              // Rango local — no afecta la pantalla de Progreso.
              const SegmentedRangeControl(),
              const SizedBox(height: 24),
              if (seriesAsync.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                BarChartCard(
                  series: series,
                  accent: AppColors.metabolicGreen,
                  periodLabel: range.periodLabel,
                  headline: 'Score al cierre de cada día metabólico.',
                  aggregationMode: mode,
                  heroAggregation: HeroAggregation.avg,
                  heroUnit: '',
                  targetValue: 100,
                  targetLabel: 'Meta 100',
                  deltaIsBetterIf: 'up',
                ),
                const SizedBox(height: 24),
                _buildTrendSection(series, mode),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'Tu puntaje refleja cómo viviste cada día metabólico al '
                  'momento de cerrarlo — llega a 100 cuando cumples los 5 '
                  'pilares. Es distinto del IMR, que mide tu estado '
                  'metabólico de fondo y se mueve en semanas.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendSection(MetricSeries series, AggregationMode mode) {
    final trend = TrendComparisonComputer.compute(
      series: series,
      mode: mode,
      betterIf: 'up',
    );
    if (trend == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Tendencia',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
        ),
        TrendComparisonCard(
          label: 'Score del día',
          unit: '',
          accent: AppColors.metabolicGreen,
          trend: trend,
          mode: mode,
        ),
      ],
    );
  }
}
