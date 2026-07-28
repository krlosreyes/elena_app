// SPEC-73: contrato de identidad post-autenticación.
//
// AuthRepository NUNCA lanza Exception por ausencia o shape del
// documento `users/{uid}`. La ausencia se modela vía
// `AppAccount.profileStatus == newProfile`, el shape inválido vía
// `partialProfile`. Sólo lanza para errores reales de credenciales
// (wrong-password, user-not-found, network) o de plataforma.

import 'package:elena_app/src/features/auth/domain/app_account.dart';

/// Firebase exige una autenticación reciente para operaciones sensibles
/// (`requires-recent-login`). Se lanza tipada, y no como una `Exception`
/// con mensaje suelto, porque la UI tiene que poder DISTINGUIRLA para
/// ofrecer el diálogo de contraseña en vez de limitarse a mostrar texto.
///
/// Antes del 27-jul-2026 el repositorio lanzaba
/// `Exception('Por seguridad, tu sesión es muy antigua. Cierra sesión,
/// vuelve a iniciar sesión…')`. La pantalla no tenía forma fiable de
/// reconocer ese caso —habría tenido que comparar cadenas— así que el
/// único remedio ofrecido al usuario era salir y volver a entrar a mano.
/// Para App Store 5.1.1(v), que exige que borrar la cuenta sea sencillo,
/// eso no basta.
class ReauthRequiredException implements Exception {
  const ReauthRequiredException({this.email});

  /// Email de la cuenta, para prellenar el diálogo si se conoce.
  final String? email;

  @override
  String toString() =>
      'Por seguridad hace falta que confirmes tu identidad antes de '
      'continuar. Tus datos siguen intactos.';
}

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

  /// Vuelve a autenticar al usuario actual con su contraseña, para
  /// refrescar la "sesión reciente" que Firebase exige antes de borrar
  /// la cuenta.
  ///
  /// Lanza `Exception` con mensaje presentable si la contraseña es
  /// incorrecta o si la cuenta no tiene contraseña — caso posible en
  /// usuarios que entraron por magic link y nunca pasaron por
  /// [setPassword]. Para ellos la vía es restablecer la contraseña con
  /// [sendPasswordResetEmail]; reautenticar con el propio magic link
  /// exigiría rehacer todo ese flujo y queda fuera de alcance.
  Future<void> reauthenticateWithPassword(String password);

  /// Elimina la cuenta de Firebase Auth.
  ///
  /// Lanza [ReauthRequiredException] si Firebase pide sesión reciente.
  /// En ese caso NO se ha borrado nada: la UI debe pedir la contraseña,
  /// llamar a [reauthenticateWithPassword] y reintentar.
  Future<void> deleteAccount();

  /// FIRE-01 (auditoría técnica 21-jul): lee el custom claim
  /// `trialExpiresAt` (epoch millis) fijado server-side por la Cloud
  /// Function `onUserCreated` (SEC-02) — inmune a que el usuario atrase
  /// el reloj del dispositivo o reinstale la app (lo que sí borra el
  /// high-water-mark local que usa `billing_providers.dart` como único
  /// mecanismo hasta este fix).
  ///
  /// Devuelve `null` si no hay usuario autenticado, si el claim todavía
  /// no existe (cuentas creadas antes de este trigger, o el token recién
  /// emitido en el signup que aún no lo incluye — ver nota en
  /// `functions/src/index.ts`), o si la lectura falla. El caller debe
  /// tratar `null` como "usar el cálculo local de respaldo", nunca como
  /// "trial vencido".
  ///
  /// `forceRefresh: true` fuerza a pedir un token nuevo al servidor en
  /// vez de reusar el cacheado — necesario justo después del signup,
  /// donde el primer token emitido puede no incluir el claim todavía.
  Future<int?> getTrialExpiresAtClaimMillis({bool forceRefresh = false});
}
