// SPEC-261.4: implementación Firestore v1 del documento de sesión.
//
// Schema: users/{uid}/alcohol_session/current. Cubierto por la regla
// catch-all `/{allPaths=**}` de firestore.rules (dueño), igual que
// alcohol_history — no requiere regla nueva.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/alcohol/data/sources/consumption_session_data_source.dart';

class FirestoreConsumptionSessionV1Source
    implements ConsumptionSessionDataSource {
  final FirebaseFirestore _firestore;

  FirestoreConsumptionSessionV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('alcohol_session')
      .doc('current');

  @override
  Stream<Map<String, dynamic>?> watch(String userId) {
    return _doc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      // Fix Web (igual que hydration): forzar Map Dart.
      return Map<String, dynamic>.from(data);
    });
  }

  @override
  Future<void> save({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _doc(userId).set(data);
  }

  @override
  Future<void> clear(String userId) async {
    await _doc(userId).delete();
  }
}
