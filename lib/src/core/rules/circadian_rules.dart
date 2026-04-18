import 'circadian_phase.dart';

/// Reglas lógicas del ciclo circadiano (Dart Puro - SPEC-10/DT-07)
class CircadianRules {
  static const int intestinalLockHour = 22;
  static const int intestinalLockMinute = 30;

  /// Definición maestra de las fases biológicas
  static const List<CircadianPhase> allPhases = [
    CircadianPhase(label: "SUEÑO", startHour: 22.5, endHour: 6.0),
    CircadianPhase(label: "ALERTA", startHour: 6.0, endHour: 9.0),
    CircadianPhase(label: "COGNITIVO", startHour: 9.0, endHour: 13.0),
    CircadianPhase(label: "RECESO", startHour: 13.0, endHour: 15.0),
    CircadianPhase(label: "MOTOR / FUERZA", startHour: 15.0, endHour: 20.0),
    CircadianPhase(label: "CREATIVIDAD", startHour: 20.0, endHour: 22.5),
  ];

  /// Determina si una fase específica está activa en este momento
  static bool isPhaseActive(CircadianPhase phase, DateTime now) {
    double current = now.hour + (now.minute / 60.0);
    if (phase.startHour < phase.endHour) {
      return current >= phase.startHour && current < phase.endHour;
    } else {
      // Caso que cruza la medianoche (Sueño)
      return current >= phase.startHour || current < phase.endHour;
    }
  }

  static String getPhaseName(DateTime time) {
    for (var phase in allPhases) {
      if (isPhaseActive(phase, time)) return phase.label;
    }
    return "REPARACIÓN";
  }

  static Duration timeUntilLock(DateTime now) {
    DateTime lock = DateTime(now.year, now.month, now.day, intestinalLockHour, intestinalLockMinute);
    if (now.isAfter(lock)) lock = lock.add(const Duration(days: 1));
    return lock.difference(now);
  }

  static bool isIntestinalLockActive(DateTime now) {
    double current = now.hour + (now.minute / 60.0);
    return (current >= 22.5 || current < 6.0);
  }
}