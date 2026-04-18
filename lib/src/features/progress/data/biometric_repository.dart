// SPEC-15: Road Map de Avance Personal
// Repositorio Firestore para snapshots biométricos periódicos.
// Colección: users/{uid}/biometric_history/{yyyy-MM-dd}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';

class BiometricRepository {
  const BiometricRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('biometric_history');

  // ─── Escritura ────────────────────────────────────────────────────────────

  /// Guarda o sobreescribe el check-in del día dado.
  /// El ID del documento es la fecha 'yyyy-MM-dd', igual que StreakEntry.
  Future<void> saveCheckIn(BiometricCheckIn checkIn) async {
    await _col(checkIn.userId)
        .doc(checkIn.date)
        .set(checkIn.toJson(), SetOptions(merge: true));
  }

  // ─── Lectura ──────────────────────────────────────────────────────────────

  /// Stream de los últimos [limit] check-ins ordenados por fecha descendente.
  Stream<List<BiometricCheckIn>> watchHistory(
    String userId, {
    int limit = 90, // 3 meses de historial máximo
  }) {
    return _col(userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) {
              try {
                return BiometricCheckIn.fromJson(doc.data());
              } catch (_) {
                return null;
              }
            })
            .whereType<BiometricCheckIn>()
            .toList());
  }

  /// Devuelve el check-in más reciente (1 lectura — para inicialización).
  Future<BiometricCheckIn?> fetchLatest(String userId) async {
    final snap = await _col(userId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    try {
      return BiometricCheckIn.fromJson(snap.docs.first.data());
    } catch (_) {
      return null;
    }
  }

  /// Check-in del día de hoy si existe.
  Future<BiometricCheckIn?> fetchToday(String userId) async {
    final today = _dateKey(DateTime.now());
    final doc = await _col(userId).doc(today).get();
    if (!doc.exists || doc.data() == null) return null;
    try {
      return BiometricCheckIn.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

// ─── Providers ───────────────────────────────────────────────────────────────

final biometricRepositoryProvider = Provider<BiometricRepository>(
  (_) => BiometricRepository(FirebaseFirestore.instance),
);
