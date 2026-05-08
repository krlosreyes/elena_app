// SPEC-50: implementación Firestore v1 del SleepDataSource.
//
// Schema legacy: users/{uid}/sleep_history/{logId}. Cada documento
// representa un ciclo de sueño individual.
//
// SPEC-49 (R3 final) introducirá v2 que escribirá a un aggregate
// daily_records — pero ese SPEC tendrá su propia data source
// implementando el mismo contrato. El switch entre v1/v2 será
// transparente para el repositorio y los notifiers.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/dashboard/data/sources/sleep_data_source.dart';

class FirestoreSleepV1Source implements SleepDataSource {
  final FirebaseFirestore _firestore;

  FirestoreSleepV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('sleep_history');

  @override
  Stream<Map<String, dynamic>?> streamLatest(String userId) {
    return _collection(userId)
        .orderBy('wokeUp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      // Inyectamos el doc.id en el map para que el mapper lo use como
      // identidad — el id no se persiste en el body del doc, solo
      // como clave del Firestore document.
      return {...doc.data(), '__docId': doc.id};
    });
  }

  @override
  Future<void> persist({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _collection(userId).doc(docId).set(data);
  }
}
