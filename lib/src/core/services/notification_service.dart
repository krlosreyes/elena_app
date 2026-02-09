import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  static Future<void> init() async {
    // Skip on Web to prevent crash (LateInitializationError)
    if (kIsWeb) {
      print("DEBUG: Notifications skipped on Web");
      return;
    }

    try {
      tz.initializeTimeZones(); // Inicializar base de datos de zonas horarias
      print("DEBUG: Timezones initialized");

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

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

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // Aquí puedes manejar qué pasa al tocar la notificación
        },
      );
      
      _isInitialized = true;
      print("DEBUG: Notifications plugin initialized");

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        print("DEBUG: Android permissions requested");
      }
    } catch (e) {
      print("ERROR in NotificationService.init: $e");
      // No re-lanzar para permitir que la app continúe
    }
  }

  static Future<void> scheduleFastingNotifications(
      DateTime startTime, Duration duration) async {
    if (kIsWeb || !_isInitialized) return;

    print("DEBUG: scheduleFastingNotifications called. Start: $startTime, Duration: $duration");
    
    try {
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
    } catch (e) {
      print("ERROR scheduling notifications: $e");
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    try {
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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
       print("ERROR scheduling single notification (id $id): $e");
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_isInitialized) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print("ERROR canceling notifications: $e");
    }
  }
}
