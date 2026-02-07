/// Base exception class for the application.
///
/// Use this class to throw expected errors that should be shown to the user.
class AppException implements Exception {
  final String message;
  final String code;

  const AppException(this.message, this.code);

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Generic unknown error.
class UnknownException extends AppException {
  const UnknownException()
      : super('Ocurrió un error inesperado', 'unknown-error');
}
