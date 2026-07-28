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
// SPEC-228: dual-write para single source of truth cross-device.
// - Lectura síncrona de arranque: SharedPreferences (cache local).
// - Escritura dual: SharedPreferences local + Firestore remote (fire-and-forget).
// - Reconciliación async al montar: si Firestore tiene datos más recientes
//   los aplica y actualiza SharedPreferences local.
// Resultado: iOS, Android y Web comparten el mismo estado de cheat day.

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/data/app_state_repository.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

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
  /// Constructor de producción: hydrata de SharedPreferences (sync) y
  /// opcionalmente reconcilia con Firestore en background (cross-device).
  CheatDayNotifier(
    this._prefs, {
    AppStateRepository? repo,
    String? uid,
  })  : _repo = repo,
        _uid = uid,
        super(const CheatDayState.empty()) {
    _hydrate();
    if (_repo != null && _uid != null) {
      _syncFromFirestore();
    }
  }

  /// Constructor testeable: hydrata contra un instante específico.
  /// Útil para tests deterministas que controlan el "hoy" y la semana ISO.
  @visibleForTesting
  CheatDayNotifier.withClock(
    this._prefs,
    DateTime now, {
    AppStateRepository? repo,
    String? uid,
  })  : _repo = repo,
        _uid = uid,
        super(const CheatDayState.empty()) {
    _hydrate(now: now);
    // No reconciliación Firestore en tests (repo/uid típicamente null).
  }

  final SharedPreferences _prefs;
  final AppStateRepository? _repo;
  final String? _uid;

  static const _kActiveDateKey = 'cheat_day_active_date';
  static const _kLastWeekIsoKey = 'cheat_day_last_week_iso';

  // ── Hidratación desde SharedPreferences ─────────────────────────────

  /// Lee el estado persistido. `now` permite inyectar el reloj para
  /// tests; en producción usa `DateTime.now()`.
  void _hydrate({DateTime? now}) {
    final activeIso = _prefs.getString(_kActiveDateKey);
    final lastWeekIso = _prefs.getString(_kLastWeekIsoKey);
    final reference = now ?? DateTime.now();
    final todayIso = _isoDate(reference);
    final thisWeekIso = isoWeek(reference);

    final activeDate = activeIso != null ? DateTime.tryParse(activeIso) : null;

    state = CheatDayState(
      isActiveToday: activeIso == todayIso,
      weeklyLockEnforced: lastWeekIso == thisWeekIso,
      lastCheatDate: activeDate,
    );
  }

  // ── Reconciliación desde Firestore (async, cross-device) ────────────

  Future<void> _syncFromFirestore() async {
    final data = await _repo!.getCheatDay(_uid!);
    if (data == null || !mounted) return;

    final remoteActiveDate = data['activeDate'] as String?;
    final remoteLastWeek = data['lastWeekIso'] as String?;
    final localActiveDate = _prefs.getString(_kActiveDateKey);
    final localLastWeek = _prefs.getString(_kLastWeekIsoKey);

    // Solo aplica si Firestore tiene datos distintos a SharedPreferences.
    if (remoteActiveDate == localActiveDate &&
        remoteLastWeek == localLastWeek) {
      return;
    }

    // Actualizar SharedPreferences con los datos de Firestore.
    if (remoteActiveDate != null) {
      await _prefs.setString(_kActiveDateKey, remoteActiveDate);
    } else {
      await _prefs.remove(_kActiveDateKey);
    }
    if (remoteLastWeek != null) {
      await _prefs.setString(_kLastWeekIsoKey, remoteLastWeek);
    }
    _hydrate();
  }

  // ── Mutaciones ────────────────────────────────────────────────────────

  /// Intenta activar el día de permitidos para HOY.
  Future<CheatDayActivationResult> activate({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final todayIso = _isoDate(today);
    final thisWeekIso = isoWeek(today);

    if (state.isActiveToday) return CheatDayActivationResult.alreadyActive;
    if (state.weeklyLockEnforced) {
      return CheatDayActivationResult.blockedByWeeklyLock;
    }

    // Local inmediato.
    await _prefs.setString(_kActiveDateKey, todayIso);
    await _prefs.setString(_kLastWeekIsoKey, thisWeekIso);
    // Firestore cross-device (fire-and-forget).
    _repo?.setCheatDayActive(_uid!, todayIso, thisWeekIso);

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
  /// logs ya marcados isCheatDay=true permanecen marcados.
  Future<void> deactivateToday() async {
    if (!state.isActiveToday) return;
    // Local.
    await _prefs.remove(_kActiveDateKey);
    // Firestore cross-device.
    _repo?.clearCheatDayActive(_uid!);
    state = state.copyWith(isActiveToday: false);
  }

  /// Refresca el estado desde SharedPreferences. Útil al cambiar de día
  /// (medianoche) o al volver del background.
  void refresh() => _hydrate();

  // ── helpers de fecha ────────────────────────────────────────────────

  /// "YYYY-MM-DD" en hora local.
  static String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  /// Semana ISO 8601: "YYYY-W##". Pública para testabilidad.
  static String isoWeek(DateTime d) {
    final thursday =
        d.add(Duration(days: 4 - ((d.weekday == 0) ? 7 : d.weekday)));
    final year = thursday.year;
    final firstJan = DateTime(year, 1, 1);
    final firstThursday =
        firstJan.add(Duration(days: (4 - firstJan.weekday) % 7));
    final weekNum =
        ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
    return '$year-W${weekNum.toString().padLeft(2, '0')}';
  }
}

/// Provider del notifier. SPEC-228: se monta con uid + AppStateRepository
/// para sync cross-device.
final cheatDayProvider =
    StateNotifierProvider<CheatDayNotifier, CheatDayState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final uid = ref.watch(
    currentUserStreamProvider.select((v) => v.valueOrNull?.id),
  );
  final repo = ref.read(appStateRepositoryProvider);
  return CheatDayNotifier(prefs, repo: repo, uid: uid);
});
