// SPEC-162: provider que combina las 7 series y entrega los insights
// causa-efecto detectados.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/causal_insight_detector.dart';
import 'package:elena_app/src/features/analysis/domain/causal_insight.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';

final causalInsightsProvider =
    Provider.autoDispose<AsyncValue<List<CausalInsight>>>((ref) {
  final imr = ref.watch(imrSeriesProvider);
  final weight = ref.watch(weightSeriesProvider);
  final fasting = ref.watch(fastingHabitSeriesProvider);
  final nutrition = ref.watch(nutritionHabitSeriesProvider);
  final hydration = ref.watch(hydrationHabitSeriesProvider);
  final exercise = ref.watch(exerciseHabitSeriesProvider);
  final sleep = ref.watch(sleepHabitSeriesProvider);

  final all = [imr, weight, fasting, nutrition, hydration, exercise, sleep];

  // Si alguna serie aún está cargando, devolvemos loading.
  if (all.any((s) => s.isLoading)) {
    return const AsyncValue.loading();
  }
  // Si alguna tiene error, lo propagamos.
  for (final s in all) {
    if (s.hasError) {
      return AsyncValue.error(s.error!, s.stackTrace!);
    }
  }

  // Todas con data.
  final habits = <MetricSeries>[
    fasting.value!,
    nutrition.value!,
    hydration.value!,
    exercise.value!,
    sleep.value!,
  ];
  final outcomes = <MetricSeries>[imr.value!, weight.value!];

  final insights = CausalInsightDetector.detect(
    habits: habits,
    outcomes: outcomes,
  );
  return AsyncValue.data(insights);
});
