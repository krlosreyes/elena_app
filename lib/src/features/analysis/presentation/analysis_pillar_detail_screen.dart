// SPEC-168.4 (2026-06-03): pantalla de detalle de un pilar.
//
// El usuario entra acá desde el overview de Análisis tocando un tile.
// Dispatch al widget de chart correspondiente según la métrica:
//   - IMR / Peso → LineChartCard
//   - Ayuno / Hidratación / Ejercicio / Sueño → BarChartCard
//   - Nutrición → NutritionPieCard
//
// Hereda el rango temporal global (`analysisRangeProvider`), así que
// si el usuario cambió a "6 M" en la lista, el detalle abre con "6 M".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/historic_summaries_provider.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
import 'package:elena_app/src/features/analysis/application/goal_for_chart_provider.dart';
import 'package:elena_app/src/features/analysis/application/nutrition_pie_provider.dart';
// SPEC-168.4.1: tendencia corta vs larga, ahora vive dentro del detalle.
import 'package:elena_app/src/features/analysis/application/trend_comparison_computer.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/bar_chart_card.dart';
// SPEC-168.4.3: widget completo de composición corporal con tabs.
import 'package:elena_app/src/features/analysis/presentation/widgets/body_composition_trend_chart.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/line_chart_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_pillar_bar_chart.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_pillar_feedback_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/nutrition_pie_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/nutrition_trend_bar_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/segmented_range_control.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/trend_comparison_card.dart';

// Rango por defecto de los detalles de pilar: Semana.
// Al salir, se restaura el default de la pantalla Progreso (m1).
class AnalysisPillarDetailScreen extends ConsumerStatefulWidget {
  const AnalysisPillarDetailScreen({super.key, required this.metric});

  final ChartMetric metric;

  @override
  ConsumerState<AnalysisPillarDetailScreen> createState() =>
      _AnalysisPillarDetailScreenState();
}

