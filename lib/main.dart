import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // ✅ Necesario para kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/providers/shared_preferences_provider.dart';
import 'src/core/services/notification_service.dart';
import 'src/core/services/app_logger.dart';
import 'src/core/config/security_config.dart';
import 'src/features/nutrition/data/food_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🌱 🧹 CLEAN & RESEED: Purge duplicates and re-inject deduplicated data
  AppLogger.info('[MAIN] Running CLEAN & RESEED to purge duplicates...');
  await FoodSeeder.cleanAndReseed();

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
    AppLogger.debug('[DEBUG] ElenaApp initialized - Food database seeding handled by registration controller');
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
