import 'package:firebase_auth/firebase_auth.dart';

/// Clase utilitaria para el diagnóstico técnico de errores de autenticación.
class AuthDiagnosticTool {
  /// Traduce fallos de Firebase a mensajes legibles con tono de ingeniería.
  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Este identificador de correo ya está vinculado a un expediente activo.';
        case 'weak-password':
          return 'Seguridad insuficiente. La clave debe tener al menos 6 caracteres.';
        case 'invalid-email':
          return 'Formato de correo electrónico no reconocido por el sistema.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Error de credenciales. No se pudo sincronizar el acceso.';
        case 'network-request-failed':
          return 'Fallo de enlace: Telemetría (Internet) no disponible.';
        case 'user-disabled':
          return 'Este expediente ha sido deshabilitado del sistema.';
        case 'too-many-requests':
          return 'Saturación de peticiones detectada. Intenta más tarde.';
        default:
          return 'Fallo técnico no tipificado: ${error.message ?? error.code}';
      }
    }

    // Fallo de red genérico o error de casteo
    if (error.toString().contains('NetworkImage') ||
        error.toString().contains('SocketException')) {
      return 'Fallo de enlace: Telemetría (Internet) no disponible.';
    }

    return 'Fallo de sincronización: ${error.toString()}';
  }
}
