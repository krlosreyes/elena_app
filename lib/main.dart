import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/providers/shared_preferences_provider.dart';
import 'src/core/services/app_logger.dart';
import 'src/core/services/crashlytics_service.dart';
import 'src/core/services/notification_service.dart';

// SPEC-80: envolvemos main en runZonedGuarded para capturar
// excepciones async no manejadas y enviarlas a Crashlytics tras
// pasar por el PII scrubber.
void main() {
  runZonedGuarded<Future<void>>(
    () async {
      await _bootstrap();
    },
    (error, stack) => CrashlyticsService.recordError(
      error,
      stack,
      reason: 'unhandled_async_error',
      fatal: true,
    ),
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SPEC-76 fix: inicializar locale 'es' para que DateFormat con
  // patrones localizados (ej. 'd MMM yyyy', 'es') funcione en todas
  // las pantallas. Sin esto, el primer uso lanza LocaleDataException
  // y rompe el render del widget.
  await initializeDateFormatting('es', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // SPEC-80: enganchar handlers de error globales lo antes posible
  // tras inicializar Firebase. Crashlytics solo reporta en release
  // mode mobile (web queda no soportado; debug solo loguea).
  await CrashlyticsService.init();

  // SPEC-73.1 (housekeeping): AppCheck se omite en web debug porque la
  // clave reCAPTCHA v3 placeholder produce errores ruidosos en consola
  // que el try/catch de Dart no puede atrapar (Firebase web SDK los
  // emite desde JS antes de propagar a Dart). La configuración real de
  // reCAPTCHA v3 se hará en SPEC-81 (hardening de producción).
  //
  // En mobile (Android/iOS) y en web release seguimos activando
  // AppCheck con su provider correspondiente.
  final shouldActivateAppCheck = !(kIsWeb && !kReleaseMode);
  if (shouldActivateAppCheck) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
        appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
        webProvider: ReCaptchaV3Provider('6LeX-OcpAAAAAI8iG-Y6G9S7v7L3H-O-1-9-O-9'),
      );
    } catch (e) {
      AppLogger.info(
        'AppCheck no se activó (configurar reCAPTCHA v3 real en SPEC-81): $e',
      );
    }
  } else {
    AppLogger.info('AppCheck omitido: web debug (ver SPEC-73.1).');
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
