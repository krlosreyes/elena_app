// SPEC-201: provider de Observaciones honestas. Reemplaza a
// `causalInsightsProvider`. Ensambla las 5 series semanales de pilares + el
// historial de streak y delega en `ObservationDetector` (puro).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/observation_detector.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

final observationsProvider =
    Provider.autoDispose<AsyncValue<List<Observation>>>((ref) {
  final fasting = ref.watch(fastingHabitSeriesProvider);
  final nutrition = ref.watch(nutritionHabitSeriesProvider);
  final hydration = ref.watch(hydrationHabitSeriesProvider);
  final exercise = ref.watch(exerciseHabitSeriesProvider);
  final sleep = ref.watch(sleepHabitSeriesProvider);

  final all = [fasting, nutrition, hydration, exercise, sleep];
  if (all.any((s) => s.isLoading)) return const AsyncValue.loading();
  for (final s in all) {
    if (s.hasError) return AsyncValue.error(s.error!, s.stackTrace!);
  }

  final habitWeekly = <MetricSeries>[
    fasting.value!,
    nutrition.value!,
    hydration.value!,
    exercise.value!,
    sleep.value!,
  ];

  // Historial de streak (puede venir descendente) → ascendente por fecha.
  final entries = [...ref.watch(streakProvider).history]
    ..sort((a, b) => a.date.compareTo(b.date));

  final observations = ObservationDetector.detect(
    habitWeekly: habitWeekly,
    dailyEntries: entries,
  );
  return AsyncValue.data(observations);
});
