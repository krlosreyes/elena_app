// SPEC-50.3: implementación Firestore v1 del StreakDataSource.
//
// Schema legacy: users/{uid}/streak_history/{dateKey}.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/streak/data/sources/streak_data_source.dart';

class FirestoreStreakV1Source implements StreakDataSource {
  final FirebaseFirestore _firestore;

  FirestoreStreakV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('streak_history');

  @override
  Stream<List<Map<String, dynamic>>> streamSince({
    required String userId,
    required String cutoffDateKey,
  }) {
    return _collection(userId)
        .where('date', isGreaterThanOrEqualTo: cutoffDateKey)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Future<void> persistMerged({
    required String userId,
    required String dateKey,
    required Map<String, dynamic> data,
  }) async {
    await _collection(userId).doc(dateKey).set(data, SetOptions(merge: true));
  }
}
