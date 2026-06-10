// SPEC-162 + SPEC-163 + SPEC-164 + SPEC-165: Análisis estilo Apple
// Fitness, función de revisión histórica (NO motivacional — eso vive
// en Hoy).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/causal_insights_provider.dart';
// SPEC-168.1: helper para formatear el dateRange del card de Nutrición pie.
import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
// SPEC-168.5.4: distribución pie A vs E.
import 'package:elena_app/src/features/analysis/application/nutrition_pie_provider.dart';
// SPEC-168.1: aggregation mode + hero aggregation enums.
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:elena_app/src/features/analysis/domain/causal_insight.dart';
import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
// SPEC-168.5.4: domain del pie chart de Nutrición.
import 'package:elena_app/src/features/analysis/domain/nutrition_pie_data.dart';
import 'package:elena_app/src/features/analysis/presentation/monthly_calendar_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/insight_tile.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/transformation_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/daily_score_trend_section.dart';
// SPEC-168.4: tile compacto del overview con sparkline + tap a detalle.
import 'package:elena_app/src/features/analysis/presentation/widgets/pillar_overview_tile.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/segmented_range_control.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  // Acentos por métrica. UI #2: los 5 pilares leen los tokens canónicos de
  // AppColors (mismo color que su card e ícono). IMR usa el accent teal.
  static const _accentImr = AppColors.accent;
  static const _accentWeight = Color(0xFF60A5FA);
  // SPEC-168.4.2: ámbar — coherente con BodyCompositionMetric.bodyFatPct.
  static const _accentBodyFat = Color(0xFFF59E0B);
  static const _accentFasting = AppColors.pillarAyuno;
  static const _accentNutrition = AppColors.pillarNutricion;
  static const _accentHydration = AppColors.pillarHidratacion;
  static const _accentExercise = AppColors.pillarEjercicio;
  static const _accentSleep = AppColors.pillarSueno;

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
    // SPEC-168.1: mode temporal para que cada chart formatee la
    // fecha-range del hero block correctamente.
    final aggregationMode = AggregationMode.forRange(range);

    // SPEC-168.2: targets del usuario por chart. Cada uno es null si el
    // goal correspondiente no está activo en `userGoals`. La línea
    // dashed solo se pinta cuando hay valor.
    // SPEC-168.4: los targets del usuario se consumen ahora en la
    // pantalla de detalle de cada pilar. La home solo muestra tiles
    // con valor agregado + sparkline.
    final imr = ref.watch(imrSeriesProvider);
    final weight = ref.watch(weightSeriesProvider);
    // SPEC-168.4.2: % grasa corporal, nuevo tile en Resultados.
    final bodyFat = ref.watch(bodyFatSeriesProvider);
    final fasting = ref.watch(fastingHabitSeriesProvider);
    final nutrition = ref.watch(nutritionHabitSeriesProvider);
    // SPEC-168.5.4: distribución pie (A vs E) además de la serie.
    final nutritionPie = ref.watch(nutritionPieDataProvider);
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
        bodyFat.value == null ||
        fasting.value == null ||
        nutrition.value == null ||
        hydration.value == null ||
        exercise.value == null ||
        sleep.value == null;

    return Scaffold(
      // SPEC-168.4.6 (2026-06-04): mismo fondo que Hoy y Perfil para
      // unidad visual en la app (las cards mantienen su #0C0C0E).
      backgroundColor: AppColors.backgroundDark,
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
                  bodyFatSeries: bodyFat.value!,
                  fastingSeries: fasting.value!,
                  nutritionSeries: nutrition.value!,
                  hydrationSeries: hydration.value!,
                  exerciseSeries: exercise.value!,
                  sleepSeries: sleep.value!,
                  insights: insights,
                  aggregationMode: aggregationMode,
                  nutritionPie: nutritionPie.value ?? const NutritionPieData(
                    aDominantCount: 0,
                    eDominantCount: 0,
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.backgroundDark,
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
        // SPEC-168.4.1: el botón "Tendencias →" se eliminó. Ahora cada
        // tendencia vive dentro del detalle de su pilar (debajo del
        // chart). El usuario ve tendencia + chart juntos en contexto.
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
    required MetricSeries bodyFatSeries,
    required MetricSeries fastingSeries,
    required MetricSeries nutritionSeries,
    required MetricSeries hydrationSeries,
    required MetricSeries exerciseSeries,
    required MetricSeries sleepSeries,
    required AsyncValue<List<CausalInsight>> insights,
    required AggregationMode aggregationMode,
    required NutritionPieData nutritionPie,
  }) {
    final allEmpty = imrSeries.isEmpty &&
        weightSeries.isEmpty &&
        bodyFatSeries.isEmpty &&
        fastingSeries.isEmpty &&
        nutritionSeries.isEmpty &&
        hydrationSeries.isEmpty &&
        exerciseSeries.isEmpty &&
        sleepSeries.isEmpty;
    if (allEmpty) {
      return [_buildStartingState()];
    }

    // SPEC-168.4 (2026-06-03): Análisis pasa a ser un overview de tiles
    // compactos. Cada tile muestra el valor agregado del período +
    // sparkline mini (o mini-pie en Nutrición), y al tap navega a la
    // pantalla de detalle con el chart completo. Patrón Apple Health
    // "Anteriores".
    return [
      // SPEC-148 §RF-148-06 (2026-06-05): card de transformación 30d
      // al inicio de Resultados. Antes que los tiles individuales para
      // que sea lo primero que el usuario lee — narrativa del cambio
      // por encima de la tabla de números.
      const TransformationCardLive(),
      const SizedBox(height: 20),
      _sectionTitle('Resultados'),
      const SizedBox(height: 12),
      // SPEC-200: seguimiento del Score del Día (HOY, llega a 100) — distinto
      // del IMR longitudinal. Va primero porque es el número que el usuario
      // mueve cada día.
      const DailyScoreTrendSection(),
      const SizedBox(height: 20),
      _imrTile(imrSeries),
      const SizedBox(height: 10),
      _weightTile(weightSeries),
      const SizedBox(height: 10),
      _bodyFatTile(bodyFatSeries),
      const SizedBox(height: 28),
      _sectionTitle('Hábitos'),
      const SizedBox(height: 12),
      _fastingTile(fastingSeries),
      const SizedBox(height: 10),
      _nutritionTile(nutritionPie),
      const SizedBox(height: 10),
      _hydrationTile(hydrationSeries),
      const SizedBox(height: 10),
      _exerciseTile(exerciseSeries),
      const SizedBox(height: 10),
      _sleepTile(sleepSeries),
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

  // ─── SPEC-168.4: tiles del overview ─────────────────────────────────

  PillarOverviewTile _imrTile(MetricSeries s) {
    final v = ChartHeroComputer.aggregateValue(s, HeroAggregation.avg);
    return PillarOverviewTile(
      metric: ChartMetric.imr,
      icon: AppIcons.imr,
      label: 'IMR',
      value: v == null ? '' : ChartHeroComputer.formatValue(v),
      unit: '',
      accent: _accentImr,
      sparklineValues: s.points.map((p) => p.value).toList(),
    );
  }

  PillarOverviewTile _weightTile(MetricSeries s) {
    final v = ChartHeroComputer.aggregateValue(s, HeroAggregation.last);
    return PillarOverviewTile(
      metric: ChartMetric.weight,
      icon: AppIcons.peso,
      label: 'Peso',
      value: v == null ? '' : ChartHeroComputer.formatValue(v),
      unit: 'kg',
      accent: _accentWeight,
      sparklineValues: s.points.map((p) => p.value).toList(),
    );
  }

  PillarOverviewTile _bodyFatTile(MetricSeries s) {
    // SPEC-168.4.3 (2026-06-03): el tile se llama "Composición corporal".
    // El valor principal sigue siendo % grasa (la lectura más universal),
    // pero el detalle abre el BodyCompositionTrendChart con sus 5 tabs
    // (peso, cintura, grasa, WHTR, masa magra). WHTR > 0.5 es proxy
    // clínico del riesgo visceral.
    final v = ChartHeroComputer.aggregateValue(s, HeroAggregation.last);
    return PillarOverviewTile(
      metric: ChartMetric.bodyFatPct,
      icon: AppIcons.composicion,
      label: 'Composición corporal',
      value: v == null ? '' : v.toStringAsFixed(1),
      unit: '% grasa',
      accent: _accentBodyFat,
      sparklineValues: s.points.map((p) => p.value).toList(),
    );
  }

  PillarOverviewTile _fastingTile(MetricSeries s) {
    final v = ChartHeroComputer.aggregateValue(s, HeroAggregation.avg);
    return PillarOverviewTile(
      metric: ChartMetric.fastingHours,
      icon: AppIcons.ayuno,
      label: 'Ayuno',
      value: v == null ? '' : ChartHeroComputer.formatValue(v),
      unit: 'h',
      accent: _accentFasting,
      sparklineValues: s.points.map((p) => p.value).toList(),
    );
  }

  PillarOverviewTile _nutritionTile(NutritionPieData pie) {
    final hasData = !pie.isEmpty;
    return PillarOverviewTile(
      metric: ChartMetric.nutritionAPct,
      icon: AppIcons.nutricion,
      label: 'Nutrición',
      value: hasData ? pie.aPct.toStringAsFixed(0) : '',
      unit: hasData ? '% A' : '',
      accent: _accentNutrition,
      sparklineValues: const [],
      aPctForPie: hasData ? pie.aPct : null,
    );
  }

  PillarOverviewTile _hydrationTile(MetricSeries s) {
    final v = ChartHeroComputer.aggregateValue(s, HeroAggregation.avg);
    return PillarOverviewTile(
      metric: ChartMetric.hydrationLiters,
      icon: AppIcons.hidratacion,
      label: 'Hidratación',
      value: v == null ? '' : ChartHeroComputer.formatValue(v),
      unit: 'L',
      accent: _accentHydration,
      sparklineValues: s.points.map((p) => p.value).toList(),
    );
  }

  PillarOverviewTile _exerciseTile(MetricSeries s) {
    final v = ChartHeroComputer.aggregateValue(s, HeroAggregation.avg);
    return PillarOverviewTile(
      metric: ChartMetric.exerciseMin,
      icon: AppIcons.ejercicio,
      label: 'Ejercicio',
      value: v == null ? '' : ChartHeroComputer.formatValue(v),
      unit: 'min',
      accent: _accentExercise,
      sparklineValues: s.points.map((p) => p.value).toList(),
    );
  }

  PillarOverviewTile _sleepTile(MetricSeries s) {
    final v = ChartHeroComputer.aggregateValue(s, HeroAggregation.avg);
    return PillarOverviewTile(
      metric: ChartMetric.sleepHours,
      icon: AppIcons.sueno,
      label: 'Sueño',
      value: v == null ? '' : ChartHeroComputer.formatValue(v),
      unit: 'h',
      accent: _accentSleep,
      sparklineValues: s.points.map((p) => p.value).toList(),
    );
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
          Icon(AppIcons.analisis,
              size: 32, color: Colors.white.withValues(alpha: 0.85)),
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
    // SPEC-168.5.2: Ayuno se mide en horas promedio por bucket. El
    // copy refleja el esfuerzo real ("16.4 h de ayuno en promedio"),
    // no días cumplidos.
    final avg = _avg(s);
    if (avg == null) return 'Sin registros de ayuno todavía.';
    return 'Promediaste ${avg.toStringAsFixed(1)} h de ayuno por día '
        'en este período.';
  }

  String _nutritionHeadline(MetricSeries s) {
    final avg = _avg(s);
    if (avg == null) return 'Sin registros de comidas todavía.';
    return 'El ${avg.round()}% de tus comidas fueron A-dominantes.';
  }

  String _hydrationHeadline(MetricSeries s) {
    // SPEC-168.5.3: Hidratación se mide en litros por día. El copy
    // refleja el consumo absoluto, no el porcentaje vs meta.
    final avg = _avg(s);
    if (avg == null) return 'Sin registros de hidratación todavía.';
    return 'Tomaste ${avg.toStringAsFixed(1)} L de agua por día en '
        'promedio.';
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
