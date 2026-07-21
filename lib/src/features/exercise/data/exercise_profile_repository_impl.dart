// Propuesta módulo Ejercicio (2026-07-21): implementación Firestore del
// perfil de hábitos de ejercicio.
//
// Schema: users/{uid}/exercise_meta/profile — documento único (no una
// colección de entradas históricas, a diferencia de exercise_history).
// Se aisla en su propia subcolección en vez de mezclarse en el doc raíz
// de `users/{uid}` para no competir por escrituras concurrentes con el
// resto de mappers que ya escriben ahí (UserModel completo).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/exercise/domain/exercise_profile.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_profile_repository.dart';

class ExerciseProfileRepositoryImpl implements ExerciseProfileRepository {
  final FirebaseFirestore _firestore;

  ExerciseProfileRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('exercise_meta')
      .doc('profile');

  @override
  Future<void> save(String userId, ExerciseProfile profile) async {
    await _doc(userId).set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Future<ExerciseProfile?> fetch(String userId) async {
    final snap = await _doc(userId).get();
    final data = snap.data();
    if (data == null) return null;
    return ExerciseProfile.fromMap(data);
  }

  @override
  Stream<ExerciseProfile?> watch(String userId) {
    return _doc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return ExerciseProfile.fromMap(data);
    });
  }
}

final exerciseProfileRepositoryProvider =
    Provider<ExerciseProfileRepository>((ref) {
  return ExerciseProfileRepositoryImpl();
});
