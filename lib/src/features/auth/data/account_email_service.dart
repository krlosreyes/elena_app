// Rediseño Perfil (2026-11-04): cambio de correo con verificación.
//
// Firebase recomienda `verifyBeforeUpdateEmail()` en lugar de
// `updateEmail()`: envía un enlace al correo NUEVO y el cambio solo se
// aplica cuando el usuario lo abre. Hasta entonces sigue entrando con el
// correo actual — nadie queda bloqueado por un error de tipeo.
//
// Vive fuera de AuthRepository a propósito: la interfaz tiene fakes en los
// tests (`implements AuthRepository`) y un método nuevo los rompería.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/utils/error_presentation.dart';

class AccountEmailService {
  AccountEmailService([FirebaseAuth? auth]) : _authOverride = auth;

  final FirebaseAuth? _authOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  /// Validación local del correo nuevo. Null = válido.
  static String? validate(String newEmail, {String? currentEmail}) {
    final e = newEmail.trim();
    if (e.isEmpty) return 'Escribe tu correo nuevo.';
    if (!_emailRe.hasMatch(e)) return 'Ese correo no parece válido.';
    if (currentEmail != null &&
        e.toLowerCase() == currentEmail.trim().toLowerCase()) {
      return 'Ese ya es tu correo actual.';
    }
    return null;
  }

  /// Envía el enlace de confirmación al correo nuevo. Requiere una sesión
  /// reciente: el llamador debe reautenticar antes.
  Future<void> requestEmailChange(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión activa.');
    }
    await _auth.setLanguageCode('es');
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  /// Mensaje en español para los errores de Firebase más comunes.
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Ese correo ya está en uso por otra cuenta.';
        case 'invalid-email':
          return 'Ese correo no parece válido.';
        case 'requires-recent-login':
          return 'Por seguridad, confirma tu identidad e intenta de nuevo.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'La contraseña no es correcta.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera unos minutos.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet.';
        case 'operation-not-allowed':
          return 'El cambio de correo no está habilitado. Escríbenos a soporte.';
      }
    }
    if (error is Exception) return presentableError(error);
    return 'No se pudo cambiar el correo. Intenta de nuevo.';
  }
}

final accountEmailServiceProvider =
    Provider<AccountEmailService>((ref) => AccountEmailService());
