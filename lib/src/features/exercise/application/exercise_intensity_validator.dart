import 'package:elena_app/src/core/orchestrator/biological_phases.dart';

/// SPEC-01/37: Validador de intensidad de ejercicio (Tipado)
/// Utiliza el motor orquestador central para validaciones coherentes
class ExerciseIntensityValidator {
  /// Categoriza intensidad en tipos de ejercicio
  /// RF-37-01: <40% = LISS, 40-70% = STRENGTH, >70% = HIIT
  static String categorizeIntensity(int intensityPercent) {
    if (intensityPercent < 40) {
      return 'LISS';
    } else if (intensityPercent < 70) {
      return 'STRENGTH';
    } else {
      return 'HIIT';
    }
  }

  /// Obtiene descripción de intensidad
  static String getIntensityExplanation(int intensityPercent) {
    if (intensityPercent < 40) {
      return 'Baja intensidad, conversacional. Ideal para recuperación.';
    } else if (intensityPercent < 70) {
      return 'Intensidad moderada. Esfuerzo pero sostenible.';
    } else {
      return 'Alta intensidad. Máximo esfuerzo, corta duración.';
    }
  }

  /// RF-37-04: Calcula carga metabólica
  /// Fórmula: (intensidad% × duración) / 30
  static double calculateMetabolicLoad({
    required int intensityPercent,
    required int durationMinutes,
  }) {
    return (intensityPercent * durationMinutes) / 3000;
  }

  /// Estima frecuencia cardíaca basada en intensidad
  /// Fórmula simplificada: (% × 140) + 60
  static int estimateHeartRate(int intensityPercent) {
    return ((intensityPercent / 100) * 140 + 60).toInt();
  }

  /// Valida sensatez de intensidad propuesta
  static String? validateIntensitySanity({
    required int intensityPercent,
    required int durationMinutes,
  }) {
    final metabolicLoad = calculateMetabolicLoad(
      intensityPercent: intensityPercent,
      durationMinutes: durationMinutes,
    );

    if (metabolicLoad > 3.0 && durationMinutes > 60) {
      return 'Carga muy alta (${metabolicLoad.toStringAsFixed(2)}/3.0). '
          'A esta intensidad, máximo 60 minutos para evitar sobreentrenamiento.';
    }

    if (intensityPercent == 0 && durationMinutes > 0) {
      return 'Intensidad 0% no tiene sentido. ¿Descansaste en vez de entrenar?';
    }

    return null;
  }

  /// RF-37-02/03: Valida intensidad contra estado metabólico (SPEC-01)
  /// Retorna (isSafe, warningMessage)
  static (bool isSafe, String? warning) validateIntensityAgainstMetabolicState({
    required int intensityPercent,
    required FastingPhase currentFastingPhase,
    required CircadianPhase currentCircadianPhase,
    required double sleepQuality,
    required int durationMinutes,
  }) {
    final String exerciseType = categorizeIntensity(intensityPercent);
    
    // Regla 1: No ejercitar en AUTOFAGIA con sueño deficiente
    if (currentFastingPhase == FastingPhase.autofagia && sleepQuality < 0.4) {
      return (
        true, // Permitir pero advertir
        '⚠️  CRÍTICO: No es seguro ejercitar ahora. '
            'Estás en Autofagia con recuperación ${(sleepQuality * 100).toStringAsFixed(0)}%. '
            'Riesgo catabolismo muscular.'
      );
    }

    // Regla 2: No HIIT en AUTOFAGIA (fase de ayuno profundo)
    if (currentFastingPhase == FastingPhase.autofagia && exerciseType == 'HIIT') {
      return (
        true, // Permitir pero advertir fuerte
        '🚨 CRÍTICO: HIIT en Autofagia es muy riesgoso. '
            'Estás en ayuno profundo - el cortisol está alto y el glucógeno bajo. '
            'Recomendado: LISS o STRENGTH al 50-60%.'
      );
    }

    // Regla 3: No ejercicio intenso en SUEÑO (noche)
    if (currentCircadianPhase == CircadianPhase.sueno && intensityPercent > 60) {
      return (
        true,
        '⚠️  Fase de SUEÑO es mala para ejercicio intenso. '
            'Afecta calidad de sueño. Considera LISS al 35% máximo.'
      );
    }

    // Regla 4: Sobrecarga con sueño deficiente
    if (sleepQuality < 0.4 && intensityPercent > 70) {
      return (
        true,
        '⚠️  Recovery muy bajo (${(sleepQuality * 100).toStringAsFixed(0)}%). '
            'No recomendado HIIT. Máximo STRENGTH al 55%.'
      );
    }

    // Regla 5: Validación de duración según intensidad
    final metabolicLoad = calculateMetabolicLoad(
      intensityPercent: intensityPercent,
      durationMinutes: durationMinutes,
    );
    if (metabolicLoad > 2.5 && durationMinutes > 45) {
      return (
        true,
        '⚠️  Duración muy larga para esta intensidad (carga: ${metabolicLoad.toStringAsFixed(2)}). '
            'Reduce a 45 minutos máximo.'
      );
    }

    return (true, null);
  }

