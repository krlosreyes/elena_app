# SPEC-146 — Auth persistence: fix del logout aparente en cold start

**Estado:** CLOSED (implementada y testeada 2026-06-01)
**Versión:** 1.0
**Fecha:** 2026-06-01 · aprobada 2026-06-01 · cerrada 2026-06-01
**Tipo:** Bugfix crítico de retención + splash screen + hardening del redirect del router
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 1 — Estabilización (post-pivot estratégico 2026-06-01)
**Estimación:** 1.5–2 horas Carlos+Claude
**Marco normativo:** `CONSTITUTION.md`.
**Depende de:** SPEC-73 (FirebaseAuthRepository + authStateProvider — sin cambios).

**Bloquea:** El abandono del usuario en el primer cold start tras instalar. Sin este fix, todo lo demás del producto es irrelevante porque el usuario no llega a verlo.

---

## 1. Contexto y motivación

### 1.1 — El bug reportado

Carlos reportó tras usar Elena en su iPhone: *"al cerrar la app y volver a abrirla muestra el login, se sale del usuario, eso no debe pasar"*.

Diagnóstico inicial (durante diagnóstico estratégico del 2026-06-01) sugería que podía ser confusión UX. **La auditoría profunda del código demuestra que es bug real.**

### 1.2 — Causa raíz

`lib/src/router/app_router.dart` línea 35:

```dart
redirect: (context, state) {
  final account = authState.value;  // ← BUG
  ...
  if (account == null) return isPublic ? null : '/login';
  ...
}
```

`authStateProvider` es `StreamProvider<AppAccount?>`. Su `.value` retorna:
- `null` cuando `AsyncLoading` (estado inicial mientras Firebase Auth hidrata la sesión del keychain iOS)
- El user cuando `AsyncData` (sesión hidratada)
- `null` cuando emite null (no autenticado)

**El router NO distingue entre "loading" y "no autenticado".** Trata ambos como `account == null` y redirige a `/login` durante los ~200-500 ms que tarda Firebase Auth en rehidratar la sesión persistida.

Cuando Firebase Auth termina, emite el user, `authStateProvider` se actualiza, el router re-evalúa y redirige al destino correcto. **Pero el usuario ya vio el `/login` por un instante.** Si la pantalla tiene foco rápido o el usuario es lento en notar, se queda ahí — efectivamente "deslogueado".