class _AnalysisPillarDetailScreenState
    extends ConsumerState<AnalysisPillarDetailScreen> {
  // SPEC-168.4.2: accent ámbar para % grasa corporal — coherente con
  // BodyCompositionMetric.bodyFatPct (#F59E0B).
  static const Color _accentBodyFat = Color(0xFFF59E0B);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Arranca en Semana al abrir el detalle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analysisRangeProvider.notifier).state = AnalysisRange.w1;
    });
  }

  @override
  void dispose() {
    // Restaura el default de la pantalla Progreso al salir.
    ref.read(analysisRangeProvider.notifier).state = AnalysisRange.m1;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    final aggregationMode = AggregationMode.forRange(range);

    return Scaffold(
      // SPEC-168.4.6: mismo fondo que Hoy/Perfil/Analisis (cards
      // mantienen su #0C0C0E).
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              const SegmentedRangeControl(),
              const SizedBox(height: 24),
              _buildChart(aggregationMode),
              // SPEC-168.4.1: debajo del chart principal aparece la
              // tendencia corta vs larga del mismo pilar. Si no hay
              // data suficiente, devuelve SizedBox.shrink.
              const SizedBox(height: 24),
              _buildTrendSection(aggregationMode),
              // IMR: card de feedback por pilar debajo de la tendencia.
              if (widget.metric == ChartMetric.imr) ...[
                const SizedBox(height: 24),
                _imrFeedbackCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// SPEC-168.4.1: sección "Tendencia" debajo del chart. Para
  /// Nutrición usamos el bicolor (verde A / amarillo E). Para el
  /// resto, TrendComparisonCard con `betterIf` según pilar.
  Widget _buildTrendSection(AggregationMode mode) {
    switch (widget.metric) {
      case ChartMetric.nutritionAPct:
        return _nutritionTrend(mode);
      case ChartMetric.imr:
        return _genericTrend(imrSeriesProvider, 'IMR', '',
            AppColors.metabolicGreen, 'up', mode);
      case ChartMetric.weight:
        return _genericTrend(weightSeriesProvider, 'Peso', 'kg',
            const Color(0xFF60A5FA), 'down', mode);
      case ChartMetric.bodyFatPct:
        return _genericTrend(bodyFatSeriesProvider, 'Grasa corporal',
            '%', _accentBodyFat, 'down', mode);
      case ChartMetric.fastingHours:
        return _genericTrend(fastingHabitSeriesProvider, 'Ayuno', 'h',
            AppColors.metabolicGreen, 'up', mode);
      case ChartMetric.hydrationLiters:
        return _genericTrend(hydrationHabitSeriesProvider, 'Hidratación',
            'L', const Color(0xFF38BDF8), 'up', mode);
      case ChartMetric.exerciseMin:
        return _genericTrend(exerciseHabitSeriesProvider, 'Ejercicio',
            'min', const Color(0xFF14B8A6), 'up', mode);
      case ChartMetric.sleepHours:
        return _genericTrend(sleepHabitSeriesProvider, 'Sueño', 'h',
            const Color(0xFF818CF8), 'up', mode);
    }
  }

  Widget _genericTrend(
    ProviderListenable<AsyncValue<MetricSeries>> provider,
    String label,
    String unit,
    Color accent,
    String betterIf,
    AggregationMode mode,
  ) {
    final s = ref.watch(provider);
    if (s.value == null) return const SizedBox.shrink();
    final trend = TrendComparisonComputer.compute(
      series: s.value!,
      mode: mode,
      betterIf: betterIf,
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
          label: label,
          unit: unit,
          accent: accent,
          trend: trend,
          mode: mode,
        ),
      ],
    );
  }

  Widget _nutritionTrend(AggregationMode mode) {
    final s = ref.watch(nutritionHabitSeriesProvider);
    if (s.value == null || s.value!.points.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Tendencia diaria',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
        ),
        NutritionTrendBarCard(
          series: s.value!,
          aggregationMode: mode,
          headline: _nutritionTrendHeadline(s.value!),
        ),
      ],
    );
  }

  String _nutritionTrendHeadline(MetricSeries s) {
    final points = s.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return 'Sin registros en este rango.';
    final avg =
        points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final pct = avg.round();
    if (pct >= 70) {
      return 'Tu alimentación viene sólida: $pct % A-dominante en promedio.';
    }
    if (pct >= 50) {
      return 'Vas en buen camino: $pct % A-dominante en promedio.';
    }
    return 'Predominaron los platos E: solo $pct % A-dominante en promedio.';
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkResponse(
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _titleFor(widget.metric),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(AggregationMode mode) {
    final periodLabel = _periodLabelFor(mode);
    switch (widget.metric) {
      case ChartMetric.imr:
        return _imrCard(mode, periodLabel);
      case ChartMetric.weight:
        return _weightCard(mode, periodLabel);
      case ChartMetric.bodyFatPct:
        return _bodyFatCard(mode, periodLabel);
      case ChartMetric.fastingHours:
        return _fastingCard(mode, periodLabel);
      case ChartMetric.nutritionAPct:
        return _nutritionCard(mode);
      case ChartMetric.hydrationLiters:
        return _hydrationCard(mode, periodLabel);
      case ChartMetric.exerciseMin:
        return _exerciseCard(mode, periodLabel);
      case ChartMetric.sleepHours:
        return _sleepCard(mode, periodLabel);
    }
  }

  Widget _loadingBox() {
    return Container(
      height: 360,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.metabolicGreen,
        ),
      ),
    );
  }

  // ─── Cards por pilar ────────────────────────────────────────────

  /// Detalle del IMR: barras apiladas semanales con los 5 pilares en sus
  /// colores. Cada barra = una semana; la altura = promedio IMR de esa
  /// semana; los segmentos de color = proporción relativa por pilar.
  Widget _imrCard(AggregationMode mode, String periodLabel) {
    final start = ref.watch(analysisRangeStartProvider);
    final today = DateTime.now();
    final docsAsync = ref.watch(
      historicSummariesProvider(
        HistoricSummariesRange(
          fromIncl: _isoDate(start),
          toIncl: _isoDate(today),
        ),
      ),
    );
    final docs = docsAsync.value;
    if (docs == null) return _loadingBox();
    return ImrPillarBarChart(docs: docs, mode: mode);
  }

  /// Card de feedback de pilares para la sección IMR.
  Widget _imrFeedbackCard() {
    final start = ref.watch(analysisRangeStartProvider);
    final today = DateTime.now();
    final docsAsync = ref.watch(
      historicSummariesProvider(
        HistoricSummariesRange(
          fromIncl: _isoDate(start),
          toIncl: _isoDate(today),
        ),
      ),
    );
    final docs = docsAsync.value;
    if (docs == null || docs.isEmpty) return const SizedBox.shrink();
    return ImrPillarFeedbackCard(docs: docs);
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Días desde el doc más antiguo hasta hoy (inclusive). Fallback para el
  /// rango "Todo" (sin `daysFromToday`). Mínimo 1.
  static int _spanDaysInclusive(List<DailySummaryDoc> docs, DateTime today) {
    if (docs.isEmpty) return 30;
    DateTime? earliest;
    for (final d in docs) {
      final parts = d.date.split('-');
      if (parts.length != 3) continue;
      final dt = DateTime(
        int.tryParse(parts[0]) ?? today.year,
        int.tryParse(parts[1]) ?? 1,
        int.tryParse(parts[2]) ?? 1,
      );
      if (earliest == null || dt.isBefore(earliest)) earliest = dt;
    }
    if (earliest == null) return 30;
    final t = DateTime(today.year, today.month, today.day);
    return (t.difference(earliest).inDays + 1).clamp(1, 100000);
  }

  Widget _bodyFatCard(AggregationMode mode, String periodLabel) {
    // SPEC-168.4.3: reusa el widget completo de SPEC-152/157 que ya
    // tiene 5 tabs (Peso, Cintura, % Grasa, WHTR, Masa magra). WHTR es
    // el proxy clínico de grasa visceral cuando no hay báscula
    // inteligente. Tiene su propio selector de período interno
    // (30/60/90 días) — independiente del SegmentedRangeControl de
    // arriba que aplica al resto del overview.
    return const BodyCompositionTrendChart();
  }

  Widget _weightCard(AggregationMode mode, String periodLabel) {
    final s = ref.watch(weightSeriesProvider);
    if (s.value == null) return _loadingBox();
    final target = ref.watch(goalForChartProvider(ChartMetric.weight));
    final targetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.weight));
    return LineChartCard(
      series: s.value!,
      accent: const Color(0xFF60A5FA),
      periodLabel: periodLabel,
      headline: 'Evolución de tu peso.',
      aggregationMode: mode,
      heroAggregation: HeroAggregation.last,
      targetValue: target,
      targetLabel: targetLabel,
      deltaIsBetterIf: 'down',
    );
  }

  Widget _fastingCard(AggregationMode mode, String periodLabel) {
    final s = ref.watch(fastingHabitSeriesProvider);
    if (s.value == null) return _loadingBox();
    final target =
        ref.watch(goalForChartProvider(ChartMetric.fastingHours));
    final targetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.fastingHours));
    return BarChartCard(
      series: s.value!,
      accent: AppColors.metabolicGreen,
      periodLabel: periodLabel,
      headline: 'Horas de ayuno por día en este período.',
      aggregationMode: mode,
      heroAggregation: HeroAggregation.avg,
      heroUnit: 'h',
      targetValue: target,
      targetLabel: targetLabel,
    );
  }

  Widget _nutritionCard(AggregationMode mode) {
    final pie = ref.watch(nutritionPieDataProvider);
    final s = ref.watch(nutritionHabitSeriesProvider);
    if (pie.value == null || s.value == null) return _loadingBox();
    return NutritionPieCard(
      data: pie.value!,
      dateRange: ChartHeroComputer.formatDateRange(s.value!, mode),
      headline: 'Calidad nutricional del período.',
    );
  }

  Widget _hydrationCard(AggregationMode mode, String periodLabel) {
    final s = ref.watch(hydrationHabitSeriesProvider);
    if (s.value == null) return _loadingBox();
    final target =
        ref.watch(goalForChartProvider(ChartMetric.hydrationLiters));
    final targetLabel = ref
        .watch(goalLabelForChartProvider(ChartMetric.hydrationLiters));
    return BarChartCard(
      series: s.value!,
      accent: const Color(0xFF38BDF8),
      periodLabel: periodLabel,
      headline: 'Litros de agua por día.',
      aggregationMode: mode,
      heroAggregation: HeroAggregation.avg,
      targetValue: target,
      targetLabel: targetLabel,
    );
  }

  Widget _exerciseCard(AggregationMode mode, String periodLabel) {
    final s = ref.watch(exerciseHabitSeriesProvider);
    if (s.value == null) return _loadingBox();
    final target =
        ref.watch(goalForChartProvider(ChartMetric.exerciseMin));
    final targetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.exerciseMin));
    return BarChartCard(
      series: s.value!,
      accent: const Color(0xFF14B8A6),
      periodLabel: periodLabel,
      headline: 'Minutos de ejercicio por día.',
      aggregationMode: mode,
      heroAggregation: HeroAggregation.avg,
      targetValue: target,
      targetLabel: targetLabel,
    );
  }

  Widget _sleepCard(AggregationMode mode, String periodLabel) {
    final s = ref.watch(sleepHabitSeriesProvider);
    if (s.value == null) return _loadingBox();
    final target = ref.watch(goalForChartProvider(ChartMetric.sleepHours));
    final targetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.sleepHours));
    return BarChartCard(
      series: s.value!,
      accent: const Color(0xFF818CF8),
      periodLabel: periodLabel,
      headline: 'Horas de sueño por noche.',
      aggregationMode: mode,
      heroAggregation: HeroAggregation.avg,
      targetValue: target,
      targetLabel: targetLabel,
    );
  }

  // ─── Helpers de copy ─────────────────────────────────────────────

  String _titleFor(ChartMetric m) {
    switch (m) {
      case ChartMetric.imr:
        return 'IMR';
      case ChartMetric.weight:
        return 'Peso';
      case ChartMetric.bodyFatPct:
        return 'Composición corporal';
      case ChartMetric.fastingHours:
        return 'Ayuno';
      case ChartMetric.nutritionAPct:
        return 'Nutrición';
      case ChartMetric.hydrationLiters:
        return 'Hidratación';
      case ChartMetric.exerciseMin:
        return 'Ejercicio';
      case ChartMetric.sleepHours:
        return 'Sueño';
    }
  }

  String _periodLabelFor(AggregationMode mode) {
    switch (mode) {
      case AggregationMode.daily:
        return 'Últimos 30 días';
      case AggregationMode.weekly:
        return 'Últimos meses';
      case AggregationMode.monthly:
        return 'Último año';
    }
  }
}
