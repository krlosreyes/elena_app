/// SPEC-25 / SPEC-306: % de grasa corporal.
///
/// Desde SPEC-306 delega en [MetabolicFormulas.bodyFatNavy], la misma
/// fórmula que usa metamorfosisvital.com.co (US Navy métrica, motor
/// spec-118-v1). Antes:
///   - hombres: coeficientes de la versión en pulgadas aplicados a
///     centímetros (sobrestimaba ~6 puntos);
///   - mujeres: una tabla fija por índice cintura-estatura que no era la
///     fórmula Navy aunque la app la citara.
/// El usuario NUNCA ingresa % grasa: siempre se calcula.
library;

import 'package:elena_app/src/core/engine/metabolic_formulas.dart';

class BodyFatCalculator {
  /// % grasa por US Navy métrica. Devuelve 0.0 si las medidas no
  /// permiten calcular (los callers tratan 0 como "sin dato").
  ///
  /// [hipCm] es obligatorio en mujeres: sin cadera devuelve 0.0 (sin
  /// dato) en lugar de inventar un valor.
  static double calculateBodyFatPercentage({
    required double waistCm,
    required double neckCm,
    required double heightCm,
    required bool isMale,
    double? hipCm,
  }) {
    final double? bf = MetabolicFormulas.bodyFatNavy(
      heightCm: heightCm,
      waistCm: waistCm,
      neckCm: neckCm,
      hipCm: hipCm,
      isMale: isMale,
    );
    if (bf == null) return 0.0;
    return bf.clamp(2.0, 60.0);
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
