// SPEC-263: implementación Firestore de la fuente de retos.
//
// Schema:
//   challenges/{code}              → metadata (memberIds array-contains query)
//   challenges/{code}/scores/{uid} → puntaje por miembro (único escritor)
//
// "Mis retos" = query por `memberIds array-contains uid`. Es un índice de
// campo único AUTOMÁTICO (no requiere firestore.indexes.json), porque no
// combinamos el array-contains con ningún orderBy — ordenamos en cliente.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/challenges/data/sources/challenge_data_source.dart';

class FirestoreChallengeV1Source implements ChallengeDataSource {
  final FirebaseFirestore _firestore;

  FirestoreChallengeV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection('challenges');

  DocumentReference<Map<String, dynamic>> _doc(String code) =>
      _challenges.doc(code);

  CollectionReference<Map<String, dynamic>> _scores(String code) =>
      _doc(code).collection('scores');

  Map<String, dynamic> _asDartMap(Map<String, dynamic> data) =>
      // Fix Web: cloud_firestore_web puede devolver LegacyJavaScriptObject.
      Map<String, dynamic>.from(data);

  @override
  Stream<List<Map<String, dynamic>>> watchMyChallenges(String userId) {
    return _challenges
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              // El id del doc (== código) no viaja dentro de data(): lo
              // inyectamos con la clave 'code' para que el mapper lo lea.
              return {..._asDartMap(d.data()), 'code': d.id};
            }).toList());
  }

  @override
  Stream<Map<String, dynamic>?> watchChallenge(String code) {
    return _doc(code).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return _asDartMap(data);
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchScores(String code) {
    return _scores(code)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _asDartMap(d.data())).toList());
  }

  @override
  Future<void> createChallenge(String code, Map<String, dynamic> data) async {
    await _doc(code).set(data);
  }

  @override
  Future<void> joinChallenge(String code, List<String> memberIds) async {
    await _doc(code).update({'memberIds': memberIds});
  }

  @override
  Future<void> publishScore(
    String code,
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _scores(code).doc(uid).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> removeScore(String code, String uid) async {
    await _scores(code).doc(uid).delete();
  }

  @override
  Future<void> deleteChallenge(String code) async {
    await _doc(code).delete();
  }
}
