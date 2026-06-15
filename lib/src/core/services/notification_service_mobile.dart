import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'app_logger.dart';
import 'pending_action_queue.dart'
    show
        PendingActionQueue,
        kHydrationYesActionId,
        kHydrationNoActionId,
        kHydrationCategoryId,
        kFastingActionCategoryId,
        kFastingCloseActionId,
        kFastingSnoozeActionId,
        kExerciseCategoryId,
        kExerciseLogActionId,
        kExerciseSnoozeActionId,
        kNutritionCategoryId,
        kNutritionLogActionId,
        kNutritionSnoozeActionId;

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-199 Fase A — Handlers de respuesta a notificaciones accionables
// ─────────────────────────────────────────────────────────────────────────────
//
// Cuando el usuario toca un botón de acción (p. ej. "Sí, lo registro" en la
// notificación de hidratación), estos handlers ENCOLAN la intención en
// `PendingActionQueue`. NO escriben Firestore acá (el contexto no tiene
// Riverpod). La app vacía la cola en foreground (`CoachingActionRouter.flush`).
//
// `notificationBackgroundResponseHandler` corre en un isolate de background:
// requiere el plugin registrant nativo para que SharedPreferences exista ahí
// (ver ios/Runner/AppDelegate). Por eso, en Fase A las acciones son
// `foreground` (abren la app), garantizando que el handler de foreground
// aplique el registro de forma confiable; el background queda como mejor
// esfuerzo / camino para una futura Fase 1b (registrar sin abrir la app).

@pragma('vm:entry-point')
void notificationBackgroundResponseHandler(NotificationResponse response) {
  unawaited(
    PendingActionQueue.handleNotificationAction(response.actionId, response.id),
  );
}

void _notificationForegroundResponseHandler(NotificationResponse response) {
  AppLogger.debug(
    '[NotificationService] response: action=${response.actionId} '
    'id=${response.id}',
  );
  unawaited(
    PendingActionQueue.handleNotificationAction(response.actionId, response.id),
  );
}

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
  // SPEC-169 (2026-06-04): eTRF — 3 horas antes de dormir, cuando
  // sleepTime - 3h cae antes del lastMealGoal. Recordatorio educativo
  // con cita Sutton 2018.
  static const int eTRFPreSleep = 107;

  static const int fasting12h = 200;
  // SPEC-169 (2026-06-04): hito autofagia inicial (Levine 2017),
  // intercalado entre 12h y 18h. Cancelado por cancelFasting() (rango 200-209).
  static const int fasting16h = 203;
  static const int fasting18h = 201;
  static const int fasting24h = 202;

  // SPEC-137 E.5: 30 min antes de la próxima comida sugerida
  // (lastMealAt + 3h). One-shot, no repeatsDaily.
  static const int nextMealReady = 300;

  // SPEC-150: hidratación. Rango 400-419 reservado (hasta 20 slots/día).
  // cancelHydration() cancela todo el rango.
  // Cadencia 30 min (audit notif 2026-06-10): la ventana activa (~14h) cabe
  // en ~28 slots → rango ampliado a 400-439.
  static const int hydrationStart = 400;
  static const int hydrationEnd = 439;

  // SPEC-199 Fase A: re-recordatorio one-shot del "Aún no" del prompt de
  // hidratación (+15 min). Fuera del rango 400-439 para no chocar con los
  // slots diarios ni ser cancelado por cancelHydration().
  static const int hydrationSnooze = 450;

  // SPEC-198: nudges de conversión de trial (día 5 y día 12).
  static const int paywallNudgeDay5 = 500;
  static const int paywallNudgeDay12 = 501;
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

