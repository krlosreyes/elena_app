// SPEC-162 + SPEC-164: providers que construyen las 7 series.
//
//   Resultados:
//     - IMR (avg de daily_summary.imrScore)
//     - Peso (last de biometric_history.weight)
//
//   Hábitos (5 pilares oficiales):
//     - Ayuno: días cumplidos por bucket (fastingProgress >= 0.95)
//     - Nutrición: % A-dominante
//     - Hidratación: % vs target diario
//     - Ejercicio: minutos/día promedio
//     - Sueño: horas/noche promedio
//
// SPEC-164: el modo de agregación se decide en runtime según el rango
// seleccionado por el usuario (daily/weekly/monthly).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/temporal_aggregator.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_repository_impl.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart'
    show fastingProvider;
import 'package:elena_app/src/features/dashboard/data/fasting_interval_repository_impl.dart';
import 'package:elena_app/src/features/dashboard/data/hydration_repository_impl.dart';
import 'package:elena_app/src/features/dashboard/data/sleep_repository_impl.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';

/// Umbral para considerar un día de ayuno "cumplido" (≥95% del target).
const double _kFastingCompletedThreshold = 0.95;

/// Sentinel temprano para rango "Todo".
final DateTime _kEpoch = DateTime(2000);

String _dateIso(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

DateTime _todayLocal() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Helper que devuelve el `AggregationMode` actual a partir del
/// rango seleccionado. Los providers lo usan para adaptar la
/// granularidad de los buckets.
AggregationMode _currentMode(Ref ref) {
  final range = ref.watch(analysisRangeProvider);
  return AggregationMode.forRange(range);
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
  final mode = _currentMode(ref);
  final repo = ref.watch(dailySummaryRepositoryProvider);
  await for (final docs in repo.watchRange(
    userId: account.uid,
    fromIncl: _dateIso(rangeStart),
    toIncl: _dateIso(_todayLocal()),
  )) {
    final points = TemporalAggregator.aggregate(
      items: docs,
      timestampOf: (d) => DateTime.parse(d.date),
      valueOf: (d) => d.imrScore.toDouble(),
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'IMR', unit: '', points: points);
  }
});

// SPEC-168.4.2 (2026-06-03): serie temporal del % de grasa corporal.
// Reusa `biometricRepository.watchHistory()` (mismo stream que peso)
// y filtra los check-ins que NO tienen bodyFatPercentage.
final bodyFatSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Grasa corporal', unit: '%');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider);
  final mode = _currentMode(ref);
  final repo = ref.watch(biometricRepositoryProvider);
  await for (final history in repo.watchHistory(account.uid)) {
    final filtered = history.where((c) {
      if (c.bodyFatPercentage == null) return false;
      if (rangeStart == null) return true;
      final ts = DateTime.parse(c.date);
      return ts.isAfter(rangeStart) || ts == rangeStart;
    }).toList();
    final points = TemporalAggregator.aggregate(
      items: filtered,
      timestampOf: (c) => DateTime.parse(c.date),
      valueOf: (c) => c.bodyFatPercentage!,
      aggregation: TemporalAggregation.last,
      mode: mode,
    );
    yield MetricSeries(label: 'Grasa corporal', unit: '%', points: points);
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
  final mode = _currentMode(ref);
  final repo = ref.watch(biometricRepositoryProvider);
  await for (final history in repo.watchHistory(account.uid)) {
    final filtered = rangeStart == null
        ? history
        : history.where((c) {
            final ts = DateTime.parse(c.date);
            return ts.isAfter(rangeStart) || ts == rangeStart;
          }).toList();
    final points = TemporalAggregator.aggregate(
      items: filtered,
      timestampOf: (c) => DateTime.parse(c.date),
      valueOf: (c) => c.weight,
      aggregation: TemporalAggregation.last,
      mode: mode,
    );
    yield MetricSeries(label: 'Peso', unit: 'kg', points: points);
  }
});

// ─── Hábitos ───────────────────────────────────────────────────────────

final fastingHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Ayuno', unit: 'h');
    return;
  }
  // SPEC-162.bugfix (2026-06-02): antes leíamos daily_summary, que
  // tiene debounce de 30s y flush a medianoche → los ayunos cerrados
  // de HOY no aparecían en el gráfico hasta el día siguiente. Ahora
  // leemos directamente de fasting_history (los FastingInterval
  // cerrados aparecen en Firestore al instante).
  //
  // SPEC-168.5.2 (2026-06-03): el eje Y representa HORAS DE AYUNO
  // (no días cumplidos 0/1). Carlos: el usuario ya tiene el target
  // visible (línea de objetivo) y la lectura de "16h promedio esta
  // semana" comunica mucho más que "5 días cumplidos". El cómputo
  // de achievement (SPEC-168.3) se preserva: comparar value (horas
  // reales) vs target (horas del protocolo activo).
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  final mode = _currentMode(ref);
  await for (final intervals in ref
      .watch(fastingIntervalRepositoryProvider)
      // SPEC-168.4.7: 2000 cubre ~5 años de uso diario sin egress
      // problemático y elimina el corte silencioso para rango "Todo".
      .watchRecentCompleted(account.uid, limit: 2000)) {
    final inRange = intervals
        .where((i) => !i.startTime.isBefore(rangeStart))
        .toList();
    final points = TemporalAggregator.aggregate(
      items: inRange,
      timestampOf: (i) => i.startTime,
      valueOf: (i) {
        final endTime = i.endTime;
        if (endTime == null) return 0.0;
        return endTime.difference(i.startTime).inMinutes / 60.0;
      },
      // Promedio en todos los modos: en daily da las horas del ayuno
      // de ese día; en weekly/monthly da el promedio de horas por
      // bucket. Lectura directa del esfuerzo metabólico real.
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'Ayuno', unit: 'h', points: points);
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
  final mode = _currentMode(ref);
  await for (final logs in ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(
    account.uid,
    rangeStart,
    until: _todayLocal().add(const Duration(days: 1)),
  )) {
    final fractionPoints = TemporalAggregator.aggregate(
      items: logs,
      timestampOf: (l) => l.timestamp,
      valueOf: (l) => l.ratio.isADominant ? 1.0 : 0.0,
      aggregation: TemporalAggregation.avg,
      mode: mode,
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
    yield MetricSeries.empty(label: 'Hidratación', unit: 'L');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  final mode = _currentMode(ref);
  await for (final logs in ref.watch(hydrationRepositoryProvider).watchSince(
        account.uid,
        rangeStart,
        until: _todayLocal().add(const Duration(days: 1)),
      )) {
    // SPEC-168.5.3 (2026-06-03): el eje Y muestra LITROS por día (no %
    // vs un target hard-coded). Lectura directa del consumo real; el
    // target line es el goal del usuario en hydrationLitersPerDay.
    final byDay = <String, double>{};
    for (final log in logs) {
      final key = _dateIso(log.timestamp);
      byDay[key] = (byDay[key] ?? 0) + log.amountInLiters;
    }
    final dayEntries = byDay.entries
        .map((e) => _DayLiters(_parseDateIso(e.key), e.value))
        .toList();
    final points = TemporalAggregator.aggregate(
      items: dayEntries,
      timestampOf: (d) => d.date,
      valueOf: (d) => d.liters,
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'Hidratación', unit: 'L', points: points);
  }
});

final exerciseHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Ejercicio', unit: 'min');
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  final mode = _currentMode(ref);
  await for (final logs in ref.watch(exerciseRepositoryProvider).watchSince(
        account.uid,
        rangeStart,
        until: _todayLocal().add(const Duration(days: 1)),
      )) {
    final byDay = <String, int>{};
    for (final log in logs) {
      final key = _dateIso(log.timestamp);
      byDay[key] = (byDay[key] ?? 0) + log.durationMinutes;
    }
    final dayEntries = byDay.entries
        .map((e) => _DayMinutes(_parseDateIso(e.key), e.value))
        .toList();
    // En modo daily mostramos el valor directo del día.
    // En weekly/monthly promediamos los minutos por día.
    final points = TemporalAggregator.aggregate(
      items: dayEntries,
      timestampOf: (d) => d.date,
      valueOf: (d) => d.minutes.toDouble(),
      aggregation: mode == AggregationMode.daily
          ? TemporalAggregation.sum
          : TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'Ejercicio', unit: 'min', points: points);
  }
});

final sleepHabitSeriesProvider =
    StreamProvider.autoDispose<MetricSeries>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield MetricSeries.empty(label: 'Sueño', unit: 'h');
    return;
  }
  final mode = _currentMode(ref);
  await for (final logs in ref
      .watch(sleepRepositoryProvider)
      // SPEC-168.4.7: 2000 cubre ~5 años de uso diario sin egress
      // problemático y elimina el corte silencioso para rango "Todo".
      .watchRecent(account.uid, limit: 2000)) {
    final rangeStart = ref.read(analysisRangeStartProvider);
    final filtered = rangeStart == null
        ? logs
        : logs
            .where((l) => l.wokeUp.isAfter(rangeStart) || l.wokeUp == rangeStart)
            .toList();
    final points = TemporalAggregator.aggregate(
      items: filtered,
      timestampOf: (l) => l.wokeUp,
      valueOf: (l) => l.wokeUp.difference(l.fellAsleep).inMinutes / 60.0,
      aggregation: TemporalAggregation.avg,
      mode: mode,
    );
    yield MetricSeries(label: 'Sueño', unit: 'h', points: points);
  }
});

// ─── Helpers internos ──────────────────────────────────────────────────

String _unitForDaysCount(AggregationMode mode) {
  switch (mode) {
    case AggregationMode.daily:
      return ''; // sin unidad — 0 o 1 (cumplió o no)
    case AggregationMode.weekly:
      return 'd/sem';
    case AggregationMode.monthly:
      return 'd/mes';
  }
}

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
