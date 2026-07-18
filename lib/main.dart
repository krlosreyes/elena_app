import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/config/recaptcha_config.dart';
import 'src/core/providers/shared_preferences_provider.dart';
import 'src/features/billing/application/billing_providers.dart';
import 'src/features/billing/application/fake_billing_service.dart';
import 'src/features/billing/data/revenuecat_billing_service.dart';
import 'src/core/services/app_logger.dart';
import 'src/core/services/analytics_service.dart';
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

  // SPEC-206 (offline-first): persistencia local explícita. En móvil ya viene
  // ON por defecto, pero la fijamos para no depender del default y con caché
  // ILIMITADA — una app de salud no debe desalojar el historial del usuario.
  // Debe configurarse ANTES de cualquier uso de Firestore. En web la
  // persistencia tiene su propio manejo (IndexedDB, single-tab), así que se
  // omite para evitar warnings multipestaña.
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      // SPEC-218: 100 MB cubre ~3.5 años de historial completo.
      // Firestore evicta datos históricos raramente accedidos al superar el límite.
      // Era CACHE_SIZE_UNLIMITED (SPEC-206) — ahora acotado para proteger
      // dispositivos con almacenamiento limitado (16–32 GB).
      cacheSizeBytes: 100 * 1024 * 1024,
    );
  }

  // PERF-02 (auditoría independiente 2026-07-11): Crashlytics, Analytics y
  // App Check no dependen entre sí (solo de Firebase.initializeApp, ya
  // completado arriba) — antes se esperaban en serie, alargando el tiempo
  // hasta el primer frame sin necesidad. Se paralelizan con Future.wait.
  // SharedPreferences y NotificationService tampoco dependen entre sí ni de
  // los anteriores, así que se lanzan en un segundo Future.wait. La única
  // dependencia real que se preserva es: SharedPreferences debe resolver
  // antes de leer `onboardingCompleted` más abajo.
  await Future.wait<void>([
    // SPEC-80: Crashlytics solo reporta en release mode mobile (web queda no
    // soportado; debug solo loguea).
    CrashlyticsService.init(),
    // SPEC-193: analytics de negocio. Nunca bloquea el arranque (el servicio
    // absorbe sus propios errores). app_open es el primer evento del embudo.
    AnalyticsService.init().then((_) => AnalyticsService.logAppOpen()),
    _activateAppCheck(),
  ]);

  final sharedPreferencesFuture = SharedPreferences.getInstance();
  final notificationInitFuture = NotificationService.init();
  await Future.wait<void>([sharedPreferencesFuture, notificationInitFuture]);
  final sharedPreferences = await sharedPreferencesFuture;

  // SPEC-172 (2026-06-04): solicitar permisos iOS post-init.
  // En flutter_local_notifications ≥ 13 el flag `requestAlertPermission`
  // del init NO dispara el modal nativo por sí solo en iOS reciente.
  // Sin esta llamada explícita, iOS marca la app como "permisos denegados
  // por default" y `zonedSchedule` se ejecuta sin error pero el sistema
  // descarta todas las entregas. Diagnóstico en docs/PLAN_HOTFIX_2026_06_04.md §P3.
  //
  // SPEC-182 §RF-182-06 (2026-06-05): para usuarios NUEVOS, el prompt
  // pasa al paso 104 del onboarding (momento educativo con 3 ejemplos
  // de notificación y respaldo bibliográfico). Usuarios EXISTENTES
  // (`onboardingCompleted == true`) siguen recibiendo el prompt acá en
  // cold start — no podemos retroceder en su flujo.
  final onboardingCompleted =
      sharedPreferences.getBool('onboardingCompleted') ?? false;
  if (onboardingCompleted) {
    await NotificationService.requestPermissions();
  }

  // SPEC-196: infra de cobro (RevenueCat). La key pública por plataforma se
  // inyecta vía --dart-define (RC_IOS_KEY / RC_ANDROID_KEY); NO se hardcodea.
  // Si no hay key (cobro aún no habilitado) o es web, se mantiene el default
  // FreeBillingService + gating inerte (la app funciona completa).
  //
  // PERF-02: NO se difiere a post-runApp en esta pasada — RevenueCat es la
  // pieza que gatea el acceso Premium (dinero real) y moverla a un
  // FutureProvider post-runApp requeriría un rediseño del wiring de
  // billing_providers.dart (swap en vivo del servicio activo) que no se
  // puede validar sin un compilador/dispositivo real en este entorno. Queda
  // documentado como seguimiento recomendado, no aplicado a ciegas.
  final billingOverrides = await _initBilling();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ...billingOverrides,
      ],
      child: const ElenaApp(),
    ),
  );
}

