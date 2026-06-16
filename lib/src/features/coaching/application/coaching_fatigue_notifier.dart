// SPEC-194 RF-2.5 — persistencia del anti-fatiga del coach.
//
// Antes los inputs anti-fatiga del `CoachingSnapshot` (`shownTodayActionIds`,
// `ignoredStreakByActionId`) quedaban en su default vacío → el motor NUNCA
// suprimía una acción ignorada para un usuario real. Este store los persiste
// y los expone de forma reactiva y síncrona para que `coachingSnapshotProvider`
// los lea.
//
// Semántica:
// - `shownTodayActionIds`: ids mostrados como acción principal HOY (penaliza
//   repetir la misma el mismo día — `kFatigueRepeatToday`).
// - `ignoredStreakByActionId`: nº de DÍAS distintos en que la acción se mostró
//   pero NO se completó (penaliza lo ya ignorado — `kFatiguePerIgnore`). Se
//   incrementa en el rollover de día; se resetea a 0 al completarse.
//
// SPEC-228: dual-write para single source of truth cross-device.
// - Lectura síncrona de arranque: SharedPreferences (cache local, startup rápido).
// - Escritura dual: SharedPreferences local + Firestore remote (fire-and-forget).
// - Reconciliación async: al montar con uid, lee Firestore en background y
//   actualiza el state si el remote tiene un `lastDate` más reciente.
// Resultado: iOS, Android y Web ven el mismo estado de coaching.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/data/app_state_repository.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Estado inmutable del anti-fatiga.
class CoachingFatigueState {
  const CoachingFatigueState({
    required this.lastDate,
    this.shownTodayActionIds = const {},
    this.completedTodayActionIds = const {},
    this.ignoredStreakByActionId = const {},
  });

  /// Día (yyyy-MM-dd) al que corresponden los sets de "hoy".
  final String lastDate;
  final Set<String> shownTodayActionIds;
  final Set<String> completedTodayActionIds;
  final Map<String, int> ignoredStreakByActionId;

  CoachingFatigueState copyWith({
    String? lastDate,
    Set<String>? shownTodayActionIds,
    Set<String>? completedTodayActionIds,
    Map<String, int>? ignoredStreakByActionId,
  }) {
    return CoachingFatigueState(
      lastDate: lastDate ?? this.lastDate,
      shownTodayActionIds: shownTodayActionIds ?? this.shownTodayActionIds,
      completedTodayActionIds:
          completedTodayActionIds ?? this.completedTodayActionIds,
      ignoredStreakByActionId:
          ignoredStreakByActionId ?? this.ignoredStreakByActionId,
    );
  }
}

class CoachingFatigueNotifier extends StateNotifier<CoachingFatigueState> {
  /// Constructor de producción: hydrata de SharedPreferences (sync) y
  /// opcionalmente reconcilia con Firestore en background (cross-device).
  CoachingFatigueNotifier(
    this._prefs, {
    AppStateRepository? repo,
    String? uid,
    DateTime Function()? clock,
  })  : _repo = repo,
        _uid = uid,
        _clock = clock ?? DateTime.now,
        super(_hydrate(_prefs)) {
    _rollOverIfNeeded();
    // Reconciliación cross-device solo si hay uid y repo disponibles.
    if (_repo != null && _uid != null) {
      _syncFromFirestore();
    }
  }

  final SharedPreferences _prefs;
  final AppStateRepository? _repo;
  final String? _uid;
  final DateTime Function() _clock;

  static const String _kKey = 'coaching.fatigue.v1';

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  // ── Hidratación desde SharedPreferences (síncrona) ──────────────────

  static CoachingFatigueState _hydrate(SharedPreferences prefs) {
    final raw = prefs.getString(_kKey);
    if (raw == null) {
      return const CoachingFatigueState(lastDate: '');
    }
    try {
      return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const CoachingFatigueState(lastDate: '');
    }
  }

