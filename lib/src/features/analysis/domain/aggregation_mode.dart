// SPEC-164: modo de agregación temporal del análisis.
//
// Pure Dart.

import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';

enum AggregationMode {
  daily,
  weekly,
  monthly;

  /// Decide el modo de agregación según el rango seleccionado.
  /// Patrón Apple Fitness: ventanas cortas usan buckets finos,
  /// ventanas largas usan buckets gruesos.
  static AggregationMode forRange(AnalysisRange range) {
    switch (range) {
      case AnalysisRange.d30:
        return AggregationMode.daily;
      case AnalysisRange.m3:
      case AnalysisRange.m6:
        return AggregationMode.weekly;
      case AnalysisRange.y1:
      case AnalysisRange.all:
        return AggregationMode.monthly;
    }
  }
}
