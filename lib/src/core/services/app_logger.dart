import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 🔐 SECURE LOGGING SERVICE
///
/// Reemplaza todos los print() statements con logging estructurado.
/// En PRODUCCIÓN: Logs de seguridad NO incluyen datos sensibles.
/// En DESARROLLO: Modo debug con más información.
class AppLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(
      colors: true,
      printEmojis: true,
      // En release, no mostrar file/line info (seguridad)
      methodCount: kDebugMode ? 2 : 0,
    ),
  );

  /// Nivel: VERBOSE - Información de debug detallada
  static void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d('$message${error != null ? '\nError: $error' : ''}');
      if (stackTrace != null) _logger.d(stackTrace);
    }
  }

  /// Nivel: DEBUG - Información de desarrollo
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message);
      if (error != null) _logger.e(error, stackTrace: stackTrace);
    }
  }

  /// Nivel: INFO - Información general
  static void info(String message) {
    _logger.i(message);
  }

  /// Nivel: WARNING - Advertencias importantes
  static void warning(String message, [dynamic error]) {
    _logger.w(message);
    if (error != null) _logger.w('Error: $error');
  }

  /// Nivel: ERROR - Errores de aplicación
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Nivel: FATAL - Errores críticos
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// ✅ TASK 1.4.1: Log de eventos de autenticación (sin datos sensibles)
  static void logAuthEvent(String event, {String? userId}) {
    info(
        '🔐 AUTH: $event${userId != null ? ' (user: ${userId.substring(0, 5)}...)' : ''}');
  }

  /// ✅ TASK 1.4.2: Log de eventos de red
  static void logNetworkEvent(String endpoint, String method, int? statusCode) {
    info(
        '🌐 API: $method $endpoint${statusCode != null ? ' [$statusCode]' : ''}');
  }

  /// ✅ TASK 1.4.3: Log de eventos de base de datos
  static void logDatabaseEvent(String collection, String operation) {
    info('📊 DB: $operation on /$collection');
  }

  /// ✅ TASK 1.4.4: Log de errores de seguridad
  static void logSecurityEvent(String event, {required bool isCritical}) {
    final level = isCritical ? '🚨 CRITICAL' : '⚠️ WARNING';
    if (isCritical) {
      warning('$level SECURITY: $event');
    } else {
      info('$level SECURITY: $event');
    }
  }

  /// ✅ TASK 1.4.5: Log de permisos
  static void logPermissionEvent(String permission, bool granted) {
    info('🔑 PERMISSION: $permission = ${granted ? 'GRANTED' : 'DENIED'}');
  }
}
