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

  // SPEC-80: enganchar handlers de error globales lo antes posible
  // tras inicializar Firebase. Crashlytics solo reporta en release
  // mode mobile (web queda no soportado; debug solo loguea).
  await CrashlyticsService.init();

  // SPEC-193: analytics de negocio. Init tras Crashlytics; nunca bloquea
  // el arranque (el servicio absorbe sus propios errores). app_open es el
  // primer evento del embudo.
  await AnalyticsService.init();
  await AnalyticsService.logAppOpen();

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
        // ignore: deprecated_member_use
        appleProvider:
            kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
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

  // DT-04: SharedPreferences debe inicializarse antes de runApp.
  final sharedPreferences = await SharedPreferences.getInstance();

  // SPEC-05: Inicializar el servicio de notificaciones (timezone + canales Android).
  await NotificationService.init();

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

/// SPEC-196/197/198: inicializa el servicio de cobro activo.
///
/// Prioridad:
///   1. BILLING_FAKE=true → FakeBillingService (gating activo, sin tienda).
///      Úsalo para validar locks y paywall en device antes de tener RC keys.
///      flutter run --dart-define=BILLING_FAKE=true
///   2. RC_IOS_KEY / RC_ANDROID_KEY → RevenueCatBillingService (producción).
///   3. Sin nada → FreeBillingService, gating inerte (app completa sin muro).
Future<List<Override>> _initBilling() async {
  // 1. Modo fake para desarrollo/QA.
  const billingFake = bool.fromEnvironment('BILLING_FAKE');
  if (billingFake) {
    AppLogger.info(
      'SPEC-197/198: BILLING_FAKE=true → FakeBillingService activo. '
      'Gating visible, paywall funcional sin tienda real.',
    );
    final service = FakeBillingService();
    return [
      billingServiceProvider.overrideWith((ref) {
        ref.onDispose(service.dispose);
        return service;
      }),
      billingEnabledProvider.overrideWithValue(true),
    ];
  }

  // 2. RevenueCat con keys reales.
  if (kIsWeb) return const [];
  const iosKey = String.fromEnvironment('RC_IOS_KEY');
  const androidKey = String.fromEnvironment('RC_ANDROID_KEY');
  final key =
      defaultTargetPlatform == TargetPlatform.iOS ? iosKey : androidKey;
  if (key.isEmpty) {
    AppLogger.info(
      'SPEC-196: sin RC key para esta plataforma → cobro deshabilitado '
      '(gating inerte, app completa). Ver docs/SETUP_BILLING.md.',
    );
    return const [];
  }
  final service = RevenueCatBillingService(apiKey: key, debugLogging: kDebugMode);
  await service.initialize();
  return [
    // SPEC-213: overrideWith (no overrideWithValue) para que ref.onDispose
    // cierre el StreamController cuando el ProviderScope se destruye.
    billingServiceProvider.overrideWith((ref) {
      ref.onDispose(service.dispose);
      return service;
    }),
    billingEnabledProvider.overrideWithValue(true),
  ];
}
