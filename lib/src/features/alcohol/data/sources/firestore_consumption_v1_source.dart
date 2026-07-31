// SPEC-261: implementación Firestore v1 del ConsumptionDataSource.
//
// Schema: users/{uid}/alcohol_history/{auto-id}. Mismo patrón y mismos
// fixes que FirestoreHydrationV1Source (SPEC-50.1), incluida la conversión
// defensiva a Map<String, dynamic> por el bug de cloud_firestore_web.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/alcohol/data/sources/consumption_data_source.dart';

class FirestoreConsumptionV1Source implements ConsumptionDataSource {
  final FirebaseFirestore _firestore;

  FirestoreConsumptionV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('alcohol_history');

  @override
  Stream<List<Map<String, dynamic>>> streamSince({
    required String userId,
    required DateTime startOfDay,
    DateTime? endOfDay,
  }) {
    Query<Map<String, dynamic>> query = _collection(userId).where(
      'timestamp',
      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
    );
    if (endOfDay != null) {
      query =
          query.where('timestamp', isLessThan: Timestamp.fromDate(endOfDay));
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => Map<String, dynamic>.from(d.data()))
              .toList(),
        );
  }

  @override
  Future<void> append({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _collection(userId).add(data);
  }

  @override
  Future<void> deleteLatest({
    required String userId,
    required DateTime since,
  }) async {
    final snap = await _collection(userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.delete();
  }
}
