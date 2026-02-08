import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones(); // Inicializar base de datos de zonas horarias

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Ajuste para iOS (Darwin)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // V18.0.1: initialize takes positional argument for settings
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Aquí puedes manejar qué pasa al tocar la notificación
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleFastingNotifications(
      DateTime startTime, Duration duration) async {
    print("DEBUG: scheduleFastingNotifications called. Start: $startTime, Duration: $duration");
    
    // Cancelar notificaciones previas para evitar duplicados
    await cancelAll();

    final endTime = startTime.add(duration);
    final now = DateTime.now();

    // Hitos metabólicos
    final milestones = {
      12: "🔥 ¡Quema de Grasa Activada! Tu cuerpo está usando reservas.",
      14: "🧠 Cetosis Detectada. Disfruta tu claridad mental.",
      16: "♻️ Modo Autofagia. Limpieza celular profunda.",
    };

    // Programar Hitos
    for (var entry in milestones.entries) {
      final milestoneTime = startTime.add(Duration(hours: entry.key));
      if (milestoneTime.isAfter(now)) {
        print("DEBUG: Scheduling notification for: $milestoneTime");
        await _scheduleNotification(
          id: entry.key,
          title: "Hito de Ayuno (${entry.key}h)",
          body: entry.value,
          scheduledTime: milestoneTime,
        );
      }
    }

    // Programar Meta Final
    if (endTime.isAfter(now)) {
      print("DEBUG: Scheduling end notification for: $endTime");
      await _scheduleNotification(
        id: 999, // ID especial para la meta
        title: "🏆 ¡Objetivo Cumplido!",
        body: "Has completado tu plan de ayuno. ¡Felicidades!",
        scheduledTime: endTime,
      );
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // V18.0.1: zonedSchedule takes mixed positional and named arguments
    // Positional: id, title, body, scheduledDate, notificationDetails
    // Named: uiLocalNotificationDateInterpretation, androidScheduleMode
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fasting_channel', // id del canal
          'Notificaciones de Ayuno', // nombre del canal
          channelDescription: 'Avisos sobre hitos metabólicos',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Named arguments REQUIRED in v18+
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
