import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class AuthService {
  final FirebaseFirestore _firestore;

  AuthService(this._firestore, _);

  /// Completes onboarding by saving user data and marking as completed.
  Future<void> completeOnboarding(UserModel user) async {
    final updatedUser = user.copyWith(
      onboardingCompleted: true,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(updatedUser.uid)
        .set(updatedUser.toJson(), SetOptions(merge: true));
  }

  /// Returns a stream of the user model for the currently logged in user.
  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;

      try {
        return UserModel.fromJson(doc.data()!);
      } catch (e) {
        // En caso de error de parseo (ej: falta un campo requerido nuevo)
        // intentamos recuperar lo que se pueda o devolvemos null para que el
        // Controller lo re-active con valores por defecto.
        return null;
      }
    });
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseFirestore.instance, FirebaseAuth.instance);
});