/// SPEC fix (2026-06-08): App Check SOLO en release. En debug, el provider
/// `AppleProvider.debug`/`AndroidProvider.debug` exige un token registrado;
/// si no está (o el token rota al reinstalar), `exchangeDebugToken` devuelve
/// 403 en bucle, FirebaseAuth pierde la credencial a media sesión
/// (`Credential Changed. Current user:` vacío) → Firestore `permission-denied`
/// → la app lo trata como logout y resetea pilares / aborta escrituras.
/// Omitir App Check en debug elimina ese churn. Release sigue usando
/// AppAttest / PlayIntegrity / reCAPTCHA sin cambios.
///
/// PERF-02: extraído a función propia para poder correrlo en paralelo con
/// Crashlytics/Analytics vía Future.wait sin cambiar su lógica interna.
Future<void> _activateAppCheck() async {
  // SPEC-73.1 (housekeeping): AppCheck se omite en web debug porque la
  // clave reCAPTCHA v3 placeholder produce errores ruidosos en consola
  // que el try/catch de Dart no puede atrapar (Firebase web SDK los
  // emite desde JS antes de propagar a Dart).
  //
  // SPEC-81: la site key real se obtiene de
  // `lib/src/core/config/recaptcha_config.dart`. Si sigue siendo el
  // placeholder, emitimos warning visible al arranque para que no
  // pase a producción sin la clave real.
  //
  // En mobile (Android/iOS) y en web release seguimos activando
  // AppCheck con su provider correspondiente.
  if (kIsWeb && recaptchaIsPlaceholder) {
    AppLogger.warning(
      'AppCheck web está usando reCAPTCHA PLACEHOLDER. '
      'Registrar dominio en Google reCAPTCHA Admin Console y actualizar '
      'kRecaptchaSiteKey en lib/src/core/config/recaptcha_config.dart '
      'antes de un release público (ver docs/PRODUCTION_HARDENING.md §1).',
    );
  }

  // SPEC fix (2026-06-08): App Check SOLO en release. En debug, el provider
  // `AppleProvider.debug`/`AndroidProvider.debug` exige un token registrado;
  // si no está (o el token rota al reinstalar), `exchangeDebugToken` devuelve
  // 403 en bucle, FirebaseAuth pierde la credencial a media sesión
  // (`Credential Changed. Current user:` vacío) → Firestore `permission-denied`
  // → la app lo trata como logout y resetea pilares / aborta escrituras.
  // Omitir App Check en debug elimina ese churn. Release sigue usando
  // AppAttest / PlayIntegrity / reCAPTCHA sin cambios.
  final shouldActivateAppCheck = kReleaseMode;
  if (shouldActivateAppCheck) {
    try {
      await FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider: kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
        // appAttestWithDeviceCheckFallback: si AppAttest falla (dispositivo no
        // soportado, provisioning issue, primer launch en TestFlight), cae a
        // DeviceCheck automáticamente. AppAttest puro bloqueaba Firestore con
        // 403 silencioso en algunos devices/TestFlight sin devolver error útil.
        // ignore: deprecated_member_use
        appleProvider: kReleaseMode
            ? AppleProvider.appAttestWithDeviceCheckFallback
            : AppleProvider.debug,
        // ignore: deprecated_member_use
        webProvider: ReCaptchaV3Provider(kRecaptchaSiteKey),
      );
    } catch (e) {
      AppLogger.info(
        'AppCheck no se activó (ver docs/PRODUCTION_HARDENING.md §1): $e',
      );
    }
  } else {
    AppLogger.info('AppCheck omitido: web debug (ver SPEC-73.1).');
  }
}

/// SPEC-196/197/198: inicializa el servicio de cobro activo.
///
/// Prioridad:
///   1. RC_IOS_KEY / RC_ANDROID_KEY → RevenueCatBillingService (producción).
///   2. kDebugMode (sin keys) → FakeBillingService automático.
///      Gating activo, paywall funcional, sin tienda real.
///      Solo requiere `flutter run` (debug build normal).
///   3. Release sin keys → FreeBillingService, gating inerte.
Future<List<Override>> _initBilling() async {
  if (kIsWeb) return const [];

  // 1. RevenueCat con keys reales (producción o QA con sandbox).
  const iosKey = String.fromEnvironment('RC_IOS_KEY');
  const androidKey = String.fromEnvironment('RC_ANDROID_KEY');
  final key =
      defaultTargetPlatform == TargetPlatform.iOS ? iosKey : androidKey;
  if (key.isNotEmpty) {
    final service =
        RevenueCatBillingService(apiKey: key, debugLogging: kDebugMode);
    await service.initialize();
    AppLogger.info('SPEC-196: RevenueCatBillingService activo.');
    return [
      billingServiceProvider.overrideWith((ref) {
        ref.onDispose(service.dispose);
        return service;
      }),
      billingEnabledProvider.overrideWithValue(true),
    ];
  }

  // 2. Debug sin keys → FakeBillingService para que el paywall muestre paquetes
  //    y la compra simulada funcione. billingEnabledProvider ya es true por
  //    defecto en debug (ver billing_providers.dart), así que el gating está
  //    activo incluso si este override no llega a aplicarse.
  if (kDebugMode) {
    AppLogger.info(
      'SPEC-197/198: debug sin RC key → FakeBillingService activo. '
      'Gating visible, paywall funcional sin tienda real.',
    );
    final service = FakeBillingService();
    return [
      billingServiceProvider.overrideWith((ref) {
        ref.onDispose(service.dispose);
        return service;
      }),
    ];
  }

  // 3. Release sin keys → FreeBillingService, gating inerte (app completa).
  AppLogger.info(
    'SPEC-196: release sin RC key → cobro deshabilitado. '
    'Ver docs/SETUP_BILLING.md.',
  );
  return const [];
}
