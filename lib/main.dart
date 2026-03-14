import 'src/features/imx/application/imx_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // ✅ Import de Seguridad
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/features/imx/application/imx_controller.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/services/notification_service.dart';

import 'package:flutter/foundation.dart'; // ✅ Necesario para kDebugMode

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  
  // ✅ HARDENING: Activación resiliente de Firebase App Check
  try {
    debugPrint('🚀 INICIANDO APP CHECK (${kDebugMode ? 'DEBUG' : 'RELEASE'})...');
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      // Para Web en Debug, si falla reCAPTCHA (común en localhost), permitimos que la app arranque
      webProvider: ReCaptchaV3Provider('6Lcw_YcpAAAAAZ6Z4G4G4G4G4G4G4G4G4G4G4G4G'),
    );
    debugPrint('✅ APP CHECK ACTIVADO.');
  } catch (e) {
    debugPrint('⚠️ APP CHECK ADVERTENCIA: No se pudo activar App Check ($e).');
    if (kDebugMode) {
      debugPrint('💡 INFO: En Web/Debug esto es normal si no se ha configurado el Debug Token en la consola de Firebase.');
    }
  }  

  await initializeDateFormatting('es');

  // Inicializar Notificaciones Locales
  try {
    await NotificationService.init();
    debugPrint('Notificaciones inicializadas correctamente');
  } catch (e) {
    debugPrint('Error inicializando notificaciones: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ElenaApp(),
    ),
  );
}
