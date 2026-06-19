// SPEC-236: Bridge Flutter ↔ WatchConnectivity (Apple Watch).
//
// Bidireccional:
//   iPhone → Watch: estado del ayuno, score, vasos, protocolo
//   Watch → iPhone: acciones del usuario (logWater, closeFasting, checkIn)
//
// Comunicación vía MethodChannel. El lado nativo (Swift) maneja WCSession.
// Si el Watch no está pareado o no está alcanzable, las llamadas son no-op
// silenciosas (no rompen la UX del iPhone).
//
// NO requiere dependencias de pub.dev — bridge nativo puro.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:elena_app/src/core/services/app_logger.dart';

/// Callback para acciones que llegan del Watch.
typedef WatchActionHandler = void Function(String action, Map<String, dynamic> data);

class WatchConnectivityService {
  WatchConnectivityService._();

  static const _channel = MethodChannel('elena/watch_connectivity');

  /// Handler registrado para acciones entrantes del Watch.
  static WatchActionHandler? _actionHandler;

  /// Indica si el Watch está pareado y la sesión está activa.
  static bool _isPaired = false;
  static bool get isPaired => _isPaired;

  /// Inicializa el servicio. Llamar desde app.dart en startup.
  ///
  /// Registra el listener para mensajes entrantes del Watch y verifica
  /// si hay un Watch pareado.
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      // Registrar handler para mensajes entrantes del Watch.
      _channel.setMethodCallHandler(_handleWatchMessage);

      // Verificar si hay Watch pareado.
      final paired =
          await _channel.invokeMethod<bool>('isWatchPaired') ?? false;
      _isPaired = paired;

      AppLogger.debug(
        '[WatchConnectivity] Inicializado. Watch pareado: $paired',
      );
    } on MissingPluginException {
      AppLogger.debug(
        '[WatchConnectivity] MethodChannel no registrado — no-op.',
      );
    } on PlatformException catch (e) {
      AppLogger.warning(
        '[WatchConnectivity] Inicialización falló: ${e.message}',
      );
    }
  }

  /// Registra el handler para acciones del Watch.
  /// Típicamente se conecta a CoachingActionRouter o directamente a notifiers.
  static void setActionHandler(WatchActionHandler handler) {
    _actionHandler = handler;
  }

  /// Handler interno para MethodChannel (Watch → iPhone).
  static Future<dynamic> _handleWatchMessage(MethodCall call) async {
    AppLogger.debug(
      '[WatchConnectivity] Mensaje del Watch: ${call.method}',
    );

    switch (call.method) {
      case 'watchAction':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final action = args['action'] as String? ?? '';
        _actionHandler?.call(action, args);
        return true;

      case 'watchPairingChanged':
        _isPaired = call.arguments as bool? ?? false;
        AppLogger.debug(
          '[WatchConnectivity] Pairing cambió: $_isPaired',
        );
        return true;

      default:
        return null;
    }
  }

  // ── iPhone → Watch: enviar estado ──────────────────────────────────────

  /// Envía el estado actual del ayuno al Watch.
  /// Usa `transferUserInfo` (fire-and-forget, sobrevive app cerrada).
  static Future<void> sendFastingUpdate({
    required bool isActive,
    required int elapsedMinutes,
    required int targetHours,
    required String phaseName,
    required String protocol,
    DateTime? startedAt,
  }) async {
    if (kIsWeb || !_isPaired) return;

    try {
      await _channel.invokeMethod('sendFastingUpdate', {
        'isActive': isActive,
        'elapsedMinutes': elapsedMinutes,
        'targetHours': targetHours,
        'phaseName': phaseName,
        'protocol': protocol,
        'startedAtMs': startedAt?.millisecondsSinceEpoch,
      });
    } on MissingPluginException {
      // No-op.
    } on PlatformException catch (e) {
      AppLogger.warning('[WatchConnectivity] sendFastingUpdate falló: ${e.message}');
    }
  }

  /// Envía el estado de hidratación al Watch.
  static Future<void> sendHydrationUpdate({
    required int glassesCount,
    required int goalGlasses,
    required double totalLiters,
  }) async {
    if (kIsWeb || !_isPaired) return;

    try {
      await _channel.invokeMethod('sendHydrationUpdate', {
        'glassesCount': glassesCount,
        'goalGlasses': goalGlasses,
        'totalLiters': totalLiters,
      });
    } on MissingPluginException {
      // No-op.
    } on PlatformException catch (e) {
      AppLogger.warning('[WatchConnectivity] sendHydrationUpdate falló: ${e.message}');
    }
  }

  /// Envía el score del día y estado de pilares al Watch.
  static Future<void> sendScoreUpdate({
    required int score,
    required Map<String, bool> pillarStatus,
  }) async {
    if (kIsWeb || !_isPaired) return;

    try {
      await _channel.invokeMethod('sendScoreUpdate', {
        'score': score,
        'pillarStatus': pillarStatus,
      });
    } on MissingPluginException {
      // No-op.
    } on PlatformException catch (e) {
      AppLogger.warning('[WatchConnectivity] sendScoreUpdate falló: ${e.message}');
    }
  }
}
