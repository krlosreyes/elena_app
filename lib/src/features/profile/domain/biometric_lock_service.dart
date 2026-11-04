// Bloqueo semanal de peso y medidas corporales.
//
// El IMR Base depende de peso, cintura, cuello y %grasa. Para que tenga
// validez longitudinal, estas medidas se registran UNA vez por semana:
//
//   - Una medición = una sesión: peso + cintura + cuello juntos (el sheet de
//     "Actualizar medidas"). Guardar un solo campo ya consume la semana, por
//     eso la UI siempre pide las tres a la vez.
//   - Tras medir, la opción queda bloqueada hasta el MISMO día de la semana
//     siguiente, a cualquier hora (inicio del día + 7). Medir el lunes en la
//     mañana permite volver a medir el lunes siguiente en la tarde.
//
// 2026-11-04 (decisión de Carlos: "solo 1 vez por semana, el resto del
// tiempo bloqueado"): se quita el atajo del Día de Permitidos — antes un
// cheat day desbloqueaba antes de tiempo. La fecha sale del historial en
// Firestore (sobrevive a reinstalar la app); SharedPreferences queda solo
// como respaldo inmediato mientras el historial sincroniza.

/// Estado calculado del bloqueo biométrico.
class BiometricLockState {
  /// True si la edición biométrica está bloqueada.
  final bool isLocked;

  /// Cuándo se registró la última medición. Null si nunca se midió.
  final DateTime? lastEditAt;

  /// Cuándo vuelve a estar disponible (inicio del día, +7 días).
  final DateTime? unlocksAt;

  const BiometricLockState({
    required this.isLocked,
    this.lastEditAt,
    this.unlocksAt,
  });

  /// Sin mediciones previas → no bloqueado.
  const BiometricLockState.unlocked()
      : isLocked = false,
        lastEditAt = null,
        unlocksAt = null;

  static const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// "Disponible el lun 10 nov". Vacío si no está bloqueado.
  String get unlockLabel {
    if (!isLocked || unlocksAt == null) return '';
    final d = unlocksAt!;
    return 'Disponible el ${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]}';
  }
}

/// Lógica pura del bloqueo biométrico. Sin deps de Flutter ni Riverpod.
class BiometricLockService {
  /// Una medición por semana.
  static const int lockDays = 7;

  /// Respaldo local del timestamp de la última medición.
  static const String kLastEditKey = 'biometry_last_edit_at';

  /// Fuentes del historial que cuentan como medición del usuario. La línea
  /// base del registro y los procesos automáticos no consumen la semana:
  /// quien acaba de registrarse puede corregir sus medidas.
  static const Set<String> manualSources = {
    'profile_edit',
    'checkin_sheet',
  };

  /// True si una entrada del historial con [source] cuenta como medición.
  /// Entradas legacy (sin source) son check-ins manuales anteriores a
  /// SPEC-143.
  static bool countsAsMeasurement(String? source) =>
      source == null || manualSources.contains(source);

  /// Último momento de medición: el más reciente entre el historial y el
  /// respaldo local.
  static DateTime? latest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  /// Calcula el estado del bloqueo.
  static BiometricLockState compute({
    required DateTime? lastMeasuredAt,
    DateTime? now,
  }) {
    if (lastMeasuredAt == null) return const BiometricLockState.unlocked();
    final n = now ?? DateTime.now();
    final unlocksAt = DateTime(
      lastMeasuredAt.year,
      lastMeasuredAt.month,
      lastMeasuredAt.day + lockDays,
    );
    return BiometricLockState(
      isLocked: n.isBefore(unlocksAt),
      lastEditAt: lastMeasuredAt,
      unlocksAt: unlocksAt,
    );
  }
}
