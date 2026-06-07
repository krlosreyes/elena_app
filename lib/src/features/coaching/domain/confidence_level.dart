// SPEC-194: nivel de evidencia de una recomendación, espejo de los niveles
// de IMR_BIBLIOGRAPHY. Alimenta el término `confidence` del scorer.
//
// Dart puro (CONSTITUTION §3.1) — sin Flutter, sin Riverpod.

enum ConfidenceLevel { high, medium, low, engineeringJudgment }

extension ConfidenceLevelWeight on ConfidenceLevel {
  /// Peso 0..1 usado por el scorer (SPEC-194 Anexo §2.3).
  double get weight => switch (this) {
        ConfidenceLevel.high => 1.0,
        ConfidenceLevel.medium => 0.7,
        ConfidenceLevel.low => 0.4,
        ConfidenceLevel.engineeringJudgment => 0.2,
      };
}
