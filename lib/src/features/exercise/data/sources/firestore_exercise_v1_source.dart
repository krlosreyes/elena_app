// SPEC-50.2: implementación Firestore v1 del ExerciseDataSource.
//
// Schema legacy: users/{uid}/exercise_history/{logId}.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/exercise/data/sources/exercise_data_source.dart';

class FirestoreExerciseV1Source implements ExerciseDataSource {
  final FirebaseFirestore _firestore;

  FirestoreExerciseV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('exercise_history');

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
  Future<void> persist({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _collection(userId).doc(docId).set(data);
  }
}
