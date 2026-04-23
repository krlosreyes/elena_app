/// SPEC-24: Manejo de errores tipado
/// Jerarquía de excepciones para clasificar diferentes tipos de fallos.
/// Permite hacer retry inteligente y mostrar UI contextual.

/// Excepción base de la app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Error de conectividad o comunicación con Firestore
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );

  @override
  String toString() => 'NetworkException: $message';
}

/// Error de validación de datos (input inválido)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required String message,
    String? code,
    Exception? originalException,
    this.fieldErrors,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );

  @override
  String toString() => 'ValidationException: $message${fieldErrors != null ? ' — $fieldErrors' : ''}';
}

/// Error de permisos (usuario no autorizado)
class PermissionException extends AppException {
  PermissionException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );

  @override
  String toString() => 'PermissionException: $message';
}

/// Error de operación no soportada
class OperationException extends AppException {
  OperationException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );

  @override
  String toString() => 'OperationException: $message';
}

/// Excepción desconocida/genérica
class UnknownException extends AppException {
  UnknownException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
  );

  @override
  String toString() => 'UnknownException: $message';
}

/// Utilidad para convertir excepciones genéricas a AppException
AppException asAppException(dynamic error) {
  if (error is AppException) return error;

  final message = error.toString();

  // Detectar tipos comunes de errores
  if (message.contains('Network') ||
      message.contains('socket') ||
      message.contains('connection')) {
    return NetworkException(
      message: 'Error de conectividad. Intenta nuevamente.',
      originalException: error is Exception ? error : null,
    );
  }

  if (message.contains('validation') ||
      message.contains('invalid') ||
      message.contains('required')) {
    return ValidationException(
      message: 'Datos inválidos. Por favor verifica tu entrada.',
      originalException: error is Exception ? error : null,
    );
  }

  if (message.contains('permission') ||
      message.contains('denied') ||
      message.contains('unauthorized')) {
    return PermissionException(
      message: 'No tienes permiso para realizar esta acción.',
      originalException: error is Exception ? error : null,
    );
  }

  return UnknownException(
    message: message,
    originalException: error is Exception ? error : null,
  );
}