Este es un patrón bien documentado en la comunidad Flutter + Firebase Auth. Ver [issue 32976 de flutter/flutter](https://github.com/flutter/flutter/issues/32976) y discusiones de GoRouter del 2023-2024.

### 1.3 — Lo que el bug NO es

Para evitar buscar en el lugar equivocado:

- **NO es bug de Firebase Auth persistence.** Firebase Auth persiste correctamente en el keychain iOS y NSUserDefaults Android sin configuración explícita (default `LOCAL`).
- **NO es bug de App Check.** App Check se activa correctamente con `AppleProvider.appAttest` en release y `AppleProvider.debug` en debug. Falla de App Check causaría errores de Firestore más tarde, no logout aparente.
- **NO es bug del `_buildAccount` retornando rawProfile=null.** Eso sería un caso de `partial_profile` que el router redirige a `/onboarding`, no a `/login`.
- **NO es bug de `setPersistence`.** En Flutter mobile el default es persistente. La API `setPersistence` solo aplica a Flutter web y aún ahí el default es `LOCAL`.

## 2. Decisión de producto (resumen ejecutivo)

1. **Se introduce `SplashScreen`** como pantalla inicial mientras el `authStateProvider` resuelve. Logo de Elena + indicador de carga sutil.
2. **`initialLocation` cambia de `/dashboard` a `/splash`** en el `GoRouter`.
3. **El `redirect` del router se modifica para distinguir AsyncLoading de AsyncData(null).** Mientras `authState.isLoading`, retorna `null` (no redirige) — el usuario queda en `/splash`.
4. **Cuando `authState` resuelve, la pantalla `SplashScreen` navega** programáticamente al destino correcto (`/login` si null, `/onboarding` si incompleto, `/dashboard` si completo).
5. **No se toca `FirebaseAuthRepository` ni `authStateProvider`.** El bug no está ahí — el comportamiento de esos componentes es correcto.

## 3. Lo que NO se hace (límites duros de scope)

- **No se cambia el modelo de persistencia de Firebase Auth.** No se llama a `setPersistence` ni se modifica la inicialización de FirebaseAuth en `main.dart`.
- **No se cambia App Check.** Su configuración actual es correcta.
- **No se introduce loading global en widget root** (`MaterialApp.builder`) — eso confundiría con otros loading states. El loading vive en `/splash` específicamente.
- **No se agrega timeout al splash.** Si Firebase Auth nunca emite (network completamente caído), el usuario queda en splash. Eso es preferible a redirigirlo a `/login` con sesión válida en el keychain — la próxima vez con red funciona normal.
- **No se cambia el comportamiento del logout explícito.** Sigue navegando a `/login` correctamente.
- **No se toca la lógica de `account.isComplete` / `account.needsOnboarding` / `account.profileStatus`.** Esa lógica de SPEC-73 está bien.

## 4. Requisitos funcionales

### RF-146-01 — `SplashScreen` widget

Crear `lib/src/features/auth/presentation/splash_screen.dart`:

```dart
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  ...
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    // Escucha el authStateProvider. Cuando resuelve (no es loading),
    // navega al destino correcto.
    ref.listen<AsyncValue<AppAccount?>>(
      authStateProvider,
      (previous, next) {
        if (next.isLoading) return;
        // Resolved.
        final account = next.value;
        final destination = _resolveDestination(account);
        if (mounted) {
          context.go(destination);
        }
      },
    );

    return const Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Elena (texto por ahora — asset image en SPEC futura)
            Text('Metamorfosis Real', ...),
            SizedBox(height: 32),
            CircularProgressIndicator(color: AppColors.metabolicGreen),
          ],
        ),
      ),
    );
  }

  String _resolveDestination(AppAccount? account) {
    if (account == null) return '/login';
    if (account.needsOnboarding) return '/onboarding';
    return '/dashboard';
  }
}
```

### RF-146-02 — Router: `/splash` como initial + redirect que respeta loading

Modificar `app_router.dart`:

```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',  // SPEC-146: cambio de '/dashboard'
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // SPEC-146 RF-146-02: durante AsyncLoading, NO redirigir.
      // El usuario queda en /splash hasta que authState resuelva.
      // Esto evita el flash de /login en cold start con sesión válida.
      if (authState.isLoading) {
        // Si la ruta actual NO es /splash (caso poco común — deep link
        // a /dashboard mientras auth aún carga), redirigimos a /splash.
        return loc == '/splash' ? null : '/splash';
      }

      // Resolved → lógica original SPEC-73 + SPEC-117 sin cambios.
      final account = authState.value;
      final isLegalDoc = loc == '/legal/privacy' || loc == '/legal/terms';
      final isPublic = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/set-password' ||
          isLegalDoc ||
          loc.startsWith('/open');

      // Splash debe redirigir cuando ya resolvió (no quedar atrapado).
      if (loc == '/splash') {
        if (account == null) return '/login';
        if (account.needsOnboarding) return '/onboarding';
        return '/dashboard';
      }

      // 1. No autenticado.
      if (account == null) {
        return isPublic ? null : '/login';
      }

      // 2. Autenticado en ruta pública (auth) → llevar a destino.
      if (isPublic && !isLegalDoc) {
        return account.isComplete ? '/dashboard' : '/onboarding';
      }

      // 3. Perfil incompleto → forzar onboarding.
      if (account.needsOnboarding && loc != '/onboarding') {
        return '/onboarding';
      }

      // 4. Perfil completo intentando entrar a /onboarding.
      if (account.isComplete && loc == '/onboarding') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // ... resto de rutas sin cambios.
    ],
  );
});
```

### RF-146-03 — Tests del redirect

Tests unitarios del flujo de redirect en estados:
- `AsyncLoading` → cualquier ruta no-splash redirige a `/splash`.
- `AsyncData(null)` + ruta privada → redirige a `/login`.
- `AsyncData(account complete)` en `/splash` → redirige a `/dashboard`.
- `AsyncData(account partial)` en `/splash` → redirige a `/onboarding`.

Los tests se hacen sobre la función de redirect aislada (extraerla a helper puro testeable).

### RF-146-04 — Refactor del redirect a helper puro testeable

Extraer la lógica del redirect a `lib/src/router/router_redirect.dart`:

```dart
String? computeRedirect({
  required AsyncValue<AppAccount?> authState,
  required String location,
}) {
  // Misma lógica del RF-146-02 pero en función pura, sin context.
}
```

El `goRouterProvider` lo invoca desde su `redirect`. Esto desacopla el GoRouter (Flutter) de la lógica del redirect (Dart puro), facilitando los tests.

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `SplashScreen` widget | `lib/src/features/auth/presentation/splash_screen.dart` (nuevo) |
| 2 | Crear helper puro de redirect | `lib/src/router/router_redirect.dart` (nuevo) |
| 3 | Modificar router: ruta /splash + initialLocation + redirect | `lib/src/router/app_router.dart` |
| 4 | Tests del redirect (función pura) | `test/router/router_redirect_test.dart` (nuevo) |
| 5 | Tests del SplashScreen | `test/features/auth/presentation/splash_screen_test.dart` (nuevo) |

Archivos NO modificados:
- `main.dart` (init de Firebase + App Check sin cambios).
- `firebase_auth_repository.dart`.
- `auth_providers.dart` (`authStateProvider` y `currentUserStreamProvider` sin cambios).
- Pantallas de login, register, forgot-password, set-password.
- Onboarding.

## 6. Modelo de datos persistente

Sin cambios.

## 7. Criterios de aceptación

1. Al instalar la app por primera vez en iPhone limpio, el usuario ve `/splash` por un instante y luego `/login`. No hay flash de `/dashboard`.

2. Tras login exitoso, navegación a `/dashboard` (o `/onboarding` si perfil incompleto).

3. Cerrar la app completamente (swipe up cerrar) y reabrir: usuario ve `/splash` brevemente y luego `/dashboard` directamente, **sin pasar por `/login`**.

4. Hot restart en debug: mismo comportamiento que cold start — splash + dashboard, no login flash.

5. Logout explícito desde Perfil: usuario va a `/login` correctamente, no a splash.

6. Deep link a `/dashboard` mientras auth aún carga: redirige a `/splash`. Cuando resuelve, redirige al destino.

7. `computeRedirect` retorna `/splash` cuando `authState.isLoading == true` y location no es `/splash`.

8. `computeRedirect` retorna `null` cuando location es `/splash` y `authState.isLoading == true` (no doble-redirect).

9. `computeRedirect` retorna `/login` cuando `authState = AsyncData(null)` y location es privada.

10. `flutter analyze` sin issues nuevos.

11. `flutter test` mantiene baseline + ≥8 tests nuevos del redirect + ≥3 del SplashScreen.

## 8. Plan de pruebas

### 8.1 — Tests del helper puro `computeRedirect`

`test/router/router_redirect_test.dart`:

- AsyncLoading + cualquier ruta no-splash → `/splash`.
- AsyncLoading + `/splash` → `null` (queda).
- AsyncData(null) + ruta privada → `/login`.
- AsyncData(null) + `/login` → `null` (queda).
- AsyncData(null) + `/legal/privacy` → `null` (público).
- AsyncData(complete) + `/splash` → `/dashboard`.
- AsyncData(partial) + `/splash` → `/onboarding`.
- AsyncData(complete) + `/onboarding` → `/dashboard`.
- AsyncData(partial) + `/dashboard` → `/onboarding`.

### 8.2 — Tests del SplashScreen widget

`test/features/auth/presentation/splash_screen_test.dart`:

- Renderiza branding + progress indicator.
- Cuando `authStateProvider` resuelve con null → llama `context.go('/login')`.
- Cuando resuelve con account complete → llama `context.go('/dashboard')`.

### 8.3 — Smoke E2E manual

Carlos en iPhone:
1. Instalar app fresca (sin sesión previa).
2. Verificar: splash → login.
3. Login → dashboard.
4. Cerrar app por completo (swipe).
5. Reabrir → splash → dashboard SIN flash de login.
6. Logout → login.

## 9. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Splash queda atrapado si authState nunca emite (network caído) | Media | Si Firebase Auth tarda demasiado (>5s), el usuario tap puede volver al login manualmente. Esto se ataca en SPEC futura con timeout + retry. Para MVP el comportamiento actual es preferible al bug. |
| R-02 | Deep links a /dashboard o /perfil mientras auth aún carga rompen UX | Baja | El redirect maneja: si está loading y location ≠ /splash, redirige a /splash. Cuando resuelve, naturalmente navega al destino. |
| R-03 | Cambio de initialLocation rompe tests existentes que asumen `/dashboard` | Media | Auditar tests existentes que usen `goRouterProvider`. Probablemente requieren un `await pumpAndSettle` adicional para esperar el redirect del splash. |
| R-04 | SplashScreen sin asset de logo se ve cutre | Baja | Para MVP usamos texto "Metamorfosis Real" con styling. Asset image puede venir en SPEC posterior de branding. |

## 10. Plan de rollout

**Bloque único (~1.5-2h):**

1. Crear `router_redirect.dart` con helper puro.
2. Tests del helper puro (~8 tests).
3. Crear `SplashScreen` widget.
4. Tests del SplashScreen (~3 tests).
5. Modificar `app_router.dart` para usar helper + nueva ruta + nuevo initialLocation.
6. `flutter analyze` + `flutter test` completo (verificar no rompo otros tests).
7. Smoke E2E manual en iPhone.
8. Commit + push.
9. Marcar SPEC-146 CLOSED.

## 11. Out of scope (explícito)

- Asset image del logo en el splash (SPEC posterior de branding).
- Timeout + retry del splash si authState nunca emite.
- Migración del FirebaseAuth a setPersistence explícito (no es necesario en mobile).
- Cambio de comportamiento del logout.
- Múltiples cuentas / fast user switching.
- Biometric unlock al reabrir la app (SPEC futura).

## 12. Aprobación

Esta SPEC requiere:

1. **Visto bueno de Carlos** sobre el diseño del SplashScreen (texto + progress indicator MVP).
2. **Sin validación clínica externa.**
3. **Sin coordinación con sitio web Metamorfosis Real.** El sitio no se ve afectado.

Aprobada por Carlos 2026-06-01 al confirmar inicio de Ola 1.

## 13. Changelog

### v1.0 — 2026-06-01

Documento inicial post-investigación del bug "se sale del usuario al cerrar la app". Causa raíz identificada: race condition entre `AsyncLoading` y `AsyncData(null)` en el redirect del GoRouter. Fix: SplashScreen como initialLocation + redirect que distingue loading de no autenticado. 1.5-2h de implementación. Primer commit visible del pivot estratégico passive→active coaching.

### Cierre 2026-06-01 (mismo día)

Implementación completada en bloque único:

- `lib/src/router/router_redirect.dart` (nuevo) — `computeRedirect` función pura testeable que distingue 4 estados del authState: `AsyncLoading`, `AsyncData(null)`, `AsyncData(complete)`, `AsyncData(partial)`. Preserva la lógica de SPEC-73 y SPEC-117 para rutas legales y públicas.
- `lib/src/features/auth/presentation/splash_screen.dart` (nuevo) — ConsumerWidget simple con branding "Metamorfosis Real / Elena · Salud metabólica" + CircularProgressIndicator color metabolicGreen.
- `lib/src/router/app_router.dart` — `initialLocation` cambiado de `/dashboard` a `/splash`. El bloque del redirect inline (50 líneas) se reemplaza por invocación a `computeRedirect`. Nueva ruta `/splash` agregada al inicio de routes.
- `test/router/router_redirect_test.dart` (nuevo) — 18 tests exhaustivos cubriendo los 4 estados × tipos de ruta (privada, pública, auth, legal, splash, onboarding, dashboard, open).
- `test/features/auth/presentation/splash_screen_test.dart` (nuevo) — 3 tests del SplashScreen.

**Patrón aplicado:** desacoplar la lógica del redirect (Dart puro testeable) del GoRouter (Flutter). El `goRouterProvider` ahora invoca `computeRedirect` con `authState` y `location`. Esto permite probar TODAS las decisiones de redirección sin levantar un widget tree completo ni mockear GoRouter.

**Próximo paso desbloqueado:** Ola 1 continúa con SPEC-132.next (HealthKit observers + background delivery, ~3-4 días) y SPEC-145 (auditoría indexes Firestore, 1 día en paralelo). El usuario ya no se desloguea al cerrar la app — primer hito visible del pivot estratégico passive→active coaching.
