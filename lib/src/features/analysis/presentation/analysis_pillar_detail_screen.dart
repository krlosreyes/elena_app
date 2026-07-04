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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_launcher.dart';
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
import 'package:elena_app/src/features/analysis/presentation/widgets/ayuno_feedback_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/pillar_feedback_card.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
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
    final isPremium = ref.watch(featureGateProvider).hasFullAccess;

    return Scaffold(
      // SPEC-168.4.6: mismo fondo que Hoy/Perfil/Analisis (cards
      // mantienen su #0C0C0E).
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: isPremium ? null : const NeverScrollableScrollPhysics(),
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
                  // Ayuno: card de análisis de hábito debajo de la tendencia.
                  if (widget.metric == ChartMetric.fastingHours) ...[
                    const SizedBox(height: 24),
                    _ayunoFeedbackCard(),
                  ],
                  // Hidratación: card de análisis de hábito debajo de la tendencia.
                  if (widget.metric == ChartMetric.hydrationLiters) ...[
                    const SizedBox(height: 24),
                    _hidratacionFeedbackCard(),
                  ],
                  // Ejercicio: card de análisis de hábito debajo de la tendencia.
                  if (widget.metric == ChartMetric.exerciseMin) ...[
                    const SizedBox(height: 24),
                    _ejercicioFeedbackCard(),
                  ],
                  // Sueño: card de análisis de hábito debajo de la tendencia.
                  if (widget.metric == ChartMetric.sleepHours) ...[
                    const SizedBox(height: 24),
                    _suenoFeedbackCard(),
                  ],
                  // Nutrición: card de análisis de hábito debajo de la tendencia.
                  if (widget.metric == ChartMetric.nutritionAPct) ...[
                    const SizedBox(height: 24),
                    _nutricionFeedbackCard(),
                  ],
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

  /// Overlay de blur + CTA premium. Incluye su propio botón ← para que el
  /// usuario pueda volver al overview sin quedar atrapado.
  Widget _buildPremiumGateOverlay(BuildContext context) {
    final label = _metricLabel(widget.metric);
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
                    // Back button propio del overlay (el original queda detrás del blur).
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
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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

  static String _metricLabel(ChartMetric metric) {
    switch (metric) {
      case ChartMetric.imr:
        return 'Detalle IMR';
      case ChartMetric.bodyFatPct:
        return 'Detalle Composición Corporal';
      case ChartMetric.fastingHours:
        return 'Detalle Ayuno';
      case ChartMetric.nutritionAPct:
        return 'Detalle Nutrición';
      case ChartMetric.hydrationLiters:
        return 'Detalle Hidratación';
      case ChartMetric.exerciseMin:
        return 'Detalle Ejercicio';
      case ChartMetric.sleepHours:
        return 'Detalle Sueño';
      case ChartMetric.weight:
        return 'Detalle Peso';
    }
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

  /// Card de feedback de hábito de ayuno.
  Widget _ayunoFeedbackCard() {
    final s = ref.watch(fastingHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();
    // fastingProtocol es String: '16:8' | '18:6' | '20:4' | 'Ninguno'
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final targetHours = _protocolHours(user?.fastingProtocol ?? '16:8');
    return AyunoFeedbackCard(series: series, targetHours: targetHours);
  }

  // ─── Feedback cards por pilar ──────────────────────────────────────

  /// Hidratación: PROMEDIO litros | EN OBJETIVO días | CUMPLIMIENTO %.
  /// Target = goal del usuario o 2.5 L por defecto.
  Widget _hidratacionFeedbackCard() {
    final s = ref.watch(hydrationHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();

    final goalRaw =
        ref.watch(goalForChartProvider(ChartMetric.hydrationLiters));
    final target = (goalRaw != null && goalRaw > 0) ? goalRaw : 2.5;

    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= target).length;
    final total = points.length;
    final pct = total > 0 ? (daysOnTarget / total * 100).round() : 0;

    final Color color;
    final String emoji, title, body;
    if (avg >= target && pct >= 70) {
      color = const Color(0xFF10B981);
      emoji = '🏆';
      title = 'Excelente hidratación';
      body = 'Estás cumpliendo tu objetivo de ${target.toStringAsFixed(1)} L '
          'la mayoría de los días. El agua potencia la termogénesis celular '
          'y mejora el transporte de nutrientes.';
    } else if (avg >= target * 0.75) {
      color = const Color(0xFF38BDF8);
      emoji = '📈';
      title = 'En progreso';
      body = 'Tu promedio de ${avg.toStringAsFixed(1)} L está cerca del '
          'objetivo. Añadir un vaso de agua al despertar y antes de cada '
          'comida puede sumar hasta 0.6 L sin esfuerzo.';
    } else {
      color = const Color(0xFFF59E0B);
      emoji = '🎯';
      title = 'Oportunidad de mejora';
      body = 'Tu promedio de ${avg.toStringAsFixed(1)} L está por debajo de '
          '${target.toStringAsFixed(1)} L. La deshidratación leve reduce el '
          'metabolismo y puede confundirse con hambre. Apunta a ${target.toStringAsFixed(1)} L diarios.';
    }

    return PillarFeedbackCard(
      headerLabel: 'ANÁLISIS DE HIDRATACIÓN',
      chips: [
        (
          label: 'PROMEDIO',
          value: '${avg.toStringAsFixed(1)} L',
          color: avg >= target
              ? const Color(0xFF10B981)
              : avg >= target * 0.75
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'EN OBJETIVO',
          value: '$daysOnTarget/$total días',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'CUMPLIMIENTO',
          value: '$pct%',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
      ],
      progressFill: (avg / (target * 1.5)).clamp(0.0, 1.0),
      progressColor: const Color(0xFF38BDF8),
      progressLeft: '0 L',
      progressRight: '${(target * 1.5).toStringAsFixed(1)} L',
      markerFraction: (target / (target * 1.5)).clamp(0.0, 1.0),
      markerLabel: 'Objetivo: ${target.toStringAsFixed(1)} L',
      statusEmoji: emoji,
      statusTitle: title,
      statusColor: color,
      statusBody: body,
    );
  }

  /// Ejercicio: PROMEDIO minutos | EN OBJETIVO días | CUMPLIMIENTO %.
  /// Target = goal del usuario o 30 min por defecto.
  Widget _ejercicioFeedbackCard() {
    final s = ref.watch(exerciseHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();

    final goalRaw =
        ref.watch(goalForChartProvider(ChartMetric.exerciseMin));
    final target = (goalRaw != null && goalRaw > 0) ? goalRaw : 30.0;

    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= target).length;
    final total = points.length;
    final pct = total > 0 ? (daysOnTarget / total * 100).round() : 0;

    final Color color;
    final String emoji, title, body;
    if (avg >= target && pct >= 70) {
      color = const Color(0xFF10B981);
      emoji = '🏆';
      title = 'Excelente actividad física';
      body = 'Estás cumpliendo tus ${target.round()} min de ejercicio '
          'la mayoría de los días. La actividad física regular optimiza la '
          'sensibilidad a la insulina y acelera el metabolismo en reposo.';
    } else if (avg >= target * 0.75) {
      color = const Color(0xFF38BDF8);
      emoji = '📈';
      title = 'En progreso';
      body = 'Tu promedio de ${avg.round()} min está cerca del objetivo. '
          'Agregar 5–10 min a tus sesiones actuales es suficiente para '
          'cruzar al rango de beneficio metabólico comprobado.';
    } else {
      color = const Color(0xFFF59E0B);
      emoji = '🎯';
      title = 'Oportunidad de mejora';
      body = 'Tu promedio de ${avg.round()} min está por debajo de '
          '${target.round()} min. Incluso 15–20 min de caminata intensa '
          'activan la quema de grasa y mejoran los marcadores hormonales.';
    }

    return PillarFeedbackCard(
      headerLabel: 'ANÁLISIS DE EJERCICIO',
      chips: [
        (
          label: 'PROMEDIO',
          value: '${avg.round()} min',
          color: avg >= target
              ? const Color(0xFF10B981)
              : avg >= target * 0.75
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'EN OBJETIVO',
          value: '$daysOnTarget/$total días',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'CUMPLIMIENTO',
          value: '$pct%',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
      ],
      progressFill: (avg / (target * 1.5)).clamp(0.0, 1.0),
      progressColor: const Color(0xFFEF4444),
      progressLeft: '0 min',
      progressRight: '${(target * 1.5).round()} min',
      markerFraction: (target / (target * 1.5)).clamp(0.0, 1.0),
      markerLabel: 'Objetivo: ${target.round()} min',
      statusEmoji: emoji,
      statusTitle: title,
      statusColor: color,
      statusBody: body,
    );
  }

  /// Sueño: PROMEDIO horas | EN OBJETIVO días | CUMPLIMIENTO %.
  /// Target = goal del usuario o 8 h por defecto.
  Widget _suenoFeedbackCard() {
    final s = ref.watch(sleepHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();

    final goalRaw =
        ref.watch(goalForChartProvider(ChartMetric.sleepHours));
    final target = (goalRaw != null && goalRaw > 0) ? goalRaw : 8.0;

    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= target).length;
    final total = points.length;
    final pct = total > 0 ? (daysOnTarget / total * 100).round() : 0;
    // Barra: 0h → 10h (máx razonable)
    const barMax = 10.0;

    final Color color;
    final String emoji, title, body;
    if (avg >= target && pct >= 70) {
      color = const Color(0xFF10B981);
      emoji = '🏆';
      title = 'Sueño reparador consistente';
      body = 'Estás logrando ${target.toStringAsFixed(1)} h de sueño '
          'la mayoría de los días. Un sueño adecuado regula la grelina y '
          'la leptina — las hormonas del hambre — y optimiza la recuperación '
          'muscular.';
    } else if (avg >= target * 0.75) {
      color = const Color(0xFF38BDF8);
      emoji = '📈';
      title = 'En progreso';
      body = 'Tu promedio de ${avg.toStringAsFixed(1)} h está cerca del '
          'objetivo. Establecer un horario de sueño fijo y evitar pantallas '
          '1 h antes de dormir puede sumar 30–60 min de calidad.';
    } else {
      color = const Color(0xFFF59E0B);
      emoji = '🎯';
      title = 'Oportunidad de mejora';
      body = 'Tu promedio de ${avg.toStringAsFixed(1)} h está por debajo de '
          '${target.toStringAsFixed(1)} h. El déficit crónico de sueño '
          'eleva el cortisol y puede ralentizar la pérdida de grasa, '
          'incluso con dieta y ejercicio correctos.';
    }

    return PillarFeedbackCard(
      headerLabel: 'ANÁLISIS DE SUEÑO',
      chips: [
        (
          label: 'PROMEDIO',
          value: '${avg.toStringAsFixed(1)} h',
          color: avg >= target
              ? const Color(0xFF10B981)
              : avg >= target * 0.75
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'EN OBJETIVO',
          value: '$daysOnTarget/$total días',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'CUMPLIMIENTO',
          value: '$pct%',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
      ],
      progressFill: (avg / barMax).clamp(0.0, 1.0),
      progressColor: const Color(0xFF818CF8),
      progressLeft: '0 h',
      progressRight: '${barMax.round()} h',
      markerFraction: (target / barMax).clamp(0.0, 1.0),
      markerLabel: 'Objetivo: ${target.toStringAsFixed(1)} h',
      statusEmoji: emoji,
      statusTitle: title,
      statusColor: color,
      statusBody: body,
    );
  }

  /// Nutrición: PROMEDIO % A-dominante | DÍAS OBJETIVO | CUMPLIMIENTO %.
  /// Target científico: ≥70 % A-dominante por período.
  Widget _nutricionFeedbackCard() {
    final s = ref.watch(nutritionHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();

    const target = 70.0; // % A-dominante objetivo (fundamento hormonal)

    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= target).length;
    final total = points.length;
    final pct = total > 0 ? (daysOnTarget / total * 100).round() : 0;

    final Color color;
    final String emoji, title, body;
    if (avg >= target && pct >= 70) {
      color = const Color(0xFF10B981);
      emoji = '🏆';
      title = 'Nutrición A-dominante';
      body = 'Tu alimentación es mayoritariamente de Tipo A: alimentos que '
          'bajan la glucosa y favorecen la quema de grasa. Esto reduce la '
          'inflamación sistémica y optimiza el perfil hormonal metabólico.';
    } else if (avg >= target * 0.75) {
      color = const Color(0xFF38BDF8);
      emoji = '📈';
      title = 'En progreso';
      body = 'Tu promedio de ${avg.round()} % A-dominante está cerca del '
          'objetivo de 70 %. Reemplazar una comida E por una opción A cada '
          'día puede marcar una diferencia visible en 2–3 semanas.';
    } else {
      color = const Color(0xFFF59E0B);
      emoji = '🎯';
      title = 'Oportunidad de mejora';
      body = 'Tu promedio de ${avg.round()} % A-dominante indica que los '
          'alimentos tipo E están predominando. Prioriza proteínas magras, '
          'vegetales y grasas saludables para activar la termogénesis y '
          'estabilizar la insulina.';
    }

    return PillarFeedbackCard(
      headerLabel: 'ANÁLISIS DE NUTRICIÓN',
      chips: [
        (
          label: 'PROMEDIO',
          value: '${avg.round()} % A',
          color: avg >= target
              ? const Color(0xFF10B981)
              : avg >= target * 0.75
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'DÍAS OBJETIVO',
          value: '$daysOnTarget/$total días',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'CUMPLIMIENTO',
          value: '$pct%',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
      ],
      progressFill: (avg / 100.0).clamp(0.0, 1.0),
      progressColor: const Color(0xFFF59E0B),
      progressLeft: '0 %',
      progressRight: '100 %',
      markerFraction: target / 100.0,
      markerLabel: 'Objetivo: ≥${target.round()} % A-dominante',
      statusEmoji: emoji,
      statusTitle: title,
      statusColor: color,
      statusBody: body,
    );
  }

  static double _protocolHours(String protocol) {
    switch (protocol) {
      case '18:6':
        return 18.0;
      case '20:4':
        return 20.0;
      case 'Ninguno':
        return 12.0;
      default:
        return 16.0; // 16:8 default
    }
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

  // SPEC-221: el label debe derivarse del AnalysisRange seleccionado,
  // NO del AggregationMode, porque daily cubre tanto w1 ("Última semana")
  // como m1 ("Último mes"). AnalysisRange.periodLabel es la fuente de verdad.
  String _periodLabelFor(AggregationMode mode) {
    return ref.read(analysisRangeProvider).periodLabel;
  }
}
