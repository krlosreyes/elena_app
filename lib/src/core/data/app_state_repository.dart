// SPEC-228: repositorio Firestore para estado de app cross-device.
//
// Reemplaza SharedPreferences como fuente de datos de negocio para que
// iOS, Android y Web vean el mismo estado. Colección:
//   users/{uid}/app_state/{doc}
//
// Documentos:
//   migrations  — guard keys de migraciones one-shot
//   coaching    — estado anti-fatiga del coach (shownToday, ignored, completed)
//   cheat_day   — día de permitidos activo + lockout semanal
//   sleep_wakeup — confirmaciones "ya desperté" por día
//
// Patrón de lectura: cache local primero (Firestore SDK offline persistence),
// fallback a server si cache falla. Esto garantiza startup síncrono y
// funcionalidad offline, con sync automático al reconectar.
//
// Patrón de escritura: siempre fire-and-forget (unawaited) — conforme a
// SPEC-206 (offline-first). Los writes van al cache local al instante y se
// sincronizan al server cuando hay conexión.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';

class AppStateRepository {
  AppStateRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String docName) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('app_state')
          .doc(docName);

  // ── Lectura con cache-first ─────────────────────────────────────────
  // Intenta cache local (sync offline). Si falla (primer arranque sin
  // cache), va al server. Retorna null si no existe el documento.

  Future<Map<String, dynamic>?> _read(String uid, String docName) async {
    try {
      final snap = await _doc(uid, docName).get(
        const GetOptions(source: Source.cache),
      );
      if (snap.exists) return snap.data();
    } catch (_) {
      // Cache miss normal en primer arranque — continuar al server.
    }
    try {
      final snap = await _doc(uid, docName).get(
        const GetOptions(source: Source.server),
      );
      return snap.exists ? snap.data() : null;
    } catch (e) {
      // SEC-07: uid truncado, nunca completo en logs.
      AppLogger.warning(
          '[AppState] read ${AppLogger.truncateUid(uid)}/$docName falló: $e');
      return null;
    }
  }

  // ── Escritura fire-and-forget ────────────────────────────────────────

  void _write(String uid, String docName, Map<String, dynamic> data) {
    unawaited(
      _doc(uid, docName)
          .set(data, SetOptions(merge: true))
          .catchError((Object e) {
        // SEC-07: uid truncado, nunca completo en logs.
        AppLogger.warning(
            '[AppState] write ${AppLogger.truncateUid(uid)}/$docName falló: $e');
      }),
    );
  }

  // ── MIGRATIONS ───────────────────────────────────────────────────────
  // Guard keys de migraciones one-shot. Cada key es un campo bool.
  // Los keys usados son:
  //   spec217_fasting_migrated — SPEC-222
  //   cycle_bootstrap_done_{userId} — SPEC-186 (sin userId, solo 'done')
  //   cycle_score_v1           — SPEC-226

  Future<bool> getMigrationFlag(String uid, String key) async {
    final data = await _read(uid, 'migrations');
    return data?[key] == true;
  }

  Future<void> setMigrationFlag(String uid, String key) async {
    // Las guard keys SÍ se awaitan para garantizar idempotencia
    // (si la app cae antes de persistir, vuelve a correr la migración).
    await _doc(uid, 'migrations').set({key: true}, SetOptions(merge: true));
  }

  // ── COACHING FATIGUE ─────────────────────────────────────────────────
  // Estructura: { lastDate, shown: [], completed: [], ignored: {id: int} }

  Future<Map<String, dynamic>?> getCoachingFatigue(String uid) =>
      _read(uid, 'coaching');

  void saveCoachingFatigue(String uid, Map<String, dynamic> data) =>
      _write(uid, 'coaching', data);

  // ── CHEAT DAY ─────────────────────────────────────────────────────────
  // Estructura: { activeDate: "yyyy-MM-dd" | null, lastWeekIso: "yyyy-Wnn" }

  Future<Map<String, dynamic>?> getCheatDay(String uid) =>
      _read(uid, 'cheat_day');

  void setCheatDayActive(
    String uid,
    String activeDate,
    String lastWeekIso,
  ) =>
      _write(uid, 'cheat_day', {
        'activeDate': activeDate,
        'lastWeekIso': lastWeekIso,
      });

  void clearCheatDayActive(String uid) =>
      _write(uid, 'cheat_day', {'activeDate': null});

  // ── SLEEP WAKE-UP ─────────────────────────────────────────────────────
  // Estructura: { "yyyy-MM-dd": true, ... } — una key por día.

  Future<bool> isSleepWakeUpConfirmed(String uid, String dayKey) async {
    final data = await _read(uid, 'sleep_wakeup');
    return data?[dayKey] == true;
  }

  void confirmSleepWakeUp(String uid, String dayKey) =>
      _write(uid, 'sleep_wakeup', {dayKey: true});

  // ── ONBOARDING ────────────────────────────────────────────────────────
  // Estructura: { completed: true }

  Future<void> setOnboardingCompleted(String uid) async {
    await _doc(uid, 'onboarding').set({'completed': true}, SetOptions(merge: true));
  }
}

final appStateRepositoryProvider = Provider<AppStateRepository>((ref) {
  return AppStateRepository();
});
