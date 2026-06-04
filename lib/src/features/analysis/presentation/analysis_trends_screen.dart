// SPEC-168.5.1 (2026-06-03): pantalla dedicada de "Tendencias".
//
// Antes (SPEC-168.5) los cards de Tendencias vivían inline en
// AnalysisScreen. Feedback Carlos: Apple lo hace opt-in — el usuario
// entra explícitamente cuando quiere comparar promedios; no le metemos
// la comparación en la home cada vez.
//
// Esta pantalla comparte `analysisRangeProvider` con AnalysisScreen
// para que el rango temporal se preserve entre las dos vistas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/trend_comparison_computer.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/nutrition_trend_bar_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/segmented_range_control.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/trend_comparison_card.dart';

class AnalysisTrendsScreen extends ConsumerStatefulWidget {
  const AnalysisTrendsScreen({super.key});

  @override
  ConsumerState<AnalysisTrendsScreen> createState() =>
      _AnalysisTrendsScreenState();
}

class _AnalysisTrendsScreenState
    extends ConsumerState<AnalysisTrendsScreen> {
  static const _accentImr = AppColors.metabolicGreen;
  static const _accentWeight = Color(0xFF60A5FA);

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    final aggregationMode = AggregationMode.forRange(range);
    final imrAsync = ref.watch(imrSeriesProvider);
    final weightAsync = ref.watch(weightSeriesProvider);
    // SPEC-168.5.4: card de Nutrición bicolor (verde A / amarillo E)
    // específica de Tendencias. La home muestra el pie agregado.
    final nutritionAsync = ref.watch(nutritionHabitSeriesProvider);

    final firstLoad = imrAsync.value == null ||
        weightAsync.value == null ||
        nutritionAsync.value == null;

    return Scaffold(
      backgroundColor: Colors.black,
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
              const SizedBox(height: 28),
              if (firstLoad)
                _buildLoading()
              else
                ..._buildContent(
                  imrSeries: imrAsync.value!,
                  weightSeries: weightAsync.value!,
                  nutritionSeries: nutritionAsync.value!,
                  mode: aggregationMode,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button minimal, estilo iOS.
        InkResponse(
          onTap: () => context.pop(),
          radius: 22,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Tendencias',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.metabolicGreen,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent({
    required imrSeries,
    required weightSeries,
    required nutritionSeries,
    required AggregationMode mode,
  }) {
    // Computamos los dos trends. Si ninguno tiene data, estado vacío.
    final imrTrend = TrendComparisonComputer.compute(
      series: imrSeries,
      mode: mode,
      betterIf: 'up',
    );
    final weightTrend = TrendComparisonComputer.compute(
      series: weightSeries,
      mode: mode,
      betterIf: 'down',
    );
    // SPEC-168.5.4: Nutrición bicolor se renderiza si la serie tiene
    // datos (no requiere trend; muestra barras verdes/amarillas).
    final hasNutritionData = nutritionSeries.points.isNotEmpty;

    if (imrTrend == null && weightTrend == null && !hasNutritionData) {
      return [_buildEmptyState()];
    }

    return [
      if (weightTrend != null) ...[
        TrendComparisonCard(
          label: 'Peso',
          unit: 'kg',
          accent: _accentWeight,
          trend: weightTrend,
          mode: mode,
        ),
        const SizedBox(height: 14),
      ],
      if (imrTrend != null) ...[
        TrendComparisonCard(
          label: 'IMR',
          unit: '',
          accent: _accentImr,
          trend: imrTrend,
          mode: mode,
        ),
        if (hasNutritionData) const SizedBox(height: 14),
      ],
      if (hasNutritionData)
        NutritionTrendBarCard(
          series: nutritionSeries,
          aggregationMode: mode,
          headline: _nutritionHeadline(nutritionSeries),
        ),
    ];
  }

  /// SPEC-168.5.4: headline conversacional para el bicolor card.
  /// Comunica el promedio de calidad y suaviza el threshold visual.
  String _nutritionHeadline(dynamic series) {
    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return 'Sin registros de comidas en este rango.';
    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final pct = avg.round();
    if (pct >= 70) {
      return 'Tu alimentación viene sólida: $pct % A-dominante en promedio.';
    }
    if (pct >= 50) {
      return 'Vas en buen camino: $pct % A-dominante en promedio.';
    }
    return 'Predominaron los platos E: solo $pct % A-dominante en promedio.';
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aún no hay tendencias para mostrar.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Necesitamos al menos 4 mediciones en este rango para '
            'detectar cambios. Probá con un rango más amplio o '
            'registrá unas mediciones más.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
