import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../science/metabolic_engine.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Constants
  static const String metabolicChannelId = 'Metabolic_Alerts';
  static const String metabolicChannelName = 'Alertas Metabólicas';
  static const String hydrationChannelId = 'hydration_channel';
  static const String yesAction = 'YES_ACTION';
  static const String noAction = 'NO_ACTION';
  static const int hydrationNotificationId = 777;

  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(
      NotificationResponse details) {
    _handleActionLogic(details);
  }

  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint("DEBUG: Notifications skipped on Web");
      return;
    }

    try {
      tz.initializeTimeZones();
      debugPrint("DEBUG: Timezones initialized");

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'hydration_category',
            actions: [
              DarwinNotificationAction.plain(yesAction, 'Sí, ya lo tomé'),
              DarwinNotificationAction.plain(noAction, 'Aún no'),
            ],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          ),
        ],
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (details) {
            _handleActionLogic(details);
          },
          onDidReceiveBackgroundNotificationResponse:
              onDidReceiveBackgroundNotificationResponse,
      );

      _isInitialized = true;
      debugPrint("DEBUG: Notifications plugin initialized");

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        debugPrint("DEBUG: Android permissions requested");
      }
    } catch (e) {
      debugPrint("ERROR in NotificationService.init: $e");
    }
  }

  static Future<void> _handleActionLogic(NotificationResponse details) async {
    debugPrint("HANDLING NOTIFICATION ACTION: ${details.actionId}");

    if (details.actionId == null || details.actionId!.isEmpty) {
      return;
    }

    if (details.actionId == yesAction) {
      await _registerHydrationAndReschedule();
    } else if (details.actionId == noAction) {
      await scheduleHydrationReminder(const Duration(minutes: 5));
    }
  }

  static Future<void> _registerHydrationAndReschedule() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('daily_logs')
            .doc(todayId);

        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          int currentGlasses = 0;

          if (snapshot.exists && snapshot.data() != null) {
            currentGlasses = snapshot.data()!['waterGlasses'] ?? 0;
          }

          transaction.set(
              docRef,
              {
                'waterGlasses': currentGlasses + 1,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          transaction.update(userRef, {
            'dailyHydration': FieldValue.increment(1),
            'lastLogUpdate': FieldValue.serverTimestamp(),
          });
        });

        debugPrint("SUCCESS: Hydration registered from notification");
      }
    } catch (e) {
      debugPrint("ERROR registering hydration in background: $e");
    } finally {
      await scheduleHydrationReminder(const Duration(minutes: 30));
    }
  }

  static Future<void> scheduleHydrationReminder(Duration delay,
      {String? body}) async {
    if (kIsWeb || !_isInitialized) return;

    final scheduledTime = DateTime.now().add(delay);
    debugPrint(
        "SCHEDULING HYDRATION for: $scheduledTime (in ${delay.inMinutes} mins)");

    try {
      await _notificationsPlugin.zonedSchedule(
          id: hydrationNotificationId,
          title: "💧 Hidratación Metabólica",
          body: body ?? "Es hora de hidratarse, ¿ya tomaste tu vaso de agua?",
          scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              hydrationChannelId,
              'Canal de Hidratación',
              channelDescription: 'Recordatorios técnicos de consumo de agua',
              importance: Importance.max,
              priority: Priority.high,
              actions: [
                AndroidNotificationAction(yesAction, 'Sí, ya lo tomé'),
                AndroidNotificationAction(noAction, 'Aún no'),
              ],
            ),
            iOS: DarwinNotificationDetails(
              categoryIdentifier: 'hydration_category',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint("ERROR scheduling hydration: $e");
    }
  }

  static Map<String, String> _getPhaseMessage(
    MetabolicZone zone,
    CircadianPhase circadian,
  ) {
    // Caso especial: mañana temprano — Fenómeno del Amanecer
    if (circadian == CircadianPhase.morningActivation &&
        zone == MetabolicZone.postAbsorption) {
      return {
        'title': 'Tu cuerpo ya se preparó solo ☀️',
        'body': 'Acaba de liberar cortisol y glucosa natural. '
            'Si no tienes hambre real, tu desayuno puede esperar. '
            'Un café negro prolonga tu quema de grasa.',
      };
    }

    // Caso especial: melatonina activa — advertencia digestiva
    if (circadian == CircadianPhase.melatoninRise) {
      return {
        'title': 'Tu sistema digestivo está cerrando 🌙',
        'body': 'Después de las 8:30 PM tu cuerpo paraliza la digestión. '
            'Ingerir comida pesada ahora compite con tu reparación celular '
            'y destruye la calidad del sueño.',
      };
    }

    switch (zone) {
      case MetabolicZone.postAbsorption:
        return {
          'title': 'Ayuno en curso',
          'body': 'Tu cuerpo está procesando la última comida. '
              'El glucógeno hepático está activo.',
        };
      case MetabolicZone.glycogenDepletion:
        return {
          'title': 'Punto de inflexión metabólico ⚡',
          'body': 'Tu cuerpo está buscando reservas. '
              'El hambre ahora es una ola hormonal temporal, '
              'no verdadera inanición. '
              'Un vaso de agua mineral o té verde te lleva al otro lado.',
        };
      case MetabolicZone.fatBurning:
        return {
          'title': '🔥 Quema de Grasa Activa',
          'body': 'Gluconeogénesis activada. Tu hígado fabrica energía '
              'desde grasa. La adrenalina sube — es normal sentir '
              'más energía y menos hambre. Hidrata con electrolitos.',
        };
      case MetabolicZone.deepKetosis:
        return {
          'title': '⚡ Cetosis Profunda — Claridad Mental',
          'body': 'Tu cerebro opera con cetonas. '
              'La hormona de crecimiento se duplica protegiendo '
              'tu masa muscular. Estado óptimo de enfoque.',
        };
      case MetabolicZone.autophagy:
        return {
          'title': '🔬 Modo Clínico — Autofagia',
          'body': 'Tus células están en limpieza profunda. '
              'Si sientes mareo o debilidad, consume caldo de hueso '
              'o agua con sal y magnesio de inmediato.',
        };
      case MetabolicZone.survivalMode:
        return {
          'title': '⚠️ Ayuno Extendido — Revisión Necesaria',
          'body': 'Llevas más de 72 horas. El cuerpo está en estrés '
              'metabólico extremo. La salud se construye con '
              'flexibilidad, no con castigos prolongados. '
              'Considera terminar el ayuno.',
        };
    }
  }

  static Future<void> sendFastingProgressNotification({
    required Duration fastingElapsed,
    DateTime? now,
  }) async {
    if (!_isInitialized) return;
    if (kIsWeb) return;

    final zone = MetabolicEngine.calculateZone(fastingElapsed);
    final circadian = MetabolicEngine.getCurrentCircadianPhase(now: now);
    final message = _getPhaseMessage(zone, circadian);

    // Alerta especial de electrolitos en fatBurning y deepKetosis
    final needsElectrolytes = zone == MetabolicZone.fatBurning ||
        zone == MetabolicZone.deepKetosis ||
        zone == MetabolicZone.autophagy;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'metabolic_phase_channel',
      'Fases Metabólicas',
      channelDescription: 'Alertas de progreso del ayuno por fase',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
    id: zone.index + 100,
    title: message['title'],
    body: needsElectrolytes
      ? '${message['body']} · Recuerda: Na, K, Mg.'
      : message['body'],
    notificationDetails: details,
    );
  }

  static Future<void> sendSurvivalModeAlert() async {
    if (!_isInitialized) return;
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'safety_channel',
      'Seguridad',
      channelDescription: 'Alertas críticas de seguridad del ayuno',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
    id: 999,
    title: '⚠️ Revisión de Seguridad Requerida',
    body: 'Llevas más de 72 horas en ayuno. '
      'El riesgo de arritmias y pérdida de masa muscular es real. '
      'Elena no puede acompañar ayunos sin supervisión médica '
      'más allá de este punto.',
    notificationDetails: details,
    );
  }

  static Future<void> scheduleFastingNotifications(
      DateTime startTime, Duration duration) async {
    if (kIsWeb || !_isInitialized) return;

    debugPrint(
        "DEBUG: scheduleFastingNotifications called. Start: $startTime, Duration: $duration");

    try {
      await cancelFastingNotifications();

      final endTime = startTime.add(duration);
      final now = DateTime.now();

      final milestones = {
        12: "🔥 ¡Quema de Grasa Activada! Tu cuerpo está usando reservas.",
        14: "🧠 Cetosis Detectada. Disfruta tu claridad mental.",
        16: "♻️ Modo Autofagia. Limpieza celular profunda.",
      };

      for (var entry in milestones.entries) {
        final milestoneTime = startTime.add(Duration(hours: entry.key));
        if (milestoneTime.isAfter(now)) {
          await _scheduleNotification(
            id: entry.key,
            title: "Hito de Ayuno (${entry.key}h)",
            body: entry.value,
            scheduledTime: milestoneTime,
          );
        }
      }

      if (endTime.isAfter(now)) {
        await _scheduleNotification(
          id: 999,
          title: "🎯 ¡Meta de Ayuno Alcanzada!",
          body:
              "Has cumplido tus ${duration.inHours} horas. ¿Deseas terminar tu ayuno ahora e iniciar tu ventana de alimentación o prefieres continuar?",
          scheduledTime: endTime,
        );
      }
    } catch (e) {
      debugPrint("ERROR in scheduleFastingNotifications: $e");
    }
  }

  static Future<void> scheduleFeedingNotifications(
      DateTime feedingStartTime, int feedingHours) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      final windowEndTime = feedingStartTime.add(Duration(hours: feedingHours));
      final alertTime = windowEndTime.subtract(const Duration(minutes: 30));
      final now = DateTime.now();

      if (alertTime.isAfter(now)) {
        await _scheduleNotification(
          id: 99,
          title: "🍌 Última Ingesta",
          body: "Tu ventana cierra en 30 min. Asegura tu estabilidad hormonal.",
          scheduledTime: alertTime,
        );
      }
    } catch (e) {
      debugPrint("ERROR in scheduleFeedingNotifications: $e");
    }
  }

  static Future<void> scheduleAntiSnackingNotification(
      DateTime fastingStartTime) async {
    if (kIsWeb || !_isInitialized) return;

    final scheduledTime = fastingStartTime.add(const Duration(hours: 6));
    debugPrint(
        "DEBUG: Intentando programar Anti-Snacking para: $scheduledTime");

    if (scheduledTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: 888,
        title: "🛡️ Escudo Anti-Snacking",
        body:
            "La quema de grasa visceral está activa. No la interrumpas con snacks. Bebe 250ml de agua ahora.",
        scheduledTime: scheduledTime,
        channelId: metabolicChannelId,
        channelName: metabolicChannelName,
      );
      debugPrint("DEBUG: Notificación Anti-Snacking programada con éxito");
    } else {
      debugPrint("DEBUG: La hora de Anti-Snacking ya pasó, ignorando");
    }
  }

  static Future<void> schedulePostPrandialWalking(
      DateTime registrationTime) async {
    if (kIsWeb || !_isInitialized) return;

    final scheduledTime = registrationTime.add(const Duration(minutes: 15));
    debugPrint(
        "DEBUG: Intentando programar Paseo Post-Prandial para: $scheduledTime");

    if (scheduledTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: 7771,
        title: "🚶 Captación de Glucosa",
        body:
            "Un paseo de 15 min ahora reducirá drásticamente tu pico de insulina post-comida.",
        scheduledTime: scheduledTime,
        channelId: metabolicChannelId,
        channelName: metabolicChannelName,
      );
      debugPrint(
          "DEBUG: Notificación Paseo Post-Prandial programada con éxito");
    } else {
      debugPrint("DEBUG: La hora de Paseo Post-Prandial ya pasó, ignorando");
    }
  }

  static Future<void> scheduleSleepPrep(DateTime scheduledTime) async {
    if (kIsWeb || !_isInitialized) return;

    debugPrint("DEBUG: Programando Prep-Sleep para: $scheduledTime");

    await _scheduleNotification(
      id: 555,
      title: "🌙 Protocolo de Sueño Circadiano",
      body:
          "Inicia tu preparación. Luz tenue y fuera pantallas. Tu ventana de reparación inicia en 60 min.",
      scheduledTime: scheduledTime,
      channelId: metabolicChannelId,
      channelName: metabolicChannelName,
    );
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb || !_isInitialized) {
      debugPrint("DEBUG: Test notification skipped (Web or Not Init)");
      return;
    }

    debugPrint("DEBUG: Lanzando notificación de prueba inmediata");
    await _notificationsPlugin.show(
      id: 9999,
      title: "🧪 ElenaApp Test",
      body: "Charlie, hidratación técnica activada. Canal Metabolic_Alerts verificado.",
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          metabolicChannelId,
          metabolicChannelName,
          channelDescription: 'Canal de pruebas metabólicas',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? channelId,
    String? channelName,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId ?? 'fasting_channel',
              channelName ?? 'Notificaciones de Ayuno',
              channelDescription: 'Avisos sobre hitos metabólicos',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint("ERROR scheduling single notification (id $id): $e");
    }
  }

  static Future<void> cancelFastingNotifications() async {
    if (kIsWeb || !_isInitialized) return;
    try {
  // Eliminadas llamadas posicionales inválidas, solo se usa la versión con id nombrado más abajo.
    await _notificationsPlugin.cancel(id: 12);
    await _notificationsPlugin.cancel(id: 14);
    await _notificationsPlugin.cancel(id: 16);
    await _notificationsPlugin.cancel(id: 999);
    await _notificationsPlugin.cancel(id: 99);
    await _notificationsPlugin.cancel(id: 888); // Anti-snacking
    await _notificationsPlugin.cancel(id: 7771); // Walking
    } catch (e) {
      debugPrint("ERROR canceling fasting notifications: $e");
    }
  }

  static Future<void> cancelHydrationReminder() async {
    if (kIsWeb || !_isInitialized) return;
    try {
  // Eliminada llamada posicional inválida, solo se usa la versión con id nombrado más abajo.
    await _notificationsPlugin.cancel(id: hydrationNotificationId);
    } catch (e) {
      debugPrint("ERROR canceling hydration reminder: $e");
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_isInitialized) return;
    try {
      await _notificationsPlugin.cancelAll();
    await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint("ERROR canceling all notifications: $e");
    }
  }
}
