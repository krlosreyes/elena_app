// SPEC-162: serie temporal de una métrica + metadata para presentación.
//
// Pure Dart.

import 'package:elena_app/src/features/analysis/domain/time_series_point.dart';

class MetricSeries {
  /// Label visible (ej. "IMR", "Peso", "Ayuno").
  final String label;

  /// Unidad para acompañar valores en UI (ej. "kg", "%", "d/sem").
  /// Vacío para métricas adimensionales.
  final String unit;

  /// Puntos ordenados ascendentemente por weekStart. Vacío si no hay
  /// data en el rango.
  final List<TimeSeriesPoint> points;

  const MetricSeries({
    required this.label,
    required this.unit,
    required this.points,
  });

  factory MetricSeries.empty({required String label, required String unit}) {
    return MetricSeries(label: label, unit: unit, points: const []);
  }

  bool get isEmpty => points.isEmpty;

  /// Valor del primer punto del rango. Null si vacío.
  double? get initialValue => points.isEmpty ? null : points.first.value;

  /// Valor del último punto del rango. Null si vacío.
  double? get currentValue => points.isEmpty ? null : points.last.value;

  /// Delta `currentValue - initialValue`. Null si vacío.
  double? get delta {
    if (points.length < 2) return null;
    return points.last.value - points.first.value;
  }

  /// Valor mínimo de la serie. Útil para escalar sparkline.
  double get minValue {
    if (points.isEmpty) return 0;
    return points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }

  /// Valor máximo de la serie.
  double get maxValue {
    if (points.isEmpty) return 0;
    return points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }
}
