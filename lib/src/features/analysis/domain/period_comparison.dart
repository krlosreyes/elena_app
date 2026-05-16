// SPEC-113: value object con la comparación de un período contra el
// anterior. Sin dependencias de Flutter — testeable 100%.

class PeriodComparison {
  /// IMR promedio del período actual (0 si no hay docs).
  final int imrAverage;

  /// IMR promedio del período anterior. `null` si no hay data del
  /// período comparable (usuario nuevo).
  final int? imrAveragePrevious;

  /// SPEC-118: IMR del día de HOY. `null` si HOY aún no tiene doc
  /// (caso poco común gracias al merge con state LIVE en analysis_screen).
  /// Permite al hero card mostrar "HOY vs PROMEDIO" simultáneamente.
  final int? imrToday;

  /// IMR del mejor día del período actual. `null` si no hay docs.
  final int? bestDayImr;
  final DateTime? bestDayDate;

  /// IMR del peor día del período actual. `null` si no hay docs.
  final int? worstDayImr;
  final DateTime? worstDayDate;

  /// Cantidad de días con data dentro del período.
  final int daysWithData;

  /// Duración total del período en días.
  final int daysInPeriod;

  const PeriodComparison({
    required this.imrAverage,
    required this.imrAveragePrevious,
    required this.imrToday,
    required this.bestDayImr,
    required this.bestDayDate,
    required this.worstDayImr,
    required this.worstDayDate,
    required this.daysWithData,
    required this.daysInPeriod,
  });

  /// Estado vacío para placeholders.
  const PeriodComparison.empty(this.daysInPeriod)
      : imrAverage = 0,
        imrAveragePrevious = null,
        imrToday = null,
        bestDayImr = null,
        bestDayDate = null,
        worstDayImr = null,
        worstDayDate = null,
        daysWithData = 0;

  /// Diferencia respecto al período anterior. `null` si no hay
  /// comparación disponible.
  int? get delta => imrAveragePrevious != null
      ? imrAverage - imrAveragePrevious!
      : null;

  /// Diferencia entre HOY y el promedio del período. Permite
  /// comunicar "tu día va mejor/peor que tu promedio". `null` si no
  /// hay IMR de HOY o el promedio es 0.
  int? get todayVsAverage =>
      imrToday != null && imrAverage > 0 ? imrToday! - imrAverage : null;
}