// SPEC-224: canal para notificaciones de ejercicio accionables.
const _exerciseChannel = AndroidNotificationChannel(
  'elena_exercise',
  'Ejercicio',
  description: 'Recordatorios de actividad física',
  importance: Importance.high,
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
      // SPEC-224: public → Wear OS refleja la notificación en el reloj.
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      // Audit notif (2026-06-10): timeSensitive para que NO se silencien en
      // Focus/Modo Sueño y se vean prominentes en lock screen + Apple Watch.
      // Requiere el entitlement Time Sensitive Notifications (Apple Developer);
      // sin él, iOS lo degrada a `active` sin romper nada.
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  static const NotificationDetails _fastingDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'elena_fasting',
      'Ayuno Metabólico',
      channelDescription: 'Hitos científicos de tu protocolo de ayuno',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      // SPEC-224: public → Wear OS refleja la notificación en el reloj.
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      // Audit notif (2026-06-10): sonido ON → el Apple Watch vibra al cruzar
      // un hito (antes era false, llegaba sin háptica).
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  // SPEC-199 / SPEC-224: notificación de hidratación ACCIONABLE.
  // A1b: se eliminó `DarwinNotificationActionOption.foreground` de las acciones
  // iOS (ver `_hydrationCategory` en init) para que el handler background
  // registre el vaso sin abrir la app — requiere el plugin registrant en
  // AppDelegate (SPEC-224). En Android, `showsUserInterface: false` deja la
  // acción en background; el flush ocurre al reanudar la app.
  static final NotificationDetails _hydrationActionableDetails =
      NotificationDetails(
    android: AndroidNotificationDetails(
      'elena_circadian',
      'Ritmos Circadianos',
      channelDescription: 'Alertas basadas en tu biología circadiana',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      // SPEC-224: public → Wear OS refleja la notificación en el reloj.
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          kHydrationYesActionId,
          'Sí, lo registro',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          kHydrationNoActionId,
          'Aún no',
          showsUserInterface: false,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      // SPEC-224: timeSensitive para que no se silencie en Focus/Modo Sueño.
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: kHydrationCategoryId,
    ),
  );

  // SPEC-224: Ayuno — "¿Quieres cerrar tu ayuno ahora?"
  static final NotificationDetails _fastingActionableDetails =
      NotificationDetails(
    android: AndroidNotificationDetails(
      'elena_fasting',
      'Ayuno Metabólico',
      channelDescription: 'Hitos científicos de tu protocolo de ayuno',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          kFastingCloseActionId,
          'Cerrar ayuno',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          kFastingSnoozeActionId,
          'Continuar ayuno',
          showsUserInterface: false,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: kFastingActionCategoryId,
    ),
  );

  // SPEC-224: Ejercicio — "¿Ya hiciste tu actividad de hoy?"
  static final NotificationDetails _exerciseActionableDetails =
      NotificationDetails(
    android: AndroidNotificationDetails(
      'elena_exercise',
      'Ejercicio',
      channelDescription: 'Recordatorios de actividad física',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          kExerciseLogActionId,
          'Sí, lo registro',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          kExerciseSnoozeActionId,
          'Luego lo hago',
          showsUserInterface: false,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: kExerciseCategoryId,
    ),
  );

  // SPEC-224: Nutrición — "¿Ya comiste en tu ventana de alimentación?"
  static final NotificationDetails _nutritionActionableDetails =
      NotificationDetails(
    android: AndroidNotificationDetails(
      'elena_circadian',
      'Ritmos Circadianos',
      channelDescription: 'Alertas basadas en tu biología circadiana',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          kNutritionLogActionId,
          'Registrar comida',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          kNutritionSnoozeActionId,
          'Aún no',
          showsUserInterface: false,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: kNutritionCategoryId,
    ),
  );

  // ── Inicialización ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Timezones (Crucial para NotificationScheduler incluso en Web)
      tz.initializeTimeZones();
      try {
        final String tzName =
            (await FlutterTimezone.getLocalTimezone()).identifier;
        tz.setLocalLocation(tz.getLocation(tzName));
        AppLogger.info('[NotificationService] Timezone: $tzName');
      } catch (e) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        AppLogger.debug('[NotificationService] Fallback a UTC: $e');
      }

      if (kIsWeb) {
        _initialized = true;
        AppLogger.info(
            '[NotificationService] Web: Modo compatibilidad activado.');
        return;
      }

      // 2. Settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // SPEC-199 / SPEC-224: categorías accionables iOS.
      // A1b: se quita `foreground` de las acciones de hidratación para que el
      // handler background pueda encolar sin abrir la app. El plugin registrant
      // en AppDelegate garantiza que SharedPreferences esté disponible en el
      // isolate de background (ver ios/Runner/AppDelegate.swift).

      final DarwinNotificationCategory hydrationCategory =
          DarwinNotificationCategory(
        kHydrationCategoryId,
        actions: <DarwinNotificationAction>[
          // A1b: sin `foreground` → registra en background sin abrir la app.
          DarwinNotificationAction.plain(kHydrationYesActionId, 'Sí, lo registro'),
          DarwinNotificationAction.plain(kHydrationNoActionId, 'Aún no'),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      );

      // SPEC-224: categoría de ayuno accionable.
      final DarwinNotificationCategory fastingCategory =
          DarwinNotificationCategory(
        kFastingActionCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(kFastingCloseActionId, 'Cerrar ayuno'),
          DarwinNotificationAction.plain(kFastingSnoozeActionId, 'Continuar ayuno'),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      );

      // SPEC-224: categoría de ejercicio accionable.
      final DarwinNotificationCategory exerciseCategory =
          DarwinNotificationCategory(
        kExerciseCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(kExerciseLogActionId, 'Sí, lo registro'),
          DarwinNotificationAction.plain(kExerciseSnoozeActionId, 'Luego lo hago'),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      );

      // SPEC-224: categoría de nutrición accionable.
      final DarwinNotificationCategory nutritionCategory =
          DarwinNotificationCategory(
        kNutritionCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(kNutritionLogActionId, 'Registrar comida'),
          DarwinNotificationAction.plain(kNutritionSnoozeActionId, 'Aún no'),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      );

      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
        notificationCategories: <DarwinNotificationCategory>[
          hydrationCategory,
          fastingCategory,
          exerciseCategory,
          nutritionCategory,
        ],
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _notificationForegroundResponseHandler,
        onDidReceiveBackgroundNotificationResponse:
            notificationBackgroundResponseHandler,
      );

      // 3. Android channels
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_circadianChannel);
      await androidPlugin?.createNotificationChannel(_fastingChannel);
      // SPEC-224: canal de ejercicio para notificaciones accionables.
      await androidPlugin?.createNotificationChannel(_exerciseChannel);

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
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
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

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final androidGranted =
          await androidPlugin?.requestNotificationsPermission();

      if (androidGranted != null) {
        AppLogger.logPermissionEvent('notifications_android', androidGranted);
        return androidGranted;
      }

      return true;
    } catch (e) {
      AppLogger.error('[NotificationService] Error requestPermissions()', e);
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

      AppLogger.debug('[NotificationService] showImmediate: $title');
    } catch (e) {
      AppLogger.error('[NotificationService] Error showImmediate()', e);
    }
  }

  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeatsDaily = true,
    bool isFasting = false,
    bool actionableHydration = false,
    // SPEC-224: nuevos tipos de notificación accionable.
    bool actionableFasting = false,
    bool actionableExercise = false,
    bool actionableNutrition = false,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      final tz.TZDateTime tzScheduled =
          tz.TZDateTime.from(scheduledTime, tz.local);

      if (!repeatsDaily && tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        AppLogger.debug(
            '[NotificationService] Skipped past notification: $title');
        return;
      }

      // Prioridad: accionable específico > accionable hydration > fasting/circadian.
      final NotificationDetails details;
      if (actionableFasting) {
        details = _fastingActionableDetails;
      } else if (actionableExercise) {
        details = _exerciseActionableDetails;
      } else if (actionableNutrition) {
        details = _nutritionActionableDetails;
      } else if (actionableHydration) {
        details = _hydrationActionableDetails;
      } else {
        details = isFasting ? _fastingDetails : _circadianDetails;
      }

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repeatsDaily ? DateTimeComponents.time : null,
      );

      AppLogger.debug(
          '[NotificationService] scheduleAt: $title → $scheduledTime');
    } catch (e) {
      AppLogger.error('[NotificationService] Error scheduleAt()', e);
    }
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id: id);
    AppLogger.debug('[NotificationService] Cancelada notificación ID: $id');
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

  /// SPEC-150: cancela las 20 slots reservadas a hidratación (400-419).
  /// Se llama antes de reprogramar la agenda completa cuando cambia el
  /// perfil circadiano del usuario.
  static Future<void> cancelHydration() async {
    if (kIsWeb || !_initialized) return;

    for (int id = NotificationIds.hydrationStart;
        id <= NotificationIds.hydrationEnd;
        id++) {
      await _plugin.cancel(id: id);
    }

    AppLogger.debug(
        '[NotificationService] Notificaciones de hidratación canceladas.');
  }
}
