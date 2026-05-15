// SPEC-110: value object puro que agrega el "estado del día" del usuario
// para la pantalla Análisis. Sin dependencias de Flutter ni Firebase.
//
// Combina el IMR del día con el % de progreso por cada uno de los 5
// pilares. La capa de presentación pinta anillos a partir de estos
// valores.

class DailySummary {
  /// IMR del día (0..100).
  final int imrScore;

  /// Progreso del pilar Ayuno (0.0..1.0).
  final double fastingProgress;

  /// Progreso del pilar Sueño (0.0..1.0).
  final double sleepProgress;

  /// Progreso del pilar Hidratación (0.0..1.0).
  final double hydrationProgress;

  /// Progreso del pilar Ejercicio (0.0..1.0).
  final double exerciseProgress;

  /// Progreso del pilar Comidas (0.0..1.0).
  final double mealsProgress;

  const DailySummary({
    required this.imrScore,
    required this.fastingProgress,
    required this.sleepProgress,
    required this.hydrationProgress,
    required this.exerciseProgress,
    required this.mealsProgress,
  });

  /// Resultado vacío para placeholders y cargas iniciales.
  const DailySummary.empty()
      : imrScore = 0,
        fastingProgress = 0,
        sleepProgress = 0,
        hydrationProgress = 0,
        exerciseProgress = 0,
        mealsProgress = 0;

  /// Constructor con clamp para garantizar 0..1 en cada pilar.
  factory DailySummary.compute({
    required int imrScore,
    required double fastingProgress,
    required double sleepProgress,
    required double hydrationProgress,
    required double exerciseProgress,
    required double mealsProgress,
  }) {
    return DailySummary(
      imrScore: imrScore.clamp(0, 100),
      fastingProgress: fastingProgress.clamp(0.0, 1.0),
      sleepProgress: sleepProgress.clamp(0.0, 1.0),
      hydrationProgress: hydrationProgress.clamp(0.0, 1.0),
      exerciseProgress: exerciseProgress.clamp(0.0, 1.0),
      mealsProgress: mealsProgress.clamp(0.0, 1.0),
    );
  }

  /// True si los 5 pilares están al ≥80% — el día está "alineado".
  bool get isFullDay =>
      fastingProgress >= 0.8 &&
      sleepProgress >= 0.8 &&
      hydrationProgress >= 0.8 &&
      exerciseProgress >= 0.8 &&
      mealsProgress >= 0.8;
}
