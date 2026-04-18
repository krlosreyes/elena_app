import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'app_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IDs de notificaciones
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Canales Android
// ─────────────────────────────────────────────────────────────────────────────

const _circadianChannel = AndroidNotificationChannel(
  'elena_circadian',
  'Ritmos Circadianos',
  description: 'Alertas basadas en tu biología circadiana',
  importance: Importance.high,
);

const _fastingChannel = AndroidNotificationChannel(
  'elena_fasting',
  'Ayuno Metabólico',
  description: 'Hitos científicos de tu protocolo de ayuno',
  importance: Importance.defaultImportance,
);

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Notification Details ────────────────────────────────────────────────────

  static const NotificationDetails _circadianDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'elena_circadian',
      'Ritmos Circadianos',
      channelDescription: 'Alertas basadas en tu biología circadiana',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    ),
  );

  static const NotificationDetails _fastingDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'elena_fasting',
      'Ayuno Metabólico',
      channelDescription: 'Hitos científicos de tu protocolo de ayuno',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    ),
  );

  // ── Inicialización ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Timezones (Crucial para NotificationScheduler incluso en Web)
      tz.initializeTimeZones();
      try {
        final String tzName = (await FlutterTimezone.getLocalTimezone()).identifier;
        tz.setLocalLocation(tz.getLocation(tzName));
        AppLogger.info('[NotificationService] Timezone: $tzName');
      } catch (e) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        AppLogger.debug('[NotificationService] Fallback a UTC: $e');
      }

      if (kIsWeb) {
        _initialized = true;
        AppLogger.info('[NotificationService] Web: Modo compatibilidad activado.');
        return;
      }

      // 2. Settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) {
          AppLogger.debug(
            '[NotificationService] Notification tapped: ${response.payload}',
          );
        },
      );

      // 3. Android channels
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_circadianChannel);
      await androidPlugin?.createNotificationChannel(_fastingChannel);

      _initialized = true;
      AppLogger.info('[NotificationService] Inicializado correctamente.');
    } catch (e, st) {
      AppLogger.error('[NotificationService] Error en init()', e, st);
    }
  }

  // ── Permisos ────────────────────────────────────────────────────────────────

  static Future<bool> requestPermissions() async {
    if (kIsWeb || !_initialized) return false;

    try {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );

      if (iosGranted != null) {
        AppLogger.logPermissionEvent('notifications_ios', iosGranted);
        return iosGranted;
      }

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final androidGranted =
          await androidPlugin?.requestNotificationsPermission();

      if (androidGranted != null) {
        AppLogger.logPermissionEvent('notifications_android', androidGranted);
        return androidGranted;
      }

      return true;
    } catch (e) {
      AppLogger.error(
          '[NotificationService] Error requestPermissions()', e);
      return false;
    }
  }

  // ── API ─────────────────────────────────────────────────────────────────────

  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    bool isFasting = false,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: isFasting ? _fastingDetails : _circadianDetails,
      );

      AppLogger.debug(
          '[NotificationService] showImmediate: $title');
    } catch (e) {
      AppLogger.error(
          '[NotificationService] Error showImmediate()', e);
    }
  }

  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeatsDaily = true,
    bool isFasting = false,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      final tz.TZDateTime tzScheduled =
          tz.TZDateTime.from(scheduledTime, tz.local);

      if (!repeatsDaily &&
          tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        AppLogger.debug(
            '[NotificationService] Skipped past notification: $title');
        return;
      }

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: isFasting ? _fastingDetails : _circadianDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            repeatsDaily ? DateTimeComponents.time : null,
      );

      AppLogger.debug(
          '[NotificationService] scheduleAt: $title → $scheduledTime');
    } catch (e) {
      AppLogger.error(
          '[NotificationService] Error scheduleAt()', e);
    }
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id: id);
    AppLogger.debug(
        '[NotificationService] Cancelada notificación ID: $id');
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
    AppLogger.debug(
        '[NotificationService] Todas las notificaciones canceladas.');
  }

  static Future<void> cancelCircadian() async {
    if (kIsWeb || !_initialized) return;

    for (int id = 100; id <= 109; id++) {
      await _plugin.cancel(id: id);
    }

    AppLogger.debug(
        '[NotificationService] Notificaciones circadianas canceladas.');
  }

  static Future<void> cancelFasting() async {
    if (kIsWeb || !_initialized) return;

    for (int id = 200; id <= 209; id++) {
      await _plugin.cancel(id: id);
    }

    AppLogger.debug(
        '[NotificationService] Notificaciones de ayuno canceladas.');
  }
}