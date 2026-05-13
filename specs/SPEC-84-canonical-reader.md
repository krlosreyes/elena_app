# SPEC-84 — Lectura del shape canónico del sitio MR + onboarding adaptativo

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Marco normativo:** `CONSTITUTION.md`, `specs/systems/persistence.spec.md`
**Antecedente:** SPEC-73 (Auth Bridge), SPEC-74 (Onboarding diferenciado), SPEC-82 (canonical mirror app→sitio).

---

# 1. Contexto

SPEC-82 cubrió la dirección app→sitio: ElenaApp escribe el shape canónico (`displayName, genderCanonical, bio, habits, imr, meta`) en paralelo al legacy para que el sitio Astro Metamorfosis Real lea desde Firestore.

Falta la dirección inversa: cuando un usuario se registra primero en el sitio web y luego abre la app, su doc `users/{uid}` tiene **solo el shape canónico** (sin campos planos legacy). La app no reconoce ese perfil como "completo" y manda al usuario al onboarding completo, aunque ya entregó toda su biometría en el sitio.

# 2. Problema

Dos clasificadores no entienden el shape canónico:

1. **`UserProfileValidator.isCompleteFromRaw`** (`lib/src/shared/domain/validators/user_profile_validator.dart:32-39`) busca `raw['age'], raw['weight'], raw['height'], raw['profile']` planos. Para un doc canónico todos son null → retorna `false` → `AppAccount.profileStatus = partialProfile` → router redirige a `/onboarding`.

2. **`OnboardingPrefill.from`** (SPEC-74, `lib/src/features/onboarding/domain/onboarding_prefill.dart`) lee solo claves planas. Ignora `raw['bio'], raw['habits'], raw['birthDate']`. Resultado: `filledCount = 0`, defaults genéricos.

Resultado visible: el usuario MR ve el onboarding completo con campos vacíos.

# 3. Solución propuesta

Cuatro cambios coordinados:

**3.1 Adapter inverso (`CanonicalToLegacyAdapter`).** Helper puro nuevo que mapea el shape canónico al shape legacy. Centraliza las coerciones inversas de SPEC-82 (`'male'→'M'`, `16h→'16:8'`, hora float → DateTime). Greppable, testeable.

**3.2 `UserProfileValidator.isCompleteFromRaw` reconoce ambos shapes.** Retorna `true` si el doc satisface el contrato legacy **o** el canónico (`bio.heightCm + bio.weightKg + bio.bodyFatPct + birthDate/birthYear` presentes).

**3.3 `OnboardingPrefill.from` consulta también el shape canónico.** Cuando lee `name`, también busca en `displayName, bio.name, habits...`. Cuando lee `weight`, también `bio.weightKg`. Etc. Cero impacto en docs legacy puros.

**3.4 Onboarding adaptativo.** El `OnboardingScreen` calcula qué pasos saltar según el prefill al entrar:
- **Paso 0 (Disclaimer):** siempre obligatorio (SPEC-70.8). EXCEPCIÓN: si `rawProfile.healthDisclaimerAccepted == true` (el sitio capturó la aceptación), se salta y se hereda.
- **Paso 1 (Biometría):** se salta si prefill cubre `weight, height, bodyFat, waist` (los 4 críticos). Si `bodyFat` falta pero los otros 3 están, se muestra solo ese campo.
- **Paso 2 (Ritmos circadianos):** se muestra siempre — el sitio actualmente no captura los 4 horarios. Si tiene `lastMealHour`, se prellena ese campo del paso.
- **Paso 3 (Hábitos):** se salta si prefill cubre `fastingProtocol`; pero `pathologies` siempre se pregunta (el sitio no la captura).

El indicador de progreso se ajusta dinámicamente (`paso N de M` donde M ≤ 4).

# 4. Plan

Seis archivos a modificar/crear, en orden:

1. **Nuevo:** `lib/src/features/auth/domain/canonical_to_legacy_adapter.dart` — adapter puro.
2. **Modificar:** `lib/src/shared/domain/validators/user_profile_validator.dart` — `isCompleteFromRaw` con dos contratos.
3. **Modificar:** `lib/src/features/onboarding/domain/onboarding_prefill.dart` — leer shape canónico también.
4. **Modificar:** `lib/src/features/onboarding/presentation/onboarding_screen.dart` — pasos adaptativos.
5. **Nuevo:** `test/features/auth/canonical_to_legacy_adapter_test.dart`.
6. **Modificar:** `test/features/onboarding/onboarding_prefill_test.dart` — cubrir shape canónico.

# 5. Criterios de aceptación

