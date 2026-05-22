// SPEC-137 §RF-137-07: día de permitidos (cheat day) con lockout
// semanal duro.
//
// Reglas operacionales (también en NUTRITION_BIBLIOGRAPHY.md §6):
// - Un solo cheat day por semana ISO.
// - Se activa ANTES del primer plato del día (no retroactivamente).
// - Los logs del día se marcan `isCheatDay = true`.
// - La racha del usuario NO se rompe ese día.
// - El día completo se excluye del cálculo `weeklyAdherence`.
//
// MVP: persistencia local en SharedPreferences (no Firestore). Si en
// el futuro queremos sync entre dispositivos, se migra a Firestore con
// una SPEC futura. La trade-off MVP está documentada en SPEC-137
// §R-06 / §10 (out of scope).
//
// Implementación:
// - Key SP `cheat_day_active_date`: ISO date string "YYYY-MM-DD" del
//   día activado. null si no hay cheat activo hoy.
// - Key SP `cheat_day_last_week_iso`: ej. "2026-W21" — la última
//   semana ISO en que se usó cheat day. Sirve para enforcement del
//   lockout semanal.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';

/// Estado del día de permitidos.
class CheatDayState {
  /// True si HOY (hora local del dispositivo) está marcado como cheat day.
  final bool isActiveToday;

  /// True si la semana ISO actual ya consumió su cheat day (incluye el de
  /// hoy si está activo). Bloquea futuras activaciones esta semana.
  final bool weeklyLockEnforced;

  /// ISO date del último cheat day registrado, o null si nunca.
  final DateTime? lastCheatDate;

  const CheatDayState({
    required this.isActiveToday,
    required this.weeklyLockEnforced,
    required this.lastCheatDate,
  });

  const CheatDayState.empty()
      : isActiveToday = false,
        weeklyLockEnforced = false,
        lastCheatDate = null;

  CheatDayState copyWith({
    bool? isActiveToday,
    bool? weeklyLockEnforced,
    DateTime? lastCheatDate,
  }) =>
      CheatDayState(
        isActiveToday: isActiveToday ?? this.isActiveToday,
        weeklyLockEnforced: weeklyLockEnforced ?? this.weeklyLockEnforced,
        lastCheatDate: lastCheatDate ?? this.lastCheatDate,
      );
}

/// Resultado de un intento de activación. UI usa el discriminante para
/// mostrar feedback.
enum CheatDayActivationResult {
  /// Activación exitosa.
  activated,

  /// Ya está activo (no-op).
  alreadyActive,

  /// Bloqueado por lockout semanal — esta semana ISO ya usó cheat day.
  blockedByWeeklyLock,
}

class CheatDayNotifier extends StateNotifier<CheatDayState> {
  /// Constructor por defecto: hidrata contra `DateTime.now()`.
  CheatDayNotifier(this._prefs) : super(const CheatDayState.empty()) {
    _hydrate();
  }

  /// Constructor testeable: hidrata contra un instante específico.
  /// Útil para tests deterministas que controlan el "hoy" y la semana
  /// ISO.
  @visibleForTesting
  CheatDayNotifier.withClock(this._prefs, DateTime now)
      : super(const CheatDayState.empty()) {
    _hydrate(now: now);
  }

  final SharedPreferences _prefs;

  static const _kActiveDateKey = 'cheat_day_active_date';
  static const _kLastWeekIsoKey = 'cheat_day_last_week_iso';

  /// Lee el estado persistido. `now` permite inyectar el reloj para
  /// tests; en producción usa `DateTime.now()`.
  void _hydrate({DateTime? now}) {
    final activeIso = _prefs.getString(_kActiveDateKey);
    final lastWeekIso = _prefs.getString(_kLastWeekIsoKey);
    final reference = now ?? DateTime.now();
    final todayIso = _isoDate(reference);
    final thisWeekIso = isoWeek(reference);

    final activeDate =
        activeIso != null ? DateTime.tryParse(activeIso) : null;

    final isActiveToday = activeIso == todayIso;
    final weeklyLockEnforced = lastWeekIso == thisWeekIso;

    state = CheatDayState(
      isActiveToday: isActiveToday,
      weeklyLockEnforced: weeklyLockEnforced,
      lastCheatDate: activeDate,
    );
  }

  /// Intenta activar el día de permitidos para HOY.
  Future<CheatDayActivationResult> activate({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final todayIso = _isoDate(today);
    final thisWeekIso = isoWeek(today);

    if (state.isActiveToday) return CheatDayActivationResult.alreadyActive;

    if (state.weeklyLockEnforced) {
      return CheatDayActivationResult.blockedByWeeklyLock;
    }

    await _prefs.setString(_kActiveDateKey, todayIso);
    await _prefs.setString(_kLastWeekIsoKey, thisWeekIso);

    state = state.copyWith(
      isActiveToday: true,
      weeklyLockEnforced: true,
      lastCheatDate: today,
    );

    return CheatDayActivationResult.activated;
  }

  /// Desactiva el cheat day del HOY (si está activo).
  ///
  /// IMPORTANTE: NO libera el lockout semanal. Una vez consumido el
  /// cheat day en una semana ISO, no se puede tener otro esa misma
  /// semana — desactivar solo "renuncia" al beneficio de hoy. Los
  /// logs ya marcados isCheatDay=true permanecen marcados (el usuario
  /// los puede editar manualmente si quiere).
  Future<void> deactivateToday() async {
    if (!state.isActiveToday) return;
    await _prefs.remove(_kActiveDateKey);
    state = state.copyWith(isActiveToday: false);
  }

  /// Refresca el estado desde SP. Útil al cambiar de día (medianoche)
  /// o al volver del background.
  void refresh() => _hydrate();

  // ── helpers de fecha ────────────────────────────────────────────────

  /// "YYYY-MM-DD" en hora local. Comparado con strings persistidos.
  static String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  /// Semana ISO 8601: "YYYY-W##". Pública para testabilidad y para que
  /// otros notifiers puedan agregarse al mismo enforcement semanal.
  static String isoWeek(DateTime d) {
    // Algoritmo ISO 8601: la semana 1 es la que contiene el primer
    // jueves del año. Implementación basada en RFC 3339.
    final thursday = d.add(Duration(days: 4 - ((d.weekday == 0) ? 7 : d.weekday)));
    final year = thursday.year;
    final firstJan = DateTime(year, 1, 1);
    final firstThursday = firstJan
        .add(Duration(days: (4 - firstJan.weekday) % 7));
    final weekNum =
        ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
    return '$year-W${weekNum.toString().padLeft(2, '0')}';
  }
}

/// Provider del notifier. Requiere `sharedPreferencesProvider`
/// inyectado en `main.dart` (ya existente para el resto del proyecto).
final cheatDayProvider =
    StateNotifierProvider<CheatDayNotifier, CheatDayState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CheatDayNotifier(prefs);
});
