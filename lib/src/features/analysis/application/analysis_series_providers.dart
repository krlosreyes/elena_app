// SPEC-162: providers que construyen las 7 series del análisis.
//
//   Resultados:
//     - IMR semanal (promedio de daily_summary.imrScore)
//     - Peso semanal (último valor de biometric_history.weight)
//
//   Hábitos (los 5 pilares oficiales):
//     - Ayuno: días/semana con fastingProgress >= 0.95
//     - Nutrición: % A-dominante semanal
//     - Hidratación: % vs target diario, promediado semanalmente
//     - Ejercicio: minutos/día promedio semanal
//     - Sueño: horas/noche promedio semanal
//
// Todas las series consumen `analysisRangeStartProvider` para filtrar.
// Cero queries Firestore adicionales — reusan repos existentes.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/weekly_aggregator.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_repository_impl.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/data/hydration_repository_impl.dart';
import 'package:elena_app/src/features/dashboard/data/sleep_repository_impl.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';

/// Umbral para considerar un día de ayuno "cumplido" (≥95% del target).
/// Misma constante que SPEC-154.
const double _kFastingCompletedThreshold = 0.95;

/// Sentinel temprano cuando el rango es "Todo".
final DateTime _kEpoch = DateTime(2000);

String _dateIso(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

DateTime _todayLocal() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

// ─── Resultados ────────────────────────────────────────────────────────

final imrSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'IMR', unit: '');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  final repo = ref.watch(dailySummaryRepositoryProvider);
  await for (final docs in repo.watchRange(
    userId: account.uid,
    fromIncl: _dateIso(rangeStart),
    toIncl: _dateIso(_todayLocal()),
  )) {
    final points = WeeklyAggregator.aggregate(
      items: docs,
      timestampOf: (d) => DateTime.parse(d.date),
      valueOf: (d) => d.imrScore.toDouble(),
      aggregation: WeeklyAggregation.avg,
    );
    yield MetricSeries(label: 'IMR', unit: '', points: points);
  }
});

final weightSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Peso', unit: 'kg');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final repo = ref.watch(biometricRepositoryProvider);
  await for (final history in repo.watchHistory(account.uid)) {
    final filtered = rangeStart == null
        ? history
        : history.where((c) {
            final ts = DateTime.parse(c.date);
            return ts.isAfter(rangeStart) || ts == rangeStart;
          }).toList();
    final points = WeeklyAggregator.aggregate(
      items: filtered,
      timestampOf: (c) => DateTime.parse(c.date),
      valueOf: (c) => c.weight,
      aggregation: WeeklyAggregation.last,
    );
    yield MetricSeries(label: 'Peso', unit: 'kg', points: points);
  }
});

// ─── Hábitos ───────────────────────────────────────────────────────────

final fastingHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Ayuno', unit: 'd/sem');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  final repo = ref.watch(dailySummaryRepositoryProvider);
  await for (final docs in repo.watchRange(
    userId: account.uid,
    fromIncl: _dateIso(rangeStart),
    toIncl: _dateIso(_todayLocal()),
  )) {
    final points = WeeklyAggregator.aggregate(
      items: docs,
      timestampOf: (d) => DateTime.parse(d.date),
      valueOf: (d) =>
          d.fastingProgress >= _kFastingCompletedThreshold ? 1.0 : 0.0,
      aggregation: WeeklyAggregation.sum,
    );
    yield MetricSeries(label: 'Ayuno', unit: 'd/sem', points: points);
  }
});

final nutritionHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Nutrición A', unit: '%');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  await for (final logs in ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(account.uid, rangeStart)) {
    final fractionPoints = WeeklyAggregator.aggregate(
      items: logs,
      timestampOf: (l) => l.timestamp,
      valueOf: (l) => l.ratio.isADominant ? 1.0 : 0.0,
      aggregation: WeeklyAggregation.avg,
    );
    final pctPoints = fractionPoints
        .map((p) => TimeSeriesPoint(
              weekStart: p.weekStart,
              value: p.value * 100,
              sampleCount: p.sampleCount,
            ))
        .toList();
    yield MetricSeries(label: 'Nutrición A', unit: '%', points: pctPoints);
  }
});

final hydrationHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Hidratación', unit: '%');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  await for (final logs in ref
      .watch(hydrationRepositoryProvider)
      .watchSince(account.uid, rangeStart)) {
    // Sumamos litros por DÍA primero — luego agregamos semanal.
    final byDay = <String, double>{};
    for (final log in logs) {
      final key = _dateIso(log.timestamp);
      byDay[key] = (byDay[key] ?? 0) + log.amountInLiters;
    }
    // No tenemos target del usuario en este provider — default 2.5L.
    // El widget muestra la tendencia, no exige precisión absoluta.
    const targetLiters = 2.5;
    final dayEntries = byDay.entries
        .map((e) => _DayLiters(_parseDateIso(e.key), e.value))
        .toList();
    final points = WeeklyAggregator.aggregate(
      items: dayEntries,
      timestampOf: (d) => d.date,
      valueOf: (d) =>
          (d.liters / targetLiters * 100).clamp(0.0, 200.0).toDouble(),
      aggregation: WeeklyAggregation.avg,
    );
    yield MetricSeries(label: 'Hidratación', unit: '%', points: points);
  }
});

final exerciseHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Ejercicio', unit: 'min/d');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  await for (final logs in ref
      .watch(exerciseRepositoryProvider)
      .watchSince(account.uid, rangeStart)) {
    final byDay = <String, int>{};
    for (final log in logs) {
      final key = _dateIso(log.timestamp);
      byDay[key] = (byDay[key] ?? 0) + log.durationMinutes;
    }
    final dayEntries = byDay.entries
        .map((e) => _DayMinutes(_parseDateIso(e.key), e.value))
        .toList();
    final points = WeeklyAggregator.aggregate(
      items: dayEntries,
      timestampOf: (d) => d.date,
      valueOf: (d) => d.minutes.toDouble(),
      aggregation: WeeklyAggregation.avg,
    );
    yield MetricSeries(label: 'Ejercicio', unit: 'min/d', points: points);
  }
});

final sleepHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Sueño', unit: 'h');
    return;
  }
  // El SleepRepository expone watchRecent con limit; para series
  // longitudinales usamos un límite alto (365). Si se requiere más,
  // futura SPEC puede extender el repo con watchSince.
  await for (final logs in ref
      .watch(sleepRepositoryProvider)
      .watchRecent(account.uid, limit: 365)) {
    final rangeStart = ref.read(analysisRangeStartProvider);
    final filtered = rangeStart == null
        ? logs
        : logs
            .where((l) => l.wokeUp.isAfter(rangeStart) || l.wokeUp == rangeStart)
            .toList();
    final points = WeeklyAggregator.aggregate(
      items: filtered,
      timestampOf: (l) => l.wokeUp,
      valueOf: (l) => l.wokeUp.difference(l.fellAsleep).inMinutes / 60.0,
      aggregation: WeeklyAggregation.avg,
    );
    yield MetricSeries(label: 'Sueño', unit: 'h', points: points);
  }
});

// ─── Helpers internos ──────────────────────────────────────────────────

class _DayLiters {
  final DateTime date;
  final double liters;
  const _DayLiters(this.date, this.liters);
}

class _DayMinutes {
  final DateTime date;
  final int minutes;
  const _DayMinutes(this.date, this.minutes);
}

DateTime _parseDateIso(String s) {
  final parts = s.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
