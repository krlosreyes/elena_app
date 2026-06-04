// SPEC-162 + SPEC-163 + SPEC-164 + SPEC-165: Análisis estilo Apple
// Fitness, función de revisión histórica (NO motivacional — eso vive
// en Hoy).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/causal_insights_provider.dart';
// SPEC-168.0.D: helper que devuelve el target del usuario por chart.
import 'package:elena_app/src/features/analysis/application/goal_for_chart_provider.dart';
// SPEC-168.5: computa la comparación corto-vs-largo.
import 'package:elena_app/src/features/analysis/application/trend_comparison_computer.dart';
// SPEC-168.1: aggregation mode + hero aggregation enums.
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:elena_app/src/features/analysis/domain/causal_insight.dart';
import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/monthly_calendar_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/bar_chart_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/insight_tile.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/line_chart_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/segmented_range_control.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/trend_comparison_card.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  // Acentos por métrica (coherentes con SPEC-161).
  static const _accentImr = AppColors.metabolicGreen;
  static const _accentWeight = Color(0xFF60A5FA);
  static const _accentFasting = AppColors.metabolicGreen;
  static const _accentNutrition = Color(0xFFFB923C);
  static const _accentHydration = Color(0xFF38BDF8);
  static const _accentExercise = Color(0xFF14B8A6);
  static const _accentSleep = Color(0xFF818CF8);

  // SPEC-168.2-fix (2026-06-03): ScrollController persistente entre
  // rebuilds. Antes, cuando un stream provider emitía (Firestore
  // refresca constantemente), el árbol se reconstruía sin controller
  // explícito y el SingleChildScrollView reseteaba al top. Ahora la
  // posición se preserva porque el controller vive en el State.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    final periodLabel = _periodLabelFor(range);
    // SPEC-168.1: mode temporal para que cada chart formatee la
    // fecha-range del hero block correctamente.
    final aggregationMode = AggregationMode.forRange(range);

    // SPEC-168.2: targets del usuario por chart. Cada uno es null si el
    // goal correspondiente no está activo en `userGoals`. La línea
    // dashed solo se pinta cuando hay valor.
    final imrTarget = ref.watch(goalForChartProvider(ChartMetric.imr));
    final imrTargetLabel = ref.watch(goalLabelForChartProvider(ChartMetric.imr));
    final weightTarget =
        ref.watch(goalForChartProvider(ChartMetric.weight));
    final weightTargetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.weight));
    final fastingTarget =
        ref.watch(goalForChartProvider(ChartMetric.fastingDays));
    final fastingTargetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.fastingDays));
    final nutritionTarget =
        ref.watch(goalForChartProvider(ChartMetric.nutritionAPct));
    final nutritionTargetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.nutritionAPct));
    final hydrationTarget =
        ref.watch(goalForChartProvider(ChartMetric.hydrationPct));
    final hydrationTargetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.hydrationPct));
    final exerciseTarget =
        ref.watch(goalForChartProvider(ChartMetric.exerciseMin));
    final exerciseTargetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.exerciseMin));
    final sleepTarget =
        ref.watch(goalForChartProvider(ChartMetric.sleepHours));
    final sleepTargetLabel =
        ref.watch(goalLabelForChartProvider(ChartMetric.sleepHours));
    final imr = ref.watch(imrSeriesProvider);
    final weight = ref.watch(weightSeriesProvider);
    final fasting = ref.watch(fastingHabitSeriesProvider);
    final nutrition = ref.watch(nutritionHabitSeriesProvider);
    final hydration = ref.watch(hydrationHabitSeriesProvider);
    final exercise = ref.watch(exerciseHabitSeriesProvider);
    final sleep = ref.watch(sleepHabitSeriesProvider);
    final insights = ref.watch(causalInsightsProvider);

    // SPEC-168.2-fix: solo consideramos "first load" cuando NINGÚN
    // provider tiene .value aún (transición inicial AsyncLoading →
    // AsyncData). Re-emisiones del stream (Firestore refresh) NO
    // disparan loading state — el árbol queda estable y el scroll
    // se mantiene en su posición.
    final firstLoad = imr.value == null ||
        weight.value == null ||
        fasting.value == null ||
        nutrition.value == null ||
        hydration.value == null ||
        exercise.value == null ||
        sleep.value == null;

    return Scaffold(
      // SPEC-165: fondo negro puro.
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header in-page estilo Apple.
              _buildPageHeader(context),
              const SizedBox(height: 24),
              const SegmentedRangeControl(),
              const SizedBox(height: 28),
              if (firstLoad)
                _buildLoading()
              else
                ..._buildContent(
                  imrSeries: imr.value!,
                  weightSeries: weight.value!,
                  fastingSeries: fasting.value!,
                  nutritionSeries: nutrition.value!,
                  hydrationSeries: hydration.value!,
                  exerciseSeries: exercise.value!,
                  sleepSeries: sleep.value!,
                  insights: insights,
                  periodLabel: periodLabel,
                  aggregationMode: aggregationMode,
                  imrTarget: imrTarget,
                  imrTargetLabel: imrTargetLabel,
                  weightTarget: weightTarget,
                  weightTargetLabel: weightTargetLabel,
                  fastingTarget: fastingTarget,
                  fastingTargetLabel: fastingTargetLabel,
                  nutritionTarget: nutritionTarget,
                  nutritionTargetLabel: nutritionTargetLabel,
                  hydrationTarget: hydrationTarget,
                  hydrationTargetLabel: hydrationTargetLabel,
                  exerciseTarget: exerciseTarget,
                  exerciseTargetLabel: exerciseTargetLabel,
                  sleepTarget: sleepTarget,
                  sleepTargetLabel: sleepTargetLabel,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: AppColors.metabolicGreen,
        unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/analysis');
          if (index == 2) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Análisis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _todayLabel(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MonthlyCalendarScreen(),
              fullscreenDialog: true,
            ),
          ),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1C),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
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

  List<Widget> _buildContent({
    required MetricSeries imrSeries,
    required MetricSeries weightSeries,
    required MetricSeries fastingSeries,
    required MetricSeries nutritionSeries,
    required MetricSeries hydrationSeries,
    required MetricSeries exerciseSeries,
    required MetricSeries sleepSeries,
    required AsyncValue<List<CausalInsight>> insights,
    required String periodLabel,
    required AggregationMode aggregationMode,
    // SPEC-168.2: targets por chart, opcional (null = sin línea).
    required double? imrTarget,
    required String? imrTargetLabel,
    required double? weightTarget,
    required String? weightTargetLabel,
    required double? fastingTarget,
    required String? fastingTargetLabel,
    required double? nutritionTarget,
    required String? nutritionTargetLabel,
    required double? hydrationTarget,
    required String? hydrationTargetLabel,
    required double? exerciseTarget,
    required String? exerciseTargetLabel,
    required double? sleepTarget,
    required String? sleepTargetLabel,
  }) {
    final allEmpty = imrSeries.isEmpty &&
        weightSeries.isEmpty &&
        fastingSeries.isEmpty &&
        nutritionSeries.isEmpty &&
        hydrationSeries.isEmpty &&
        exerciseSeries.isEmpty &&
        sleepSeries.isEmpty;
    if (allEmpty) {
      return [_buildStartingState()];
    }

    return [
      _sectionTitle('Resultados'),
      const SizedBox(height: 14),
      // SPEC-168.1: cada chart card recibe heroAggregation explícito
      // para que el bloque hero diga "PROMEDIO" / "TOTAL" / "ÚLTIMO"
      // según corresponda a la métrica.
      // SPEC-168.2: cada chart recibe targetValue/targetLabel del goal
      // activo del usuario (null si el goal está inactivo).
      LineChartCard(
        series: imrSeries,
        accent: _accentImr,
        periodLabel: periodLabel,
        headline: _imrHeadline(imrSeries, periodLabel),
        aggregationMode: aggregationMode,
        heroAggregation: HeroAggregation.avg,
        targetValue: imrTarget,
        targetLabel: imrTargetLabel,
        deltaIsBetterIf: 'up',
      ),
      const SizedBox(height: 14),
      LineChartCard(
        series: weightSeries,
        accent: _accentWeight,
        periodLabel: periodLabel,
        headline: _weightHeadline(weightSeries),
        aggregationMode: aggregationMode,
        // El peso "actual" del rango es el último registro, no el
        // promedio (Apple Health también muestra ÚLTIMO en Peso).
        heroAggregation: HeroAggregation.last,
        targetValue: weightTarget,
        targetLabel: weightTargetLabel,
        deltaIsBetterIf: 'down',
      ),
      // SPEC-168.5: sección "Tendencias" — comparación de promedios
      // recientes vs históricos para Peso e IMR (las dos métricas de
      // resultado más relevantes para el usuario MR). Los cards solo
      // se renderizan si hay suficiente data (>= 4 buckets).
      ..._buildTrendsSection(
        weightSeries: weightSeries,
        imrSeries: imrSeries,
        aggregationMode: aggregationMode,
      ),
      const SizedBox(height: 36),
      _sectionTitle('Hábitos'),
      const SizedBox(height: 14),
      BarChartCard(
        series: fastingSeries,
        accent: _accentFasting,
        periodLabel: periodLabel,
        headline: _fastingHeadline(fastingSeries),
        aggregationMode: aggregationMode,
        // Ayuno se suma: total de días cumplidos en el rango.
        heroAggregation: HeroAggregation.sum,
        heroUnit: 'd',
        targetValue: fastingTarget,
        targetLabel: fastingTargetLabel,
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: nutritionSeries,
        accent: _accentNutrition,
        periodLabel: periodLabel,
        headline: _nutritionHeadline(nutritionSeries),
        aggregationMode: aggregationMode,
        heroAggregation: HeroAggregation.avg,
        targetValue: nutritionTarget,
        targetLabel: nutritionTargetLabel,
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: hydrationSeries,
        accent: _accentHydration,
        periodLabel: periodLabel,
        headline: _hydrationHeadline(hydrationSeries),
        aggregationMode: aggregationMode,
        heroAggregation: HeroAggregation.avg,
        targetValue: hydrationTarget,
        targetLabel: hydrationTargetLabel,
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: exerciseSeries,
        accent: _accentExercise,
        periodLabel: periodLabel,
        headline: _exerciseHeadline(exerciseSeries),
        aggregationMode: aggregationMode,
        heroAggregation: HeroAggregation.avg,
        targetValue: exerciseTarget,
        targetLabel: exerciseTargetLabel,
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: sleepSeries,
        accent: _accentSleep,
        periodLabel: periodLabel,
        headline: _sleepHeadline(sleepSeries),
        aggregationMode: aggregationMode,
        heroAggregation: HeroAggregation.avg,
        targetValue: sleepTarget,
        targetLabel: sleepTargetLabel,
      ),
      const SizedBox(height: 36),
      _sectionTitle('Observaciones'),
      const SizedBox(height: 4),
      insights.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.metabolicGreen,
            ),
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No pudimos cargar las observaciones.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Seguí registrando — Elena necesita más patrones '
                'para devolverte conclusiones causa-efecto.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: list.map((i) => InsightTile(insight: i)).toList(),
          );
        },
      ),
    ];
  }

  String _periodLabelFor(AnalysisRange r) {
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
        return 'Desde el inicio';
    }
  }

  /// SPEC-168.5: arma la sección "Tendencias" con cards de Peso e IMR.
  /// Retorna [] si ninguno tiene suficiente data (TrendComparisonComputer
  /// devolvió null). Si solo uno tiene data, renderiza solo ese.
  List<Widget> _buildTrendsSection({
    required MetricSeries weightSeries,
    required MetricSeries imrSeries,
    required AggregationMode aggregationMode,
  }) {
    final weightTrend = TrendComparisonComputer.compute(
      series: weightSeries,
      mode: aggregationMode,
      betterIf: 'down',
    );
    final imrTrend = TrendComparisonComputer.compute(
      series: imrSeries,
      mode: aggregationMode,
      betterIf: 'up',
    );
    if (weightTrend == null && imrTrend == null) return const [];

    return [
      const SizedBox(height: 36),
      _sectionTitle('Tendencias'),
      const SizedBox(height: 14),
      if (weightTrend != null) ...[
        TrendComparisonCard(
          label: 'Peso',
          unit: 'kg',
          accent: _accentWeight,
          trend: weightTrend,
          mode: aggregationMode,
        ),
        if (imrTrend != null) const SizedBox(height: 14),
      ],
      if (imrTrend != null)
        TrendComparisonCard(
          label: 'IMR',
          unit: '',
          accent: _accentImr,
          trend: imrTrend,
          mode: aggregationMode,
        ),
    ];
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildStartingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 14),
          const Text(
            'Tu trazabilidad arranca acá.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Necesitás al menos 30 días de registro para que Elena '
            'detecte causa-efecto confiable entre tus hábitos y tus '
            'resultados.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Headlines conversacionales (SPEC-165 §2.6) ────────────────────

  String _imrHeadline(MetricSeries s, String periodLabel) {
    final avg = _avg(s);
    if (avg == null) return 'Sin datos de IMR todavía.';
    final value = avg.round();
    return 'Tu IMR promedio fue $value en ${_periodIntoPhrase(periodLabel)}.';
  }

  String _weightHeadline(MetricSeries s) {
    final current = s.currentValue;
    if (current == null) return 'Sin datos de peso todavía.';
    final delta = s.delta;
    if (delta == null || delta.abs() < 0.05) {
      return 'Pesás ${current.toStringAsFixed(1)} kg. '
          'Sostuviste tu peso en este período.';
    }
    final verb = delta < 0 ? 'Bajaste' : 'Subiste';
    return 'Pesás ${current.toStringAsFixed(1)} kg. '
        '$verb ${delta.abs().toStringAsFixed(1)} kg en este período.';
  }

  String _fastingHeadline(MetricSeries s) {
    final avg = _avg(s);
    if (avg == null) return 'Sin registros de ayuno todavía.';
    final unit = s.unit; // '', 'd/sem', 'd/mes'
    if (unit == 'd/sem') {
      return 'Cumpliste ${avg.toStringAsFixed(1)} días de ayuno por '
          'semana en promedio.';
    }
    if (unit == 'd/mes') {
      return 'Cumpliste ${avg.round()} días de ayuno por mes en '
          'promedio.';
    }
    // daily: 0 o 1 — promedio = % de días cumplidos.
    final pct = (avg * 100).round();
    return 'Cumpliste tu ayuno en $pct% de los días registrados.';
  }

  String _nutritionHeadline(MetricSeries s) {
    final avg = _avg(s);
    if (avg == null) return 'Sin registros de comidas todavía.';
    return 'El ${avg.round()}% de tus comidas fueron A-dominantes.';
  }

  String _hydrationHeadline(MetricSeries s) {
    final avg = _avg(s);
    if (avg == null) return 'Sin registros de hidratación todavía.';
    return 'Tomaste ${avg.round()}% de tu meta hídrica en promedio.';
  }

  String _exerciseHeadline(MetricSeries s) {
    final avg = _avg(s);
    if (avg == null) return 'Sin registros de ejercicio todavía.';
    return 'Hiciste ${avg.round()} min de ejercicio por día en '
        'promedio.';
  }

  String _sleepHeadline(MetricSeries s) {
    final avg = _avg(s);
    if (avg == null) return 'Sin registros de sueño todavía.';
    return 'Dormiste un promedio de ${avg.toStringAsFixed(1)} h '
        'por noche.';
  }

  double? _avg(MetricSeries s) {
    if (s.points.isEmpty) return null;
    final sum = s.points.fold<double>(0, (acc, p) => acc + p.value);
    return sum / s.points.length;
  }

  String _periodIntoPhrase(String periodLabel) {
    // "Últimos 3 meses" → "los últimos 3 meses"
    if (periodLabel.startsWith('Últim')) {
      return 'los ${periodLabel.toLowerCase()}';
    }
    return 'todo el período';
  }

  static const _daysLong = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  static const _monthsLong = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  String _todayLabel() {
    final n = DateTime.now();
    final day = _daysLong[(n.weekday - 1).clamp(0, 6)];
    final month = _monthsLong[n.month - 1];
    return '$day, ${n.day} de $month';
  }
}
