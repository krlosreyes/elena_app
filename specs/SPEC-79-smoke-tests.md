# SPEC-79 — Smoke tests E2E mínimos

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Hardening pre-launch
**Marco normativo:** `CONSTITUTION.md`, decisión de alcance (Carlos: "Mínimo").

---

# 1. Contexto

El plan original (`PLAN_LANZAMIENTO_v1.0.md §4.4`) marcaba SPEC-79 como L (4-5 días) cubriendo tests de regresión visual + smoke E2E completos. Tras revisar el roadmap y descubrir que el Sprint 1-2 ya está cerrado por el equipo, Carlos eligió el alcance mínimo: dos smoke tests críticos que detecten regresiones graves en login y onboarding antes de cada release. Sin golden tests (frágiles entre plataformas) ni integration_test full (requiere device pool en CI). Suficiente para una primera versión.

# 2. Problema

Sin tests del flujo crítico, una refactorización futura puede romper el login o el onboarding sin que la suite lo detecte. Los tests unitarios actuales cubren componentes aislados (validators, mappers, repositories) pero no el flujo de pantalla.

# 3. Solución propuesta

Dos widget tests con `ProviderContainer` y overrides:

**3.1 `login_screen_smoke_test.dart`** — verifica que:
- `LoginScreen` renderiza sin throws con providers mockeados.
- Los inputs de email y password aceptan texto.
- Tap en "Iniciar METAMORFOSIS" dispara `AuthController.signIn` con los valores ingresados.
- Si el repo retorna éxito, no aparece error en SnackBar.

**3.2 `onboarding_finalsubmit_smoke_test.dart`** — verifica que:
- `OnboardingController.completeOnboarding(user)` con un `UserModel` válido llama a `saveProfile` en el repository.
- El AppAccount se invalida tras el save (re-clasificación de SPEC-73 BUGFIX).
- Si `imr.current` no existe en rawProfile, se persiste el baseline (SPEC-82).
- Si `imr.current` SÍ existe, NO se pisa (SPEC-85).

Los dos tests son de widget/state — más mantenibles que integration_test full. Ambos usan los mismos mocks que ya están en dev_dependencies (`firebase_auth_mocks`, `fake_cloud_firestore`).

# 4. Plan

| Archivo | Cambio |
|---|---|
| `test/smoke/login_screen_smoke_test.dart` (nuevo) | Test de pantalla Login con override de `authRepositoryProvider` |
| `test/smoke/onboarding_finalsubmit_smoke_test.dart` (nuevo) | Test del controller `OnboardingController.completeOnboarding` end-to-end |

# 5. Criterios de aceptación

- Ambos tests verdes localmente y en CI.
- Si alguien reemplaza `signInWithEmail` por una firma incompatible, el test de login falla.
- Si alguien rompe el orden saveProfile → invalidate → updateCurrentImr del OnboardingController, el test del onboarding falla.
- `flutter analyze` sin issues nuevos.
- `flutter test` con +N tests verdes (N = número de cases de cada smoke).

# 6. Pruebas

Los tests son las pruebas. No se requiere "test of tests" — la propia validación es ejecutar `flutter test`.

# 7. Riesgos

- **Goldens fuera de scope.** Si una refactorización visual cambia el layout de Login sin tocar lógica, este test no lo detecta. Aceptable como trade-off de alcance mínimo.
- **No es integration_test real.** Si el router cambia el flujo (ej. redirect post-login), el test del controller sigue verde pero el usuario real puede quedar atascado. Cubierto por smoke test manual en device (SPEC-73 §smoke test pendiente).
- **Riverpod scope.** Los tests usan `ProviderContainer` directamente, no `ProviderScope` con `MaterialApp`. Algunas interacciones (ej. listeners) pueden comportarse diferente. Los tests están diseñados para validar lógica de application layer; no widget testing visual.

# 8. Out of scope

- Golden tests (decisión de alcance — Carlos eligió mínimo).
- Integration tests con Firebase Emulator (CI cost).
- Tests del flujo MR completo (cubierto manualmente en smoke de SPEC-84).
- Tests de regresión visual.

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 468 verdes / 3 skipped / 0 rojos (+6 nuevos: 3 login + 3 onboarding).

**Hotfixes incluidos en el mismo commit (regresiones pre-existentes detectadas en smoke manual):**
1. `LocaleDataException` en `disclaimer_screen.dart` al usar `DateFormat('d MMM yyyy', 'es')` sin inicializar la data del locale → fix en `main.dart` con `await initializeDateFormatting('es', null)`.
2. Layout legal en Profile: las 3 tarjetas separadas (Condiciones médicas, Privacidad, Términos) ocupaban demasiado espacio visual → agrupadas en una sola tarjeta con dividers internos.
