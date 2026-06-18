// SPEC-162: agregador semanal genérico.
//
// ⚠️ DEPRECATED — SPEC-230 (2026-06-18): reemplazado por TemporalAggregator
// que soporta daily/weekly/monthly con timezone correcto. Ningún caller
// activo usa esta clase. Mantenida temporalmente por si hay tests legacy.
//
// Toma una colección de items con fecha asociada y los agrupa por
// semana ISO (lunes-domingo). Soporta múltiples modos de agregación.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';

enum WeeklyAggregation {
  /// Suma de los valores de la semana.
  sum,

  /// Promedio aritmético de los valores.
  avg,

  /// Conteo de items en la semana (ignora valor).
  count,

  /// Último valor de la semana (por timestamp).
  last,

  /// Máximo valor de la semana.
  max,
}

class WeeklyAggregator {
  WeeklyAggregator._();

  /// Agrupa [items] por semana ISO y aplica [aggregation].
  ///
  /// - `timestampOf`: extrae el timestamp del item.
  /// - `valueOf`: extrae el valor numérico (ignorado para `count`).
  /// - `weeksToShow`: si se provee, limita a las últimas N semanas con data.
  ///
  /// Retorna puntos ordenados ascendente por `weekStart`. Las semanas
  /// sin items NO se emiten (no se rellena con 0).
  static List<TimeSeriesPoint> aggregate<T>({
    required Iterable<T> items,
    required DateTime Function(T) timestampOf,
    required double Function(T) valueOf,
    required WeeklyAggregation aggregation,
    int? weeksToShow,
  }) {
    if (items.isEmpty) return const [];

    // Agrupar por inicio de semana ISO (lunes 00:00 local).
    final byWeek = <DateTime, List<T>>{};
    for (final item in items) {
      final ts = timestampOf(item);
      final weekStart = _startOfIsoWeek(ts);
      byWeek.putIfAbsent(weekStart, () => []).add(item);
    }

    final entries = byWeek.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final points = <TimeSeriesPoint>[];
    for (final entry in entries) {
      final weekStart = entry.key;
      final weekItems = entry.value;
      final value = _aggregateBatch(weekItems, valueOf, timestampOf, aggregation);
      points.add(TimeSeriesPoint(
        weekStart: weekStart,
        value: value,
        sampleCount: weekItems.length,
      ));
    }

    if (weeksToShow != null && points.length > weeksToShow) {
      return points.sublist(points.length - weeksToShow);
    }
    return points;
  }

  /// Inicio del lunes de la semana ISO de [date], hora 00:00:00 local.
  /// SPEC-230 BUG-F: toLocal() defensivo (Firestore timestamps son UTC).
  static DateTime _startOfIsoWeek(DateTime date) {
    final local = date.toLocal();
    // weekday: lunes=1, ..., domingo=7.
    final daysSinceMonday = local.weekday - 1;
    final monday = DateTime(local.year, local.month, local.day)
        .subtract(Duration(days: daysSinceMonday));
    return monday;
  }

  static double _aggregateBatch<T>(
    List<T> batch,
    double Function(T) valueOf,
    DateTime Function(T) timestampOf,
    WeeklyAggregation aggregation,
  ) {
    switch (aggregation) {
      case WeeklyAggregation.sum:
        return batch.fold<double>(0, (acc, item) => acc + valueOf(item));
      case WeeklyAggregation.avg:
        final sum =
            batch.fold<double>(0, (acc, item) => acc + valueOf(item));
        return sum / batch.length;
      case WeeklyAggregation.count:
        return batch.length.toDouble();
      case WeeklyAggregation.last:
        final sorted = [...batch]
          ..sort((a, b) => timestampOf(a).compareTo(timestampOf(b)));
        return valueOf(sorted.last);
      case WeeklyAggregation.max:
        return batch
            .map(valueOf)
            .reduce((a, b) => a > b ? a : b);
    }
  }
}
