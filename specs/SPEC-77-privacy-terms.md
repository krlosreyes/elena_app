# SPEC-77 — Política de privacidad + Términos de uso in-app

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Hardening pre-launch (bloqueador App Store / Play / GDPR)
**Marco normativo:** Apple App Store Review Guideline 5.1.1 (Privacy), Google Play Privacy Policy Requirement, GDPR Art. 13.

---

# 1. Contexto

Tanto Apple como Google exigen que toda app que recolecte datos de usuarios (autenticación, biometría, hábitos) muestre una política de privacidad y unos términos de uso accesibles. ElenaApp recolecta más que la mayoría: identidad (email), datos biométricos (peso, cintura, %grasa), comportamiento (comidas, sueño, ejercicio, hidratación, ayunos), IMR derivado. Sin pantallas legales accesibles, la app es rechazada en review.

# 2. Problema

Hoy la app no tiene pantallas de privacy ni terms. Tampoco hay links durante el registro ("Al continuar aceptas..."). Bloquea submission a stores y expone a la empresa legalmente.

# 3. Solución propuesta

**3.1 Constantes canonicalizadas** en `lib/src/features/auth/domain/legal_text.dart`:
- `kPrivacyPolicyVersion: int` y `kTermsOfServiceVersion: int` (inicialmente 1, para futuras actualizaciones).
- `kPrivacyPolicySections: List<LegalSection>` y `kTermsOfServiceSections: List<LegalSection>`.
- `LegalSection {title, body}` modelo simple.

El contenido se redacta provisionalmente cubriendo: qué datos se recolectan, para qué se usan, con quién se comparten (Firebase, Metamorfosis Real), retención, derechos del usuario (acceso, eliminación, portabilidad), contacto. Marcado explícitamente como **PROVISIONAL — pendiente revisión legal**.

**3.2 Pantallas read-only:**
- `PrivacyPolicyScreen` en `lib/src/features/auth/presentation/privacy_policy_screen.dart`.
- `TermsOfServiceScreen` en `lib/src/features/auth/presentation/terms_of_service_screen.dart`.

Ambas siguen el patrón de `DisclaimerScreen` (SPEC-76): AppBar + ListView de secciones.

**3.3 Rutas:**
- `/legal/privacy` → PrivacyPolicyScreen
- `/legal/terms` → TermsOfServiceScreen

**3.4 Entry points:**
- **LoginScreen**: texto pequeño debajo del botón principal: "Al iniciar sesión aceptas nuestros [Términos] y [Política de privacidad]." (los corchetes son tappable).
- **RegisterScreen**: texto similar antes del botón REGISTRARME.
- **ProfileScreen**: dos tiles bajo CUENTA, junto al disclaimer médico.

**3.5 Versionado para invalidación futura.** Las constantes versionadas habilitan el mismo patrón de SPEC-76: si Apple/Google exigen un cambio mayor, subimos `kPrivacyPolicyVersion` y agregamos un mecanismo de "tu confirmación está pendiente" (out of scope ahora — basta con tener las pantallas).

# 4. Plan

| Archivo | Cambio |
|---|---|
| `lib/src/features/auth/domain/legal_text.dart` (nuevo) | Constantes + modelo `LegalSection` |
| `lib/src/features/auth/presentation/privacy_policy_screen.dart` (nuevo) | Pantalla read-only |
| `lib/src/features/auth/presentation/terms_of_service_screen.dart` (nuevo) | Pantalla read-only |
| `lib/src/features/auth/presentation/widgets/legal_footer.dart` (nuevo) | Widget reutilizable para login/register |
| `lib/src/router/app_router.dart` | Rutas `/legal/privacy` y `/legal/terms` |
| `lib/src/features/auth/presentation/login_screen.dart` | Insertar `LegalFooter` debajo del botón |
| `lib/src/features/auth/presentation/register_screen.dart` | Insertar `LegalFooter` antes del botón |
| `lib/src/features/auth/presentation/profile_screen.dart` | Tiles "Política de privacidad" y "Términos de uso" bajo CUENTA |
| `test/features/auth/legal_text_test.dart` (nuevo) | Tests del modelo + secciones mínimas |

# 5. Criterios de aceptación

- Tap en "Política de privacidad" desde Login/Register/Profile abre `PrivacyPolicyScreen` con todas las secciones renderizadas.
- Tap en "Términos" igual.
- `LegalFooter` en Login muestra el texto "Al iniciar sesión aceptas...".
- `LegalFooter` en Register muestra "Al registrarte aceptas...".
- Las pantallas tienen título de AppBar y son scroleables.
- El texto está marcado en código como `PROVISIONAL — pendiente revisión legal` (comentario al inicio del archivo + nota visible al final de cada pantalla).
- `flutter analyze` sin issues nuevos.
- `flutter test` mantiene 454+ verdes con nuevos tests.

# 6. Pruebas

`legal_text_test.dart`:
- `kPrivacyPolicySections.length >= 5` (cobertura mínima: datos recolectados, uso, compartir, derechos, contacto).
- `kTermsOfServiceSections.length >= 4`.
- Cada `LegalSection` tiene `title` y `body` no vacíos.
- Versiones son enteros positivos.

# 7. Riesgos

- **El texto provisional puede ser rechazado en review** por estar incompleto. Mitigación: marcar claramente como "PROVISIONAL" + obtener revisión legal antes de submission. No es bloqueador para esta SPEC — es bloqueador externo para Sprint 6.
- **GDPR Right to Erasure**: SPEC-83 ya implementó delete account. La política debe mencionarlo. Cubierto en el texto.
- **i18n**: la app es solo español neutro. Apple/Google permiten una sola lengua si la audiencia es regional. Si se internacionaliza, se actualiza después.

# 8. Out of scope

- Revisión legal del texto.
- Mecanismo de re-aceptación cuando la versión cambia (basta con tener las pantallas accesibles; el opt-in se hace en la cuenta de Firebase).
- Cookies banner (no aplica, es app móvil).
- Política específica de menores de 18 años (la app no acepta menores según el disclaimer médico ya cubierto en SPEC-76).

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 462 verdes / 3 skipped / 0 rojos. Suite acepta los nuevos tests del modelo legal sin regresión.

**Bloqueador externo confirmado:** revisión legal del texto pendiente antes de submission a stores. La estructura técnica está lista. Cuando legal apruebe el copy final, se reemplaza en `legal_text.dart` y se incrementa la versión correspondiente.

**Smoke test pendiente:**
1. Login screen → tap "Política de privacidad" en el footer → ver pantalla con banner PROVISIONAL.
2. Register → tap "Términos de uso" → ver pantalla.
3. Profile → tile "Política de privacidad" → ver pantalla.
4. Sin sesión activa, abrir `/legal/privacy` y `/legal/terms` directamente → el router permite acceso (públicas).
