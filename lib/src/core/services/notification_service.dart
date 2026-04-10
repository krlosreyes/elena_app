import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Servicio de notificaciones locales.
/// En Web, las notificaciones nativas no están soportadas;
/// esta implementación es un stub seguro.
class NotificationService {
  NotificationService._();

  /// Inicializa el servicio de notificaciones.
  /// En web o cuando las notificaciones no están disponibles, se omite sin errores.
  static Future<void> init() async {
    if (kIsWeb) {
      AppLogger.info('[NotificationService] Notificaciones no disponibles en Web. Omitiendo init.');
      return;
    }
    // En plataformas nativas se puede inicializar flutter_local_notifications aquí.
    AppLogger.info('[NotificationService] Inicializado correctamente.');
  }

  /// Programa una notificación local.
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    DateTime? scheduledTime,
  }) async {
    if (kIsWeb) return;
    // Implementación nativa iría aquí.
    AppLogger.debug('[NotificationService] Notificación programada: $title');
  }

  /// Cancela todas las notificaciones pendientes.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    AppLogger.debug('[NotificationService] Todas las notificaciones canceladas.');
  }
}
