// SPEC-162: rango temporal del análisis. Selector global.
//
// Pure Dart.

enum AnalysisRange {
  d30,
  m3,
  m6,
  y1,
  all;

  /// Días desde hoy hacia atrás. `null` para `all` (sin límite).
  int? get daysFromToday {
    switch (this) {
      case AnalysisRange.d30:
        return 30;
      case AnalysisRange.m3:
        return 90;
      case AnalysisRange.m6:
        return 180;
      case AnalysisRange.y1:
        return 365;
      case AnalysisRange.all:
        return null;
    }
  }

  String get label {
    switch (this) {
      case AnalysisRange.d30:
        return '30d';
      case AnalysisRange.m3:
        return '3m';
      case AnalysisRange.m6:
        return '6m';
      case AnalysisRange.y1:
        return '1a';
      case AnalysisRange.all:
        return 'Todo';
    }
  }
}
