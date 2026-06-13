// SPEC-BUG7: Bloqueo semanal de datos biométricos.
//
// El IMR Base (bloque Estructura, 50% del IMR) depende de peso, cintura y
// %grasa. Para que tenga validez longitudinal, estos datos solo deben
// actualizarse una vez por "semana metabólica". Si se pudieran editar
// libremente, un usuario podría manipular el IMR registrando medidas
// favorables el día de medición.
//
// Regla (Opción A — aprobada 2026-06-13):
//   isLocked = true  si, desde el último edit:
//     - No han pasado 6 días, Y
//     - No ha ocurrido un Día de Permitidos (cheat day) DESPUÉS del edit.
//
// La segunda condición hace que el cheat day actúe como cierre natural
// de la semana metabólica — el usuario señala conscientemente que el
// ciclo cerró y puede volver a medirse.
//
// El lockout semanal del cheat day (uno por semana ISO, implementado en
// cheat_day_notifier.dart) garantiza que este "shortcut" no sea trivial:
// el mínimo lock real vía cheat day es varios días.

/// Estado calculado del bloqueo biométrico.
class BiometricLockState {
  /// True si la edición biométrica está bloqueada.
  final bool isLocked;

  /// Cuándo se realizó el último edit. Null si nunca se editó.
  final DateTime? lastEditAt;

  /// Cuándo el lock expira por tiempo (lastEditAt + 6 días).
  /// Null si nunca se editó.
  final DateTime? unlocksAt;

  const BiometricLockState({
    required this.isLocked,
    this.lastEditAt,
    this.unlocksAt,
  });

  /// Estado inicial: sin historial de edición → no bloqueado.
  const BiometricLockState.unlocked()
      : isLocked = false,
        lastEditAt = null,
        unlocksAt = null;

  /// Label para mostrar en UI: "Disponible el 19/6".
  String get unlockLabel {
    if (!isLocked || unlocksAt == null) return '';
    final d = unlocksAt!;
    return 'Disponible el ${d.day}/${d.month}';
  }
}

/// Lógica pura del bloqueo biométrico. Sin deps de Flutter ni Riverpod.
class BiometricLockService {
  /// Días que dura el lock por tiempo (fallback si no hay cheat day).
  static const int lockDays = 6;

  /// Clave de SharedPreferences donde se persiste el timestamp del
  /// último edit de biometría.
  static const String kLastEditKey = 'biometry_last_edit_at';

  /// Calcula el estado del lock dado el último edit y el último cheat day.
  ///
  /// [lastEditIso]  — valor de SP (ISO-8601 string) o null si nunca editó.
  /// [lastCheatDate] — último cheat day registrado (puede ser null).
  static BiometricLockState compute({
    required String? lastEditIso,
    required DateTime? lastCheatDate,
  }) {
    if (lastEditIso == null) return const BiometricLockState.unlocked();

    final lastEditAt = DateTime.tryParse(lastEditIso);
    if (lastEditAt == null) return const BiometricLockState.unlocked();

    final unlocksAt = lastEditAt.add(Duration(days: lockDays));

    // Condición 1: 6 días ya transcurrieron → desbloqueado.
    if (DateTime.now().isAfter(unlocksAt)) {
      return BiometricLockState(
        isLocked: false,
        lastEditAt: lastEditAt,
        unlocksAt: unlocksAt,
      );
    }

    // Condición 2: cheat day ocurrió DESPUÉS del edit → desbloqueado.
    if (lastCheatDate != null) {
      final editDay = DateTime(
          lastEditAt.year, lastEditAt.month, lastEditAt.day);
      final cheatDay = DateTime(
          lastCheatDate.year, lastCheatDate.month, lastCheatDate.day);
      if (cheatDay.isAfter(editDay)) {
        return BiometricLockState(
          isLocked: false,
          lastEditAt: lastEditAt,
          unlocksAt: unlocksAt,
        );
      }
    }

    // Ninguna condición de desbloqueo → bloqueado.
    return BiometricLockState(
      isLocked: true,
      lastEditAt: lastEditAt,
      unlocksAt: unlocksAt,
    );
  }
}
