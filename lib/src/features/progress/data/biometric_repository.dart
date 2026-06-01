// SPEC-15: Road Map de Avance Personal
// Repositorio Firestore para snapshots biométricos periódicos.
// Colección: users/{uid}/biometric_history/{yyyy-MM-dd}
//
// SPEC-143: agrega `applyBiometricUpdate` — escribe atómicamente al
// doc raíz del usuario y al snapshot histórico en un WriteBatch.
// Sub el `limit` default de `watchHistory` de 90 a 365 días para que
// el IMR longitudinal (SPEC-141) pueda leer tendencia anual sin
// recargar.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';

class BiometricRepository {
  const BiometricRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('biometric_history');

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection('users').doc(userId);

  // ─── Escritura ────────────────────────────────────────────────────────────

  /// Guarda o sobreescribe el check-in del día dado.
  /// El ID del documento es la fecha 'yyyy-MM-dd', igual que StreakEntry.
  Future<void> saveCheckIn(BiometricCheckIn checkIn) async {
    await _col(checkIn.userId)
        .doc(checkIn.date)
        .set(checkIn.toJson(), SetOptions(merge: true));
  }

  /// SPEC-143: escritura atómica del doc raíz del usuario + snapshot
  /// histórico. Usa WriteBatch — Firestore garantiza que ambos writes
  /// se aplican o ninguno (R-02 mitigado).
  ///
  /// [historySnapshot] es la entrada que se persiste en
  /// `biometric_history/{yyyy-MM-dd}`. Si ya existe un doc para ese día,
  /// se sobrescribe con merge (último write del día gana, consistente
  /// con SPEC-143 §RF-143-03).
  ///
  /// [userDocUpdates] es el mapa de campos a actualizar en `users/{uid}`.
  /// Típicamente {'weight': X, 'waistCircumference': Y, ...}. Solo los
  /// campos biométricos que el delta tocó.
  ///
  /// El llamador canónico es `BiometricHistoryService`. Otros callsites
  /// deberían usar el servicio, no este método directo.
  Future<void> applyBiometricUpdate({
    required String userId,
    required BiometricCheckIn historySnapshot,
    required Map<String, dynamic> userDocUpdates,
  }) async {
    final batch = _firestore.batch();
    if (userDocUpdates.isNotEmpty) {
      batch.update(_userDoc(userId), userDocUpdates);
    }
    batch.set(
      _col(userId).doc(historySnapshot.date),
      historySnapshot.toJson(),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  // ─── Lectura ──────────────────────────────────────────────────────────────

  /// Stream de los últimos [limit] check-ins ordenados por fecha descendente.
  ///
  /// SPEC-143: default subido de 90 a 365 días. SPEC-141 lee tendencia
  /// anual del IMR longitudinal sin recargar; mantener el default bajo
  /// obligaba a callsites a pasar `limit: 365` cada vez. El costo de
  /// egress es despreciable porque la UI filtra client-side a ventanas
  /// menores. Callers que quieran solo "último mes" pueden pasar `limit: 31`.
  Stream<List<BiometricCheckIn>> watchHistory(
    String userId, {
    int limit = 365,
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
    final snap =
        await _col(userId).orderBy('date', descending: true).limit(1).get();
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