  /// RF-37-03: Recomendación óptima de intensidad basada en SPEC-01
  static (int, String, String) recommendOptimalIntensity({
    required FastingPhase currentFastingPhase,
    required CircadianPhase currentCircadianPhase,
    required double sleepQuality,
  }) {
    // Lógica sincronizada con OrchestratorEngine
    String recommendedType;
    int recommendedIntensity;

    if (sleepQuality < 0.4) {
      recommendedType = 'LISS';
      recommendedIntensity = 35;
    } else if (currentFastingPhase == FastingPhase.autofagia) {
      recommendedType = sleepQuality > 0.6 ? 'STRENGTH' : 'LISS';
      recommendedIntensity = 50;
    } else {
      switch (currentCircadianPhase) {
        case CircadianPhase.alerta:
          recommendedType = 'STRENGTH';
          recommendedIntensity = 75;
          break;
        case CircadianPhase.cognitivo:
          recommendedType = 'HIIT';
          recommendedIntensity = 80;
          break;
        case CircadianPhase.receso:
          recommendedType = 'LISS';
          recommendedIntensity = 55;
          break;
        case CircadianPhase.motorFuerza:
          recommendedType = 'STRENGTH';
          recommendedIntensity = 85;
          break;
        case CircadianPhase.creatividad:
          recommendedType = 'LISS';
          recommendedIntensity = 40;
          break;
        case CircadianPhase.sueno:
        default:
          recommendedType = 'LISS';
          recommendedIntensity = 20;
          break;
      }
    }

    String reasoning = _getReasoning(
      fastingPhase: currentFastingPhase,
      circadianPhase: currentCircadianPhase,
      sleepQuality: sleepQuality,
      recommendedType: recommendedType,
    );

    return (recommendedIntensity, recommendedType, reasoning);
  }

  /// Genera explicación de por qué se recomienda esta intensidad
  static String _getReasoning({
    required FastingPhase fastingPhase,
    required CircadianPhase circadianPhase,
    required double sleepQuality,
    required String? recommendedType,
  }) {
    if (sleepQuality < 0.4) {
      return 'Recuperación baja. Solo LISS para no estresar el sistema.';
    }

    if (fastingPhase == FastingPhase.autofagia) {
      return 'En Autofagia profunda. Evita catabolismo muscular con LISS/STRENGTH moderado.';
    }

    switch (circadianPhase) {
      case CircadianPhase.alerta:
        return 'Pico de cortisol matutino. Ideal para STRENGTH y construcción muscular.';
      case CircadianPhase.cognitivo:
        return 'Máxima alerta cognitiva y energía. Óptimo para HIIT de corta duración.';
      case CircadianPhase.receso:
        return 'Ventana de reposo post-prandial. LISS ligero para asistir digestión.';
      case CircadianPhase.motorFuerza:
        return 'Pico de fuerza y coordinación muscular. Ideal para STRENGTH intenso.';
      case CircadianPhase.creatividad:
        return 'Descenso de temperatura central. LISS moderado para preparar el sueño.';
      case CircadianPhase.sueno:
        return 'Fase de reparación biológica. Mínima intensidad recomendada.';
      default:
        return 'Basado en tu ritmo circadiano y fase de ayuno.';
    }
  }

  /// Multiplicador de seguridad (Sincronizado SPEC-01)
  static double getExerciseSafetyMultiplier(FastingPhase fastingPhase) {
    return switch (fastingPhase) {
      FastingPhase.alerta => 1.0,
      FastingPhase.gluconeogenesis => 0.95,
      FastingPhase.cetosis => 0.85,
      FastingPhase.autofagia => 0.6,
    };
  }

  /// Verifica si el ejercicio propuesto es compatible con ayuno actual
  static bool isCompatibleWithCurrentFasting({
    required FastingPhase fastingPhase,
    required int intensityPercent,
    required int durationMinutes,
  }) {
    final metabolicLoad = calculateMetabolicLoad(
      intensityPercent: intensityPercent,
      durationMinutes: durationMinutes,
    );

    // En AUTOFAGIA profunda, limita carga metabólica
    if (fastingPhase == FastingPhase.autofagia && metabolicLoad > 1.5) {
      return false;
    }

    return true;
  }
}
