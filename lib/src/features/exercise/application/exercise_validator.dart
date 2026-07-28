import 'package:elena_app/src/core/orchestrator/biological_phases.dart';

/// SPEC-01: Validador de transiciones de ejercicio (Tipado).
/// RF-34-02: Valida que el ejercicio sea seguro según estado metabólico.
class ExerciseValidator {
  /// Valida si es seguro hacer ejercicio del tipo y intensidad especificados.
  ///
  /// Retorna (esSeguro, razonSiNo)
  static (bool, String?) validateExercise({
    required OrchestratorFastingBand fastingPhase,
    required CircadianPhase circadianPhase,
    required double sleepQuality,
    required String? exerciseType,
    required int intensityPercent,
  }) {
    // Primero: verificar seguridad básica (Autofagia profunda + sueño malo)
    if (fastingPhase == OrchestratorFastingBand.autofagia &&
        sleepQuality < 0.4) {
      return (
        false,
        'No es seguro ejercitar ahora: Autofagia profunda con recuperación de sueño insuficiente (${(sleepQuality * 100).toStringAsFixed(0)}%)',
      );
    }

    // Fase de sueño circadiano -> no ejercitar
    if (circadianPhase == CircadianPhase.sueno) {
      return (
        false,
        'No es seguro ejercitar durante la fase de sueño circadiano.'
      );
    }

    // RF-34-02: Validar que HIIT no ocurre en Autofagia profunda
    if (fastingPhase == OrchestratorFastingBand.autofagia &&
        exerciseType == 'HIIT' &&
        intensityPercent > 70) {
      return (
        false,
        '⚠️  HIIT en Autofagia profunda (12+ h) es ALTO RIESGO de catabolismo muscular. '
            'Recomendado: LISS (<60%) o STRENGTH (<70%) en lugar de HIIT.',
      );
    }

    // Validar intensidad en Autofagia
    if (fastingPhase == OrchestratorFastingBand.autofagia &&
        intensityPercent > 75) {
      return (
        false,
        'Intensidad >75% en Autofagia es arriesgada. '
            'Máximo recomendado: 70% para evitar catabolismo.',
      );
    }

    // Validar sleep quality vs intensidad
    if (sleepQuality < 0.4 && intensityPercent > 70) {
      return (
        false,
        'Calidad de sueño baja (${(sleepQuality * 100).toStringAsFixed(0)}%). '
            'No es seguro ejercitar >70%. Recomendado LISS <50%.',
      );
    }

    return (true, null);
  }

  /// Calcula multiplicador de seguridad basado en fasting phase
  /// Valores sincronizados con OrchestratorEngine
  static double getExerciseSafetyMultiplier(
      OrchestratorFastingBand fastingPhase) {
    return switch (fastingPhase) {
      OrchestratorFastingBand.alerta => 1.0,
      OrchestratorFastingBand.gluconeogenesis => 0.95,
      OrchestratorFastingBand.cetosis => 0.85,
      OrchestratorFastingBand.autofagia => 0.6,
    };
  }
}
