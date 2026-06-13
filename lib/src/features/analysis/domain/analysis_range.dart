// SPEC-162: rango temporal del análisis. Selector global.
//
// Pure Dart.

enum AnalysisRange {
  w1,
  m1,
  m3,
  m6,
  y1;

  /// Días desde hoy hacia atrás.
  int get daysFromToday {
    switch (this) {
      case AnalysisRange.w1:
        return 7;
      case AnalysisRange.m1:
        return 30;
      case AnalysisRange.m3:
        return 90;
      case AnalysisRange.m6:
        return 180;
      case AnalysisRange.y1:
        return 365;
    }
  }

  String get label {
    switch (this) {
      case AnalysisRange.w1:
        return 'Semana';
      case AnalysisRange.m1:
        return 'Mes';
      case AnalysisRange.m3:
        return '3M';
      case AnalysisRange.m6:
        return '6M';
      case AnalysisRange.y1:
        return '1A';
    }
  }

  String get periodLabel {
    switch (this) {
      case AnalysisRange.w1:
        return 'Última semana';
      case AnalysisRange.m1:
        return 'Último mes';
      case AnalysisRange.m3:
        return 'Últimos 3 meses';
      case AnalysisRange.m6:
        return 'Últimos 6 meses';
      case AnalysisRange.y1:
        return 'Último año';
    }
  }
}
