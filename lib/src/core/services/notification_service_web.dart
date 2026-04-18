import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

class NotificationIds {
  static const int wakeUp = 100;
  static const int firstMeal = 101;
  static const int lastMealWarning = 102;
  static const int intestinalLock60 = 103;
  static const int intestinalLock30 = 104;
  static const int intestinalLockActive = 105;
  static const int sleep = 106;
  static const int fasting12h = 200;
  static const int fasting18h = 201;
  static const int fasting24h = 202;
}

class NotificationService {
  NotificationService._();

  static Future<void> init() async {
    try {
      // Inicializar timezone incluso en Web para evitar errores en NotificationScheduler
      tz.initializeTimeZones();
      // En Web, no podemos obtener el timezone local de forma fiable con flutter_timezone 
      // fácilmente sin permisos extra, así que seteamos UTC o dejamos que tz.local falle graciosamente
      // mediante un default si es necesario. Pero la llamada a initializeTimeZones() activa el sistema.
      tz.setLocalLocation(tz.getLocation('UTC')); 
      
      AppLogger.info('[NotificationService] Web: Timezone UTC inicializado para compatibilidad.');
    } catch (e) {
      AppLogger.debug('[NotificationService] Web: Error al inicializar timezone: $e');
    }
  }

  static Future<bool> requestPermissions() async {
    return true; // Pretendemos que sí para no bloquear flujos
  }

  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    bool isFasting = false,
  }) async {
    // No-op en Web
  }

  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeatsDaily = true,
    bool isFasting = false,
  }) async {
    // No-op en Web
  }

  static Future<void> cancel(int id) async {
    // No-op en Web
  }

  static Future<void> cancelAll() async {
    // No-op en Web
  }

  static Future<void> cancelCircadian() async {
    // No-op en Web
  }

  static Future<void> cancelFasting() async {
    // No-op en Web
  }
}
