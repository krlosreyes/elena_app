// SPEC-111: implementación Firestore v1 del DailySummaryDataSource.
//
// Schema: users/{uid}/daily_summary/{YYYYMMDD}. El id del doc es el
// `date` formateado sin guiones para que sea válido como Firestore
// document id y ordenable lexicográficamente.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/analysis/data/sources/daily_summary_data_source.dart';

class FirestoreDailySummaryV1Source implements DailySummaryDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDailySummaryV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('daily_summary');

  @override
  Future<void> persist({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _collection(userId).doc(docId).set(data);
  }

  @override
  Future<Map<String, dynamic>?> readDoc({
    required String userId,
    required String docId,
  }) async {
    final snap = await _collection(userId).doc(docId).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchRange({
    required String userId,
    required String fromIncl,
    required String toIncl,
  }) {
    // `date` se guarda como `YYYY-MM-DD` (con guiones), comparable
    // lexicográficamente — el rango funciona como rango de fechas.
    return _collection(userId)
        .where('date', isGreaterThanOrEqualTo: fromIncl)
        .where('date', isLessThanOrEqualTo: toIncl)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
