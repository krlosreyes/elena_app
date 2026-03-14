import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/exceptions/exceptions.dart';

/// Interfaz que define el contrato de autenticación, facilitando
/// la inyección de dependencias y el Unit Testing (Mocking).
abstract class IAuthRepository {
  User? get currentUser;
  Stream<User?> authStateChanges();
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}

/// Implementación concreta de IAuthRepository usando Firebase.
class AuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository(this._firebaseAuth);

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // ✅ MEJORA DE SEGURIDAD (No Nuclear Fix):
      // Se analizan solo las excepciones nativas de Firebase para evitar
      // ocultar errores fatales del framework.
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      // Cualquier otro error inesperado se reporta sin filtrar información
      throw AppException(e.toString(), 'unknown');
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // ✅ MEJORA DE SEGURIDAD
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AppException(e.toString(), 'unknown');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw const UnknownException();
    }
  }

  AppException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AppException(
            'Credenciales incorrectas.', 'auth/invalid-credentials');
      case 'email-already-in-use':
        return const AppException(
            'El correo ya está registrado.', 'auth/email-in-use');
      case 'invalid-email':
        return const AppException(
            'El formato del correo es inválido.', 'auth/invalid-email');
      case 'weak-password':
        return const AppException(
            'La contraseña es muy débil.', 'auth/weak-password');
      case 'user-disabled':
        return const AppException(
            'Esta cuenta ha sido deshabilitada.', 'auth/user-disabled');
      case 'network-request-failed':
        return const AppException(
            'Error de conexión. Verifica tu internet.', 'auth/network-error');
      case 'too-many-requests':
        return const AppException('Demasiados intentos. Intenta más tarde.',
            'auth/too-many-requests');
      default:
        return AppException('Error de autenticación: ${e.message}', e.code);
    }
  }
}

// ✅ Provider configurado hacia la Interfaz
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

