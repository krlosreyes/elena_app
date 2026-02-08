import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle notification tap
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> scheduleFastingNotifications(DateTime startTime, int plannedHours) async {
    await cancelAll(); // Clear previous schedules

    final now = DateTime.now();
    
    // Milestones
    final milestones = [
      {'hour': 12, 'title': '🔥 Quema de Grasa Activada', 'body': 'Tu cuerpo está usando sus reservas de grasa como energía.'},
      {'hour': 14, 'title': '🧠 Cetosis Detectada', 'body': 'Claridad mental y energía estable. ¡Vas muy bien!'},
      {'hour': 16, 'title': '♻️ Modo Autofagia', 'body': 'Limpieza celular profunda iniciada.'},
    ];

    for (var m in milestones) {
      final hour = m['hour'] as int;
      final milestoneTime = startTime.add(Duration(hours: hour));
      
      if (milestoneTime.isAfter(now)) {
        await _scheduleNotification(
          id: hour,
          title: m['title'] as String,
          body: m['body'] as String,
          scheduledTime: milestoneTime,
        );
      }
    }

    // Goal Reached
    final goalTime = startTime.add(Duration(hours: plannedHours));
    if (goalTime.isAfter(now)) {
       await _scheduleNotification(
          id: 999,
          title: '🏆 ¡Objetivo Cumplido!',
          body: 'Has completado tu ayuno de $plannedHours horas. ¡Felicidades!',
          scheduledTime: goalTime,
        );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fasting_channel',
          'Fasting Alerts',
          channelDescription: 'Notifications for fasting milestones',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
