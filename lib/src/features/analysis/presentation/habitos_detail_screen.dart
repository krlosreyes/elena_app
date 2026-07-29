// 17-jul: "Tus Hábitos" (los 5 pilares) se saca del scroll único de
// AnalysisScreen y pasa a vivir en su propia pantalla — ver comentario
// en resultados_detail_screen.dart, mismo movimiento aplicado acá.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
import 'package:elena_app/src/features/analysis/application/nutrition_pie_provider.dart';
import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/nutrition_pie_data.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/pillar_overview_tile.dart';

class HabitosDetailScreen extends ConsumerWidget {
  const HabitosDetailScreen({super.key});

  static const _accentFasting = AppColors.pillarAyuno;
  static const _accentNutrition = AppColors.pillarNutricion;
  static const _accentHydration = AppColors.pillarHidratacion;
  static const _accentExercise = AppColors.pillarEjercicio;
  static const _accentSleep = AppColors.pillarSueno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fasting = ref.watch(fastingHabitSeriesProvider);
    final nutrition = ref.watch(nutritionHabitSeriesProvider);
    final nutritionPie = ref.watch(nutritionPieDataProvider);
    final hydration = ref.watch(hydrationHabitSeriesProvider);
    final exercise = ref.watch(exerciseHabitSeriesProvider);
    final sleep = ref.watch(sleepHabitSeriesProvider);

    final firstLoad = fasting.value == null ||
        nutrition.value == null ||
        hydration.value == null ||
        exercise.value == null ||
        sleep.value == null;

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
          'Tus hábitos',
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
                  _fastingTile(fasting.value!),
                  const SizedBox(height: 10),
                  _nutritionTile(
                    nutritionPie.value ??
                        const NutritionPieData(
                          aDominantCount: 0,
                          eDominantCount: 0,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _hydrationTile(hydration.value!),
                  const SizedBox(height: 10),
                  _exerciseTile(exercise.value!),
                  const SizedBox(height: 10),
                  _sleepTile(sleep.value!),
                ],
              ),
      ),
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
}
