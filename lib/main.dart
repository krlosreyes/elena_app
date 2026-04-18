import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/providers/shared_preferences_provider.dart';
import 'src/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // DT-06: Firebase App Check (Modo Debug para pruebas locales)
  try {
    // En Web, si la clave no es válida para el dominio (localhost), fallará.
    // Usamos un bloque más robusto para evitar que el error ruidoso interrumpa el flujo.
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
      webProvider: ReCaptchaV3Provider('6LeX-OcpAAAAAI8iG-Y6G9S7v7L3H-O-1-9-O-9'), // Producción/Localhost
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint("ℹ️ AppCheck no se activó (común en localhost sin configuración ReCAPTCHA): $e");
    }
  }

  // DT-04: SharedPreferences debe inicializarse antes de runApp.
  final sharedPreferences = await SharedPreferences.getInstance();

  // SPEC-05: Inicializar el servicio de notificaciones (timezone + canales Android).
  await NotificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ElenaApp(),
    ),
  );
}