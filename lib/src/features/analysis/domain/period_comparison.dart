// SPEC-113: value object con la comparación de un período contra el
// anterior. Sin dependencias de Flutter — testeable 100%.

class PeriodComparison {
  /// IMR promedio del período actual (0 si no hay docs).
  final int imrAverage;

  /// IMR promedio del período anterior. `null` si no hay data del
  /// período comparable (usuario nuevo).
  final int? imrAveragePrevious;

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
}
