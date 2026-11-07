// Sign in with Apple (App Store 4.8, 2026-11-06).
//
// Vive fuera de [AuthRepository] a propósito: los tests tienen fakes que
// `implements AuthRepository` y un método nuevo los rompería (mismo
// criterio que AccountEmailService).
//
// Tres responsabilidades:
//   1. Entrar / registrarse con Apple (iOS). Al entrar bien,
//      `authStateChanges` mueve el router, igual que con Google.
//   2. Reautenticar con Apple antes de operaciones sensibles. Guarda el
//      `authorizationCode` fresco que devuelve Apple.
//   3. Antes de borrar la cuenta, revocar el token de Apple con ese código.
//      Apple exige la revocación para cuentas creadas con Sign in with
//      Apple; sin un código fresco no se puede, así que se fuerza la
//      reautenticación (ReauthRequiredException).

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/domain/auth_repository.dart';

/// `providerId` de Apple en Firebase.
const kAppleProviderId = 'apple.com';

/// True si el usuario actual tiene Apple entre sus proveedores.
bool userHasApple(User? user) =>
    user?.providerData.any((p) => p.providerId == kAppleProviderId) ?? false;

/// Códigos de Firebase que significan "el usuario canceló".
bool isAppleCancel(FirebaseAuthException e) =>
    e.code == 'canceled' ||
    e.code == 'cancelled' ||
    e.code == 'web-context-canceled' ||
    e.code == 'web-context-cancelled' ||
    e.code == 'user-cancelled' ||
    e.code == 'popup-closed-by-user' ||
    (e.message?.toLowerCase().contains('cancel') ?? false);

class AppleAuthService {
  AppleAuthService([FirebaseAuth? auth]) : _authOverride = auth;

  final FirebaseAuth? _authOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static const _timeout = Duration(seconds: 20);

  /// Código de autorización de la última reautenticación con Apple.
  String? _freshAuthorizationCode;

  /// Solo se ofrece en iOS (en Android pediría una web de Apple).
  static bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  AppleAuthProvider _provider() => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  /// Entra o registra con Apple. `false` si canceló.
  Future<bool> signIn() async {
    try {
      final cred = await _auth.signInWithProvider(_provider()).timeout(_timeout);
      _freshAuthorizationCode = cred.additionalUserInfo?.authorizationCode;
      return true;
    } on TimeoutException {
      throw Exception(
        'La conexión está tardando más de lo esperado. Verifica tu red e '
        'inténtalo de nuevo.',
      );
    } on FirebaseAuthException catch (e) {
      if (isAppleCancel(e)) return false;
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'Ya existe una cuenta con ese correo. Entra con tu contraseña o '
          'con Google.',
        );
      }
      if (e.code == 'operation-not-allowed') {
        throw Exception(
          'El ingreso con Apple no está disponible ahora mismo. Entra con '
          'tu correo y contraseña.',
        );
      }
      throw Exception('No pudimos entrar con Apple. Inténtalo de nuevo.');
    }
  }

  /// Reautentica al usuario actual con Apple. `false` si canceló.
  Future<bool> reauthenticate() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay sesión activa. Vuelve a iniciar sesión.');
    }
    try {
      final cred =
          await user.reauthenticateWithProvider(_provider()).timeout(_timeout);
      _freshAuthorizationCode = cred.additionalUserInfo?.authorizationCode;
      return true;
    } on TimeoutException {
      throw Exception(
        'La confirmación está tardando más de lo esperado. Verifica tu '
        'conexión e inténtalo de nuevo.',
      );
    } on FirebaseAuthException catch (e) {
      if (isAppleCancel(e)) return false;
      if (e.code == 'user-mismatch') {
        throw Exception(
          'Ese Apple ID no es el de esta sesión. Usa el mismo con el que '
          'entraste.',
        );
      }
      throw Exception('No pudimos confirmar tu identidad con Apple.');
    }
  }

  /// Paso previo al borrado de una cuenta con Apple: revoca el token.
  ///
  /// Sin un código fresco lanza [ReauthRequiredException] para que la UI
  /// reautentique con Apple y reintente. No hace nada si el usuario no
  /// usa Apple.
  Future<void> revokeBeforeDelete() async {
    final user = _auth.currentUser;
    if (!userHasApple(user)) return;
    final code = _freshAuthorizationCode;
    if (code == null) throw ReauthRequiredException(email: user?.email);
    try {
      await _auth.revokeTokenWithAuthorizationCode(code).timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'La eliminación está tardando más de lo esperado. Verifica tu '
        'conexión e inténtalo de nuevo. No se borró nada.',
      );
    } on FirebaseAuthException {
      // El código caduca a los 5 minutos y es de un solo uso: pedimos
      // reautenticar de nuevo en vez de borrar sin revocar.
      _freshAuthorizationCode = null;
      throw ReauthRequiredException(email: user?.email);
    } finally {
      _freshAuthorizationCode = null;
    }
  }
}

final appleAuthServiceProvider =
    Provider<AppleAuthService>((ref) => AppleAuthService());
