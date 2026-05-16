import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elena_app/src/core/converters/timestamp_converter.dart';

part 'exercise_log.freezed.dart';
part 'exercise_log.g.dart';

/// Tipo de ejercicio (SPEC-68). Categorías estándar de la literatura
/// del fitness (ACSM Guidelines): cada una tiene curvas de respuesta
/// metabólica distintas que el ScoreEngine pondera diferente.
enum ExerciseType {
  /// Low Intensity Steady State — caminata, trote suave, ciclismo recreativo.
  liss,

  /// High Intensity Interval Training — sprints, Tabata, etc.
  hiit,

  /// Entrenamiento de fuerza — pesas, calistenia.
  strength,

  /// Movilidad / flexibilidad — yoga, stretching, foam rolling.
  mobility,
}

/// Intensidad subjetiva categórica. Complementa al `rpe` numérico.
enum ExerciseIntensity {
  low,
  moderate,
  high,
}

@freezed
class ExerciseLog with _$ExerciseLog {
  const factory ExerciseLog({
    required String id,
    required String userId,
    required int durationMinutes,

    /// Etiqueta libre legacy (SPEC-03). Se mantiene para retrocompatibilidad
    /// con logs antiguos. SPEC-68 introduce `type` como enum tipado.
    required String activityType,
    @TimestampConverter() required DateTime timestamp,
    @Default(1.0) double intensityMultiplier,

    // ── SPEC-68: tipificación del ejercicio ─────────────────────────────

    /// Tipo de ejercicio según categorías ACSM. `null` para logs legacy
    /// que no tienen el dato; el ScoreEngine usa un multiplicador neutral.
    ExerciseType? type,

    /// Intensidad subjetiva categórica. `null` para logs legacy.
    ExerciseIntensity? intensity,

    /// Rate of Perceived Exertion (1-10, escala Borg modificada).
    /// `null` si el usuario no lo registró. Solo valores en [1, 10].
    int? rpe,

    /// Frecuencia cardíaca promedio durante la sesión, en bpm.
    /// `null` si no se midió. Debe ser >= 30 si presente.
    int? heartRateAvg,
  }) = _ExerciseLog;

  factory ExerciseLog.fromJson(Map<String, dynamic> json) =>
      _$ExerciseLogFromJson(json);
}
