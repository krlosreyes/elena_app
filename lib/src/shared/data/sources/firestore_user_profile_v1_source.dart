// SPEC-50.5: implementación Firestore v1 del UserProfileDataSource.
//
// Schema legacy: users/{uid}.
// Subcolección: users/{uid}/protocol_adjustments/{auto-id}.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/shared/data/sources/user_profile_data_source.dart';

class FirestoreUserProfileV1Source implements UserProfileDataSource {
  final FirebaseFirestore _firestore;

  FirestoreUserProfileV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // SPEC-87: inyectamos `id` del doc Firestore al map antes de
  // devolverlo. El sitio web Metamorfosis Real escribe el shape
  // canónico SIN un campo `id` plano (el id es el del doc, no se
  // duplica). Sin este patch, `UserModel.id` queda en '' y los
  // notifiers que construyen paths con `user.id` (streak, sleep,
  // hydration, exercise, nutrition) generan paths inválidos
  // (`users//streak_history`) que Firestore rechaza con
  // `permission-denied`.
  //
  // El id del doc Firestore es la fuente autoritativa — si el doc
  // trajera un id distinto, lo sobrescribimos.
  @override
  Stream<Map<String, dynamic>?> streamProfile(String userId) {
    return _users.doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return <String, dynamic>{...data, 'id': userId};
    });
  }

  @override
  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _users.doc(userId).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    if (updates.isEmpty) return;
    await _users.doc(userId).update(updates);
  }

  @override
  Future<void> appendProtocolAdjustment({
    required String userId,
    required Map<String, dynamic> adjustment,
  }) async {
    await _users.doc(userId).collection('protocol_adjustments').add({
      ...adjustment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
