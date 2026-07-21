// Propuesta módulo Ejercicio (2026-07-21), Fase 5: cálculo puro del
// horario sugerido para el recordatorio de la sesión programada del
// día — listo para que `NotificationScheduler` lo consuma.
//
// DECISIÓN DE ALCANCE (ver informe final de la sesión): esta pieza es
// intencionalmente pura y NO se conectó a `NotificationScheduler` /
// `NotificationIds` en esta sesión. Ese registro de IDs es compartido
// entre `notification_service_mobile.dart` y
// `notification_service_web.dart` y no hay compilador disponible en
// este entorno para verificar que un ID nuevo no colisione ni que el
// build de ambas plataformas siga pasando. Wire-up sugerido para una
// sesión con toolchain: agregar `NotificationIds.exercisePlan = 800` en
// ambos archivos y un `NotificationScheduler.scheduleExercisePlanReminder`
// siguiendo el mismo patrón que `scheduleHydrationReminders`.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';

class ExercisePlanReminder {
  ExercisePlanReminder._();

  /// Hora de inicio (24h) de la ventana recomendada de cada fase —
  /// misma tabla que el comentario de `CircadianPhase` en
  /// `biological_phases.dart` y que
  /// `WeeklyPlanSplitCard._phaseWindowLabel`.
  static const Map<CircadianPhase, int> _phaseStartHour = {
    CircadianPhase.alerta: 6,
    CircadianPhase.cognitivo: 9,
    CircadianPhase.receso: 13,
    CircadianPhase.motorFuerza: 15,
    CircadianPhase.creatividad: 20,
    CircadianPhase.sueno: 22,
  };

  /// Devuelve el `DateTime` (mismo día que `day`) al inicio de la
  /// ventana recomendada para `phase`. `null` si `phase` es `sueno`
  /// (no se agenda recordatorio de ejercicio en fase de sueño).
  static DateTime? suggestedTimeFor(CircadianPhase phase, DateTime day) {
    if (phase == CircadianPhase.sueno) return null;
    final hour = _phaseStartHour[phase]!;
    return DateTime(day.year, day.month, day.day, hour);
  }
}