  static CoachingFatigueState _fromJson(Map<String, dynamic> j) {
    return CoachingFatigueState(
      lastDate: (j['lastDate'] as String?) ?? '',
      shownTodayActionIds:
          ((j['shown'] as List?)?.cast<String>() ?? const []).toSet(),
      completedTodayActionIds:
          ((j['completed'] as List?)?.cast<String>() ?? const []).toSet(),
      ignoredStreakByActionId:
          ((j['ignored'] as Map?)?.map(
                (k, v) => MapEntry(k as String, (v as num).toInt()),
              ) ??
              const {}),
    );
  }

  Map<String, dynamic> _toJson() => {
        'lastDate': state.lastDate,
        'shown': state.shownTodayActionIds.toList(),
        'completed': state.completedTodayActionIds.toList(),
        'ignored': state.ignoredStreakByActionId,
      };

  // ── Reconciliación desde Firestore (async, cross-device) ────────────

  Future<void> _syncFromFirestore() async {
    final data = await _repo!.getCoachingFatigue(_uid!);
    if (data == null || !mounted) return;
    final remoteDate = (data['lastDate'] as String?) ?? '';
    // Solo actualiza si Firestore tiene datos de un día más reciente.
    if (remoteDate.compareTo(state.lastDate) <= 0) return;
    final remoteState = _fromJson(data);
    state = remoteState;
    // Sincronizar a SharedPreferences para el próximo arranque.
    await _prefs.setString(_kKey, jsonEncode(data));
    _rollOverIfNeeded();
  }

  // ── Persistencia dual (local + remote) ──────────────────────────────

  Future<void> _persist() async {
    final data = _toJson();
    // 1. Local síncrono (startup rápido en el mismo device).
    await _prefs.setString(_kKey, jsonEncode(data));
    // 2. Firestore cross-device (fire-and-forget, SPEC-206).
    if (_repo != null && _uid != null) {
      _repo!.saveCoachingFatigue(_uid!, data);
    }
  }

  // ── Lógica de rollover y mutación ───────────────────────────────────

  /// Si cambió el día desde `lastDate`, incrementa `ignoredStreak` de cada
  /// acción mostrada y no completada el día anterior, y limpia los sets de
  /// "hoy". Idempotente dentro del mismo día.
  void _rollOverIfNeeded() {
    final today = _dateKey(_clock());
    if (state.lastDate == today) return;

    final ignored = Map<String, int>.from(state.ignoredStreakByActionId);
    if (state.lastDate.isNotEmpty) {
      for (final id in state.shownTodayActionIds) {
        if (!state.completedTodayActionIds.contains(id)) {
          ignored[id] = (ignored[id] ?? 0) + 1;
        }
      }
    }
    state = CoachingFatigueState(
      lastDate: today,
      shownTodayActionIds: const {},
      completedTodayActionIds: const {},
      ignoredStreakByActionId: ignored,
    );
    _persist();
  }

  /// Registra que la acción se mostró como principal (la llama el card).
  void recordShown(String actionId) {
    _rollOverIfNeeded();
    if (state.shownTodayActionIds.contains(actionId)) return;
    state = state.copyWith(
      shownTodayActionIds: {...state.shownTodayActionIds, actionId},
    );
    _persist();
  }

  /// Registra que la acción se completó (la llama CoachingCompletionService).
  /// Resetea su racha de ignorada a 0.
  void recordCompleted(String actionId) {
    _rollOverIfNeeded();
    final ignored = Map<String, int>.from(state.ignoredStreakByActionId)
      ..remove(actionId);
    state = state.copyWith(
      completedTodayActionIds: {...state.completedTodayActionIds, actionId},
      ignoredStreakByActionId: ignored,
    );
    _persist();
  }
}

/// Store reactivo del anti-fatiga. `coachingSnapshotProvider` lo watchea.
/// SPEC-228: se monta con uid + AppStateRepository para sync cross-device.
final coachingFatigueProvider =
    StateNotifierProvider<CoachingFatigueNotifier, CoachingFatigueState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final uid = ref.watch(
    currentUserStreamProvider.select((v) => v.valueOrNull?.id),
  );
  final repo = ref.read(appStateRepositoryProvider);
  return CoachingFatigueNotifier(prefs, repo: repo, uid: uid);
});
