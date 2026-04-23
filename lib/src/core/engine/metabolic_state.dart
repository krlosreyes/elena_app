/// Snapshot completo del estado metabólico del usuario.
///
/// Contiene tanto valores normalizados (0.0–1.0) como valores crudos
/// necesarios para el ScoreEngine. Una sola clase, una sola fuente de verdad.
///
/// Flujo: Providers → MetabolicStateBuilder → MetabolicState → ScoreEngine
class MetabolicState {
  // ── Valores normalizados (0.0–1.0) ──────────────────────────────────────

  /// Horas de ayuno normalizadas via sigmoid: 1/(1+e^(-(h-14)/1.5))
  /// 0.0 = sin ayuno, ~0.5 = 14h, ~1.0 = 20h+
  final double fastingHours;

  /// Nivel de glucógeno estimado (inverso del progreso de ayuno).
  /// 1.0 = glucógeno lleno (recién comido), 0.0 = reservas agotadas.
  /// Derivado directamente de las horas de ayuno.
  final double glycogenLevel;

  /// Alineación circadiana: qué tan bien se alinea la última comida con el goal.
  /// 1.0 = dentro de ventana óptima, 0.0 = comida nocturna fuera de ventana.
  /// Calculado por el builder comparando lastMealTime vs lastMealGoal.
  final double circadianAlignment;

  /// Calidad del sueño normalizada.
  /// 0.0 = sin sueño, 1.0 = sueño óptimo (7-9h).
  /// Calculado por el builder desde las horas de sueño.
  final double sleepQuality;

  /// Carga de ejercicio normalizada.
  /// 0.0 = sin ejercicio, 1.0 = 60 min+.
  /// Calculado por el builder desde minutos de ejercicio.
  final double exerciseLoad;

  /// Carga glucémica / calidad nutricional normalizada.
  /// 0.0 = sin comidas, 1.0 = adherencia perfecta.
  /// Calculado por el builder: 60% adherencia comidas + 40% ventana.
  final double glycemicLoad;

  /// Nivel de hidratación normalizado.
  /// 0.0 = sin hidratación, 1.0 = goal alcanzado.
  /// Calculado por el builder desde litros actuales / goal.
  final double hydrationLevel;

  /// Coherencia metabólica: sincronización inter-pilar.
  /// 0.0 = pilares descoordinados, 1.0 = sincronización perfecta.
  /// Calculado por el builder desde los datos de todos los pilares.
  final double metabolicCoherence;

  // ── Valores crudos (para ScoreEngine) ───────────────────────────────────

  /// Horas reales de ayuno (e.g., 16.5)
  final double fastingHoursRaw;

  /// Horas reales de sueño (e.g., 7.5)
  final double sleepHoursRaw;

  /// Minutos reales de ejercicio hoy (e.g., 45)
  final double exerciseMinutesRaw;

  /// Score nutricional base (0-1) del NutritionNotifier.
  /// Se pasa al ScoreEngine como nutritionScore.
  final double nutritionScoreRaw;

  /// Adherencia semanal (0-1) pre-calculada por StreakEngine.
  final double weeklyAdherence;

  /// DateTime estable de la última comida.
  final DateTime lastMealTime;

  /// Timestamp de la última actualización del estado.
  final DateTime timestamp;

  const MetabolicState({
    required this.fastingHours,
    required this.glycogenLevel,
    required this.circadianAlignment,
    required this.sleepQuality,
    required this.exerciseLoad,
    required this.glycemicLoad,
    required this.hydrationLevel,
    required this.metabolicCoherence,
    required this.fastingHoursRaw,
    required this.sleepHoursRaw,
    required this.exerciseMinutesRaw,
    required this.nutritionScoreRaw,
    required this.weeklyAdherence,
    required this.lastMealTime,
    required this.timestamp,
  });

  /// Factory para estado inicial (sin datos).
  factory MetabolicState.empty() => MetabolicState(
        fastingHours: 0.0,
        glycogenLevel: 1.0,
        circadianAlignment: 0.5,
        sleepQuality: 0.0,
        exerciseLoad: 0.0,
        glycemicLoad: 0.0,
        hydrationLevel: 0.0,
        metabolicCoherence: 0.8,
        fastingHoursRaw: 0.0,
        sleepHoursRaw: 0.0,
        exerciseMinutesRaw: 0.0,
        nutritionScoreRaw: 0.0,
        weeklyAdherence: 0.0,
        lastMealTime: DateTime.now(),
        timestamp: DateTime.now(),
      );

  /// Score promedio de los pilares normalizados (utilidad para dashboards).
  double get overallScore =>
      (fastingHours +
          (1.0 - glycogenLevel) +
          circadianAlignment +
          sleepQuality +
          exerciseLoad +
          glycemicLoad +
          hydrationLevel +
          metabolicCoherence) /
      8.0;

  /// true si al menos un pilar tiene datos reales.
  bool get isComplete =>
      fastingHoursRaw > 0 ||
      sleepHoursRaw > 0 ||
      exerciseMinutesRaw > 0 ||
      nutritionScoreRaw > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetabolicState &&
          fastingHours == other.fastingHours &&
          glycogenLevel == other.glycogenLevel &&
          circadianAlignment == other.circadianAlignment &&
          sleepQuality == other.sleepQuality &&
          exerciseLoad == other.exerciseLoad &&
          glycemicLoad == other.glycemicLoad &&
          hydrationLevel == other.hydrationLevel &&
          metabolicCoherence == other.metabolicCoherence &&
          fastingHoursRaw == other.fastingHoursRaw &&
          sleepHoursRaw == other.sleepHoursRaw &&
          exerciseMinutesRaw == other.exerciseMinutesRaw;

  @override
  int get hashCode => Object.hash(
        fastingHours,
        glycogenLevel,
        circadianAlignment,
        sleepQuality,
        exerciseLoad,
        glycemicLoad,
        hydrationLevel,
        metabolicCoherence,
        fastingHoursRaw,
        sleepHoursRaw,
        exerciseMinutesRaw,
      );

  @override
  String toString() =>
      'MetabolicState(fasting: ${fastingHours.toStringAsFixed(2)}, '
      'glycogen: ${glycogenLevel.toStringAsFixed(2)}, '
      'circadian: ${circadianAlignment.toStringAsFixed(2)}, '
      'sleep: ${sleepQuality.toStringAsFixed(2)}, '
      'exercise: ${exerciseLoad.toStringAsFixed(2)}, '
      'glycemic: ${glycemicLoad.toStringAsFixed(2)}, '
      'hydration: ${hydrationLevel.toStringAsFixed(2)}, '
      'coherence: ${metabolicCoherence.toStringAsFixed(2)})';
}
