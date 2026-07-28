// SPEC-168.1 (2026-06-03): cómputo del valor del hero y el rango de
// fechas, a partir de una MetricSeries.
//
// Funciones puras — sin Riverpod ni Flutter. Cada chart card las usa
// para producir el bloque hero arriba del gráfico.

import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';

class ChartHeroComputer {
  ChartHeroComputer._();

  /// Calcula el valor del hero a partir de los buckets de la serie,
  /// aplicando la agregación elegida.
  /// Si no hay buckets, devuelve null.
  static double? aggregateValue(MetricSeries series, HeroAggregation mode) {
    if (series.points.isEmpty) return null;
    final values = series.points
        .where((p) => p.sampleCount > 0)
        .map((p) => p.value)
        .toList();
    if (values.isEmpty) return null;
    switch (mode) {
      case HeroAggregation.avg:
        final sum = values.fold<double>(0, (a, b) => a + b);
        return sum / values.length;
      case HeroAggregation.sum:
        return values.fold<double>(0, (a, b) => a + b);
      case HeroAggregation.last:
        return values.last;
      case HeroAggregation.max:
        return values.reduce((a, b) => a > b ? a : b);
    }
  }

  /// Formatea el valor para mostrar en el hero. Sin decimales si es
  /// entero o ≥ 100; un decimal si es fraccional pequeño.
  static String formatValue(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  /// Rango de fechas humanizado a partir del primer y último bucket
  /// de la serie, según el modo de agregación temporal.
  ///
  /// Ejemplos:
  ///   daily, < 14 días → "7 a 13 jun. de 2026"
  ///   daily, ≥ 14     → "may. a jun. de 2026"
  ///   weekly          → idem usando weekStart de extremos
  ///   monthly         → "jul. de 2025 a jun. de 2026"
  ///
  /// Si la serie tiene un solo bucket, devuelve solo ese bucket en su
  /// forma corta (ej. "7 jun. de 2026" o "jun. de 2026").
  static String formatDateRange(MetricSeries series, AggregationMode mode) {
    if (series.points.isEmpty) return '';
    final first = series.points.first.weekStart;
    final last = series.points.last.weekStart;

    if (first == last) {
      switch (mode) {
        case AggregationMode.monthly:
          return _monthYearShort(first);
        default:
          return '${first.day} ${_monthShort(first)}. de ${first.year}';
      }
    }

    switch (mode) {
      case AggregationMode.monthly:
        if (first.year == last.year) {
          return '${_monthShort(first)}. a ${_monthShort(last)}. de ${first.year}';
        }
        return '${_monthYearShort(first)} a ${_monthYearShort(last)}';
      case AggregationMode.daily:
      case AggregationMode.weekly:
        final spanDays = last.difference(first).inDays;
        if (spanDays > 60) {
          // > 2 meses: solo mes y año.
          if (first.year == last.year) {
            return '${_monthShort(first)}. a ${_monthShort(last)}. de ${first.year}';
          }
          return '${_monthYearShort(first)} a ${_monthYearShort(last)}';
        }
        // Mismo mes → "7 a 13 jun. de 2026".
        if (first.month == last.month && first.year == last.year) {
          return '${first.day} a ${last.day} ${_monthShort(first)}. de ${first.year}';
        }
        // Cross-mes → "28 jun. al 5 jul. de 2026".
        if (first.year == last.year) {
          return '${first.day} ${_monthShort(first)}. al '
              '${last.day} ${_monthShort(last)}. de ${first.year}';
        }
        // Cross-año (raro pero defensivo).
        return '${first.day} ${_monthShort(first)}. de ${first.year} al '
            '${last.day} ${_monthShort(last)}. de ${last.year}';
    }
  }

  /// SPEC-168.3 (2026-06-03): cuenta cuántos buckets de la serie
  /// cumplieron el target (value >= target). Retorna null si `target`
  /// es null o la serie no tiene buckets con datos. Buckets vacíos
  /// (`sampleCount == 0`) no cuentan ni como cumplidos ni en el
  /// denominador.
  static ({int achieved, int total})? computeAchievement(
    MetricSeries series,
    double? target,
  ) {
    if (target == null) return null;
    final filled = series.points.where((p) => p.sampleCount > 0).toList();
    if (filled.isEmpty) return null;
    final achieved = filled.where((p) => p.value >= target).length;
    return (achieved: achieved, total: filled.length);
  }

  /// SPEC-168.3: formato humano del achievement según el modo temporal.
  /// "12 de 30 días", "8 de 13 sem", "3 de 6 meses".
  static String formatAchievementLabel(
    int achieved,
    int total,
    AggregationMode mode,
  ) {
    switch (mode) {
      case AggregationMode.daily:
        return total == 1
            ? '$achieved de $total día'
            : '$achieved de $total días';
      case AggregationMode.weekly:
        return '$achieved de $total sem';
      case AggregationMode.monthly:
        return total == 1
            ? '$achieved de $total mes'
            : '$achieved de $total meses';
    }
  }

  /// SPEC-168.7 (2026-06-04): formato corto para el tooltip de un
  /// bucket al hacer tap. Daily → "5 jun. de 2026", weekly → "Sem del
  /// 5 jun.", monthly → "jun. de 2026".
  static String formatTooltipDate(DateTime weekStart, AggregationMode mode) {
    final ms = _monthsShort[weekStart.month - 1];
    switch (mode) {
      case AggregationMode.daily:
        return '${weekStart.day} $ms. de ${weekStart.year}';
      case AggregationMode.weekly:
        return 'Sem del ${weekStart.day} $ms.';
      case AggregationMode.monthly:
        return '$ms. de ${weekStart.year}';
    }
  }

  static const _monthsShort = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String _monthShort(DateTime d) => _monthsShort[d.month - 1];

  static String _monthYearShort(DateTime d) =>
      '${_monthShort(d)}. de ${d.year}';
}
