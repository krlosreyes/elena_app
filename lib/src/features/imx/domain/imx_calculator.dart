import 'dart:math';

class ImxCalculator {
  // --- CAPA 1: BODY SCORE (B) ---
  // S1: Waist-to-Height Ratio (WHtR) - Óptimo ~0.45, Riesgo >0.5
  static double _calculateS1(double waistCm, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final ratio = waistCm / heightCm;
    // Normalization: 1.0 at 0.45, scales down as it moves away from 0.45
    // Usaremos una penalización lineal
    double score = 1.0 - ((ratio - 0.45).abs() / 0.15); 
    return score.clamp(0.0, 1.0);
  }

  // S2: Waist-to-Hip Ratio (WHR) - Óptimo <0.85 (Mujeres), <0.90 (Hombres)
  // Simplificado para ElenaApp, ideal general ~0.8
  static double _calculateS2(double waistCm, double hipCm) {
    if (hipCm <= 0) return 0.0;
    final ratio = waistCm / hipCm;
    double score = 1.0 - ((ratio - 0.8).abs() / 0.2);
    return score.clamp(0.0, 1.0);
  }

  // S3: Neck-to-Height Ratio - Indicador de apnea/resistencia insulina. Óptimo <0.5
  static double _calculateS3(double neckCm, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final ratio = neckCm / heightCm;
    double score = 1.0 - ((ratio - 0.5).abs() / 0.2);
    return score.clamp(0.0, 1.0);
  }

  // CORE BODY CALCULATION
  static double calculateBodyScore(double waistCm, double heightCm, double hipCm, double neckCm) {
    final s1 = _calculateS1(waistCm, heightCm);
    final s2 = _calculateS2(waistCm, hipCm);
    final s3 = _calculateS3(neckCm, heightCm);
    
    // Promedio ponderado o simple. Asumiremos simple para Capa B
    return (s1 + s2 + s3) / 3.0; // Resultado entre 0.0 y 1.0
  }

  // --- CAPA 2: METABOLIC SCORE (M) ---
  // S4: Fasting - Función Logística: 1 / (1 + e^-(F-14)/2)
  static double _calculateS4(double avgFastingHours) {
    // F=16 -> ~0.73, F=18 -> ~0.88, F=12 -> ~0.26
    return 1.0 / (1.0 + exp(-(avgFastingHours - 14.0) / 2.0));
  }

  // S5: Energy - Autoevaluación 0 a 10, normalizada a 0.0 - 1.0
  static double _calculateS5(int energyLevel1To10) {
    return (energyLevel1To10.clamp(0, 10)) / 10.0;
  }

  // CORE METABOLIC CALCULATION
  static double calculateMetabolicScore(double avgFastingHours, int energyLevel1To10) {
    final s4 = _calculateS4(avgFastingHours);
    final s5 = _calculateS5(energyLevel1To10);
    // M = 0.6 * S4 + 0.4 * S5 (Según el prompt)
    return (0.6 * s4) + (0.4 * s5); // Resultado entre 0.0 y 1.0
  }

  // --- CAPA 3: LIFESTYLE SCORE (H) ---
  // S6: Nutrición (0 a 100)
  static double _calculateS6(double nutritionAdherenceScore) {
    return (nutritionAdherenceScore.clamp(0.0, 100.0)) / 100.0;
  }

  // S7: Ejercicio (0 a 100)
  static double _calculateS7(double exerciseAdherenceScore) {
     return (exerciseAdherenceScore.clamp(0.0, 100.0)) / 100.0;
  }

  // S8: Sueño (0 a 24 horas)
  static double _calculateS8(double avgSleepHours) {
    // Óptimo ~7.5 a 8.5 horas
    double score = 1.0 - ((avgSleepHours - 8.0).abs() / 4.0);
    return score.clamp(0.0, 1.0);
  }

  // CORE LIFESTYLE CALCULATION
  static double calculateLifestyleScore(double nutritionScore, double exerciseScore, double sleepHours) {
    final s6 = _calculateS6(nutritionScore);
    final s7 = _calculateS7(exerciseScore);
    final s8 = _calculateS8(sleepHours);
    // H = 0.4 * S6 + 0.4 * S7 + 0.2 * S8
    return (0.4 * s6) + (0.4 * s7) + (0.2 * s8); // Resultado entre 0.0 y 1.0
  }

  // --- IMX MASTER CALCULATION ---
  static double calculateTotalIMX({
    required double waistCm,
    required double heightCm,
    required double hipCm,
    required double neckCm,
    required double avgFastingHours,
    required int energyLevel1To10,
    required double nutritionAdherenceScore,
    required double exerciseAdherenceScore,
    required double avgSleepHours,
  }) {
    final b = calculateBodyScore(waistCm, heightCm, hipCm, neckCm);
    final m = calculateMetabolicScore(avgFastingHours, energyLevel1To10);
    final h = calculateLifestyleScore(nutritionAdherenceScore, exerciseAdherenceScore, avgSleepHours);

    // IMX = 100 * (0.4 * B + 0.3 * M + 0.3 * H)
    double rawImx = 100.0 * ((0.4 * b) + (0.3 * m) + (0.3 * h));
    return rawImx.clamp(0.0, 100.0);
  }
}
