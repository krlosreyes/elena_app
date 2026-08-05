// SPEC-264: implementación Firestore de los zumbidos.
//
// Schema: challenges/{code}/nudges/{autoId} = { fromUid, fromName, toUid,
// typeId, createdAt (millis) }. La consulta "para mí" es una igualdad simple
// (toUid == uid) → índice de campo único automático; se ordena en cliente para
// no necesitar índice compuesto.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/challenges/data/sources/nudge_data_source.dart';

class FirestoreNudgeV1Source implements NudgeDataSource {
  final FirebaseFirestore _firestore;

  FirestoreNudgeV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _nudges(String code) => _firestore
      .collection('challenges')
      .doc(code)
      .collection('nudges');

  @override
  Future<void> send(String code, Map<String, dynamic> data) async {
    await _nudges(code).add(data);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchForRecipient(
    String code,
    String uid,
  ) {
    return _nudges(code)
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              return {...Map<String, dynamic>.from(d.data()), 'id': d.id};
            }).toList());
  }
}
