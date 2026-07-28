// SPEC-50.1: implementación Firestore v1 del HydrationDataSource.
//
// Schema legacy: users/{uid}/hydration_history/{auto-id}.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/hydration/data/sources/hydration_data_source.dart';

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
    DateTime? endOfDay,
  }) {
    Query<Map<String, dynamic>> query = _collection(userId).where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay));
    if (endOfDay != null) {
      query =
          query.where('timestamp', isLessThan: Timestamp.fromDate(endOfDay));
    }
    return query
        .snapshots()
        // Fix Web: cloud_firestore_web puede retornar
        // LegacyJavaScriptObject como `data()` aunque la collection
        // esté tipada como Map<String, dynamic>. Forzamos conversión
        // a Map Dart con .from() — funciona idéntico en mobile.
        .map((snap) =>
            snap.docs.map((d) => Map<String, dynamic>.from(d.data())).toList());
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
