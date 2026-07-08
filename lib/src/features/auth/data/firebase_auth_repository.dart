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

import 'dart:async';

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
      throw Exception(
          'Sesión no encontrada. Vuelve a abrir el link del email.');
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // SPEC-248b: Orden correcto — Firestore PRIMERO, Auth DESPUÉS.
  //
  // El orden anterior (Auth → Firestore) era incorrecto: una vez que
  // `user.delete()` se ejecuta, el token de Auth queda inválido y las
  // reglas de Firestore rechazan cualquier write posterior. Resultado:
  // subcollections nunca se borraban del cliente.
  //
  // Nuevo orden:
  //   1. Borrar subcollections de users/{uid} (mientras auth es válido)
  //   2. Borrar doc raíz users/{uid}
  //   3. Borrar fasting_history plana (legacy SPEC-50.4)
  //   4. Eliminar Auth — dispara Cloud Function onUserDeleted como red de seguridad
  //   5. signOut local
  //
  // Si el paso 4 falla con requires-recent-login: Auth sigue existiendo pero
  // Firestore ya está limpio. El usuario puede reintentar sin inconsistencia.
  // La Cloud Function onUserDeleted (SPEC-207/248) actúa como red de seguridad
  // para datos creados en el intervalo o si el cliente falla a medio camino.
  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // 1. Borrar todas las subcollections MIENTRAS el usuario está autenticado.
    //    Las reglas de Firestore requieren request.auth válido para writes.
    for (final sub in _kUserSubcollections) {
      try {
        await _deleteSubcollection(uid, sub);
      } catch (_) {
        // Best-effort. La Cloud Function onUserDeleted lo limpia si falla.
      }
    }

    // 2. Borrar doc raíz users/{uid}.
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (_) {
      // Best-effort.
    }

    // 3. Borrar fasting_history plana legacy (SPEC-50.4 / SPEC-217 transición).
    try {
      await _deleteFastingHistoryForUser(uid);
    } catch (_) {
      // Best-effort.
    }

    // 4. Eliminar cuenta de Firebase Auth.
    //    Esto dispara la Cloud Function onUserDeleted (SPEC-207/248) como
    //    red de seguridad para cualquier dato residual.
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Por seguridad, tu sesión es muy antigua. Cierra sesión, '
          'vuelve a iniciar sesión y vuelve a intentar eliminar la cuenta.',
        );
      }
      throw _handleAuthException(e);
    } catch (_) {
      throw Exception('Error técnico al eliminar la cuenta de autenticación.');
    }

    // 5. Cerrar sesión local para limpiar caches de Firebase Auth.
    try {
      await _auth.signOut();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Subcolecciones bajo users/{uid} que se borran en cascada.
  /// Debe mantenerse sincronizado con USER_SUBCOLLECTIONS en functions/src/index.ts.
  static const _kUserSubcollections = [
    'sleep_history',
    'nutrition_history',
    'hydration_history',
    'exercise_history',
    'biometric_history',
    'metabolic_cycles',
    'daily_summary',
    'streak_history',
    'imr_history',
    'protocol_adjustments',
    'app_state',
    'fasting_checkins',
    'sleep_routines',
    'post_reads',
    'fasting_history',
  ];

  /// Borra todos los documentos de una subcollection en batches de 400.
  Future<void> _deleteSubcollection(String uid, String subcollection) async {
    const batchSize = 400;
    final col =
        _firestore.collection('users').doc(uid).collection(subcollection);
    var snapshot = await col.limit(batchSize).get();
    while (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      snapshot = await col.limit(batchSize).get();
    }
  }

  /// Borra los documentos de `fasting_history` donde `userId == uid`.
  ///
  /// SPEC-207 inc2 — best-effort en cliente mientras la Cloud Function
  /// corre en background. No lanza excepción; el caller la envuelve en try/catch.
  Future<void> _deleteFastingHistoryForUser(String uid) async {
    const batchSize = 400;
    final col = _firestore.collection('fasting_history');
    var snapshot =
        await col.where('userId', isEqualTo: uid).limit(batchSize).get();

    while (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      snapshot =
          await col.where('userId', isEqualTo: uid).limit(batchSize).get();
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

    // SPEC-206: `authStateChanges` hace asyncMap sobre `_buildAccount`. Si este
    // `.get()` se CUELGA (puede pasar tras la secuencia offline→reconexión→
    // logout→login), el stream nunca emite, `authState` queda en loading y el
    // router atrapa al usuario en /splash ("no permite el ingreso a la app").
    // El try/catch previo solo atrapaba errores, no un cuelgue. Blindaje:
    //   1. timeout sobre la lectura de servidor,
    //   2. fallback a SOLO caché local (un usuario existente tiene su doc en
    //      caché → se clasifica bien aunque el servidor no responda).
    Map<String, dynamic>? rawProfile;
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));
      rawProfile = snap.exists ? snap.data() : null;
    } catch (_) {
      try {
        final cached = await _firestore
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        rawProfile = cached.exists ? cached.data() : null;
      } catch (_) {
        // Sin servidor ni caché: tratamos como ausente. El router manda a
        // /onboarding; al recuperar red el authStateChanges re-emite y
        // re-clasifica.
        rawProfile = null;
      }
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
