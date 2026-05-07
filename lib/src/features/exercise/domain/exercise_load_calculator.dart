// SPEC-68: ExerciseLoadCalculator — ponderación de carga de ejercicio.
//
// Antes (SPEC-03): la carga se calculaba como `(minutos / 60).clamp(0, 1.0)`
// — sin distinguir entre 60 min de yoga y 60 min de HIIT. La literatura
// ACSM hace décadas que esa equiparación es inválida fisiológicamente.
//
// Ahora: una matriz `tipo × intensidad → multiplicador` ajusta el peso
// según el estímulo metabólico real del ejercicio.
//
// Función pura. Sin Flutter, sin Riverpod, sin DateTime.now(). Testeable
// con valores sintéticos.

import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

class ExerciseLoadCalculator {
  ExerciseLoadCalculator._();

  /// Multiplicador por tipo. SPEC-70: ref IMR_BIBLIOGRAPHY.md §8.1.
  /// MEDIUM (LaForgia 2006: HIIT EPOC ~50% mayor que LISS).
  /// - HIIT genera mayor estímulo metabólico (EPOC, sensibilidad insulínica).
  /// - STRENGTH activa síntesis proteica muscular durante 24-48h.
  /// - MOBILITY tiene impacto metabólico bajo pero contribuye a recuperación.
  static const Map<ExerciseType, double> _typeMultiplier = {
    ExerciseType.liss: 1.0,
    ExerciseType.hiit: 1.5,
    ExerciseType.strength: 1.3,
    ExerciseType.mobility: 0.6,
  };

  /// Multiplicador por intensidad subjetiva.
  /// SPEC-70 §8.2 — ENGINEERING JUDGMENT (mismo principio dosis-respuesta
  /// que tipo, pero a nivel de RPE; asimetría conservadora 0.3 abajo/arriba).
  static const Map<ExerciseIntensity, double> _intensityMultiplier = {
    ExerciseIntensity.low: 0.7,
    ExerciseIntensity.moderate: 1.0,
    ExerciseIntensity.high: 1.3,
  };

  /// Calcula la carga normalizada (0.0–1.5) para una sesión individual.
  ///
  /// Fórmula:
  ///   load = (minutos / 60) × typeMultiplier × intensityMultiplier
  ///   clamp [0.0, 1.5] para que un solo entrenamiento intenso pueda
  ///   superar 1.0 sin sobrepasar el dominio razonable.
  ///
  /// Si `type` o `intensity` son null (logs legacy), usa multiplicador 1.0
  /// (equivalente al cálculo SPEC-03 anterior — backward compat).
  static double calculate({
    required int durationMinutes,
    ExerciseType? type,
    ExerciseIntensity? intensity,
  }) {
    if (durationMinutes <= 0) return 0.0;
    final base = durationMinutes / 60.0;
    final tMul = type != null ? _typeMultiplier[type]! : 1.0;
    final iMul = intensity != null ? _intensityMultiplier[intensity]! : 1.0;
    return (base * tMul * iMul).clamp(0.0, 1.5);
  }

  /// Suma las cargas de varios logs.
  static double sumDailyLoad(List<ExerciseLog> logs) {
    var total = 0.0;
    for (final log in logs) {
      total += calculate(
        durationMinutes: log.durationMinutes,
        type: log.type,
        intensity: log.intensity,
      );
    }
    return total.clamp(0.0, 2.0);
  }
}
