# SPEC-80 — Firebase Crashlytics + PII scrubbing

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Hardening pre-launch (observabilidad post-launch)
**Marco normativo:** `CONSTITUTION.md`, [Firebase Crashlytics docs](https://firebase.google.com/docs/crashlytics).

---

# 1. Contexto

Sin observabilidad de crashes en producción, los bugs reportados por usuarios son la única señal de problemas. Eso es tarde y caro. Necesitamos capturar excepciones automáticamente con suficiente contexto para diagnosticar, pero sin filtrar PII (email, uid, nombre).

# 2. Problema

La app no reporta crashes a ningún backend. Si un usuario tiene un null pointer o un error de red sin manejar, queda invisible al equipo. `AppLogger.error` escribe a consola local — sirve en debug, no en producción.

# 3. Solución propuesta

**3.1 Firebase Crashlytics** como backend (no Sentry):
- Ya usamos Firebase para auth/firestore/appcheck — sin nuevo SaaS.
- Console integrada con el resto del stack.
- Cero configuración extra (usa el `google-services.json` / `GoogleService-Info.plist` ya presentes).
- Limitación: **no soporta web**. Para web MVP queda fuera; cuando se lance versión web se agrega Sentry en SPEC futura.

**3.2 `CrashlyticsService`** (`lib/src/core/services/crashlytics_service.dart`):
- `init()` — engancha `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`. Habilita collection solo si `kReleaseMode` (no inunda Console durante desarrollo).
- `recordError(Object error, StackTrace? stack, {String? reason, bool fatal = false})` — wrapper que aplica PII scrubbing al mensaje antes de enviar.
- `setUserId(String? uid)` — para correlacionar crashes pero sin enviar email/nombre.
- Internamente skip si `kIsWeb` (Crashlytics no funciona en web).

**3.3 PII Scrubber puro** (`lib/src/core/services/pii_scrubber.dart`):
- `scrub(String input)` reemplaza patrones reconocibles:
  - Emails: regex `\b[\w.-]+@[\w.-]+\.\w+\b` → `[REDACTED_EMAIL]`.
  - Firebase Auth UIDs: regex de 28 chars alfanuméricos → `[REDACTED_UID]`.
  - Bearer tokens / API keys que aparezcan en stacktraces → `[REDACTED_TOKEN]`.
- Función pura, testeable.

**3.4 `main.dart` wiring** dentro de `runZonedGuarded` para capturar excepciones async no manejadas.

# 4. Plan

| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | + `firebase_crashlytics: ^4.x` |
| `lib/src/core/services/pii_scrubber.dart` (nuevo) | Función pura `scrub(String)` |
| `lib/src/core/services/crashlytics_service.dart` (nuevo) | Wrapper init + recordError |
| `lib/main.dart` | `runZonedGuarded` + `CrashlyticsService.init()` |
| `test/core/services/pii_scrubber_test.dart` (nuevo) | Tests del scrubber |

# 5. Criterios de aceptación

- En release build Android/iOS, una excepción no manejada se reporta a Firebase Console → Crashlytics dentro de minutos.
- El mensaje reportado NO contiene email del usuario actual ni su uid en texto plano.
- En debug build, Crashlytics no envía (evita inundación durante desarrollo).
- En web, el servicio queda inactivo sin romper la app.
- `flutter test` mantiene 468+ verdes con +N nuevos del scrubber.

# 6. Pruebas

`pii_scrubber_test.dart`:
- Email simple: `'Error de carlos@example.com'` → `'Error de [REDACTED_EMAIL]'`.
- Multiple emails en la misma frase.
- Email con subdomain y plus addressing.
- UID Firebase (28 alfanumérico): `'uid abc123XYZ456...28chars'` → `'uid [REDACTED_UID]'`.
- String sin PII queda intacto.
- Bearer token formato `Bearer eyJ...` → `Bearer [REDACTED_TOKEN]`.

# 7. Riesgos

- **Web no cubierto**: Crashlytics no funciona en web. Si se lanza versión web antes de SPEC futura con Sentry, esos crashes son invisibles. Aceptable porque MVP es mobile.
- **PII en stacktraces no obvios**: el scrubber solo detecta patrones conocidos. Si un stacktrace incluye una variable con email asignada a un local, la regex la captura. Pero si está en JSON nested o codificada, puede escapar. Mitigación: revisar primeros 10 reportes en Console y refinar.
- **`firebase_crashlytics` requiere `google-services.json` con el config de Crashlytics activado**. Ya presente en el proyecto; verificar al primer build.
- **Performance**: Crashlytics tiene overhead despreciable. No bloquea el run.

# 8. Out of scope

- Sentry para web (SPEC futura cuando se lance versión web).
- Analytics events (separado: `AuthTelemetry` stub queda como está; SPEC futura puede cablearlo a Firebase Analytics).
- Performance Monitoring (Firebase Performance es otro paquete; no incluido).
- Custom dashboards en Crashlytics Console (configuración de Console, no de código).

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 479 verdes / 3 skipped / 0 rojos (+11 nuevos del PiiScrubber).

**Pendientes externos pre-launch:**
1. Firebase Console → Crashlytics → habilitar SDK del proyecto (si no está).
2. Smoke test en device release: forzar un crash artificial (ej. `throw Exception('test')`) y verificar que aparece en Console dentro de 5-10 min.
3. Revisar los primeros 10 reportes y refinar el PII scrubber si aparece data no anticipada.
