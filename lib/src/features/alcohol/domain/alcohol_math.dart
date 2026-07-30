// SPEC-261: matemática pura del alcohol.
//
// Fuente única de verdad para convertir cualquier bebida a su costo
// metabólico verificable. Todo aquí es determinístico y sin efectos:
// no toca Firestore, ni reloj (recibe el tiempo por parámetro), ni
// estado. Eso lo hace 100% testeable y reusable desde el notifier, el
// mapper y la UI sin duplicar fórmulas.
//
// Fundamento científico (ver Protocolo_Consumo_Consciente_Elena.docx §2):
//   - Densidad del etanol: 0,789 g/ml.
//   - Unidad Estándar de Alcohol (UEA), OMS/AUDIT: 10 g de alcohol puro.
//   - Eliminación hepática (cinética de orden cero): ~0,10 g de alcohol
//     por kg de peso por hora (≈ 7 g/h a 70 kg; rango 0,09–0,11).
//   - Widmark: factor de distribución r ≈ 0,68 (hombre) / 0,55 (mujer),
//     porque el alcohol se reparte en el agua corporal.
//
// La estimación de alcoholemia (BAC) es SOLO orientativa. Nunca debe
// usarse para decidir si conducir.
library;

/// Sexo biológico usado solo para el factor de distribución de Widmark.
enum WidmarkSex { male, female }

/// Utilidades de cálculo del alcohol. Clase no instanciable: todo estático.
abstract final class AlcoholMath {
  /// Densidad del etanol en g/ml.
  static const double ethanolDensity = 0.789;

  /// 1 Unidad Estándar de Alcohol (OMS/AUDIT) = 10 g de alcohol puro.
  static const double gramsPerStandardUnit = 10.0;

  /// Tasa de eliminación por kg de peso por hora (g·kg⁻¹·h⁻¹).
  static const double eliminationPerKgPerHour = 0.10;

  /// Peso de referencia (kg) cuando no se conoce el del usuario.
  static const double referenceWeightKg = 70.0;

  /// Factor de distribución de Widmark por sexo biológico.
  static double widmarkR(WidmarkSex sex) =>
      sex == WidmarkSex.male ? 0.68 : 0.55;

  /// Gramos de alcohol puro en una servida.
  ///
  /// `volumeMl` en mililitros, `abv` como fracción (0,40 = 40 %).
  /// Devuelve 0 para entradas no positivas (defensivo).
  static double gramsOfAlcohol({
    required double volumeMl,
    required double abv,
  }) {
    if (volumeMl <= 0 || abv <= 0) return 0;
    return volumeMl * abv * ethanolDensity;
  }

  /// Convierte gramos de alcohol a Unidades Estándar de Alcohol (UEA).
  static double standardUnits(double grams) {
    if (grams <= 0) return 0;
    return grams / gramsPerStandardUnit;
  }

  /// Tasa de eliminación (g/h) para un peso dado. Nunca menor que la de
  /// referencia mínima para evitar divisiones absurdas con pesos ~0.
  static double eliminationRatePerHour(double weightKg) {
    final w = weightKg > 0 ? weightKg : referenceWeightKg;
    return eliminationPerKgPerHour * w;
  }

  /// Horas que tarda el cuerpo en metabolizar `grams` de alcohol.
  ///
  /// Cinética de orden cero: tiempo = gramos / tasa. No se acelera con
  /// café, agua ni comida (la comida solo ralentiza la absorción, no la
  /// eliminación).
  static double hoursToMetabolize({
    required double grams,
    double weightKg = referenceWeightKg,
  }) {
    if (grams <= 0) return 0;
    return grams / eliminationRatePerHour(weightKg);
  }

  /// Alcoholemia estimada (g/L) por el modelo de Widmark, `hoursElapsed`
  /// después de ingerir `grams`. Orientativa; nunca baja de 0.
  ///
  /// BAC = grams / (r · pesoKg) − β · t, con β = 0,15 g/L/h (equivalente
  /// clínico de la tasa de eliminación expresada en g/L de sangre).
  static double estimatedBac({
    required double grams,
    required double weightKg,
    required WidmarkSex sex,
    required double hoursElapsed,
  }) {
    final w = weightKg > 0 ? weightKg : referenceWeightKg;
    if (grams <= 0) return 0;
    const bacEliminationPerHour = 0.15; // g/L por hora
    final peak = grams / (widmarkR(sex) * w);
    final elapsed = hoursElapsed > 0 ? hoursElapsed : 0;
    final bac = peak - bacEliminationPerHour * elapsed;
    return bac > 0 ? bac : 0;
  }

  /// Formatea una duración en horas como "2 h 8 min" / "45 min".
  static String formatHours(double hours) {
    if (hours <= 0) return '0 min';
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h <= 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }
}
