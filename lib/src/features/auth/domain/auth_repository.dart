// SPEC-73: contrato de identidad post-autenticación.
//
// AuthRepository NUNCA lanza Exception por ausencia o shape del
// documento `users/{uid}`. La ausencia se modela vía
// `AppAccount.profileStatus == newProfile`, el shape inválido vía
// `partialProfile`. Sólo lanza para errores reales de credenciales
// (wrong-password, user-not-found, network) o de plataforma.

import 'package:elena_app/src/features/auth/domain/app_account.dart';

abstract class AuthRepository {
  /// Stream del estado de autenticación.
  ///
  /// Emite `null` SÓLO cuando no hay sesión activa en Firebase Auth.
  /// Para cualquier usuario autenticado emite un `AppAccount` no-nulo,
  /// anexando su `profileStatus` (NEW / PARTIAL / COMPLETE).
  Stream<AppAccount?> get authStateChanges;

  /// Registra un usuario con email/password y crea el documento de
  /// perfil mínimo en Firestore.
  ///
  /// El AppAccount retornado siempre tiene `profileStatus = newProfile`
  /// porque acabamos de crear la cuenta — el OnboardingController es
  /// quien completa los campos.
  Future<AppAccount> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Valida credenciales contra Firebase Auth y clasifica el estado de
  /// perfil del usuario.
  ///
  /// Retorna `AppAccount` con uno de tres `profileStatus`:
  /// - `newProfile`: doc `users/{uid}` no existe.
  /// - `partialProfile`: doc existe pero no cumple invariantes mínimos.
  /// - `completeProfile`: doc cumple invariantes.
  ///
  /// NUNCA lanza por ausencia de perfil. Sólo por credenciales
  /// inválidas (wrong-password, user-not-found, etc.).
  Future<AppAccount> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  /// SPEC-73 §RF-73-09: dispara email transaccional con magic link para
  /// usuarios MR que necesitan establecer contraseña por primera vez.
  Future<void> sendSignInLinkToEmail(String email);

  /// Valida el magic link y autentica al usuario. Después de esta
  /// llamada el usuario está autenticado pero típicamente sin password
  /// — el flujo de UI debe forzar `setPassword` inmediatamente.
  Future<AppAccount> signInWithEmailLink({
    required String email,
    required String emailLink,
  });

  /// Establece (o reemplaza) la contraseña del usuario autenticado.
  /// Sólo válido inmediatamente después de `signInWithEmailLink`.
  Future<void> setPassword(String newPassword);

  Future<void> deleteAccount();
}
