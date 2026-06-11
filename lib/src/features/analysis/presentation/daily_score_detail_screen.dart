// SPEC-200 / SPEC-200.1: detalle del "Score del Día" — abierto desde el tile
// de Resultados. Usa el MISMO BarChartCard + sección Tendencia que el detalle
// de Ayuno para mantener coherencia visual (barras día a día + hero promedio +
// línea de meta + comparación corto vs largo).

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

class DailyScoreDetailScreen extends ConsumerStatefulWidget {
  const DailyScoreDetailScreen({super.key});

  @override
  ConsumerState<DailyScoreDetailScreen> createState() =>
      _DailyScoreDetailScreenState();
}

class _DailyScoreDetailScreenState
    extends ConsumerState<DailyScoreDetailScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Igual que el detalle de pilar: arranca en 30 días.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(analysisRangeProvider) != AnalysisRange.d30) {
        ref.read(analysisRangeProvider.notifier).state = AnalysisRange.d30;
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    final mode = AggregationMode.forRange(range);
    final series = ref.watch(dailyScoreSeriesProvider);

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
              const SegmentedRangeControl(),
              const SizedBox(height: 24),
              BarChartCard(
                series: series,
                accent: AppColors.metabolicGreen,
                periodLabel: _periodLabel(range),
                headline: 'Tu score por día en este período.',
                aggregationMode: mode,
                heroAggregation: HeroAggregation.avg,
                heroUnit: '',
                targetValue: 100,
                targetLabel: 'Meta 100',
                deltaIsBetterIf: 'up',
              ),
              const SizedBox(height: 24),
              _buildTrendSection(series, mode),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'Tu puntaje diario refleja cómo viviste cada día — llega a '
                  '100 cuando cumples los 5 pilares. Es distinto del IMR, que '
                  'mide tu estado metabólico de fondo y se mueve en semanas.',
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

  String _periodLabel(AnalysisRange r) {
    switch (r) {
      case AnalysisRange.d30:
        return 'Últimos 30 días';
      case AnalysisRange.m3:
        return 'Últimos 3 meses';
      case AnalysisRange.m6:
        return 'Últimos 6 meses';
      case AnalysisRange.y1:
        return 'Último año';
      case AnalysisRange.all:
        return 'Todo tu historial';
    }
  }
}
