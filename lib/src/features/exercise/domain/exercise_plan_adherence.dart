// Propuesta módulo Ejercicio (2026-07-21), Fase 5: evalúa si lo que el
// usuario registró hoy coincide con lo que el plan programó.
//
// DECISIÓN DE ALCANCE (ver informe final de la sesión): esta función es
// una pieza pura y aditiva — NO está conectada todavía a
// `StreakEngine.evaluateExercise` ni a `StreakEntry` persistido. Cablear
// esto al sistema de racha real requiere tocar `StreakEntry`
// (freezed, con generación de código) y el pipeline de
// reconciliación que ya tuvo varias rondas de bugs delicados (ver
// memoria del proyecto — "auditoría racha", 3 rondas, "sistema
// coherente" pedido explícitamente por Carlos). Sin un compilador
// disponible en este entorno para verificar el cambio, cablear esta
// pieza al sistema de racha en producción sin poder correr
// `flutter test` es un riesgo que no vale la pena tomar a ciegas.
// Este archivo deja la lógica lista, testeada de forma aislada, para
// que se cablee en una sesión con toolchain disponible.

import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/weekly_exercise_plan.dart';

/// Nivel de cumplimiento del día contra el plan.
enum PlanAdherenceLevel {
  /// No había sesión programada (día de descanso) y no se registró
  /// nada — correcto.
  restHonored,

  /// Día de descanso pero el usuario igual entrenó — no es un
  /// incumplimiento, solo se marca para que la UI pueda reconocerlo
  /// (§4.4: "reconociendo cumplimiento parcial sin ser punitivo").
  restBrokenVoluntarily,

  /// El tipo registrado coincide con el tipo programado y la duración
  /// alcanza al menos el 80% de la sugerida.
  fullMatch,

  /// Se registró actividad pero de un tipo distinto al programado
  /// (p.ej. tocaba fuerza y se registró cardio).
  wrongType,

  /// El tipo coincide pero la duración quedó por debajo del 80% de la
  /// sugerida.
  partialDuration,

  /// Día con sesión programada y no se registró nada.
  missed,
}

class ExercisePlanAdherence {
  ExercisePlanAdherence._();

  /// Umbral de duración para considerar "cumplida" una sesión — mismo
  /// criterio de margen que el resto de StreakEngine (80%, ver
  /// `evaluateFasting`/`evaluateHydration`).
  static const double kDurationThreshold = 0.80;

  static PlanAdherenceLevel evaluate({
    required PlanDayEntry scheduled,
    required List<ExerciseLog> loggedToday,
  }) {
    final loggedMinutes =
        loggedToday.fold<int>(0, (sum, l) => sum + l.durationMinutes);

    if (scheduled.type == PlanSessionType.descanso) {
      return loggedMinutes > 0
          ? PlanAdherenceLevel.restBrokenVoluntarily
          : PlanAdherenceLevel.restHonored;
    }

    if (loggedToday.isEmpty || loggedMinutes == 0) {
      return PlanAdherenceLevel.missed;
    }

    final matchesType = loggedToday.any((l) => _matchesType(l, scheduled));
    if (!matchesType) {
      return PlanAdherenceLevel.wrongType;
    }

    final ratio = scheduled.durationMinutes > 0
        ? loggedMinutes / scheduled.durationMinutes
        : 1.0;
    return ratio >= kDurationThreshold
        ? PlanAdherenceLevel.fullMatch
        : PlanAdherenceLevel.partialDuration;
  }

  static bool _matchesType(ExerciseLog log, PlanDayEntry scheduled) {
    // Logs legacy sin `type` tipado: se da el beneficio de la duda
    // (no penalizar retroactivamente logs de antes de SPEC-68).
    if (log.type == null) return true;
    switch (scheduled.type) {
      case PlanSessionType.fuerza:
        return log.type == ExerciseType.strength;
      case PlanSessionType.cardio:
        return log.type == ExerciseType.liss || log.type == ExerciseType.hiit;
      case PlanSessionType.descanso:
        return true;
    }
  }
}