- `flutter analyze` sin issues nuevos sobre baseline (~108).
- `flutter test` con tests nuevos verdes (cubre adapter + prefill canónico + validator dual-shape).
- Usuario con doc canónico **completo** (bio + birthDate + 4 horarios + disclaimer) clasifica como `completeProfile` → router lo lleva directo a `/dashboard`.
- Usuario con doc canónico **parcial** (bio + birthDate, sin horarios) clasifica como `partialProfile` → router lo lleva a `/onboarding`, pero solo se muestran los pasos cuyos campos faltan.
- El paso de Disclaimer Médico se salta solo si el sitio reportó `healthDisclaimerAccepted: true` o equivalente.
- El indicador de progreso del onboarding muestra `paso N de M` (M dinámico).
- El prefill chip de SPEC-74 sigue mostrándose con el contador correcto.
- Ningún flujo existente cambia para usuarios legacy puros (shape plano).

# 6. Pruebas

Tests nuevos:

- **`canonical_to_legacy_adapter_test.dart`** — coerciones inversas: `'male'→'M'`, `16h→'16:8'`, `birthYear:1985 → age = currentYear - 1985`, hora float `21.5 → DateTime(today, 21, 30)`. 8-10 casos.
- **`onboarding_prefill_test.dart` (extendido)** — para cada campo, un caso "leyendo desde shape canónico". Ej: `OnboardingPrefill.from({'bio': {'weightKg': 80}}).weight == 80`. 6-8 casos nuevos.
- **`user_profile_validator_test.dart` (extendido)** — `isCompleteFromRaw({'bio': {...}, 'birthDate': '...'}) == true`. 3 casos: shape canónico completo, shape canónico parcial, shape mezclado.

Smoke test manual:
- Registrarse en metamorfosisreal.com con biometría + horarios + disclaimer.
- Abrir la app y loguearse con esa cuenta.
- Esperado: ir directo a dashboard sin ver el onboarding.
- Caso parcial: misma cuenta pero sin horarios → onboarding muestra solo el paso 2 (ritmos circadianos), con datos pre-llenados donde aplique.

# 7. Riesgos

- **Sitio MR no captura los 4 horarios** → todo usuario MR pasa por el paso 2 del onboarding. Es la realidad actual; aceptable como UX.
- **Si el sitio captura `disclaimerAccepted` pero la app SPEC-70.8 evoluciona** (nueva versión del disclaimer, ej. SPEC-70.8.2 con condiciones adicionales) → el usuario MR puede "saltar" un disclaimer que ya no es vigente. Mitigación: comparar la versión del disclaimer aceptado en el sitio contra la versión actual de la app antes de saltarlo. Si no coincide, mostrar nuevamente. Out-of-scope para SPEC-84 (al cierre el sitio no versiona disclaimers) — agregar TODO.
- **Mapeo `lastMealHour: 21.5 → DateTime`** asume "hoy a las 21:30 local". Si el usuario viaja en zona horaria, el DateTime se interpreta en local; aceptable porque `lastMealGoal` es una meta diaria, no un timestamp absoluto.
- **`birthYear` ambiguo** sobre el mes/día. La app usa `_birthDate` (DateTime completo). Cuando solo tenemos `birthYear`, asumimos 1 de enero. El cálculo de `age` queda con error ±1 año por unos meses. Aceptable.
- **Edge case:** un usuario que registra en el sitio (canónico) y luego completa onboarding desde la app (que escribe ambos shapes con SPEC-82) tendrá AMBOS shapes. Esto es correcto y deseable — la coexistencia ya está soportada.

# 8. Out of scope

- Versionado de `healthDisclaimerAccepted` (comparar versión del sitio vs app antes de saltarlo).
- Migración masiva de usuarios canónico-puros a shape mezclado.
- Captura de los 4 horarios circadianos en el sitio web (no es alcance de ElenaApp).
- Re-renderizado del onboarding cuando el rawProfile cambia mientras el usuario está en pantalla (es write-once en initState).
- Inferencia de `bodyFat` si el sitio no lo trajo (Carlos decidió que en ese caso se pregunta en el flujo corto).

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 416 verdes / 3 skipped / 0 rojos. Suite total subió de 375 (post-SPEC-82) a 416 (+41 tests entre SPEC-84/85/86).

**Smoke test pendiente en device:** registrar usuario en metamorfosisreal.com con biometría + horarios + disclaimer → abrir la app → confirmar que NO se ve el onboarding completo (solo los pasos cuyos campos faltan).

**Desviaciones del plan:**

- El sitio actualmente no captura los 4 horarios circadianos. Mientras el sitio no los entregue, el usuario MR siempre verá el paso 2 (Ritmos) del onboarding. Aceptable como UX inicial — se cierra cuando el sitio amplíe captura.
- El `bodyFat` "real vs default" se detecta directamente desde `rawProfile['bio']['bodyFatPct']` (no via OnboardingPrefill). Más robusto.

**Hallazgos out-of-scope detectados durante implementación:**

- La política de "fuente de verdad" entre app y sitio se materializó como conflicto real (SPEC-85). La app pisaba el valor del sitio con baseline parcial. Se abrieron SPEC-85 y SPEC-86 como bugfixes inmediatos.
