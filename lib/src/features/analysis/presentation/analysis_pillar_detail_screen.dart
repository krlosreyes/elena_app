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
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_launcher.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/historic_summaries_provider.dart';
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
import 'package:elena_app/src/features/analysis/presentation/widgets/pillar_analysis_feedback_sections.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/bar_chart_card.dart';
// SPEC-168.4.3: widget completo de composición corporal con tabs.
import 'package:elena_app/src/features/analysis/presentation/widgets/body_composition_trend_chart.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/line_chart_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_pillar_bar_chart.dart';
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
    // try-catch defensivo: la mutación propaga invalidaciones síncronas que
    // pueden chocar con el teardown del widget → "Cannot use ref after disposed".
    try {
      ref.read(analysisRangeProvider.notifier).state = AnalysisRange.m1;
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    final aggregationMode = AggregationMode.forRange(range);
    // SPEC-197 + SPEC-240: detalle de pilar — Premium o en Trial.
    //
    // UX-PROGRESO (auditoría técnica 21-jul, P1): antes esto bloqueaba
    // el detalle COMPLETO con un blur — Free no veía ni el gráfico de
    // 7 días. Ahora Free siempre ve el chart de la semana (rango w1,
    // ya es el default al abrir esta pantalla); lo que sigue detrás
    // del gate es el histórico más largo (mes/3M/6M/1A, ver
    // `SegmentedRangeControl.locked`) y la sección de Tendencia +
    // feedback por pilar, que necesitan ese histórico para decir algo
    // real.
    final isPremium = ref.watch(featureGateProvider).hasFullAccess;

    // UX-PROGRESO (hallazgo de auditoría propia, 22-jul): el reset a w1
    // en initState corre en addPostFrameCallback (a propósito — mutar
    // el provider de forma síncrona en initState puede disparar
    // "modify provider while widget tree is building"). Eso deja UN
    // frame donde `range` todavía puede ser el rango largo que el
    // usuario tenía seleccionado en la lista de Progreso, ANTES del
    // callback. Si eso pasa para Free, no construimos el chart con ese
    // rango (evitamos la query real a Firestore con datos que deberían
    // estar bloqueados) — mostramos un loader hasta el frame siguiente,
    // cuando el callback ya corrigió el rango a w1.
    if (!isPremium && range != AnalysisRange.w1) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.metabolicGreen,
          ),
        ),
      );
    }

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
              SegmentedRangeControl(
                locked: !isPremium,
                onLockedTap: () => openPaywall(
                  context, ref,
                  feature: GatedFeature.analyticsHistory,
                ),
              ),
              const SizedBox(height: 24),
              // UX-PROGRESO: el chart de la semana (w1) es siempre
              // visible, Free incluido — es la "vista simple de 7
              // días" que pidió la auditoría.
              _buildChart(aggregationMode),
              const SizedBox(height: 24),
              if (isPremium) ...[
                // SPEC-168.4.1: tendencia corta vs larga del mismo
                // pilar. Si no hay data suficiente, devuelve
                // SizedBox.shrink.
                _buildTrendSection(aggregationMode),
                // IMR: card de feedback por pilar debajo de la tendencia.
                if (widget.metric == ChartMetric.imr) ...[
                  const SizedBox(height: 24),
                  const ImrPillarFeedbackSection(),
                ],
                // Ayuno: card de análisis de hábito debajo de la tendencia.
                if (widget.metric == ChartMetric.fastingHours) ...[
                  const SizedBox(height: 24),
                  const AyunoPillarFeedbackSection(),
                ],
                // Hidratación: card de análisis de hábito debajo de la tendencia.
                if (widget.metric == ChartMetric.hydrationLiters) ...[
                  const SizedBox(height: 24),
                  const HidratacionFeedbackSection(),
                ],
                // Ejercicio: card de análisis de hábito debajo de la tendencia.
                if (widget.metric == ChartMetric.exerciseMin) ...[
                  const SizedBox(height: 24),
                  const EjercicioFeedbackSection(),
                ],
                // Sueño: card de análisis de hábito debajo de la tendencia.
                if (widget.metric == ChartMetric.sleepHours) ...[
                  const SizedBox(height: 24),
                  const SuenoFeedbackSection(),
                ],
                // Nutrición: card de análisis de hábito debajo de la tendencia.
                if (widget.metric == ChartMetric.nutritionAPct) ...[
                  const SizedBox(height: 24),
                  const NutricionFeedbackSection(),
                ],
              ] else
                _buildHistoryUpsellCard(context),
            ],
          ),
        ),
      ),
    );
  }

  /// UX-PROGRESO (21-jul, P1): reemplaza al antiguo blur de página
  /// completa (`AnalysisPremiumGateOverlay`). Se muestra una sola vez,
  /// debajo del chart de 7 días, en vez de tapar tendencia + las 6
  /// variantes de feedback por pilar con candados repetidos.
  Widget _buildHistoryUpsellCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.metabolicGreen.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tendencia y análisis de evolución',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ya ves tu semana. Con Premium desbloqueas meses de histórico, '
            'comparativas de corto vs. largo plazo y el análisis de hábito '
            'de este pilar.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.metabolicGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => openPaywall(
                context, ref,
                feature: GatedFeature.analyticsHistory,
              ),
              child: const Text(
                'Desbloquear Premium',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
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

  // SPEC-119: feedback cards por pilar (_imrFeedbackCard,
  // _ayunoFeedbackCard, _hidratacionFeedbackCard, _ejercicioFeedbackCard,
  // _suenoFeedbackCard, _nutricionFeedbackCard) + `_protocolHours` →
  // ImrPillarFeedbackSection / AyunoPillarFeedbackSection /
  // HidratacionFeedbackSection / EjercicioFeedbackSection /
  // SuenoFeedbackSection / NutricionFeedbackSection
  // (widgets/pillar_analysis_feedback_sections.dart). Extraído en
  // ARCH-03. PERF-01: `AyunoPillarFeedbackSection` cambió
  // `ref.watch(currentUserStreamProvider).valueOrNull` (objeto
  // completo) por `.select((a) => a.valueOrNull?.fastingProtocol)`
  // porque solo usa ese campo.

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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

  // SPEC-221: el label debe derivarse del AnalysisRange seleccionado,
  // NO del AggregationMode, porque daily cubre tanto w1 ("Última semana")
  // como m1 ("Último mes"). AnalysisRange.periodLabel es la fuente de verdad.
  String _periodLabelFor(AggregationMode mode) {
    return ref.read(analysisRangeProvider).periodLabel;
  }
}
