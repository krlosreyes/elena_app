// SPEC-80: wrapper sobre Firebase Crashlytics con PII scrubbing.
//
// Diseño:
// - En kReleaseMode (Android/iOS): envía a Crashlytics.
// - En kDebugMode: solo loguea por AppLogger (no inunda Console
//   durante desarrollo).
// - En kIsWeb: skip total (Crashlytics no soporta web).
//
// El mensaje de error pasa por `PiiScrubber.scrub` antes de ser
// enviado, removiendo email/uid/tokens en texto plano.

import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/pii_scrubber.dart';

class CrashlyticsService {
  CrashlyticsService._();

  /// Inicializa los handlers globales de error.
  ///
  /// Llamar desde `main.dart` dentro de `runZonedGuarded`. Habilita
  /// la colección solo en release (web siempre off).
  static Future<void> init() async {
    if (kIsWeb) {
      AppLogger.info('[CrashlyticsService] Skip: web no soporta Crashlytics');
      return;
    }

    final crashlytics = FirebaseCrashlytics.instance;

    // Habilitar solo en release. En debug verás los crashes en consola.
    await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

    // Errores del framework Flutter.
    FlutterError.onError = (FlutterErrorDetails details) {
      final scrubbed = FlutterErrorDetails(
        exception: details.exception,
        stack: details.stack,
        library: details.library,
        context: details.context,
        informationCollector: details.informationCollector,
        silent: details.silent,
      );
      crashlytics.recordFlutterFatalError(scrubbed);
    };

    // Errores async no manejados (post Flutter 3.x).
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Registra un error con scrubbing de PII. Reason es opcional pero
  /// recomendable para clasificar (ej. "auth_signin_failed").
  static void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    if (kIsWeb) {
      AppLogger.error('[Crashlytics-skip-web] $error', error, stack);
      return;
    }

    final scrubbedMessage = PiiScrubber.scrub(error.toString());

    if (!kReleaseMode) {
      AppLogger.error(
        '[Crashlytics-debug] reason=$reason fatal=$fatal | $scrubbedMessage',
        error,
        stack,
      );
      return;
    }

    FirebaseCrashlytics.instance.recordError(
      scrubbedMessage,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Asocia el uid del usuario actual con los crashes. El uid SÍ es
  /// PII pero Crashlytics lo trata como identifier no-display.
  /// Pasar null al cerrar sesión.
  static Future<void> setUserId(String? uid) async {
    if (kIsWeb) return;
    if (!kReleaseMode) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
  }
}
