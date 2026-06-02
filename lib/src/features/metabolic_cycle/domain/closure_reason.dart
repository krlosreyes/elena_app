// SPEC-149: razones de cierre del Día Metabólico.
//
// Cada razón corresponde a un trigger documentado en §RF-149-04 de la SPEC.
// El cierre se persiste con la razón para auditoría y análisis posterior.

/// Razones por las cuales un MetabolicCycle puede cerrarse.
///
/// Orden de prioridad si múltiples disparan simultáneamente:
/// 1. manualNextFasting (usuario explícito)
/// 2. fallbackSleepDetected (sueño manual o HealthKit)
/// 3. fallback3hAfterWindow (timer pasivo)
/// 4. fallbackAbsolute (defensa contra ciclos huérfanos)
/// 5. fallbackCalendar (modo "Ninguno")
/// 6. protocolChanged (cambio de protocolo invalida ciclo abierto)
enum ClosureReason {
  /// Usuario inició explícitamente un nuevo ayuno desde el botón.
  /// Requiere que hayan pasado ≥30 min desde startedAt del ciclo abierto
  /// para evitar falsos cierres por toques accidentales.
  manualNextFasting,

  /// Pasaron 3h desde el cierre esperado de la ventana de alimentación
  /// sin que se detecte un nuevo ayuno iniciado. Fallback pasivo para
  /// usuarios que olvidan iniciar el botón pero ya cerraron su ventana.
  fallback3hAfterWindow,

  /// Sueño detectado (manual o vía HealthKit cuando SPEC-132.next esté
  /// listo) Y han pasado ≥2h desde lastMealTime. El cierre se ancla al
  /// timestamp del sleepStart.
  fallbackSleepDetected,

  /// 28h pasaron desde startedAt sin que ninguna otra razón haya cerrado.
  /// Defensa absoluta contra ciclos huérfanos (bugs, pérdida de
  /// conexión, dispositivos no sincronizados).
  fallbackAbsolute,

  /// Usuario tiene fastingProtocol == 'Ninguno'. El ciclo se cierra a
  /// las 23:59:59 local de hoy, equivalente al modelo calendárico SPEC-138.
  fallbackCalendar,

  /// El usuario cambió su fastingProtocol mientras tenía un ciclo abierto.
  /// El ciclo previo se cierra inmediatamente con esta razón y se abre
  /// un nuevo ciclo con el nuevo protocolo.
  protocolChanged,
}

/// Helpers para serialización al persistir en Firestore.
extension ClosureReasonSerialization on ClosureReason {
  String get value {
    switch (this) {
      case ClosureReason.manualNextFasting:
        return 'manualNextFasting';
      case ClosureReason.fallback3hAfterWindow:
        return 'fallback3hAfterWindow';
      case ClosureReason.fallbackSleepDetected:
        return 'fallbackSleepDetected';
      case ClosureReason.fallbackAbsolute:
        return 'fallbackAbsolute';
      case ClosureReason.fallbackCalendar:
        return 'fallbackCalendar';
      case ClosureReason.protocolChanged:
        return 'protocolChanged';
    }
  }

  static ClosureReason? fromString(String? raw) {
    if (raw == null) return null;
    for (final r in ClosureReason.values) {
      if (r.value == raw) return r;
    }
    return null;
  }
}
