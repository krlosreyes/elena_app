import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'package:elena_app/src/core/services/pii_scrubber.dart';

/// 🔐 SECURE LOGGING SERVICE
///
/// Reemplaza todos los print() statements con logging estructurado.
/// En PRODUCCIÓN: Logs de seguridad NO incluyen datos sensibles.
/// En DESARROLLO: Modo debug con más información.
///
/// AUD-04 (auditoría pre-producción 2026-07-12): `PiiScrubber` antes solo
/// se aplicaba en `CrashlyticsService.recordError`. Cualquier call-site que
/// llamara a `AppLogger` directamente (la mayoría del código) quedaba sin
/// protección — un email/UID sin truncar o un bearer token en el mensaje
/// de una excepción podían llegar en texto plano a la consola/dispositivo.
/// Ahora el scrubbing se aplica aquí, en la base, para que cualquier
/// call-site futuro quede protegido por defecto sin tener que acordarse.
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
      final scrubbedMessage = PiiScrubber.scrub(message);
      final scrubbedError =
          error != null ? PiiScrubber.scrub(error.toString()) : null;
      _logger.d(
          '$scrubbedMessage${scrubbedError != null ? '\nError: $scrubbedError' : ''}');
      if (stackTrace != null) _logger.d(stackTrace);
    }
  }

  /// Nivel: DEBUG - Información de desarrollo
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(PiiScrubber.scrub(message));
      if (error != null) {
        _logger.e(PiiScrubber.scrub(error.toString()), stackTrace: stackTrace);
      }
    }
  }

  /// Nivel: INFO - Información general
  static void info(String message) {
    _logger.i(PiiScrubber.scrub(message));
  }

  /// Nivel: WARNING - Advertencias importantes
  static void warning(String message, [dynamic error]) {
    _logger.w(PiiScrubber.scrub(message));
    if (error != null)
      _logger.w('Error: ${PiiScrubber.scrub(error.toString())}');
  }

  /// Nivel: ERROR - Errores de aplicación
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(
      PiiScrubber.scrub(message),
      error: error != null ? PiiScrubber.scrub(error.toString()) : null,
      stackTrace: stackTrace,
    );
  }

  /// Nivel: FATAL - Errores críticos
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(
      PiiScrubber.scrub(message),
      error: error != null ? PiiScrubber.scrub(error.toString()) : null,
      stackTrace: stackTrace,
    );
  }

  /// ✅ TASK 1.4.1: Log de eventos de autenticación (sin datos sensibles)
  static void logAuthEvent(String event, {String? userId}) {
    info(
        '🔐 AUTH: $event${userId != null ? ' (user: ${truncateUid(userId)})' : ''}');
  }

  /// SEC-07 (auditoría 2026-07-11): trunca un UID de Firebase Auth para
  /// logging — suficiente para correlacionar entradas del mismo usuario
  /// en un log sin exponer el identificador completo. Antes solo
  /// `logAuthEvent` truncaba; varios call sites (`AppStateRepository`,
  /// `HealthObserverProvider`, `FastingHistoryMigrator`) interpolaban el
  /// UID completo directamente. Usar este helper en cualquier log nuevo
  /// que incluya un uid.
  static String truncateUid(String uid) =>
      uid.length <= 5 ? uid : '${uid.substring(0, 5)}...';

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
