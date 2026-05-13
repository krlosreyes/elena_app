# SPEC-85 — Proteger `imr.current` del sitio: no pisar con baseline

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Bugfix de SPEC-82
**Marco normativo:** `CONSTITUTION.md`
**Antecedente:** SPEC-82 (canonical mirror).

---

# 1. Contexto

SPEC-82 introdujo dos puntos de escritura a `users/{uid}.imr.current`:

1. **`OnboardingController.completeOnboarding`** persiste un baseline (solo bloque Estructura, score ≤ 50) al finalizar onboarding.
2. **`imrPersistenceProvider`** persiste el IMR recalculado del dashboard, con debounce de 15s.

Ambos escriben sin verificar si el sitio web Metamorfosis Real ya había escrito un valor previo. El riesgo L documentado en SPEC-82 §7 se materializó en producción (smoke test 13-may-2026): un usuario que se registró en el sitio web con IMR 52, al cerrar onboarding en la app, vio cómo Firestore quedó con 37 (baseline app pisó el 52 del sitio).

# 2. Problema

La política operativa de SPEC-82 dice: *"la app es la fuente de verdad para usuarios activos; el sitio sólo lee"*. Pero la app SOLO es mejor fuente cuando tiene cálculo completo (con `lastMealTime` y data behavioral). Cuando solo puede ofrecer baseline (estructura), el cálculo del sitio (que presumiblemente usa todos los inputs disponibles) es preferible.

Pisar `imr.current` con un baseline parcial degrada la información sin justificación.

# 3. Solución propuesta

Dos guardas:

**3.1 `OnboardingController.completeOnboarding`** lee `account.rawProfile?['imr']?['current']` antes de persistir el baseline. Si ya existe un valor (escrito por el sitio), salta la escritura del baseline. La app seguirá recalculando reactivamente; cuando tenga data behavioral, el `imrPersistenceProvider` actualizará con un valor mejor.

**3.2 `imrPersistenceProvider`** amplía el filtro actual. Hoy filtra `(score==0 && zone=='N/A')` (empty). Ahora también filtra "baseline disfrazado": un IMR donde `metabolicScore == 0 && behaviorScore == 0` (no es vacío pero tampoco tiene data behavioral). Solo persiste cálculos completos.

# 4. Plan

Dos archivos a modificar:

1. `lib/src/features/onboarding/application/onboarding_controller.dart` — guarda condicional.
2. `lib/src/core/engine/imr_persistence_provider.dart` — filtro ampliado.

# 5. Criterios de aceptación

- Un usuario que viene del sitio con `imr.current.imrScore = 52` cierra onboarding → `users/{uid}.imr.current.imrScore` sigue siendo 52 en Firestore (no se pisa con baseline).
- Un usuario que se registra desde la app (sin `imr.current` previo) cierra onboarding → la app persiste baseline (≤ 50) como hoy.
- Cuando el usuario carga su primera comida y `imrProvider` recomputa con `lastMealTime` no-null → `imrPersistenceProvider` flushea ese valor a Firestore. El valor "completo" puede ser mejor o peor que el del sitio, pero ahora SÍ tiene más datos.
- Ningún test existente regresiona.

# 6. Pruebas

Test nuevo en `test/features/onboarding/onboarding_baseline_imr_test.dart`:

- "skip baseline persist si imr.current existe en rawProfile" — el `_CapturingRepo` NO recibe `updateCurrentImr` cuando el AppAccount entrega `rawProfile: {imr: {current: {imrScore: 52}}}`.

Test nuevo en `test/core/engine/imr_persistence_filter_test.dart`:

- "no persiste si metabolicScore==0 && behaviorScore==0" — incluso si totalScore > 0 (baseline).
- "persiste cuando metabolicScore > 0 o behaviorScore > 0" — cálculo completo.

# 7. Riesgos

- **Si el sitio escribe un valor incorrecto (ej. fórmula bug)**, la app lo respeta hasta que el usuario tenga data behavioral. Asumimos que la app finalmente "se impone" cuando recomputa con datos reales. La política es: app gana en presencia de inputs completos.
- **Edge case:** un usuario que cierra onboarding y NO carga ningún log nunca → `imr.current` queda con el valor del sitio para siempre. Aceptable.
- **Si el usuario se registró en la app (no sitio) y `imr.current` no existe**, el baseline persiste normalmente — sin regresión.

# 8. Out of scope

- Versionado de qué fuente escribió `imr.current` (`source: 'app' | 'site'`). Útil para auditoría futura, no necesario ahora.
- Reconciliación de valores divergentes con merging inteligente. La regla actual (app gana cuando tiene completo, sitio gana cuando app solo tiene baseline) es suficiente.
- SPEC-86 (display): que el Dashboard muestre el valor persistido del sitio cuando el cálculo local es baseline. Va en SPEC paralela.

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 416 verdes / 3 skipped / 0 rojos. Test específico de SPEC-85 (`onboarding_baseline_imr_test.dart > "NO persiste baseline cuando imr.current ya existe"`) en verde.

**Smoke test pendiente:** abrir la app con un usuario MR que tenga `imr.current.imrScore = 52` en Firestore → cerrar onboarding → confirmar que el doc sigue mostrando 52 (no se sobrescribe con baseline 37).

**Sin desviaciones del plan original.**
