// SPEC-162 + SPEC-163: pantalla Análisis como trazabilidad +
// causa-efecto, con gráficos estilo Apple Fitness.
//
// Estructura:
//   AppBar
//   Selector temporal (chips prominentes)
//   TUS RESULTADOS — LineChartCard × 2 (IMR + Peso)
//   TUS HÁBITOS — BarChartCard × 5 (pilares oficiales)
//   INSIGHTS DETECTADOS — lista de CausalInsight

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
import 'package:elena_app/src/features/analysis/presentation/widgets/range_selector_chips.dart';

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

    final allSeries = [
      imr,
      weight,
      fasting,
      nutrition,
      hydration,
      exercise,
      sleep,
    ];
    final allLoading = allSeries.any((s) => s.isLoading);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'ANÁLISIS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MonthlyCalendarScreen(),
                fullscreenDialog: true,
              ),
            ),
            tooltip: 'Ver mes',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RangeSelectorChips(),
            const SizedBox(height: 22),
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
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
      _sectionHeader('TUS RESULTADOS'),
      const SizedBox(height: 10),
      LineChartCard(
        series: imrSeries,
        accent: _accentImr,
        periodLabel: periodLabel,
        statLabel: 'ACTUAL',
        deltaIsBetterIf: 'up',
      ),
      const SizedBox(height: 14),
      LineChartCard(
        series: weightSeries,
        accent: _accentWeight,
        periodLabel: periodLabel,
        statLabel: 'ACTUAL',
        deltaIsBetterIf: 'down',
      ),
      const SizedBox(height: 28),
      _sectionHeader('TUS HÁBITOS'),
      const SizedBox(height: 10),
      BarChartCard(
        series: fastingSeries,
        accent: _accentFasting,
        periodLabel: periodLabel,
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: nutritionSeries,
        accent: _accentNutrition,
        periodLabel: periodLabel,
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: hydrationSeries,
        accent: _accentHydration,
        periodLabel: periodLabel,
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: exerciseSeries,
        accent: _accentExercise,
        periodLabel: periodLabel,
      ),
      const SizedBox(height: 14),
      BarChartCard(
        series: sleepSeries,
        accent: _accentSleep,
        periodLabel: periodLabel,
      ),
      const SizedBox(height: 28),
      _sectionHeader('INSIGHTS DETECTADOS'),
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
            'No pudimos cargar los insights.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Seguí registrando — Elena necesita más patrones para '
                'devolverte conclusiones causa-efecto.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
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
        return '30 DÍAS';
      case AnalysisRange.m3:
        return '3 MESES';
      case AnalysisRange.m6:
        return '6 MESES';
      case AnalysisRange.y1:
        return '1 AÑO';
      case AnalysisRange.all:
        return 'TODO';
    }
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.50),
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStartingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          const Text(
            'Tu trazabilidad arranca acá.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Necesitás al menos 30 días de registro para que Elena '
            'detecte causa-efecto confiable entre tus hábitos y tus '
            'resultados.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Volvé en unos días para ver tu primera detección.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
