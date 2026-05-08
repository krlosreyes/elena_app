// SPEC-50.4: implementación Firestore v1 del FastingIntervalDataSource.
//
// Schema legacy: colección flat `fasting_history/{docId}` con `userId`
// como campo del doc. Distinto del resto de pilares que usan
// `users/{uid}/...`. Decisión histórica preservada — esta SPEC envuelve
// el schema, no lo migra.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/dashboard/data/sources/fasting_interval_data_source.dart';

class FirestoreFastingIntervalV1Source implements FastingIntervalDataSource {
  final FirebaseFirestore _firestore;

  FirestoreFastingIntervalV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('fasting_history');

  @override
  Stream<Map<String, dynamic>?> streamLatest(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    });
  }

  @override
  Future<String> closeAllOpenAndCreate({
    required String userId,
    required DateTime closeAt,
    required Map<String, dynamic> Function(String newDocId) buildNewData,
  }) async {
    final batch = _firestore.batch();

    // 1. Buscar todos los abiertos para cerrarlos.
    final openQuery = await _collection
        .where('userId', isEqualTo: userId)
        .where('endTime', isNull: true)
        .get();

    for (final doc in openQuery.docs) {
      batch.update(doc.reference, {
        'endTime': Timestamp.fromDate(closeAt),
      });
    }

    // 2. Crear el nuevo (id auto-generado).
    final newDocRef = _collection.doc();
    final data = buildNewData(newDocRef.id);
    batch.set(newDocRef, data);

    await batch.commit();
    return newDocRef.id;
  }
}
