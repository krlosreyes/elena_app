// SPEC-73: implementación Firebase del AuthRepository.
//
// Diferencias vs versión previa:
// - `signInWithEmail` retorna AppAccount y NUNCA lanza por ausencia de
//   perfil. La asunción anterior de que un sign-in válido implicaba un
//   doc `users/{uid}` con shape estricto rompía el flujo de usuarios
//   provenientes de metamorfosisreal.com (BD compartida, mismo
//   proyecto Firebase, distinto shape de perfil).
// - `authStateChanges` emite AppAccount no-nulo para cualquier usuario
//   autenticado. El null queda reservado a "no autenticado".
// - Se eliminó el método `isUserOnboarded`. El router lee
//   `AppAccount.profileStatus` directamente, evitando una lectura
//   extra de Firestore por cada cambio de ruta.
// - Nuevos métodos para magic link (RF-73-09): `sendSignInLinkToEmail`,
//   `signInWithEmailLink`, `setPassword`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/shared/domain/validators/user_profile_validator.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AppAccount?> get authStateChanges =>
      _auth.authStateChanges().asyncMap<AppAccount?>((firebaseUser) async {
        if (firebaseUser == null) return null;
        return _buildAccount(firebaseUser);
      });

  @override
  Future<AppAccount> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      // Seed mínimo: id + name + email. NO escribe age/weight/height
      // porque el OnboardingController los completará. El doc queda en
      // estado PARTIAL inmediatamente y el router lo redirige a
      // /onboarding.
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': name,
        'email': email,
      }, SetOptions(merge: true));
      return AppAccount(
        uid: user.uid,
        email: email,
        displayName: name,
        profileStatus: AppProfileStatus.partialProfile,
        rawProfile: {'id': user.uid, 'name': name, 'email': email},
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<AppAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _buildAccount(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // SPEC-73 §RF-73-09: magic link.
  //
  // ActionCodeSettings.url debe coincidir con el dominio autorizado en
  // Firebase Console > Authentication > Authorized domains. El handler
  // del deep link en el cliente extrae el link y llama
  // `signInWithEmailLink`.
  @override
  Future<void> sendSignInLinkToEmail(String email) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://elena-app-2026-v1.firebaseapp.com/set-password',
          handleCodeInApp: true,
          androidPackageName: 'com.metamorfosis.elena.elena_app',
          androidInstallApp: true,
          androidMinimumVersion: '1',
          iOSBundleId: 'com.metamorfosis.elena.elenaApp',
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<AppAccount> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        throw Exception('Link de acceso inválido o expirado.');
      }
      final credential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      return _buildAccount(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> setPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Sesión no encontrada. Vuelve a abrir el link del email.');
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final uid = user.uid;
      await _firestore.collection('users').doc(uid).delete();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Seguridad: por favor re-inicia sesión antes de eliminar tu cuenta.',
        );
      }
      throw _handleAuthException(e);
    } catch (_) {
      throw Exception('Error técnico al eliminar cuenta.');
    }
  }

  /// Lee `users/{uid}` y construye el AppAccount clasificando el shape.
  ///
  /// SPEC-73 §CA-73-01/02/03 — 3 ramas:
  /// - doc no existe → NEW_PROFILE, rawProfile = null
  /// - doc existe pero incompleto → PARTIAL_PROFILE, rawProfile = doc
  /// - doc existe y completo → COMPLETE_PROFILE, rawProfile = doc
  Future<AppAccount> _buildAccount(User firebaseUser) async {
    final email = firebaseUser.email ?? '';
    final displayName = firebaseUser.displayName;
    final uid = firebaseUser.uid;
    final createdAt = firebaseUser.metadata.creationTime;

    Map<String, dynamic>? rawProfile;
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      rawProfile = snap.exists ? snap.data() : null;
    } catch (_) {
      // Pérdida momentánea de red: tratamos como ausente. El router
      // mandará a /onboarding; al recuperar red el authStateChanges
      // re-emite y re-clasifica.
      rawProfile = null;
    }

    final AppProfileStatus status;
    if (rawProfile == null) {
      status = AppProfileStatus.newProfile;
    } else if (UserProfileValidator.isCompleteFromRaw(rawProfile)) {
      status = AppProfileStatus.completeProfile;
    } else {
      status = AppProfileStatus.partialProfile;
    }

    // Si el email no estaba denormalizado en el doc, lo añadimos.
    // Facilita queries cross-app y queries de admin sin abrir reglas.
    if (rawProfile != null && rawProfile['email'] == null) {
      // Best-effort, no bloqueamos el login si falla.
      _firestore.collection('users').doc(uid).set(
        {'email': email},
        SetOptions(merge: true),
      ).catchError((_) {});
    }

    return AppAccount(
      uid: uid,
      email: email,
      displayName: displayName ??
          (rawProfile?['name'] as String?) ??
          (rawProfile?['displayName'] as String?),
      profileStatus: status,
      rawProfile: rawProfile,
      createdAt: createdAt,
    );
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('Contraseña débil.');
      case 'email-already-in-use':
        // SPEC-73 §RF-73-08: mensaje específico que sugiere usar
        // sign-in en lugar de registro. El usuario MR llega aquí
        // cuando intenta "registrarse" con un email que ya existe en
        // la user-pool compartida.
        return Exception(
          'Ya tienes cuenta en Metamorfosis Real. '
          'Inicia sesión con tu contraseña.',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Credenciales incorrectas.');
      case 'invalid-email':
        return Exception('Email inválido.');
      case 'user-disabled':
        return Exception('Esta cuenta está suspendida.');
      case 'too-many-requests':
        return Exception(
          'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
        );
      case 'network-request-failed':
        return Exception('Sin conexión. Verifica tu internet.');
      default:
        return Exception('Error de autenticación: ${e.code}.');
    }
  }
}
