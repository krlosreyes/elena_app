// SPEC-193: wrapper sobre Firebase Analytics.
//
// Diseño (espejo de CrashlyticsService, SPEC-80):
// - kIsWeb: skip total (mantenemos paridad con el resto de observabilidad
//   mobile-first del proyecto; Analytics web se evaluará aparte).
// - Nunca lanza: todo va en try/catch y delega a AppLogger. Un fallo de
//   telemetría jamás debe romper un flujo de usuario (memoria
//   feedback_workflow_lessons: try/catch que loguea warning es OK).
// - Solo nombres del catálogo AnalyticsEvents (SPEC-193 §2.2).
// - Sin PII en parámetros (SPEC-193 §2.4).

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/services/app_logger.dart';

class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;

  /// Instancia perezosa. Null en web (skip).
  static FirebaseAnalytics? get _instance {
    if (kIsWeb) return null;
    return _analytics ??= FirebaseAnalytics.instance;
  }

  /// Llamar desde main.dart tras CrashlyticsService.init().
  static Future<void> init() async {
    if (kIsWeb) {
      AppLogger.info(
          '[AnalyticsService] Skip: web no instrumentado (SPEC-193)');
      return;
    }
    try {
      // AUD-02 (auditoría pre-producción 2026-07-12): gatear a release,
      // igual que CrashlyticsService.init(). Antes se pasaba `true` fijo,
      // por lo que builds de debug/QA contaminaban las métricas de
      // producción desde el día 1.
      await _instance?.setAnalyticsCollectionEnabled(kReleaseMode);
    } catch (e, s) {
      AppLogger.warning('[AnalyticsService] init falló: $e');
      AppLogger.error('[AnalyticsService] init', e, s);
    }
  }

  /// Registra un evento. `name` debe pertenecer a [AnalyticsEvents].
  /// En debug se valida contra el catálogo y se avisa si no está.
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? params,
  }) async {
    if (kIsWeb) return;
    assert(
      AnalyticsEvents.all.contains(name),
      'Evento "$name" no está en AnalyticsEvents (SPEC-193 §2.2)',
    );
    try {
      await _instance?.logEvent(name: name, parameters: params);
    } catch (e) {
      AppLogger.warning('[AnalyticsService] logEvent($name) falló: $e');
    }
  }

  /// Asocia el uid pseudónimo de Firebase (sin PII).
  static Future<void> setUserId(String? uid) async {
    if (kIsWeb) return;
    try {
      await _instance?.setUserId(id: uid);
    } catch (e) {
      AppLogger.warning('[AnalyticsService] setUserId falló: $e');
    }
  }

  /// Marca la pantalla actual (embudo de navegación).
  static Future<void> setCurrentScreen(String screenName) async {
    if (kIsWeb) return;
    try {
      await _instance?.logScreenView(screenName: screenName);
    } catch (e) {
      AppLogger.warning('[AnalyticsService] setCurrentScreen falló: $e');
    }
  }

  /// Helper de conveniencia para SPEC-193 §RF-193-03.
  static Future<void> logAppOpen() => logEvent(
        AnalyticsEvents.appOpen,
        params: {
          AnalyticsParams.platform: defaultTargetPlatform.name,
        },
      );
}
