// SPEC-215: fuente canónica única para la conversión protocolo → horas.
//
// Antes de este archivo existían 3 copias del mismo switch:
//   - MetabolicCycleService._hoursFromProtocol (private, double?)
//   - NotificationScheduler.protocolFastingHours (static, int?)
//   - _parseFastingProtocol en user_profile_mapper.dart (private, int?)
//
// Ahora todos los callers usan [fastingHoursForProtocol].

/// Devuelve las horas de ayuno del protocolo canónico.
///
/// Protocolos válidos: '12:12', '14:10', '16:8', '18:6', '20:4', '22:2', 'OMAD'.
/// 'Ninguno' → `null` (sin ventana de ayuno definida).
/// Cualquier otro valor desconocido → `null` (sin inventar).
int? fastingHoursForProtocol(String protocol) {
  switch (protocol) {
    case '12:12':
      return 12;
    case '14:10':
      return 14;
    case '16:8':
      return 16;
    case '18:6':
      return 18;
    case '20:4':
      return 20;
    case '22:2':
      return 22;
    case 'OMAD':
      return 23;
    case 'Ninguno':
    default:
      return null;
  }
}
