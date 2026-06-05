// SPEC-171 §RF-171-01 (2026-06-04): cómputo puro del Score del Día
// para el ciclo metabólico abierto.
//
// Aplica los pesos rebalanceados de SPEC-140 (sleep 25%, fasting 22%,
// exercise 20%, nutrition 18%, hydration 15%) — los mismos que usa
// StreakEntry.dailyQualityScore — pero sobre las magnitudes en vivo
// del ciclo abierto, no sobre el snapshot persistido en daily_summary.
//
// Función pura sin Riverpod/Flutter — testeable sin ProviderContainer.
//
// El llamador (displayDailyScoreProvider en daily_score_provider.dart)
// se encarga de leer las magnitudes de los providers cycle-aware
// (SPEC-149.2) y pasárnoslas. Si una magnitud es null, se renormaliza
// el resto (mismo comportamiento que SPEC-140).
//
// Fundamento bibliográfico: IMR_BIBLIOGRAPHY.md §6 (peso del Score del
// Día) + §13 (Día Metabólico).

class CycleScoreComputer {
  CycleScoreComputer._();

  // Pesos canónicos SPEC-140 (suman 1.00).
  static const double _wSleep = 0.25;
  static const double _wFasting = 0.22;
  static const double _wExercise = 0.20;
  static const double _wNutrition = 0.18;
  static const double _wHydration = 0.15;

  /// Computa el score 0-100 a partir de las magnitudes del ciclo.
  ///
  /// Magnitudes null se omiten y los pesos restantes se renormalizan,
  /// igual que `StreakEntry.dailyQualityScore`. Magnitudes fuera del
  /// rango [0, 1] se clampean. Si TODAS son null, retorna 0 (caller
  /// debería fallback al provider legacy en ese caso).
  static int compute({
    double? fastingMagnitude,
    double? sleepQualityScore,
    double? hydrationMagnitude,
    double? exerciseMagnitude,
    double? nutritionMagnitude,
  }) {
    double weightedSum = 0.0;
    double totalWeight = 0.0;

    void add(double? mag, double w) {
      if (mag == null) return;
      weightedSum += w * mag.clamp(0.0, 1.0);
      totalWeight += w;
    }

    add(fastingMagnitude, _wFasting);
    add(sleepQualityScore, _wSleep);
    add(hydrationMagnitude, _wHydration);
    add(exerciseMagnitude, _wExercise);
    add(nutritionMagnitude, _wNutrition);

    if (totalWeight == 0.0) return 0;
    final raw = (weightedSum / totalWeight).clamp(0.0, 1.0);
    return (raw * 100).round();
  }
}
