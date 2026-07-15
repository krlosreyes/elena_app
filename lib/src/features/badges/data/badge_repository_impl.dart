// Sistema de insignias (2026-07-15) — implementación Firestore.
// Colección: users/{uid}/badges/{badgeId}. Mismo patrón que
// FirestoreStreakV1Source (SPEC-50.3): fuente delgada, el repositorio
// traduce a/desde el modelo de dominio.
//
// `create` usa `set()` SIN merge y con el mismo badgeId como ID de
// documento — si el documento ya existe (re-evaluación, reintento
// offline), Firestore simplemente lo sobreescribe con datos idénticos.
// No usamos `SetOptions(merge: true)` a propósito: una insignia no tiene
// campos "incrementales" como sí los tiene un StreakEntry (que se
// actualiza varias veces en el mismo día a medida que se completan
// pilares) — acá el documento nace completo y no vuelve a cambiar.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/badges/domain/badge_repository.dart';
import 'package:elena_app/src/features/badges/domain/earned_badge.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  final FirebaseFirestore _firestore;

  BadgeRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('badges');

  @override
  Stream<List<EarnedBadge>> watchEarned(String userId) {
    return _collection(userId).snapshots().map((snap) {
      return snap.docs
          .map((d) {
            try {
              return EarnedBadge.fromJson(Map<String, dynamic>.from(d.data()));
            } catch (_) {
              // Doc corrupto: lo saltamos para no tumbar toda la galería.
              return null;
            }
          })
          .whereType<EarnedBadge>()
          .toList();
    });
  }

  @override
  Future<void> create(String userId, EarnedBadge badge) async {
    await _collection(userId).doc(badge.badgeId).set(badge.toJson());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepositoryImpl();
});
