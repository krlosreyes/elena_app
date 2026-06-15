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
    // BUG-FIX: antes faltaba orderBy('timestamp'). Firestore exige que el
    // campo del filtro de rango tenga un orderBy explícito para usar el
    // índice correcto. Sin él, los docs se devuelven en orden de docId
    // (alfabético) → el índice de timestamp no se usa → el stream puede
    // no actualizarse en vivo correctamente con la caché offline.
    // deleteLatest ya usaba orderBy — ahora streamSince es consistente.
    Query<Map<String, dynamic>> query = _collection(userId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp');
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

  @override
  Future<void> deleteLatest({
    required String userId,
    required DateTime since,
  }) async {
    final snap = await _collection(userId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.delete();
  }

  @override
  Future<void> deleteById({
    required String userId,
    required String logId,
  }) async {
    // Firestore delete es idempotente — no lanza si el doc no existe.
    await _collection(userId).doc(logId).delete();
  }
}
