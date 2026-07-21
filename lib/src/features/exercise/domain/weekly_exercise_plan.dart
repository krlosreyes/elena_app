// Propuesta módulo Ejercicio (2026-07-21), Fase 2: estructura del plan
// semanal de 6 días de fuerza+cardio + 1 de descanso. Salida de
// WeeklyExercisePlanEngine — ver
// application/weekly_exercise_plan_engine.dart.
//
// Clase plana (sin freezed) — mismo criterio que ExerciseProfile: este
// repo no tiene toolchain de codegen disponible en el entorno donde se
// escribió este archivo.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';

/// Tipo de sesión de un día del plan.
enum PlanSessionType { fuerza, cardio, descanso }

extension PlanSessionTypeLabel on PlanSessionType {
  String get label {
    switch (this) {
      case PlanSessionType.fuerza:
        return 'Fuerza';
      case PlanSessionType.cardio:
        return 'Cardio';
      case PlanSessionType.descanso:
        return 'Descanso';
    }
  }
}

/// Sub-tipo de intensidad de cardio. `baja` = LISS/zona 2 (caminar,
/// bici suave); `alta` = HIIT/intervalos. Solo aplica cuando
/// `PlanDayEntry.type == PlanSessionType.cardio`.
enum CardioIntensity { baja, alta }

extension CardioIntensityLabel on CardioIntensity {
  String get label => this == CardioIntensity.alta ? 'HIIT' : 'LISS / zona 2';
}

/// Una entrada del plan de 7 días.
class PlanDayEntry {
  /// 1 = lunes … 7 = domingo (ISO 8601 weekday).
  final int weekday;
  final PlanSessionType type;
  final int durationMinutes;

  /// Solo relevante si `type == cardio`.
  final CardioIntensity? cardioIntensity;

  /// Fase circadiana sugerida para esta sesión (§4.3 de la propuesta):
  /// fuerza → motorFuerza (15-20h, coincide con el pico de fuerza
  /// máxima de la evidencia revisada); cardio alta → cognitivo (9-13h);
  /// cardio baja → receso. `null` en descanso.
  final CircadianPhase? recommendedPhase;

  /// Justificación corta reusable en la UI (una línea).
  final String rationale;

  const PlanDayEntry({
    required this.weekday,
    required this.type,
    required this.durationMinutes,
    required this.cardioIntensity,
    required this.recommendedPhase,
    required this.rationale,
  });

  static const List<String> _weekdayShort = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom',
  ];

  String get weekdayShortLabel => _weekdayShort[(weekday - 1).clamp(0, 6)];
}

/// El plan semanal completo — siempre 7 `PlanDayEntry`, ordenados de
/// lunes (weekday=1) a domingo (weekday=7).
class WeeklyExercisePlan {
  final List<PlanDayEntry> days;

  /// Etiqueta de la zona ACSM usada para generar el plan (p.ej. "Alto",
  /// "Promedio") — solo para trazabilidad/debug en UI.
  final String zoneLabel;
  final DateTime generatedAt;

  const WeeklyExercisePlan({
    required this.days,
    required this.zoneLabel,
    required this.generatedAt,
  });

  int get fuerzaCount =>
      days.where((d) => d.type == PlanSessionType.fuerza).length;
  int get cardioCount =>
      days.where((d) => d.type == PlanSessionType.cardio).length;

  /// Entrada del plan para el día de hoy, según `DateTime.now().weekday`
  /// (o el `now` inyectado para tests).
  PlanDayEntry entryFor(DateTime now) {
    final iso = now.weekday; // dart: 1=lunes...7=domingo, ya es ISO 8601.
    return days.firstWhere(
      (d) => d.weekday == iso,
      orElse: () => days.first,
    );
  }
}
