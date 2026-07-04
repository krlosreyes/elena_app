// SPEC-200 / SPEC-200.1: detalle del "Score del Día".
//
// Fuente: closedCycleScoreSeriesProvider — el score al momento del CIERRE
// del ciclo metabólico (MetabolicCycle.dailyScore), no el score en vivo.
//
// Rango: abre en Semana. Al salir restaura m1 para la pantalla Progreso.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_launcher.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analysisRangeProvider.notifier).state = AnalysisRange.w1;
    });
  }

  @override
  void dispose() {
    // BUGFIX (2026-06-14): la mutación de analysisRangeProvider propaga
    // sincronamente la invalidación de dailyScoreSeriesProvider al widget
    // mientras está en medio del teardown → "Cannot use ref after disposed".
    // try-catch defensivo: el valor se restaura correctamente en el caso
    // feliz; en el caso de error (ProviderScope teardown, hot-restart en
    // debug), el estado se resetea en el siguiente cold start sin impacto.
    try {
      ref.read(analysisRangeProvider.notifier).state = AnalysisRange.m1;
    } catch (_) {}
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    final mode = AggregationMode.forRange(range);
    // SPEC-219 rev2: fuente ÚNICA — ciclos cerrados con dailyScore.
    // Sin fallback a streak (scores distintos causaban flip-flop).
    final series = ref.watch(resolvedDailyScoreSeriesProvider);
    // Spinner mientras el stream de ciclos no haya emitido aún.
    final seriesAsync = ref.watch(closedCycleScoreSeriesProvider);
    final showSpinner = seriesAsync.isLoading && series.points.isEmpty;
    // SPEC-197: detalle Score del Día solo Premium.
    final isPremium = ref.watch(featureGateProvider).hasFullAccess;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              controller: _scroll,
              physics: isPremium ? null : const NeverScrollableScrollPhysics(),
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
                  if (showSpinner)
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
          // SPEC-197 soft gate: blur overlay para usuarios Free.
          if (!isPremium) _buildPremiumGateOverlay(context),
        ],
      ),
    );
  }

  /// Overlay de blur + CTA premium con su propio botón ←.
  Widget _buildPremiumGateOverlay(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.50],
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    AppColors.backgroundDark.withValues(alpha: 0.92),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkResponse(
                      onTap: () => context.pop(),
                      radius: 22,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: AppColors.metabolicGreen
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: AppColors.metabolicGreen,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Detalle Score del Día',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Gráficas detalladas, tendencias y análisis de evolución disponibles con Elena Premium.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 14,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () => openPaywall(
                                    context, ref,
                                    feature: GatedFeature.analyticsHistory,
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.metabolicGreen,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Desbloquear Premium',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
