// SPEC-194 RF-2.5 — persistencia del anti-fatiga del coach.
//
// Antes los inputs anti-fatiga del `CoachingSnapshot` (`shownTodayActionIds`,
// `ignoredStreakByActionId`) quedaban en su default vacío → el motor NUNCA
// suprimía una acción ignorada para un usuario real. Este store los persiste
// localmente (SharedPreferences) y los expone de forma reactiva y síncrona
// para que `coachingSnapshotProvider` los lea.
//
// Semántica:
// - `shownTodayActionIds`: ids mostrados como acción principal HOY (penaliza
//   repetir la misma el mismo día — `kFatigueRepeatToday`).
// - `ignoredStreakByActionId`: nº de DÍAS distintos en que la acción se mostró
//   pero NO se completó (penaliza lo ya ignorado — `kFatiguePerIgnore`). Se
//   incrementa en el rollover de día; se resetea a 0 al completarse.
//
// Dart puro + SharedPreferences (CONSTITUTION §3.2: sin Firestore).

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';

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
  CoachingFatigueNotifier(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(_hydrate(_prefs)) {
    // Reconciliar al arrancar: si el último día guardado no es hoy, las
    // acciones mostradas y no completadas ayer cuentan como ignoradas.
    _rollOverIfNeeded();
  }

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const String _kKey = 'coaching.fatigue.v1';

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static CoachingFatigueState _hydrate(SharedPreferences prefs) {
    final raw = prefs.getString(_kKey);
    if (raw == null) {
      return const CoachingFatigueState(lastDate: '');
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
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
    } catch (_) {
      // Dato corrupto → arrancar limpio.
      return const CoachingFatigueState(lastDate: '');
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _kKey,
      jsonEncode({
        'lastDate': state.lastDate,
        'shown': state.shownTodayActionIds.toList(),
        'completed': state.completedTodayActionIds.toList(),
        'ignored': state.ignoredStreakByActionId,
      }),
    );
  }

  /// Si cambió el día desde `lastDate`, incrementa `ignoredStreak` de cada
  /// acción mostrada y no completada el día anterior, y limpia los sets de
  /// "hoy". Idempotente dentro del mismo día.
  void _rollOverIfNeeded() {
    final today = _dateKey(_clock());
    if (state.lastDate == today) return;

    final ignored = Map<String, int>.from(state.ignoredStreakByActionId);
    // Solo penaliza si había un día previo real (no en el primer arranque).
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
final coachingFatigueProvider =
    StateNotifierProvider<CoachingFatigueNotifier, CoachingFatigueState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CoachingFatigueNotifier(prefs);
});
