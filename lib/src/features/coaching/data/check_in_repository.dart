// SPEC-232: CRUD Firestore para fasting_checkins.
//
// Patrón offline-first (SPEC-206): write no-bloqueante + stream como
// fuente de verdad. Sin abstract layer — es un repo interno del coaching,
// no necesita fake en tests (se testea vía el notifier).

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/coaching/domain/fasting_check_in.dart';

class CheckInRepository {
  CheckInRepository({FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _fs.collection('users').doc(userId).collection('fasting_checkins');

  // ── Write (fire-and-forget, SPEC-206) ─────────────────────────────────

  /// Persiste un check-in. No bloquea; Firestore offline cache lo encolará
  /// si no hay red. Idempotente: si el docId ya existe, se sobreescribe
  /// con el mismo dato (mismo hito, mismo día).
  void save(FastingCheckIn checkIn) {
    unawaited(
      _col(checkIn.userId).doc(checkIn.id).set(checkIn.toMap()).catchError(
            (e) => AppLogger.error('[CheckInRepo] save falló', e),
          ),
    );
  }

  // ── Read (stream = fuente de verdad) ──────────────────────────────────

  /// Stream de check-ins del ciclo actual (desde [since]).
  /// Ordenados por timestamp ascendente.
  Stream<List<FastingCheckIn>> watchSince(String userId, DateTime since) {
    return _col(userId)
        .where('timestamp', isGreaterThanOrEqualTo: since.toIso8601String())
        .orderBy('timestamp')
        .snapshots()
        .map((snap) {
      final out = <FastingCheckIn>[];
      for (final doc in snap.docs) {
        final ci = FastingCheckIn.fromMap(doc.id, doc.data());
        if (ci != null) out.add(ci);
      }
      return out;
    });
  }

  /// Último check-in del ciclo actual (útil para coaching post-respuesta).
  Stream<FastingCheckIn?> watchLast(String userId, DateTime since) {
    return _col(userId)
        .where('timestamp', isGreaterThanOrEqualTo: since.toIso8601String())
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return FastingCheckIn.fromMap(doc.id, doc.data());
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository();
});
