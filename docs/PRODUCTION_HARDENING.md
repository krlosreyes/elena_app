# Production Hardening Checklist — SPEC-81

**Última actualización:** 13 de mayo de 2026

Checklist obligatoria antes de subir un build de release a App Store / Play Store / Firebase Hosting.

---

## 1. reCAPTCHA v3 para AppCheck web

**Estado:** ⚠️ usando placeholder.

**Pasos para producción:**

1. Acceder a [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin).
2. Login con la cuenta Google que administra `metamorfosisreal.com`.
3. Click **"+ Create"** (nuevo sitio).
4. Tipo: **reCAPTCHA v3**.
5. Etiqueta: `elena-app-prod`.
6. Dominios:
   - `localhost`
   - `metamorfosisreal.com`
   - `www.metamorfosisreal.com`
   - `elena-app-2026-v1.firebaseapp.com`
   - `elena-app-2026-v1.web.app`
7. Aceptar términos.
8. Click **Submit** → copiar la **Site Key**.
9. Editar `lib/src/core/config/recaptcha_config.dart`:
   ```dart
   const String kRecaptchaSiteKey = 'la-key-real-aquí';
   ```
10. Commit + push.
11. Firebase Console → App Check → Apps → Web → Configure → pegar la **Site Key**.
12. Firebase Console → App Check → APIs → Cloud Firestore → **Enforce**.

**Verificación:**
- Al arrancar la app web no debe aparecer el warning `"AppCheck web está usando reCAPTCHA PLACEHOLDER"`.
- En Firebase Console → App Check → Apps, el contador de "Verified" debe subir cuando se navega la app.

---

## 2. Firestore Rules

**Estado:** ✅ hardened con SPEC-81 (denial-by-default + size cap + id match).

**Smoke test pre-deploy:**

```bash
cd elena_app
firebase emulators:start --only firestore
```

En otra terminal, ejecutar manualmente con curl o con un cliente Firestore que:

- Cliente autenticado como uid `A` intenta leer `users/B/...` → debe ser rechazado.
- Cliente autenticado intenta escribir un doc de 200KB → debe ser rechazado.
- Cliente autenticado intenta escribir `users/A` con `id: 'OTRO_UID'` → debe ser rechazado.
- Cliente no autenticado intenta leer `metamorfosis_posts` → debe ser permitido.

**Deploy:**
```bash
firebase deploy --only firestore:rules
```

---

## 3. Firebase Crashlytics (SPEC-80)

**Estado:** ✅ implementado, requiere primer crash de verificación.

**Pasos:**
1. Firebase Console → Crashlytics → habilitar SDK del proyecto.
2. Hacer un build de release Android/iOS.
3. Forzar un crash artificial: agregar `throw Exception('test crashlytics')` en algún tap handler temporal.
4. Reinstalar y reproducir.
5. Esperar 5-10 min — debe aparecer en Crashlytics Console.
6. Quitar el crash artificial, hacer commit y nuevo build de release.

---

## 4. Build de release

### Android
```bash
flutter build appbundle --release
```

Verificar que:
- `google-services.json` correcto (proyecto `elena-app-2026-v1`).
- `applicationId` en `android/app/build.gradle.kts`: `com.metamorfosis.elena.elena_app`.
- Keystore de release configurado en `android/key.properties`.
- `AndroidManifest.xml` tiene el intent-filter de deep links (SPEC-78).

### iOS
```bash
flutter build ipa --release
```

Verificar:
- `GoogleService-Info.plist` correcto.
- `Runner.entitlements` tiene `applinks:metamorfosisreal.com`.
- Capability "Associated Domains" habilitada en Xcode → Signing & Capabilities.
- Capability "Push Notifications" habilitada si se usa firebase_messaging (futuro).
- AppID en developer.apple.com tiene "Associated Domains" activado.
- Provisioning profile regenerado tras agregar capabilities.

---

## 5. Deep Links (SPEC-78)

Confirmar con el equipo del sitio Metamorfosis Real que están publicados:
- `https://metamorfosisreal.com/.well-known/assetlinks.json` (Android).
- `https://metamorfosisreal.com/.well-known/apple-app-site-association` (iOS).

Ver `docs/DEEP_LINKS_SETUP.md` para el contenido exacto.

---

## 6. Privacy + Terms (SPEC-77)

**Estado:** ⚠️ texto PROVISIONAL, pendiente revisión legal.

Antes del submission:
1. Pasar `lib/src/features/auth/domain/legal_text.dart` a revisión legal.
2. Aplicar las correcciones del abogado.
3. Incrementar `kPrivacyPolicyVersion` y `kTermsOfServiceVersion`.
4. Commit + nuevo build.

---

## 7. Disclaimer médico (SPEC-76)

**Estado:** ⚠️ texto pendiente de revisión clínica externa.

Antes del submission:
1. Pasar `lib/src/features/auth/domain/health_disclaimer.dart` a revisión clínica.
2. Aplicar correcciones.
3. Incrementar `kHealthDisclaimerVersion`.
4. Commit + nuevo build.

---

## 8. Smoke test integrado en device

Antes de submission, ejecutar todos los escenarios listados en `SPEC-73 §smoke test pendiente` con cuentas MR reales en device físico:

1. Login con usuario MR existente (sin doc Firestore).
2. Login con usuario MR con shape canónico completo.
3. Registro nuevo desde la app.
4. Email already in use → mensaje específico.
5. Edición biométrica.
6. Protocol selector.
7. Eliminar cuenta.
8. Paleta canónica visible.

Documentar resultado de cada uno antes de aprobar el release.
