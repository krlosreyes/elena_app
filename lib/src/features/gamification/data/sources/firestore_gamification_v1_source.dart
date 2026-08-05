// SPEC-262: implementación Firestore del wallet.
//
// Schema: users/{uid}/gamification/state (doc único). La colección
// 'gamification' NO está en la lista de exclusión de firestore.rules, así que
// el catch-all `/{allPaths=**}` permite create/update/delete del dueño
// (withinSizeLimit < 100 KB, sin campo 'id'). No requiere regla nueva.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/gamification/data/sources/gamification_data_source.dart';

class FirestoreGamificationV1Source implements GamificationDataSource {
  final FirebaseFirestore _firestore;

  FirestoreGamificationV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('gamification')
      .doc('state');

  @override
  Stream<Map<String, dynamic>?> watch(String userId) {
    return _doc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      // Fix Web: forzar Map Dart (cloud_firestore_web puede devolver
      // LegacyJavaScriptObject).
      return Map<String, dynamic>.from(data);
    });
  }

  @override
  Future<void> save({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _doc(userId).set(data, SetOptions(merge: true));
  }
}
