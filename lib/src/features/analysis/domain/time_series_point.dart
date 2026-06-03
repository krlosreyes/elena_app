// SPEC-162: punto de una serie temporal semanal.
//
// Pure Dart — sin Flutter ni Riverpod.

class TimeSeriesPoint {
  /// Inicio de la semana ISO (lunes) a la que pertenece este punto.
  final DateTime weekStart;

  /// Valor agregado de la métrica para esa semana.
  final double value;

  /// Cantidad de muestras subyacentes (logs/docs) que se agregaron.
  /// 0 indica semana sin data — el builder NO emite puntos así.
  final int sampleCount;

  const TimeSeriesPoint({
    required this.weekStart,
    required this.value,
    required this.sampleCount,
  });
}
