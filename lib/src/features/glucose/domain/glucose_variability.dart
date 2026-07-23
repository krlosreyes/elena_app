// Módulo "Tu Glucosa" — variabilidad glucémica (propuesta §2.5 y
// §12.2). Fuente: Monnier et al., Diabetes Care 2017 — coeficiente de
// variación (%CV) ≥36% separa glucemia estable de inestable, umbral
// adoptado por el consenso internacional de uso de CGM.
//
// Función pura, sin dependencias — testeable con listas sintéticas.

import 'dart:math' as math;

class GlucoseVariabilityResult {
  final double standardDeviation;

  /// Coeficiente de variación en porcentaje (SD / media × 100).
  final double coefficientOfVariationPercent;

  /// true si %CV ≥ 36% (Monnier et al. 2017) — "tu glucosa varía más de
  /// lo habitual". Nunca se presenta como alerta aislada: debe ir
  /// siempre acompañado del mecanismo probable que identifique
  /// GlucoseInsightEngine (propuesta §12.2).
  final bool isHighVariability;

  /// Cantidad de lecturas usadas en el cálculo — regla R8: con menos de
  /// 7 no se calcula (ver `GlucoseVariability.compute`).
  final int sampleSize;

  const GlucoseVariabilityResult({
    required this.standardDeviation,
    required this.coefficientOfVariationPercent,
    required this.isHighVariability,
    required this.sampleSize,
  });

  /// Estado "sin suficientes datos" — R8.
  static const insufficientData = GlucoseVariabilityResult(
    standardDeviation: 0,
    coefficientOfVariationPercent: 0,
    isHighVariability: false,
    sampleSize: 0,
  );

  bool get hasEnoughData => sampleSize >= GlucoseVariability.kMinSampleSize;
}

class GlucoseVariability {
  GlucoseVariability._();

  /// Umbral de Monnier et al., Diabetes Care 2017 (propuesta §2.5).
  static const double kHighVariabilityThresholdPercent = 36.0;

  /// R8: mínimo de lecturas para que el cálculo de variabilidad tenga
  /// sentido estadístico mínimo — evita reportar "alta variabilidad"
  /// con 2-3 datos sueltos.
  static const int kMinSampleSize = 7;

  /// Calcula SD y %CV sobre una lista de valores de glucosa (mg/dL),
  /// típicamente los últimos 14 días de lecturas en el mismo contexto
  /// (ayunas) para no mezclar poblaciones distintas de valores.
  static GlucoseVariabilityResult compute(List<int> valuesMgDl) {
    if (valuesMgDl.length < kMinSampleSize) {
      return GlucoseVariabilityResult.insufficientData;
    }
    final mean = valuesMgDl.reduce((a, b) => a + b) / valuesMgDl.length;
    if (mean <= 0) return GlucoseVariabilityResult.insufficientData;

    final variance = valuesMgDl
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        valuesMgDl.length;
    final sd = math.sqrt(variance);
    final cv = (sd / mean) * 100;

    return GlucoseVariabilityResult(
      standardDeviation: sd,
      coefficientOfVariationPercent: cv,
      isHighVariability: cv >= kHighVariabilityThresholdPercent,
      sampleSize: valuesMgDl.length,
    );
  }
}
