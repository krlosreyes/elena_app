import 'package:elena_app/src/shared/domain/models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
  
  Future<bool> isUserOnboarded(String uid);

  // MÉTODO AGREGADO: Definición del contrato de eliminación
  Future<void> deleteAccount();
}