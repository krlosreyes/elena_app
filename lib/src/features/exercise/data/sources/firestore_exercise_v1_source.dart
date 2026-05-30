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
    DateTime? endOfDay,
  }) {
    Query<Map<String, dynamic>> query = _collection(userId).where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay));
    if (endOfDay != null) {
      query = query.where('timestamp',
          isLessThan: Timestamp.fromDate(endOfDay));
    }
    return query
        .snapshots()
        // Fix Web: cloud_firestore_web puede retornar
        // LegacyJavaScriptObject como `data()` aunque la collection
        // esté tipada. Forzamos conversión a Map Dart con .from().
        .map((snap) => snap.docs
            .map((d) => Map<String, dynamic>.from(d.data()))
            .toList());
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
