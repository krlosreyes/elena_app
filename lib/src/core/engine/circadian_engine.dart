// ─────────────────────────────────────────────────────────────────────────────
// SPEC-51: CircadianEngine — Fuente única de verdad sobre las fases circadianas
// ─────────────────────────────────────────────────────────────────────────────
//
// Antes de SPEC-51, la tabla de fases vivía duplicada en tres lugares:
//   - core/rules/circadian_rules.dart (strings con label)
//   - core/orchestrator/orchestrator_engine.dart (enum CircadianPhase)
//   - core/orchestrator/orchestrator_service.dart (eliminado en SPEC-46)
//
// CircadianEngine consolida toda la información horaria en este archivo.
// CircadianRules pasa a ser un wrapper legacy (API string) que delega aquí
// para no romper los consumidores existentes.
//
// SPEC-00: Dart puro — sin Flutter, sin Riverpod, sin Firestore.
// SPEC-60: ningún factory aquí invoca DateTime.now() ni fuentes de no-determinismo.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';

/// Definición declarativa de una fase circadiana.
///
/// Renombrada desde la antigua clase `CircadianPhase` (legacy en
/// `core/rules/circadian_phase.dart`) para evitar colisión con el
/// enum `CircadianPhase` de `biological_phases.dart`.
///
/// Los painters de UI (ej. `biological_cycles_painter`) consumen esta
/// estructura para renderizar el dial completo del día.
class CircadianPhaseDefinition {
  final String label;
  final double startHour;
  final double endHour;
  final CircadianPhase phase;

  const CircadianPhaseDefinition({
    required this.label,
    required this.startHour,
    required this.endHour,
    required this.phase,
  });
}

/// Motor circadiano puro. Fuente única de verdad sobre fases del día.
///
/// Reglas:
/// - Sin DateTime.now() — siempre se le pasa el `now` desde fuera.
/// - Sin estado mutable.
/// - Mismo input → mismo output.
class CircadianEngine {
  CircadianEngine._();

  // ── Constantes horarias (fuente única) ─────────────────────────────────

  /// Hora de inicio del bloqueo intestinal nocturno (22:30).
  /// SPEC-70: ref IMR_BIBLIOGRAPHY.md §4.6 — LOW (Hood & Amir 2017,
  /// melatonina endógena empieza a subir a esa hora en cronotipos promedio).
  static const int intestinalLockHour = 22;
  static const int intestinalLockMinute = 30;

  /// Bloqueo intestinal en minutos totales desde la medianoche.
  /// SPEC-59: helper centralizado para comparaciones lineales.
  /// Valor: 22 * 60 + 30 = 1350.
  static const int intestinalLockMinutes =
      (intestinalLockHour * 60) + intestinalLockMinute;

  /// Tabla canónica de fases del día.
  /// Cualquier modificación de horas se hace AQUÍ — los demás módulos delegan.
  static const List<CircadianPhaseDefinition> allPhases = [
    CircadianPhaseDefinition(
      label: 'SUEÑO',
      startHour: 22.5,
      endHour: 6.0,
      phase: CircadianPhase.sueno,
    ),
    CircadianPhaseDefinition(
      label: 'ALERTA',
      startHour: 6.0,
      endHour: 9.0,
      phase: CircadianPhase.alerta,
    ),
    CircadianPhaseDefinition(
      label: 'COGNITIVO',
      startHour: 9.0,
      endHour: 13.0,
      phase: CircadianPhase.cognitivo,
    ),
    CircadianPhaseDefinition(
      label: 'RECESO',
      startHour: 13.0,
      endHour: 15.0,
      phase: CircadianPhase.receso,
    ),
    CircadianPhaseDefinition(
      label: 'MOTOR / FUERZA',
      startHour: 15.0,
      endHour: 20.0,
      phase: CircadianPhase.motorFuerza,
    ),
    CircadianPhaseDefinition(
      label: 'CREATIVIDAD',
      startHour: 20.0,
      endHour: 22.5,
      phase: CircadianPhase.creatividad,
    ),
  ];

  // ── API tipada (preferida en código nuevo) ──────────────────────────────

  /// Retorna el enum `CircadianPhase` para el timestamp dado.
  /// API tipada — preferida en el core. Dispara sobre `allPhases` para
  /// que cualquier futuro cambio de tabla se refleje automáticamente.
  static CircadianPhase currentPhase(DateTime now) {
    for (final def in allPhases) {
      if (_isPhaseActive(def, now)) return def.phase;
    }
    // Fallback defensivo — la tabla cubre 24h, no debería alcanzarse.
    return CircadianPhase.alerta;
  }

  /// Tiempo restante hasta el próximo cierre de la ventana intestinal (22:30).
  /// Si `now` es exactamente 22:30:00, retorna `Duration.zero` (lock activo).
  static Duration timeUntilLock(DateTime now) {
    DateTime lock = DateTime(
      now.year,
      now.month,
      now.day,
      intestinalLockHour,
      intestinalLockMinute,
    );
    if (now.isAfter(lock)) lock = lock.add(const Duration(days: 1));
    return lock.difference(now);
  }

  /// True si en este instante el bloqueo intestinal está activo
  /// (entre 22:30 y 06:00 del día siguiente).
  static bool isIntestinalLockActive(DateTime now) {
    final current = now.hour + (now.minute / 60.0);
    return current >= 22.5 || current < 6.0;
  }

  /// True si `now` está dentro de la ventana `[start, end]` evaluada en
  /// "minutos del día" (ignora la fecha). Si `start > end`, asume ventana
  /// que cruza la medianoche.
  static bool isInWindow(DateTime now, DateTime start, DateTime end) {
    final nowMin = now.hour * 60 + now.minute;
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    if (startMin <= endMin) {
      return nowMin >= startMin && nowMin <= endMin;
    }
    // Cruza medianoche
    return nowMin >= startMin || nowMin <= endMin;
  }

  // ── API legacy (string) — para consumidores antiguos ───────────────────

  /// Retorna el `label` de la fase actual (string en mayúsculas).
  /// Equivalente a la antigua `CircadianRules.getPhaseName`.
  static String currentPhaseName(DateTime now) {
    for (final def in allPhases) {
      if (_isPhaseActive(def, now)) return def.label;
    }
    return 'REPARACIÓN';
  }

  /// True si la `definition` está activa en el `now` dado.
  /// Manejo de cruce de medianoche cuando `startHour > endHour`.
  static bool _isPhaseActive(CircadianPhaseDefinition def, DateTime now) {
    final current = now.hour + (now.minute / 60.0);
    if (def.startHour < def.endHour) {
      return current >= def.startHour && current < def.endHour;
    }
    // Caso que cruza la medianoche (Sueño)
    return current >= def.startHour || current < def.endHour;
  }
}
