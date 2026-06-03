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
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:elena_app/src/features/analysis/domain/causal_insight.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/monthly_calendar_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/bar_chart_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/insight_tile.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/line_chart_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/segmented_range_control.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  // Acentos por métrica (coherentes con SPEC-161).
  static const _accentImr = AppColors.metabolicGreen;
  static const _accentWeight = Color(0xFF60A5FA);
  static const _accentFasting = AppColors.metabolicGreen;
  static const _accentNutrition = Color(0xFFFB923C);
  static const _accentHydration = Color(0xFF38BDF8);
  static const _accentExercise = Color(0xFF14B8A6);
  static const _accentSleep = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analysisRangeProvider);
    final periodLabel = _periodLabelFor(range);
    final imr = ref.watch(imrSeriesProvider);
    final weight = ref.watch(weightSeriesProvider);
    final fasting = ref.watch(fastingHabitSeriesProvider);
    final nutrition = ref.watch(nutritionHabitSeriesProvider);
    final hydration = ref.watch(hydrationHabitSeriesProvider);
    final exercise = ref.watch(exerciseHabitSeriesProvider);
    final sleep = ref.watch(sleepHabitSeriesProvider);
    final insights = ref.watch(causalInsightsProvider);

    final allLoading = [
      imr,
      weight,
      fasting,
      nutrition,
      hydration,
      exercise,
      sleep,
    ].any((s) => s.isLoading);

    return Scaffold(
      // SPEC-165: fondo negro puro.
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header in-page estilo Apple.
              _buildPageHeader(context),
              const SizedBox(height: 24),
              const SegmentedRangeControl(),
              const SizedBox(height: 28),
              if (allLoading)
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
      LineChartCard(
        series: imrSeries,
        accent: _accentImr,
        periodLabel: periodLabel,
        headline: _imrHeadline(imrSeries, periodLabel),
        deltaIsBetterIf: 'up',
      ),
      const SizedBox(height: 14),
      LineChartCard(
        series: weightSeries,
        accent: _accentWeight,
        periodLabel: periodLabel,
        headline: _weightHeadline(weightSeries),
        deltaIsBetterIf: 'down',
      ),
      const SizedBox(height: 36),
      _sectionTitle('Hábitos'),
      const SizedBox(height: 14),
      BarChartCard(
        series: fastingSeries,
        accent: _accentFasting,
        periodLabel: periodLabel,
        headline: _fastingHeadline(fastingSeries),
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: nutritionSeries,
        accent: _accentNutrition,
        periodLabel: periodLabel,
        headline: _nutritionHeadline(nutritionSeries),
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: hydrationSeries,
        accent: _accentHydration,
        periodLabel: periodLabel,
        headline: _hydrationHeadline(hydrationSeries),
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: exerciseSeries,
        accent: _accentExercise,
        periodLabel: periodLabel,
        headline: _exerciseHeadline(exerciseSeries),
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: sleepSeries,
        accent: _accentSleep,
        periodLabel: periodLabel,
        headline: _sleepHeadline(sleepSeries),
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
