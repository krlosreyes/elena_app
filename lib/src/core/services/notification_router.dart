import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/services/app_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-222: Deeplink routing al tocar el cuerpo de una notificación
// ─────────────────────────────────────────────────────────────────────────────
//
// Cuando el usuario toca el cuerpo de la notificación (no un botón de
// acción), el handler recibe un `payload` JSON con `route` y opcionalmente
// `pillar`. Este servicio parsea el payload y navega al destino correcto.
//
// El payload se guarda en `_pendingPayload` si la app no tiene un router
// montado todavía (cold start). El widget raíz debe llamar
// `NotificationRouter.flushPending(context)` tras el primer frame.

class NotificationRouter {
  NotificationRouter._();

  /// Payload pendiente de cold start (la app se abrió desde una notificación
  /// y el widget tree aún no estaba montado).
  static String? _pendingPayload;

  /// Procesa el payload de una notificación.
  ///
  /// Si [context] es null (background/cold start), guarda el payload para
  /// procesarlo después con [flushPending]. Si [context] está disponible,
  /// navega inmediatamente.
  static void handlePayload(String payload, [BuildContext? context]) {
    if (context != null) {
      _navigate(payload, context);
    } else {
      _pendingPayload = payload;
      AppLogger.debug(
        '[NotificationRouter] Payload guardado para cold start: $payload',
      );
    }
  }

  /// Procesa un payload pendiente de cold start.
  /// Llamar desde el widget raíz (app.dart) tras el primer frame.
  static void flushPending(BuildContext context) {
    if (_pendingPayload != null) {
      _navigate(_pendingPayload!, context);
      _pendingPayload = null;
    }
  }

  /// Indica si hay un payload pendiente sin procesar.
  static bool get hasPending => _pendingPayload != null;

  static void _navigate(String payload, BuildContext context) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      // SPEC-222 fix: no existe ruta '/' en GoRouter — usar '/dashboard'.
      final rawRoute = data['route'] as String? ?? '/dashboard';
      final route = rawRoute == '/' ? '/dashboard' : rawRoute;

      AppLogger.debug(
        '[NotificationRouter] Navegando a: $route',
      );

      GoRouter.of(context).go(route);
    } catch (e) {
      AppLogger.error(
        '[NotificationRouter] Error parseando payload: $payload',
        e,
      );
      // Fallback seguro: '/dashboard' existe siempre en el router.
      try {
        GoRouter.of(context).go('/dashboard');
      } catch (_) {
        // Si hasta el fallback falla (p.ej. context desmontado), ignorar.
      }
    }
  }

  // ── Helpers para generar payloads consistentes ────────────────────────────

  /// Payload para notificaciones circadianas (wakeUp, sleep, locks).
  static String circadianPayload() =>
      jsonEncode({'route': '/dashboard', 'category': 'circadian'});

  /// Payload para notificaciones de alimentación (firstMeal, lastMealWarning).
  static String nutritionPayload() =>
      jsonEncode({'route': '/dashboard', 'category': 'nutrition'});

  /// Payload para hitos de ayuno (12h, 16h, 18h, 24h).
  static String fastingPayload() =>
      jsonEncode({'route': '/dashboard', 'category': 'fasting'});

  /// Payload para hidratación.
  static String hydrationPayload() =>
      jsonEncode({'route': '/dashboard', 'category': 'hydration'});

  /// Payload para paywall nudges.
  static String paywallPayload() => jsonEncode({'route': '/paywall'});

  /// SPEC-234: payload para la rutina nocturna de sueño.
  static String sleepRoutinePayload() =>
      jsonEncode({'route': '/sleep-routine', 'category': 'sleep'});

  /// SPEC-241: payload para hitos de ayuno accionables.
  /// Incluye las horas del hito para que el router sepa cuál fue.
  static String fastingMilestonePayload({required int hours}) =>
      jsonEncode({'route': '/dashboard', 'category': 'fasting', 'milestone_hours': hours});

  /// 20-jul: payload para el resumen diario de "tus 5 objetivos de
  /// hoy" — lleva a la pantalla de Objetivos (metas + avance en vivo),
  /// no al Dashboard como el resto de las circadianas.
  static String goalsPayload() =>
      jsonEncode({'route': '/profile/objetivos', 'category': 'goals'});
}
