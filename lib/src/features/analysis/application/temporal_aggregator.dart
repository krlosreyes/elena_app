// SPEC-164: agregador temporal adaptativo.
//
// Reemplaza el WeeklyAggregator fijo de SPEC-162. Cada bucket se
// calcula según `mode`: día calendárico, semana ISO o mes calendárico.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';

enum TemporalAggregation {
  sum,
  avg,
  count,
  last,
  max,
}

class TemporalAggregator {
  TemporalAggregator._();

  /// Agrupa [items] en buckets según [mode] y aplica [aggregation].
  ///
  /// Cada `TimeSeriesPoint.weekStart` representa el inicio del bucket
  /// (el campo conserva el nombre original por compatibilidad).
  static List<TimeSeriesPoint> aggregate<T>({
    required Iterable<T> items,
    required DateTime Function(T) timestampOf,
    required double Function(T) valueOf,
    required TemporalAggregation aggregation,
    required AggregationMode mode,
    int? bucketsToShow,
  }) {
    if (items.isEmpty) return const [];

    final byBucket = <DateTime, List<T>>{};
    for (final item in items) {
      final ts = timestampOf(item);
      final bucket = _bucketStart(ts, mode);
      byBucket.putIfAbsent(bucket, () => []).add(item);
    }

    final entries = byBucket.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final points = <TimeSeriesPoint>[];
    for (final e in entries) {
      final value = _aggregateBatch(e.value, valueOf, timestampOf, aggregation);
      points.add(TimeSeriesPoint(
        weekStart: e.key,
        value: value,
        sampleCount: e.value.length,
      ));
    }

    if (bucketsToShow != null && points.length > bucketsToShow) {
      return points.sublist(points.length - bucketsToShow);
    }
    return points;
  }

  /// Inicio del bucket que contiene [date], según [mode].
  ///
  /// SPEC-229 BUG-E: [date] puede llegar como UTC (Firestore
  /// `Timestamp.toDate()` devuelve UTC). Convertimos a local ANTES
  /// de extraer año/mes/día para que un cierre a las 11:30pm local
  /// (= 4:30am UTC+1d) caiga en el día correcto del usuario.
  static DateTime _bucketStart(DateTime date, AggregationMode mode) {
    final local = date.toLocal();
    switch (mode) {
      case AggregationMode.daily:
        return DateTime(local.year, local.month, local.day);
      case AggregationMode.weekly:
        // Semana ISO: lunes 00:00 local.
        final daysSinceMonday = local.weekday - 1;
        final monday = DateTime(local.year, local.month, local.day)
            .subtract(Duration(days: daysSinceMonday));
        return monday;
      case AggregationMode.monthly:
        return DateTime(local.year, local.month, 1);
    }
  }

  static double _aggregateBatch<T>(
    List<T> batch,
    double Function(T) valueOf,
    DateTime Function(T) timestampOf,
    TemporalAggregation aggregation,
  ) {
    switch (aggregation) {
      case TemporalAggregation.sum:
        return batch.fold<double>(0, (acc, item) => acc + valueOf(item));
      case TemporalAggregation.avg:
        final sum = batch.fold<double>(0, (acc, item) => acc + valueOf(item));
        return sum / batch.length;
      case TemporalAggregation.count:
        return batch.length.toDouble();
      case TemporalAggregation.last:
        final sorted = [...batch]
          ..sort((a, b) => timestampOf(a).compareTo(timestampOf(b)));
        return valueOf(sorted.last);
      case TemporalAggregation.max:
        return batch.map(valueOf).reduce((a, b) => a > b ? a : b);
    }
  }
}
