# SPEC-81 — Hardening de `firestore.rules` + reCAPTCHA v3 real

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Hardening pre-launch
**Marco normativo:** `CONSTITUTION.md`, Apple App Store Review Guideline 5.1.2 (data security), Google reCAPTCHA v3 docs.

---

# 1. Contexto

Antes del lanzamiento público, dos puntos de seguridad pendientes:

1. **`firestore.rules`** funciona pero permite escrituras con shapes arbitrarios. Un cliente comprometido podría escribir basura en `users/{uid}` y la app no validaría.
2. **AppCheck en web** usa un reCAPTCHA v3 placeholder (`'6LeX-OcpAAAA...'` en `main.dart:41`) que falla en cualquier dominio real. Producción necesita una clave registrada con `metamorfosisreal.com` y dominios de testing.

# 2. Problema

Las reglas actuales:
- ✅ Cubren `users/{uid}` y subcolecciones (autenticación + uid match).
- ✅ Cubren `fasting_history` top-level (SPEC-83).
- ✅ Cubren catálogos `master_food_db`, `master_exercises_db`, `user_food_suggestions`, `metamorfosis_posts`.
- ❌ NO tienen denial-by-default explícito. Si alguien crea una colección nueva, Firestore por defecto deniega — pero esa garantía debería estar como regla explícita.
- ❌ NO validan shape en write a `users/{uid}` (un cliente comprometido podría escribir `users/{uid} = {malicious: '...'}`).

reCAPTCHA:
- ❌ Placeholder `'6LeX-OcpAAAAAI8iG-Y6G9S7v7L3H-O-1-9-O-9'` en `main.dart:41` no funciona. Cualquier deploy a producción web fallaría AppCheck silenciosamente.

# 3. Solución propuesta

**3.1 `firestore.rules` con denial-by-default explícito** y validación mínima de shape en `users/{uid}`:

- Default: `allow read, write: if false;` al final del bloque `match /databases/{database}/documents`.
- En `users/{uid}` write: verificar que `request.resource.data.id == userId` (SPEC-87 inyecta este campo; si alguien intenta escribir un id distinto, denial).
- En `users/{uid}` write: limitar tamaño del doc (`request.resource.size() < 100000` = 100KB protect against abuse).
- Subcolecciones: mantener wildcard pero también limitar tamaño.

**3.2 reCAPTCHA v3 con variable de entorno y placeholder claro**:

- Mover la clave a un constante explícita en `lib/src/core/config/recaptcha_config.dart` con TODO visible.
- Documentar paso a paso en `docs/PRODUCTION_HARDENING.md` cómo registrar el dominio en Google reCAPTCHA Console y obtener la clave real.
- Si la clave sigue siendo el placeholder, mostrar un warning visible al levantar la app (no bloqueante).

# 4. Plan

| Archivo | Cambio |
|---|---|
| `firestore.rules` | Denial-by-default + shape validation + size limit |
| `lib/src/core/config/recaptcha_config.dart` (nuevo) | Constante con TODO visible y validación |
| `lib/main.dart` | Usar la constante; warning si placeholder |
| `docs/PRODUCTION_HARDENING.md` (nuevo) | Checklist pre-launch con reCAPTCHA setup |

# 5. Criterios de aceptación

- `firebase deploy --only firestore:rules` despliega las reglas nuevas sin errores de compilación.
- Un cliente autenticado puede leer/escribir su propio doc.
- Un cliente autenticado NO puede leer ni escribir el doc de otro usuario.
- Un cliente NO autenticado solo puede leer `metamorfosis_posts`.
- Un cliente que intenta escribir un payload mayor a 100KB es rechazado.
- Si reCAPTCHA está en placeholder, la consola muestra warning al arranque.
- `flutter analyze` sin issues nuevos.
- `flutter test` mantiene 479+ verdes.

# 6. Pruebas

- **Test de reglas con Firebase Emulator Suite** (manual, pre-deploy): `firebase emulators:start --only firestore` + suite básica de denial. Out of scope automatizarlo en CI por costo de setup; documentado en `docs/PRODUCTION_HARDENING.md` para verificación pre-launch.
- Test pura del config: si `RecaptchaConfig.isPlaceholder` retorna true para la clave default. Útil para CI gate "no deployar a prod con placeholder".

# 7. Riesgos

- **Romper escrituras actuales**: si agrego shape validation muy estricta, escrituras válidas podrían fallar. Mitigación: solo validar `id` match y tamaño máximo; no validar tipos de campos individuales (delegado a `UserProfileMapper._validate`).
- **reCAPTCHA registro**: requiere Google reCAPTCHA Admin Console, dominio verificado, y proteger la secret key (no debe ir al cliente — solo la site key). Si Carlos no completa el registro antes del lanzamiento web, AppCheck queda sin enforcement efectivo (la app sigue funcionando, solo sin protección anti-bot).
- **Apps móviles**: AppCheck en mobile usa Play Integrity / App Attest, no reCAPTCHA. SPEC-81 no toca ese path.

# 8. Out of scope

- Cloud Functions de validación de shape avanzada (out of scope MVP).
- Audit logs (separado).
- Anti-spam en `user_food_suggestions` (las escrituras son por usuario autenticado; abuso requiere SPEC futura con rate limiting).
- Migración del shape canónico vs legacy (cubierto en SPEC-82/87).

# 9. Resultado

(Se completa al cerrar el SPEC.)
