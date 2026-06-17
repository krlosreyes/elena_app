import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-223 Fase 2: Entrypoint Dart para BGAppRefreshTask
// ─────────────────────────────────────────────────────────────────────────────
//
// Este código corre en un FlutterEngine headless (~30s de CPU).
// NO tiene widget tree ni Riverpod — solo acceso a SharedPreferences,
// flutter_local_notifications y MethodChannel.
//
// Responsabilidades:
//   1. Leer estado actual desde SharedPreferences (caché local).
//   2. Evaluar si las notificaciones programadas siguen siendo relevantes.
//   3. Cancelar o reprogramar via flutter_local_notifications.
//   4. Señalar "done" al handler Swift via MethodChannel.
//
// El entrypoint se registra como `@pragma('vm:entry-point')` para que
// el tree-shaker de Dart no lo elimine en release.

@pragma('vm:entry-point')
void backgroundNotificationRefresh() {
  // Garantizar que los bindings nativos estén disponibles sin widget tree.
  DartPluginRegistrant.ensureInitialized();

  const channel = MethodChannel('com.metamorfosis.elena/background_refresh');

  // Ejecutar el refresh y señalar al handler Swift.
  _runRefresh().then((success) {
    channel.invokeMethod('refreshComplete', success);
  }).catchError((e) {
    AppLogger.error('[BackgroundRefresh] Error en refresh', e);
    channel.invokeMethod('refreshComplete', false);
  });
}

Future<bool> _runRefresh() async {
  try {
    // 1. Inicializar NotificationService (timezone + plugin).
    await NotificationService.init();

    // 2. Leer estado desde SharedPreferences.
    final prefs = await SharedPreferences.getInstance();

    // ── 2a. Hidratación completada → cancelar reminders restantes ──────
    final hydrationCompleted = prefs.getBool('hydration_goal_completed') ?? false;
    if (hydrationCompleted) {
      await NotificationService.cancelHydration();
      AppLogger.debug(
        '[BackgroundRefresh] Hidratación completada — reminders cancelados.',
      );
    }

    // ── 2b. Ayuno activo → verificar notificaciones de comida ──────────
    final isFasting = prefs.getBool('fasting_active') ?? false;
    if (isFasting) {
      // Cancelar notificaciones de alimentación si el ayuno sigue activo.
      await NotificationService.cancelFeeding();
      AppLogger.debug(
        '[BackgroundRefresh] Ayuno activo — feeding notifs canceladas.',
      );
    }

    // ── 2c. Futuro: más evaluaciones dinámicas ─────────────────────────
    // - Milestone de ayuno dinámico (si el usuario extendió voluntariamente).
    // - Sueño detectado por HealthKit → cancelar reminders nocturnos.
    // - Daily summary si no se generó en foreground.

    AppLogger.info('[BackgroundRefresh] Refresh completado.');
    return true;
  } catch (e) {
    AppLogger.error('[BackgroundRefresh] Error', e);
    return false;
  }
}
