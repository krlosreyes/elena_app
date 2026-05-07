// SPEC-63: implementación legacy del NutritionDataSource.
//
// Persiste a la colección plana `users/{uid}/nutrition_history/{logId}`.
// Esta es la estructura física actual del repo (anterior al SDD).
// SPEC-49 (R3) introducirá `firestore_nutrition_v2_source.dart` que
// escribe al aggregate `users/{uid}/daily_records/{date}/meals/{logId}`
// según `persistence.spec.md`. El intercambio se hará solo en el provider;
// la capa domain/application/presentation no se entera.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/nutrition/data/sources/nutrition_data_source.dart';

class FirestoreNutritionV1Source implements NutritionDataSource {
  FirestoreNutritionV1Source(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('nutrition_history');

  @override
  Stream<List<({String docId, Map<String, dynamic> data})>> watchTodayLogs(
    String userId,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _col(userId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (docId: doc.id, data: doc.data()))
            .toList(growable: false));
  }

  @override
  Future<void> saveLog(
    String userId,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _col(userId).doc(docId).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteLog(String userId, String docId) async {
    await _col(userId).doc(docId).delete();
  }

  @override
  Future<({String docId, Map<String, dynamic> data})?> latestTodayLog(
    String userId,
  ) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _col(userId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return (docId: doc.id, data: doc.data());
  }
}
