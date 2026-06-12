// SPEC-205 inc1: fuente Firestore del feed de artículos.
//
// Colección: `metamorfosis_posts` (raíz). Filtro `status == "published"`,
// orden `publishedAt` desc. Requiere índice compuesto
// (status ASC + publishedAt DESC) — ver firestore.indexes.json.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/content/data/post_data_source.dart';

class FirestorePostSource implements PostDataSource {
  final FirebaseFirestore _firestore;

  FirestorePostSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String kCollection = 'metamorfosis_posts';

  @override
  Future<List<Map<String, dynamic>>> fetchPublishedRaw({int limit = 30}) async {
    final snap = await _firestore
        .collection(kCollection)
        .where('status', isEqualTo: 'published')
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) {
      // Fix Web: forzar Map Dart (cloud_firestore_web puede devolver
      // LegacyJavaScriptObject). Inyectamos el doc.id para el modelo.
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return data;
    }).toList();
  }

  CollectionReference<Map<String, dynamic>> _reads(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('post_reads');

  @override
  Future<void> incrementViews(String postId) async {
    await _firestore.collection(kCollection).doc(postId).update({
      'analytics.views': FieldValue.increment(1),
    });
  }

  @override
  Future<void> markRead({
    required String userId,
    required String postId,
  }) async {
    await _reads(userId).doc(postId).set({
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<Set<String>> watchReadIds(String userId) {
    return _reads(userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }
}
