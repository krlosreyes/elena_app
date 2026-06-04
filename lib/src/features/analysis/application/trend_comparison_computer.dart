// SPEC-168.5 (2026-06-03): computa la comparación entre el promedio
// reciente (corto) y el promedio total (largo) de una MetricSeries.
//
// Funciones puras — sin Riverpod ni Flutter.

import 'dart:math' as math;

import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/domain/trend_comparison.dart';

class TrendComparisonComputer {
  TrendComparisonComputer._();

  /// Devuelve la comparación corto vs largo de la serie. Null cuando:
  /// - No hay 4+ buckets con datos (poco contexto para tendencia).
  /// - El short window calculado < 2.
  ///
  /// El short window es ~33% del rango con tope por modo:
  ///   daily   → max 7 buckets (última semana)
  ///   weekly  → max 4 buckets (último mes)
  ///   monthly → max 3 buckets (último trimestre)
  static TrendComparison? compute({
    required MetricSeries series,
    required AggregationMode mode,
    required String betterIf,
  }) {
    final filled = series.points.where((p) => p.sampleCount > 0).toList();
    if (filled.length < 4) return null;

    final shortK = _shortWindowSize(filled.length, mode);
    if (shortK < 2) return null;

    final shortBuckets = filled.sublist(filled.length - shortK);
    final shortAvg = _avg(shortBuckets.map((p) => p.value));
    final longAvg = _avg(filled.map((p) => p.value));

    return TrendComparison(
      shortAvg: shortAvg,
      longAvg: longAvg,
      shortWindow: shortK,
      longWindow: filled.length,
      betterIf: betterIf,
    );
  }

  static int _shortWindowSize(int n, AggregationMode mode) {
    final third = n ~/ 3;
    switch (mode) {
      case AggregationMode.daily:
        return math.min(7, third);
      case AggregationMode.weekly:
        return math.min(4, third);
      case AggregationMode.monthly:
        return math.min(3, third);
    }
  }

  static double _avg(Iterable<double> xs) {
    if (xs.isEmpty) return 0.0;
    return xs.reduce((a, b) => a + b) / xs.length;
  }
}
