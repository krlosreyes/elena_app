/// SPEC-25: Calculador de Porcentaje de Grasa Corporal
/// Implementa fórmulas científicas validadas (US Navy)
/// El usuario NUNCA ingresa % grasa — siempre se calcula

import 'dart:math' as math;

class BodyFatCalculator {
  /// Calcula % grasa corporal usando la fórmula US Navy
  /// Para hombres: 86.010 × log10(C - N) - 70.041 × log10(A) + 36.76
  /// Para mujeres: Requiere cadera (no soportado aún — usar fórmula simplificada)
  static double calculateBodyFatPercentage({
    required double waistCm,
    required double neckCm,
    required double heightCm,
    required bool isMale,
  }) {
    // Validar que tenemos las medidas mínimas
    if (waistCm <= 0 || neckCm <= 0 || heightCm <= 0) {
      return 0.0; // Fallback: sin datos
    }

    if (isMale) {
      // Fórmula US Navy para hombres
      return _calculateMaleBodyFat(waistCm, neckCm, heightCm);
    } else {
      // Fórmula simplificada para mujeres (requeriría cadera para precisión)
      // Por ahora: aproximación basada en cintura/altura
      return _calculateFemaleBodyFat(waistCm, neckCm, heightCm);
    }
  }

  /// Fórmula US Navy para hombres
  /// % Grasa = 86.010 × log10(Cintura - Cuello) - 70.041 × log10(Altura) + 36.76
  static double _calculateMaleBodyFat(
      double waistCm, double neckCm, double heightCm) {
    final difference = waistCm - neckCm;

    // Evitar log de números <= 0
    if (difference <= 0 || heightCm <= 0) return 15.0; // Default masculino promedio

    final log10Difference = math.log(difference) / math.log(10);
    final log10Height = math.log(heightCm) / math.log(10);

    final bodyFat =
        86.010 * log10Difference - 70.041 * log10Height + 36.76;

    // Clamp a rangos realistas (2-60%)
    return bodyFat.clamp(2.0, 60.0);
  }

  /// Fórmula aproximada para mujeres (sin cadera)
  /// Nota: La fórmula US Navy oficial para mujeres requiere cadera
  /// Esta es una aproximación simplificada
  static double _calculateFemaleBodyFat(
      double waistCm, double neckCm, double heightCm) {
    // Aproximación basada en cintura/altura ratio
    final whtr = waistCm / heightCm;

    // Convertir WHTR a % grasa aproximado para mujeres
    // Rango típico: WHTR 0.40-0.55 → % grasa 20-35%
    if (whtr < 0.40) return 18.0;
    if (whtr < 0.45) return 22.0;
    if (whtr < 0.50) return 26.0;
    if (whtr < 0.55) return 30.0;
    if (whtr < 0.60) return 34.0;
    return 38.0;
  }

  /// Valida que el % calculado sea coherente con peso/altura
  static bool isCoherent({
    required double weight,
    required double height,
    required double calculatedBodyFatPct,
  }) {
    // Masa magra = peso × (1 - grasa%)
    final leanMass = weight * (1 - calculatedBodyFatPct / 100);

    // Validar que masa magra sea realista
    // Mínimo: ~20 kg (muy delgado)
    // Máximo: 95% del peso (con grasa esencial)
    if (leanMass < 20 || leanMass > weight * 0.95) {
      return false;
    }

    return true;
  }
}
