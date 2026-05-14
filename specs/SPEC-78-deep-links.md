# SPEC-78 — Deep Links / Universal Links MR → App

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Hardening pre-launch (handover sitio MR → app)
**Marco normativo:** `CONSTITUTION.md`, [Android App Links](https://developer.android.com/training/app-links), [iOS Universal Links](https://developer.apple.com/ios/universal-links/).

---

# 1. Contexto

El sitio Metamorfosis Real y la app comparten Firebase Auth + Firestore. Cuando un usuario en el sitio toca un link tipo "Abre tu IMR en la app" (desde un email transaccional, una compartida o el footer del propio sitio), debe abrir ElenaApp directamente en la pantalla relevante, sin pasar por un browser intermedio.

Sin esto: el link abre el browser → el browser muestra una página de "abre la app" → fricción extra.

# 2. Problema

Hoy el `AndroidManifest.xml` (`android/app/src/main/AndroidManifest.xml:32-53`) tiene un único `intent-filter` con `MAIN/LAUNCHER` — no entiende deep links. El `Info.plist` (`ios/Runner/Info.plist`) no declara Associated Domains. El `go_router` ya soporta URL parsing pero no hay rutas dedicadas a entry points externos (excepto `/set-password` que SPEC-73 §RF-73-09 introdujo).

# 3. Solución propuesta

**3.1 Rutas deep-linkable** en `app_router.dart`:
- `/open` (raíz de un deep link genérico) → redirige a `/dashboard` si auth, a `/login` si no.
- `/open/imr` → `/dashboard` con scroll al score.
- `/open/welcome` → onboarding (post-magic-link, ya cubierto por `/set-password`).

**3.2 Android App Links** en `AndroidManifest.xml`. Agregar `intent-filter` con `autoVerify="true"` que matchea `https://metamorfosisreal.com/app/*`. Cuando Android verifica el dominio (via `assetlinks.json` en el sitio), abrir la app directo sin mostrar el chooser.

**3.3 iOS Universal Links** en `Info.plist`. Declarar Associated Domains con `applinks:metamorfosisreal.com`. Apple verifica con `apple-app-site-association` en el sitio.

**3.4 Manejo de cold start** en `app.dart`. `go_router` ya captura la URL inicial; el redirect de auth la respeta.

# 4. Plan

| Archivo | Cambio |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Intent-filter para `https://metamorfosisreal.com/app/*` con `autoVerify="true"` |
| `ios/Runner/Info.plist` | Comentario sobre Associated Domains (se configura en Xcode Capabilities, no en Info.plist) |
| `ios/Runner/Runner.entitlements` (verificar si existe; si no, agregar) | `com.apple.developer.associated-domains: applinks:metamorfosisreal.com` |
| `lib/src/router/app_router.dart` | Rutas `/open`, `/open/imr`, `/open/welcome` (públicas para deep link) |
| `docs/DEEP_LINKS_SETUP.md` (nuevo) | Documenta los archivos .well-known que el sitio debe servir |
| `test/router/deep_link_routing_test.dart` (nuevo si tiene sentido) | Tests del redirect según auth state |

# 5. Criterios de aceptación

- Android: tap en `https://metamorfosisreal.com/app/imr` desde un email abre la app en `/dashboard` (si autenticado) o `/login` (si no). Sin chooser.
- iOS: mismo comportamiento, sin pasar por Safari.
- Si el deep link es a una ruta protegida y el usuario no está autenticado, el router lo manda a `/login` y al autenticarse vuelve al destino original.
- `flutter analyze` sin issues nuevos.
- `flutter test` mantiene 462+ verdes.

# 6. Pruebas

Manual:
1. Compilar app en device → instalar → ejecutar `adb shell am start -W -a android.intent.action.VIEW -d "https://metamorfosisreal.com/app/imr" com.metamorfosis.elena.elena_app` (Android).
2. iOS: `xcrun simctl openurl booted https://metamorfosisreal.com/app/imr`.
3. Tap en un link de email real una vez que el sitio publique `.well-known/assetlinks.json` y `.well-known/apple-app-site-association`.

Test automatizado:
- `deep_link_routing_test.dart` con `goRouterProvider` overriden, simulando location inicial `/open/imr` con/sin auth → verifica que el redirect lleva al destino correcto.

# 7. Riesgos

- **Verificación de dominio depende del sitio**. Sin los archivos `.well-known` publicados, Android no auto-verifica y muestra el chooser. iOS tampoco abre como Universal Link. La configuración técnica de la app está lista en SPEC-78; el sitio cumple su parte en paralelo.
- **firebaseapp.com como dominio alternativo**: Firebase Auth ya usa `elena-app-2026-v1.firebaseapp.com` para magic links (SPEC-73). Eso no entra acá — es ruta interna de Firebase.
- **Build iOS**: cambios en `Runner.entitlements` requieren rebuild + provisioning profile que incluya el capability "Associated Domains". Pre-requisito de Apple Developer Program (debe estar configurado en App Store Connect).

# 8. Out of scope

- Publicar `.well-known/assetlinks.json` y `apple-app-site-association` en `metamorfosisreal.com`. Responsabilidad del equipo del sitio. Documentado en `DEEP_LINKS_SETUP.md`.
- Generación dinámica de short links (ej. bit.ly). Los deep links son URLs estáticas con parámetros.
- Tracking de campañas (UTM params). Si se requiere, se agrega en SPEC-80 (telemetría) sin tocar esta SPEC.
- Compatibilidad con web (clicks en el browser que abren la PWA). La app es nativa móvil; el sitio tiene su propia versión web.

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 462 verdes / 3 skipped / 0 rojos. Sin cambios en cobertura (los entry points `/open*` son redirects puros, no tienen lógica que testear unitariamente).

**Pendientes externos para que el deep link funcione end-to-end:**
1. Equipo del sitio publica `.well-known/assetlinks.json` y `.well-known/apple-app-site-association` según `docs/DEEP_LINKS_SETUP.md`.
2. Equipo iOS habilita capability "Associated Domains" en Xcode + AppID.
3. Smoke test en device físico tras los dos pasos anteriores.
