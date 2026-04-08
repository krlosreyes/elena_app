import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'; // ✅ Necesario para kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/config/security_config.dart';
import 'src/core/providers/shared_preferences_provider.dart';
import 'src/core/services/app_logger.dart';
import 'src/core/services/notification_service.dart';
import 'src/features/nutrition/data/food_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Crashlytics: solo en plataformas nativas (no soportado en Web) ──
  if (!kIsWeb) {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  // ── Capturar errores Flutter no manejados ──
  FlutterError.onError = (details) {
    // 🛡️ Suprimir error conocido del engine web (disposed EngineFlutterView)
    // Este assertion se dispara cuando Timer/Stream mutan state post-dispose.
    // Es benigno y no tiene impacto funcional en la app.
    if (kIsWeb && _isDisposedViewError(details)) {
      return;
    }

    FlutterError.presentError(details);
    AppLogger.error('[FLUTTER_ERROR] ${details.exceptionAsString()}');
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // ── Capturar errores async fuera del framework Flutter ──
  PlatformDispatcher.instance.onError = (error, stack) {
    // 🛡️ Suprimir disposed view en web (también puede llegar por aquí)
    if (kIsWeb) {
      final errStr = error.toString();
      if (errStr.contains('isDisposed') ||
          errStr.contains('disposed') ||
          errStr.contains('window.dart')) {
        return true; // Handled — suprimir
      }
    }
    AppLogger.error('[PLATFORM_ERROR] $error\n$stack');
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  // ── Habilitar persistencia offline de Firestore ──
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 🌱 Seed de datos solo en modo desarrollo
  if (kDebugMode) {
    AppLogger.info('[MAIN] Running CLEAN & RESEED to purge duplicates...');
    await FoodSeeder.cleanAndReseed();
  }

  final prefs = await SharedPreferences.getInstance();

  // ✅ SOLUCIÓN BLINDADA 1.2: Inicialización segura de servicios
  await _setupFirebaseSecurity();

  await initializeDateFormatting('es');

  // Inicializar Notificaciones Locales
  try {
    await NotificationService.init();
    AppLogger.info('Notificaciones inicializadas correctamente');
  } catch (e) {
    AppLogger.error('Error inicializando notificaciones: $e');
  }

  if (kDebugMode) {
    AppLogger.debug(
        '[DEBUG] ElenaApp initialized - Food database seeding handled by registration controller');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ElenaApp(),
    ),
  );
}

/// ✅ ENCAPSULACIÓN DE SEGURIDAD (Solución 1.2)
Future<void> _setupFirebaseSecurity() async {
  if (kIsWeb) {
    if (kDebugMode) {
      AppLogger.info('💡 INFO: Saltando App Check/Messaging en Web/Debug.');
      return;
    }
    // En Web Release, App Check es opcional o vía recaptcha
  }

  try {
    AppLogger.info('🚀 INICIANDO PROTOCOLOS DE SEGURIDAD...');
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
      providerWeb: ReCaptchaV3Provider(
        SecurityConfig.recaptchaV3SiteKey,
      ),
    );
    AppLogger.info('✅ SEGURIDAD ACTIVADA.');
  } catch (e) {
    AppLogger.warning('⚠️ ADVERTENCIA SEGURIDAD: $e');
  }
}

/// 🛡️ Detecta el error benigno de Flutter Web: "Trying to render a disposed EngineFlutterView"
/// Ocurre cuando un Timer/Stream muta state después de que la view fue disposed.
/// Verifica contra TODAS las representaciones posibles del error.
bool _isDisposedViewError(FlutterErrorDetails details) {
  // Chequear la excepción como string (incluye message del AssertionError)
  final exStr = details.exception.toString();
  if (exStr.contains('isDisposed') ||
      exStr.contains('disposed') ||
      exStr.contains('EngineFlutterView') ||
      exStr.contains('window.dart')) {
    return true;
  }
  // Chequear exceptionAsString (formato del framework)
  final easStr = details.exceptionAsString();
  if (easStr.contains('isDisposed') ||
      easStr.contains('disposed') ||
      easStr.contains('window.dart')) {
    return true;
  }
  // Chequear el summary (DiagnosticsNode)
  final summary = details.summary.toString();
  if (summary.contains('disposed') || summary.contains('window.dart')) {
    return true;
  }
  // Chequear stack trace si existe
  final stack = details.stack?.toString() ?? '';
  if (stack.contains('window.dart') && stack.contains('render')) {
    return true;
  }
  return false;
}
