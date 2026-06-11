import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'app_logger.dart';

class NotificationIds {
  static const int wakeUp = 100;
  static const int firstMeal = 101;
  static const int lastMealWarning = 102;
  static const int intestinalLock60 = 103;
  static const int intestinalLock30 = 104;
  static const int intestinalLockActive = 105;
  static const int sleep = 106;
  // SPEC-169 (2026-06-04): eTRF pre-sueño.
  static const int eTRFPreSleep = 107;
  static const int fasting12h = 200;
  static const int fasting18h = 201;
  static const int fasting24h = 202;
  // SPEC-169 (2026-06-04): hito autofagia inicial.
  static const int fasting16h = 203;
  // SPEC-137 E.5: 30 min antes de la próxima comida sugerida
  // (lastMealAt + 3h). One-shot, no repeatsDaily.
  static const int nextMealReady = 300;
  // Hidratación. Cadencia 30 min → rango 400-439.
  static const int hydrationStart = 400;
  static const int hydrationEnd = 439;
  // SPEC-199 Fase A: re-recordatorio del "Aún no" (+15 min).
  static const int hydrationSnooze = 450;
  // SPEC-198: nudges de conversión de trial (día 5 y día 12).
  static const int paywallNudgeDay5 = 500;
  static const int paywallNudgeDay12 = 501;
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

      AppLogger.info(
          '[NotificationService] Web: Timezone UTC inicializado para compatibilidad.');
    } catch (e) {
      AppLogger.debug(
          '[NotificationService] Web: Error al inicializar timezone: $e');
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
    bool actionableHydration = false,
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

  // SPEC-150: hidratación es No-op en web (notificaciones nativas no
  // funcionan igual en web). Las notifs solo aplican a iOS/Android.
  static Future<void> cancelHydration() async {
    // No-op en Web
  }
}
