import 'package:firebase_app_check/firebase_app_check.dart'; // ✅ Import de Seguridad
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
import 'src/features/nutrition/data/food_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🌱 🧹 CLEAN & RESEED: Purge duplicates and re-inject deduplicated data
  print(
    '[MAIN] 🧹 Running CLEAN & RESEED to purge duplicates and ensure clean database...',
  );
  await FoodSeeder.cleanAndReseed();

  final prefs = await SharedPreferences.getInstance();

  // ✅ SOLUCIÓN BLINDADA 1.2: Inicialización segura de servicios
  await _setupFirebaseSecurity();

  await initializeDateFormatting('es');

  // Inicializar Notificaciones Locales
  try {
    await NotificationService.init();
    debugPrint('Notificaciones inicializadas correctamente');
  } catch (e) {
    debugPrint('Error inicializando notificaciones: $e');
  }

  // 🔧 [DEBUG] SEED FIRESTORE
  // Database seeding is now automatic on user registration
  // See: register_controller.dart -> seedInitialNutritionData()

  if (kDebugMode) {
    print(
      '[DEBUG] ElenaApp initialized - Food database seeding handled by registration controller',
    );
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
      debugPrint('💡 INFO: Saltando App Check/Messaging en Web/Debug.');
      return;
    }
    // En Web Release, App Check es opcional o vía recaptcha
  }

  try {
    debugPrint('🚀 INICIANDO PROTOCOLOS DE SEGURIDAD...');
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
      providerWeb: ReCaptchaV3Provider(
        '6Lcw_YcpAAAAAZ6Z4G4G4G4G4G4G4G4G4G4G4G4G',
      ),
    );
    debugPrint('✅ SEGURIDAD ACTIVADA.');
  } catch (e) {
    debugPrint('⚠️ ADVERTENCIA SEGURIDAD: $e');
  }
}
