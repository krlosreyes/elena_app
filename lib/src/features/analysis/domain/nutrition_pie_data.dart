// SPEC-168.5.4 (2026-06-03): distribución A-dominante vs E-dominante
// de las comidas del rango, para el pie chart de Nutrición en Análisis.
//
// El BarChart de % por día comunicaba progreso temporal, pero Carlos
// quiere que la home muestre de un golpe "qué tan saludable comí en
// este período" — un pie de 2 sectores. La evolución temporal (barras
// bicolor por día) se mueve a la pantalla de Tendencias.
//
// Pure Dart — sin Flutter ni Riverpod.

class NutritionPieData {
  /// Comidas marcadas A-dominantes según `MealRatio.isADominant`.
  /// Incluye Todo A, 3 a 1, 2 a 1.
  final int aDominantCount;

  /// Comidas no A-dominantes: 1 a 1, Todo E.
  final int eDominantCount;

  const NutritionPieData({
    required this.aDominantCount,
    required this.eDominantCount,
  });

  static const empty = NutritionPieData(aDominantCount: 0, eDominantCount: 0);

  int get total => aDominantCount + eDominantCount;

  /// Porcentaje 0–100 de comidas A-dominantes. 0 si no hay registros.
  double get aPct => total == 0 ? 0.0 : (aDominantCount * 100.0 / total);

  bool get isEmpty => total == 0;
}
