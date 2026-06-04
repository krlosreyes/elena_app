// SPEC-168.5 (2026-06-03): comparación de dos promedios (corto vs
// largo) para la sección "Tendencias" de Análisis.
//
// Patrón Apple Health: "En promedio, bajaste de peso en los últimos
// 6 días" muestra dos líneas — un promedio largo (toda la ventana) y
// un promedio corto (últimos N buckets). El usuario ve evolución
// reciente sin tener que comparar mentalmente.
//
// Pure Dart — sin Flutter ni Riverpod.

class TrendComparison {
  /// Promedio del subconjunto reciente (últimos `shortWindow` buckets).
  final double shortAvg;

  /// Promedio del rango completo (`longWindow` buckets).
  final double longAvg;

  /// Cuántos buckets reciente cubren el promedio corto.
  final int shortWindow;

  /// Cuántos buckets totales cubren el promedio largo.
  final int longWindow;

  /// Dirección "deseable" de la métrica: 'up' o 'down'.
  /// Peso: 'down'. IMR / hidratación / ejercicio: 'up'.
  final String betterIf;

  const TrendComparison({
    required this.shortAvg,
    required this.longAvg,
    required this.shortWindow,
    required this.longWindow,
    required this.betterIf,
  });

  /// Diferencia signed: positiva si el corto subió respecto al largo.
  double get diff => shortAvg - longAvg;

  /// True si la diferencia es despreciable (< 1% del promedio largo).
  /// Sin este umbral las tendencias serían ruidosas y dispararían
  /// copy alarmista para cambios irrelevantes.
  bool get isStable {
    if (longAvg.abs() < 0.001) return diff.abs() < 0.01;
    return diff.abs() < longAvg.abs() * 0.01;
  }

  /// True cuando el cambio reciente va en la dirección deseable.
  /// Útil para colorear o decidir el tono del copy.
  bool get isImprovement {
    if (isStable) return false;
    return betterIf == 'up' ? diff > 0 : diff < 0;
  }
}
