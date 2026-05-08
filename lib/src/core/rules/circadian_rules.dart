// SPEC-51: API legacy (string) — delega a CircadianEngine.
//
// Antes: este archivo contenía la tabla canónica de fases circadianas con
// sus horas hardcodeadas. Esa tabla vivía duplicada en orchestrator_engine
// y orchestrator_service (eliminado en SPEC-46).
//
// Ahora: CircadianEngine es la fuente única de verdad. Esta clase se
// conserva como wrapper de compatibilidad para los consumidores que aún
// usan strings (`fasting_notifier`, `analysis_screen`,
// `biological_cycles_painter`). Cuando todos migren a la API tipada,
// este archivo se podrá eliminar.

import 'package:elena_app/src/core/engine/circadian_engine.dart';
import 'circadian_phase.dart';

/// Wrapper legacy de [CircadianEngine]. Mantiene la API previa a SPEC-51
/// para no romper consumidores existentes.
class CircadianRules {
  CircadianRules._();

  /// Hora del bloqueo intestinal (22).
  static const int intestinalLockHour = CircadianEngine.intestinalLockHour;

  /// Minuto del bloqueo intestinal (30).
  static const int intestinalLockMinute = CircadianEngine.intestinalLockMinute;

  /// Bloqueo intestinal en minutos totales (1290 = 21:30 desde SPEC-70.5).
  /// SPEC-59 RF-59-03 — helper para comparaciones lineales.
  static const int intestinalLockMinutes =
      CircadianEngine.intestinalLockMinutes;

  /// Tabla maestra de fases — re-exportada del engine.
  /// Adapta los `CircadianPhaseDefinition` del engine al tipo legacy
  /// `CircadianPhase` (label/startHour/endHour) que este archivo expone.
  static List<CircadianPhase> get allPhases => CircadianEngine.allPhases
      .map((def) => CircadianPhase(
            label: def.label,
            startHour: def.startHour,
            endHour: def.endHour,
          ))
      .toList(growable: false);

  /// Determina si una fase específica está activa en este momento.
  /// Mantiene la firma legacy que recibe `CircadianPhase` (clase) y `DateTime`.
  static bool isPhaseActive(CircadianPhase phase, DateTime now) {
    final current = now.hour + (now.minute / 60.0);
    if (phase.startHour < phase.endHour) {
      return current >= phase.startHour && current < phase.endHour;
    }
    // Caso que cruza la medianoche (Sueño)
    return current >= phase.startHour || current < phase.endHour;
  }

  /// Nombre de la fase activa en `time` (string en mayúsculas).
  /// Delega a [CircadianEngine.currentPhaseName].
  static String getPhaseName(DateTime time) =>
      CircadianEngine.currentPhaseName(time);

  /// Tiempo restante hasta el próximo cierre del bloqueo intestinal.
  /// Delega a [CircadianEngine.timeUntilLock].
  static Duration timeUntilLock(DateTime now) =>
      CircadianEngine.timeUntilLock(now);

  /// True si en este instante el bloqueo intestinal está activo.
  /// Delega a [CircadianEngine.isIntestinalLockActive].
  static bool isIntestinalLockActive(DateTime now) =>
      CircadianEngine.isIntestinalLockActive(now);
}
