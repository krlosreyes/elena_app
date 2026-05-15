// SPEC-92: helper puro para recalcular `bodyFatPercentage` cuando el
// usuario edita una medida biométrica individual (peso, cintura, cuello).
//
// No tiene dependencias de Flutter ni de Firebase. Es 100% testeable.
// La lógica está encapsulada para que el mismo flow se pueda invocar
// desde el Profile (edición individual) y desde otros editores que
// puedan aparecer en el futuro (ej. un setup-wizard rápido).

import 'package:elena_app/src/features/profile/domain/body_fat_calculator.dart';

/// Resultado del recálculo. `isCoherent == false` significa que los
/// inputs (cintura ≤ cuello, valores fuera de rango, etc.) no permiten
/// calcular un % grasa creíble — el caller debe **conservar** el
/// `bodyFatPercentage` previo en vez de sobreescribirlo.
class BiometryRecalcResult {
  /// % grasa nuevo. `null` si no había suficientes datos para calcular
  /// (ej. waist o neck ausentes). En ese caso, el caller persiste solo
  /// el campo editado y deja `bodyFatPercentage` como estaba.
  final double? bodyFatPercentage;

  /// Confianza derivada del cálculo:
  ///   'ALTA'  — cálculo coherente con todas las medidas presentes.
  ///   'MEDIA' — cálculo posible pero fuera del rango coherente con peso.
  ///   'BAJA'  — sin datos suficientes; valor null o fallback poblacional.
  final String confidenceLevel;

  /// True si el nuevo % grasa pasa el check de `isCoherent` contra peso.
  /// Cuando es false, **el caller no debe sobreescribir** bodyFat — solo
  /// persistir el campo editado y mostrar feedback al usuario.
  final bool isCoherent;

  const BiometryRecalcResult({
    required this.bodyFatPercentage,
    required this.confidenceLevel,
    required this.isCoherent,
  });
}

class BiometryRecalc {
  BiometryRecalc._();

  /// Recalcula `bodyFatPercentage` a partir de las medidas efectivas
  /// post-edición. Devuelve un [BiometryRecalcResult] que el caller
  /// usa para decidir si persiste el nuevo bodyFat o lo conserva.
  ///
  /// Reglas:
  /// - Si `waistCm` o `neckCm` son null → no se puede calcular →
  ///   `bodyFatPercentage = null`, confidence 'BAJA', isCoherent false.
  /// - Si la fórmula US Navy retorna 0 (datos inválidos) → mismo caso.
  /// - Si el resultado falla `isCoherent` contra el peso → confidence
  ///   'MEDIA' y `isCoherent = false`. El caller decide si sobreescribir.
  /// - Si todo OK → confidence 'ALTA', `isCoherent = true`.
  ///
  /// Importante: el parámetro `gender` se acepta como String para
  /// alinearse con `UserModel.gender` (que ya es String 'M' / 'F' /
  /// 'Otro'). Cualquier valor distinto de 'M' (case-insensitive) se
  /// trata como femenino para el cálculo.
  static BiometryRecalcResult recompute({
    required double weightKg,
    required double heightCm,
    required double? waistCm,
    required double? neckCm,
    required String gender,
  }) {
    // Sin medidas mínimas no hay cálculo posible.
    if (waistCm == null || neckCm == null) {
      return const BiometryRecalcResult(
        bodyFatPercentage: null,
        confidenceLevel: 'BAJA',
        isCoherent: false,
      );
    }

    final bool isMale = gender.toUpperCase() == 'M';

    final double bodyFat = BodyFatCalculator.calculateBodyFatPercentage(
      waistCm: waistCm,
      neckCm: neckCm,
      heightCm: heightCm,
      isMale: isMale,
    );

    // La fórmula puede devolver 0.0 cuando las medidas son inválidas
    // (negativos, ceros). Tratamos eso como "no calculable".
    if (bodyFat <= 0) {
      return const BiometryRecalcResult(
        bodyFatPercentage: null,
        confidenceLevel: 'BAJA',
        isCoherent: false,
      );
    }

    final bool coherent = BodyFatCalculator.isCoherent(
      weight: weightKg,
      height: heightCm,
      calculatedBodyFatPct: bodyFat,
    );

    return BiometryRecalcResult(
      bodyFatPercentage: bodyFat,
      confidenceLevel: coherent ? 'ALTA' : 'MEDIA',
      isCoherent: coherent,
    );
  }
}
