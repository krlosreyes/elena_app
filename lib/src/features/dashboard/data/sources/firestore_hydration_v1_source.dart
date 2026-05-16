// SPEC-50.1: implementación Firestore v1 del HydrationDataSource.
//
// Schema legacy: users/{uid}/hydration_history/{auto-id}.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/dashboard/data/sources/hydration_data_source.dart';

class FirestoreHydrationV1Source implements HydrationDataSource {
  final FirebaseFirestore _firestore;

  FirestoreHydrationV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('hydration_history');

  @override
  Stream<List<Map<String, dynamic>>> streamSince({
    required String userId,
    required DateTime startOfDay,
  }) {
    return _collection(userId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<void> append({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _collection(userId).add(data);
  }
}
