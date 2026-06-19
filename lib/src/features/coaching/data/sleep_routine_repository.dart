// SPEC-234: CRUD Firestore para sleep_routines.
//
// Patrón offline-first (SPEC-206): write no-bloqueante + stream como
// fuente de verdad. Un doc por día (ID determinista: routine_{yyyy-MM-dd}).

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/coaching/domain/sleep_routine_check_in.dart';

class SleepRoutineRepository {
  SleepRoutineRepository({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _fs.collection('users').doc(userId).collection('sleep_routines');

  // ── Write (fire-and-forget, SPEC-206) ─────────────────────────────────

  /// Persiste o actualiza la rutina nocturna del día. Idempotente: el docId
  /// es determinista por fecha. Firestore offline cache encolará si no hay red.
  void save(SleepRoutineCheckIn routine) {
    unawaited(
      _col(routine.userId)
          .doc(routine.id)
          .set(routine.toMap(), SetOptions(merge: true))
          .catchError(
            (e) => AppLogger.error('[SleepRoutineRepo] save falló', e),
          ),
    );
  }

  // ── Read (stream = fuente de verdad) ──────────────────────────────────

  /// Stream de la rutina nocturna de hoy, o null si aún no se inició.
  Stream<SleepRoutineCheckIn?> watchToday(String userId, DateTime today) {
    final docId = SleepRoutineCheckIn.buildId(userId, today);
    return _col(userId).doc(docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return SleepRoutineCheckIn.fromMap(snap.id, snap.data()!);
    });
  }

  /// Stream de rutinas de los últimos [days] días (para estadísticas futuras).
  Stream<List<SleepRoutineCheckIn>> watchRecent(
    String userId,
    DateTime since,
  ) {
    return _col(userId)
        .where('date', isGreaterThanOrEqualTo: since.toIso8601String())
        .orderBy('date', descending: true)
        .limit(14)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => SleepRoutineCheckIn.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final sleepRoutineRepositoryProvider = Provider<SleepRoutineRepository>((ref) {
  return SleepRoutineRepository();
});
