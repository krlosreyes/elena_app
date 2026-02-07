import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/exceptions/exceptions.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository(this._firebaseAuth);

  /// Returns the current signed-in [User], or `null` if the user is signed out.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream to listen for authentication state changes.
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  /// Signs in a user with email and password.
  ///
  /// Throws [AppException] with Spanish error messages for common cases.
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // 🛑 NUCLEAR FIX: No usamos 'on FirebaseAuthException'. Atrapamos TODO.
      final errorRaw = e.toString();
      print('🚨 ERROR CRUDO: $errorRaw');

      // Búsqueda de texto simple para evitar problemas de tipos
      if (errorRaw.contains('user-not-found') || errorRaw.contains('invalid-credential') || errorRaw.contains('wrong-password')) {
         throw AppException('Credenciales incorrectas.', 'auth/invalid-credentials');
      }
      if (errorRaw.contains('invalid-email')) {
         throw AppException('El formato del correo es inválido.', 'auth/invalid-email');
      }
      if (errorRaw.contains('user-disabled')) {
         throw AppException('Esta cuenta ha sido deshabilitada.', 'auth/user-disabled');
      }
      if (errorRaw.contains('network-request-failed')) {
         throw AppException('Error de conexión. Verifica tu internet.', 'auth/network-error');
      }
      if (errorRaw.contains('too-many-requests')) {
         throw AppException('Demasiados intentos. Intenta más tarde.', 'auth/too-many-requests');
      }

      // Si no coincide, lanzamos el error genérico limpio
      throw AppException(errorRaw, 'unknown');
    }
  }

  /// Creates a new user account with email and password.
  ///
  /// Throws [AppException] with Spanish error messages for common cases.
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // 🛑 NUCLEAR FIX: No usamos 'on FirebaseAuthException'. Atrapamos TODO.
      final errorRaw = e.toString();
      print('🚨 ERROR CRUDO: $errorRaw'); 

      // Búsqueda de texto simple para evitar problemas de tipos
      if (errorRaw.contains('email-already-in-use')) {
        throw AppException('Este correo ya está registrado.', 'email-exists');
      }
      if (errorRaw.contains('weak-password')) {
        throw AppException('La contraseña es muy débil (mínimo 6 caracteres).', 'weak-pass');
      }
      if (errorRaw.contains('invalid-email')) {
        throw AppException('El correo no es válido.', 'invalid-email');
      }
      if (errorRaw.contains('operation-not-allowed')) {
        throw AppException('Habilita Email/Password en Firebase Console.', 'config-error');
      }

      // Si no coincide, lanzamos el error genérico limpio
      throw AppException(errorRaw, 'unknown');
    }
  }

  /// Signs out the current user.
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
        return const AppException('Credenciales incorrectas.', 'auth/invalid-credentials');
      case 'email-already-in-use':
        return const AppException('El correo ya está registrado.', 'auth/email-in-use');
      case 'invalid-email':
        return const AppException('El formato del correo es inválido.', 'auth/invalid-email');
      case 'weak-password':
        return const AppException('La contraseña es muy débil.', 'auth/weak-password');
      case 'user-disabled':
        return const AppException('Esta cuenta ha sido deshabilitada.', 'auth/user-disabled');
      case 'network-request-failed':
        return const AppException('Error de conexión. Verifica tu internet.', 'auth/network-error');
      case 'too-many-requests':
        return const AppException('Demasiados intentos. Intenta más tarde.', 'auth/too-many-requests');
      default:
        return AppException('Error de autenticación: ${e.message}', e.code);
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(FirebaseAuth.instance);
}

@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}
