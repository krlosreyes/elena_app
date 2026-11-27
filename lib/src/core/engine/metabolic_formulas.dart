// SPEC-306: fórmulas metabólicas canónicas, idénticas a las del sitio
// metamorfosisvital.com.co (src/lib/imr/engine.ts, motor spec-118-v1, y
// src/lib/calculators/bodyComposition.ts).
//
// Regla: si cambia una fórmula aquí, cambia también en el sitio. Los dos
// repositorios prueban contra el mismo archivo de casos
// (test/fixtures/metabolic_cases.json en la app,
//  src/lib/imr/fixtures/metabolic_cases.json en el sitio).
//
// Dart puro: sin Flutter ni Firebase.

import 'dart:math' as math;

/// Versión del motor. Igual a `ENGINE_VERSION` del sitio.
const String kMetabolicEngineVersion = 'spec-118-v1';

double _log10(double x) => math.log(x) / math.ln10;

class MetabolicFormulas {
  MetabolicFormulas._();

  /// % de grasa corporal por la fórmula US Navy en su versión métrica
  /// (medidas en centímetros). Hodgdon & Beckett 1984, informes 84-11 y
  /// 84-29.
  ///
  ///   Hombres: 495 / (1.0324 − 0.19077·log10(cintura − cuello)
  ///                   + 0.15456·log10(estatura)) − 450
  ///   Mujeres: 495 / (1.29579 − 0.35004·log10(cintura + cadera − cuello)
  ///                   + 0.22100·log10(estatura)) − 450
  ///
  /// En mujeres la cadera es obligatoria: sin ella devuelve null. No se
  /// estima, porque una cadera estimada (p. ej. cintura × 1,05) da valores
  /// irreales en mujeres delgadas (2 % para 170 cm / cintura 60).
  /// Devuelve null si las medidas no permiten calcular.
  static double? bodyFatNavy({
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double? hipCm,
    required bool isMale,
  }) {
    if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return null;
    final double density;
    if (isMale) {
      if (waistCm - neckCm <= 0) return null;
      density = 1.0324 -
          0.19077 * _log10(math.max(1, waistCm - neckCm)) +
          0.15456 * _log10(heightCm);
    } else {
      if (hipCm == null || hipCm <= 0) return null;
      final double hip = hipCm;
      if (waistCm + hip - neckCm <= 0) return null;
      density = 1.29579 -
          0.35004 * _log10(math.max(1, waistCm + hip - neckCm)) +
          0.22100 * _log10(heightCm);
    }
    if (density <= 0) return null;
    return math.max(2.0, 495 / density - 450);
  }

  /// True si a esta persona le falta la cadera para poder calcular.
  static bool needsHip({required bool isMale, double? hipCm}) =>
      !isMale && (hipCm == null || hipCm <= 0);

  /// Centro del rango "fitness" del ACSM por edad y sexo. Referencia de
  /// la edad metabólica (igual que `referenceBodyFatPct` del sitio).
  static double referenceBodyFatPct(int age, bool isMale) {
    if (isMale) {
      if (age < 30) return 14;
      if (age < 40) return 17;
      if (age < 50) return 20;
      if (age < 60) return 22;
      return 24;
    }
    if (age < 30) return 22;
    if (age < 40) return 24;
    if (age < 50) return 27;
    if (age < 60) return 29;
    return 31;
  }

  /// Edad metabólica, método del sitio:
  ///   edad + (grasa − referencia) + 0,6 × max(0, IMC − 22),
  ///   limitada a 18–80 años.
  static int metabolicAge({
    required int age,
    required double weightKg,
    required double heightCm,
    required double bodyFatPct,
    required bool isMale,
  }) {
    final double heightM = heightCm / 100;
    final double bmi = weightKg / (heightM * heightM);
    final double deltaBf = bodyFatPct - referenceBodyFatPct(age, isMale);
    final double deltaBmi = math.max(0, bmi - 22);
    final double offset = deltaBf * 1.0 + deltaBmi * 0.6;
    return (age + offset).round().clamp(18, 80);
  }

  /// Tasa metabólica en reposo, Mifflin-St Jeor (kcal/día).
  static double bmrMifflin({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) =>
      10 * weightKg + 6.25 * heightCm - 5 * age + (isMale ? 5 : -161);

  /// Índice cintura-estatura (ICE).
  static double whtr(double waistCm, double heightCm) =>
      heightCm > 0 ? waistCm / heightCm : 0;

  /// Categoría del ICE según NICE NG246 (igual que la calculadora del
  /// sitio): bajo < 0,40 ≤ saludable < 0,50 ≤ aumentado < 0,60 ≤ alto.
  static WhtrCategory whtrCategory(double whtr) {
    if (whtr >= 0.60) return WhtrCategory.alto;
    if (whtr >= 0.50) return WhtrCategory.aumentado;
    if (whtr >= 0.40) return WhtrCategory.saludable;
    return WhtrCategory.bajo;
  }

  /// Categoría de grasa corporal según el American Council on Exercise
  /// (mismos cortes que el sitio).
  ///   Hombres: <6 esencial, <14 atletas, <18 fitness, <25 promedio, ≥25 obesidad.
  ///   Mujeres: <14 esencial, <21 atletas, <25 fitness, <32 promedio, ≥32 obesidad.
  static FatCategory fatCategory(double bodyFatPct, bool isMale) {
    final List<double> cuts = isMale ? [6, 14, 18, 25] : [14, 21, 25, 32];
    if (bodyFatPct >= cuts[3]) return FatCategory.obesidad;
    if (bodyFatPct >= cuts[2]) return FatCategory.promedio;
    if (bodyFatPct >= cuts[1]) return FatCategory.fitness;
    if (bodyFatPct >= cuts[0]) return FatCategory.atletas;
    return FatCategory.esencial;
  }
}

enum WhtrCategory {
  bajo('Por debajo de 0,40'),
  saludable('Saludable'),
  aumentado('Riesgo aumentado'),
  alto('Riesgo alto');

  const WhtrCategory(this.label);
  final String label;
}

enum FatCategory {
  esencial('Esencial'),
  atletas('Atletas'),
  fitness('Fitness'),
  promedio('Promedio'),
  obesidad('Obesidad');

  const FatCategory(this.label);
  final String label;
}
