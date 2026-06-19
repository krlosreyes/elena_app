// SPEC-235: Bridge Flutter ↔ ActivityKit (iOS) / Ongoing Notification (Android).
//
// Gestiona la Live Activity del ayuno: timer en Isla Dinámica (iOS 16.1+),
// lock screen, y notificación ongoing en Android.
//
// El puente usa MethodChannel. El lado nativo (Swift) registra el canal
// en AppDelegate y maneja las llamadas de ActivityKit. En Android, el
// fallback es una notificación ongoing con barra de progreso (ID 700).
//
// Ciclo de vida:
//   startFastingManual() → LiveActivityService.start()
//   Timer 60s (evaluator) → LiveActivityService.update()
//   closeFasting() → LiveActivityService.end()
//
// Limitación v1: solo timer local (sin push). Después de ~8h iOS marca
// la actividad como stale. Aceptable para v1.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:elena_app/src/core/services/app_logger.dart';

/// Fases visuales del ayuno para la Live Activity.
enum LiveActivityPhase {
  digestion,
  fatBurning,
  ketosis,
  autophagy;

  String get displayName => switch (this) {
        digestion => 'Digestión',
        fatBurning => 'Quemando reservas',
        ketosis => 'Cetosis activa',
        autophagy => 'Limpieza profunda',
      };

  /// Determina la fase según minutos transcurridos.
  static LiveActivityPhase fromElapsedMinutes(int minutes) {
    if (minutes >= 960) return autophagy; // 16h+
    if (minutes >= 720) return ketosis; // 12h+
    if (minutes >= 240) return fatBurning; // 4h+
    return digestion; // 0-4h
  }
}

class LiveActivityService {
  LiveActivityService._();

  static const _channel = MethodChannel('elena/live_activity');

  /// Indica si hay una Live Activity activa.
  static bool _active = false;
  static bool get isActive => _active;

  /// Inicia la Live Activity del ayuno.
  ///
  /// iOS: crea una Live Activity vía ActivityKit (Isla Dinámica + lock screen).
  /// Android: crea una notificación ongoing con barra de progreso.
  static Future<void> start({
    required DateTime startedAt,
    required String protocol,
    required int targetHours,
  }) async {
    if (kIsWeb) return;

    try {
      await _channel.invokeMethod('startFastingActivity', {
        'startedAt': startedAt.millisecondsSinceEpoch,
        'protocol': protocol,
        'targetHours': targetHours,
      });
      _active = true;
      AppLogger.debug(
        '[LiveActivity] Iniciada: protocol=$protocol, target=${targetHours}h',
      );
    } on MissingPluginException {
      // Canal no registrado (web, tests, device sin soporte).
      AppLogger.debug('[LiveActivity] MethodChannel no registrado — no-op.');
    } on PlatformException catch (e) {
      // iOS < 16.1 o permisos denegados.
      AppLogger.warning('[LiveActivity] No disponible: ${e.message}');
    }
  }

  /// Actualiza la Live Activity con el estado actual del ayuno.
  ///
  /// Llamar cada ~60 segundos desde el evaluator o un timer periódico.
  static Future<void> update({
    required int elapsedMinutes,
    required LiveActivityPhase phase,
    int? nextMilestoneMinutes,
    String? nextMilestoneName,
  }) async {
    if (kIsWeb || !_active) return;

    try {
      await _channel.invokeMethod('updateFastingActivity', {
        'elapsedMinutes': elapsedMinutes,
        'currentPhase': phase.name,
        'phaseName': phase.displayName,
        'nextMilestoneMinutes': nextMilestoneMinutes,
        'nextMilestoneName': nextMilestoneName,
      });
    } on MissingPluginException {
      // No-op.
    } on PlatformException catch (e) {
      AppLogger.warning('[LiveActivity] update falló: ${e.message}');
    }
  }

  /// Finaliza la Live Activity al cerrar el ayuno.
  ///
  /// Muestra un resumen final breve antes de desaparecer.
  static Future<void> end({
    int? totalMinutes,
    String? summary,
  }) async {
    if (kIsWeb || !_active) return;

    try {
      await _channel.invokeMethod('endFastingActivity', {
        'totalMinutes': totalMinutes,
        'summary': summary,
      });
      _active = false;
      AppLogger.debug(
        '[LiveActivity] Finalizada: ${totalMinutes ?? 0} min',
      );
    } on MissingPluginException {
      _active = false;
    } on PlatformException catch (e) {
      _active = false;
      AppLogger.warning('[LiveActivity] end falló: ${e.message}');
    }
  }

  /// Verifica si el dispositivo soporta Live Activities.
  /// iOS 16.1+: true. Android: siempre true (usa ongoing notification).
  static Future<bool> isSupported() async {
    if (kIsWeb) return false;

    try {
      final result =
          await _channel.invokeMethod<bool>('isLiveActivitySupported');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
