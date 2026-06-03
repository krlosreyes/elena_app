// SPEC-162: pantalla Análisis reescrita como trazabilidad +
// causa-efecto.
//
// Cuatro estados:
//   1. Loading — alguna serie aún se está leyendo.
//   2. Insuficiente data — <30 días → InsufficientDataView.
//   3. Datos suficientes — bloques Resultados + Hábitos + Insights.
//   4. Error — fallback simple.
//
// El selector global de rango vive arriba de todo y aplica a las 7
// series. Sin tabs — UN solo flujo vertical.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/causal_insights_provider.dart';
import 'package:elena_app/src/features/analysis/domain/causal_insight.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/monthly_calendar_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/insight_tile.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/metric_row.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/range_selector_chips.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  // Colores por hábito coherentes con SPEC-161.
  static const _accentImr = AppColors.metabolicGreen;
  static const _accentWeight = Color(0xFF60A5FA);
  static const _accentFasting = AppColors.metabolicGreen;
  static const _accentNutrition = Color(0xFFFB923C);
  static const _accentHydration = Color(0xFF38BDF8);
  static const _accentExercise = Color(0xFF14B8A6);
  static const _accentSleep = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RangeSelectorChips(),
            const SizedBox(height: 24),
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
      height: 320,
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
  }) {
    // Si todos están vacíos, mostramos estado "arrancando".
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
      const SizedBox(height: 12),
      MetricRow(series: imrSeries, accent: _accentImr),
      const SizedBox(height: 24),
      MetricRow(series: weightSeries, accent: _accentWeight),
      const SizedBox(height: 28),
      _divider(),
      const SizedBox(height: 28),
      _sectionHeader('TUS HÁBITOS'),
      const SizedBox(height: 12),
      MetricRow(series: fastingSeries, accent: _accentFasting),
      const SizedBox(height: 22),
      MetricRow(series: nutritionSeries, accent: _accentNutrition),
      const SizedBox(height: 22),
      MetricRow(series: hydrationSeries, accent: _accentHydration),
      const SizedBox(height: 22),
      MetricRow(series: exerciseSeries, accent: _accentExercise),
      const SizedBox(height: 22),
      MetricRow(series: sleepSeries, accent: _accentSleep),
      const SizedBox(height: 28),
      _divider(),
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

  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.50),
        fontSize: 10,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
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
