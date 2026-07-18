// TEST-04 (auditoría pre-producción 2026-07-11).
//
// Primer smoke test de integration_test/. Objetivo mínimo: montar el
// widget raíz `ElenaApp` (lib/src/app.dart) de punta a punta y verificar
// que no crashea al construirse ni en los primeros frames. NO cubre el
// flujo completo registro → onboarding → dashboard — ese es el siguiente
// paso recomendado, y requiere decisiones de diseño de test que no se
// tomaron a ciegas en esta pasada (ver bloque "Próximos pasos" al final).
//
// ── Por qué este test inicializa Firebase REAL en vez de mockear ──────────
//
// `ElenaApp.build()` (ver app.dart) observa de forma incondicional media
// docena de providers — `notificationSchedulerProvider`,
// `dailySummaryPersistenceServiceProvider`, `metabolicCycleEvaluatorProvider`,
// `cycleScoreMigrationProvider`, `weeklyImrStalenessTriggerProvider` — que a
// su vez construyen EAGERMENTE (dentro del propio builder del provider, no
// dentro de un método async posterior) repositorios Firestore concretos
// (`FirestoreUserProfileV1Source`, `AppStateRepository`,
// `MetabolicCycleRepositoryImpl`, `FirestoreStreakV1Source`,
// `FirestoreFastingIntervalV1Source`, etc.), cada uno con su propio
// `firestore ?? FirebaseFirestore.instance` inline. No existe en este
// proyecto un `firestoreProvider` central compartido — cada repo referencia
// `FirebaseFirestore.instance` directo — así que no hay UN solo punto de
// override para inyectar `FakeFirebaseFirestore()` (patrón que sí usan los
// tests de repositorio en test/, ver p.ej.
// test/features/auth/firebase_auth_repository_test.dart). Habría que
// overridear ~8-10 providers de repositorio individuales con sus tipos e
// implementaciones concretas exactas — no lo hice a ciegas en esta pasada
// porque no puedo compilar/ejecutar Flutter en este sandbox para verificar
// cada firma, y un error ahí produce un archivo que ni siquiera compila.
//
// La alternativa (esta que se implementó) es la convención estándar de
// Flutter para integration_test/: correr contra un Firebase real (o un
// emulador, si Carlos prefiere apuntar `--dart-define` a uno) en un
// dispositivo/simulador real, igual que hace `lib/main.dart`. Con
// Firebase.initializeApp() completado, `FirebaseFirestore.instance` /
// `FirebaseAuth.instance` ya no lanzan `[core/no-app]` — el usuario
// simplemente no está autenticado, así que las queries a Firestore fallarán
// con `permission-denied` (aparecen como `AsyncError` en los providers, no
// como excepciones síncronas que tiren el árbol de widgets).
//
// ── Qué NO se validó en este sandbox ───────────────────────────────────────
//
// Este sandbox no tiene Flutter SDK instalado (no hay forma de correr
// `flutter test integration_test/app_smoke_test.dart`). Este archivo se
// escribió leyendo el código fuente real de ElenaApp, app_router.dart y
// main.dart, pero NO se ejecutó ni una sola vez. Es el primer paso a validar
// en la Mac de Carlos, con un simulador/dispositivo conectado:
//
//   flutter test integration_test/app_smoke_test.dart
//
// Riesgos conocidos que podrían hacer fallar esta primera corrida (y que
// habría que resolver iterando con el stack trace real, no a ciegas):
//   - `initializeDateFormatting('es', null)` no se llamó aquí (main.dart sí
//     lo hace antes de Firebase.initializeApp) — si alguna pantalla bajo
//     /splash usa DateFormat con patrón localizado antes de que este test
//     lo inicialice, podría lanzar LocaleDataException.
//   - App Check no se activa en este test (sí lo hace main.dart) — en
//     release mode los reads de Firestore podrían rechazarse; en debug
//     debería comportarse igual que correr la app sin token de depuración
//     registrado (permission-denied, no crash).
//   - `metabolicCycleEvaluatorProvider` liga un `Stream.periodic` — por eso
//     este test usa `pump(duration)` acotado varias veces en vez de
//     `pumpAndSettle()`, que podría no terminar nunca.

import 'package:elena_app/src/app.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ElenaApp monta sin crashear (smoke mínimo)', (tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // main.dart siempre overridea este provider (su default lanza
    // UnimplementedError) — ver
    // lib/src/core/providers/shared_preferences_provider.dart.
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const ElenaApp(),
      ),
    );

    // No usamos pumpAndSettle(): metabolicCycleEvaluatorProvider mantiene
    // vivo un Stream.periodic interno que nunca "asienta". Unos pocos
    // pumps acotados alcanzan para dejar correr el primer frame + los
    // microtasks/futures inmediatos (splash, redirect inicial).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Assert mínimo del smoke test: nada se propagó como excepción no
    // manejada durante el montaje ni los primeros frames.
    expect(tester.takeException(), isNull);
  });
}

// ── Próximos pasos (no implementados en esta pasada) ─────────────────────
//
// Flujo completo registro → onboarding → dashboard: requiere decidir (con
// Carlos, no a ciegas):
//   1. Contra qué backend correr — ¿proyecto Firebase real de staging, o
//      Firestore/Auth Emulator Suite vía `--dart-define` o
//      `USE_FIRESTORE_EMULATOR`? El proyecto no tiene hoy un flag para
//      apuntar la app a emuladores en runtime (ver firebase.json — solo
//      configura el emulador de Firestore para funciones/reglas, no para
//      la app Flutter).
//   2. Cómo crear/limpiar un usuario de prueba real entre corridas
//      (`FirebaseAuth` + Firestore) sin ensuciar producción.
//   3. Cómo simular HealthKit/Health Connect (el onboarding puede tocar
//      permisos nativos que no responden igual en un simulador sin salud
//      configurada).
