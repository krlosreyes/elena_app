// 17-jul: "Tus Resultados" (Score del día, IMR, Composición corporal) se
// saca del scroll único de AnalysisScreen y pasa a vivir en su propia
// pantalla — Progreso ahora es 4 cards colapsadas (ver ResultsEntryCard).
// Mismo AppBar/estructura que BadgesScreen. El contenido de los tiles
// (PillarOverviewTile) no cambió, solo se movió de archivo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/pillar_overview_tile.dart';

class ResultadosDetailScreen extends ConsumerWidget {
  const ResultadosDetailScreen({super.key});

  static const _accentImr = AppColors.accent;
  static const _accentBodyFat = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imr = ref.watch(imrSeriesProvider);
    final bodyFat = ref.watch(bodyFatSeriesProvider);
    final firstLoad = imr.value == null || bodyFat.value == null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tus Resultados',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: firstLoad
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.metabolicGreen,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  _dailyScoreTile(ref),
                  const SizedBox(height: 10),
                  _imrTile(ref, imr.value!),
                  const SizedBox(height: 10),
                  _bodyFatTile(bodyFat.value!),
                ],
              ),
      ),
    );
  }

  PillarOverviewTile _dailyScoreTile(WidgetRef ref) {
    final s = ref.watch(resolvedDailyScoreSeriesProvider);
    final v = ChartHeroComputer.aggregateValue(s, HeroAggregation.last);
    return PillarOverviewTile(
      metric: ChartMetric.imr,
      routeOverride: '/analysis/daily-score',
      icon: Icons.today_rounded,
      label: 'Score del día',
      value: v == null ? '' : ChartHeroComputer.formatValue(v),
      unit: '',
      accent: AppColors.metabolicGreen,
      sparklineValues: s.points.map((p) => p.value).toList(),
    );
  }

  PillarOverviewTile _imrTile(WidgetRef ref, MetricSeries s) {
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

  PillarOverviewTile _bodyFatTile(MetricSeries s) {
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
}
