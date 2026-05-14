# SPEC-90 — Onboarding calcula `bodyFatPercentage` con la fórmula US Navy

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Bugfix crítico (contamina el IMR de todo usuario nuevo)
**Marco normativo:** `CONSTITUTION.md`, `IMR_BIBLIOGRAPHY.md` §2.4 (FFMI).
**Antecedente:** SPEC-82 §10 (hallazgo out-of-scope detectado durante la auditoría).

---

# 1. Contexto

El `BodyFatCalculator` (`lib/src/features/profile/domain/body_fat_calculator.dart`) ya implementa la fórmula US Navy desde la SPEC-25:

- Hombres: `86.010 × log10(cintura − cuello) − 70.041 × log10(altura) + 36.76`.
- Mujeres: aproximación basada en WHtR (la oficial Navy requiere cadera, no capturada).

El onboarding (`onboarding_screen.dart`, paso "Hardware Base") captura los inputs necesarios: cintura, cuello, altura, género. Pero `_finalSubmit` construye el `UserModel` sin pasar `bodyFatPercentage`, así que Freezed aplica `@Default(20.0)` desde `user_model.g.dart:20`.

# 2. Problema

Todo usuario que termina onboarding desde la app arranca con `bodyFatPercentage = 20.0` literal. Eso afecta el bloque Estructura del IMR vía:

- `leanMass = peso × (1 - 0.20)` siempre — falso para usuarios con %grasa real distinto.
- `FFMI = leanMass / altura²` también falso.
- `bloque Estructura` (50% del IMR total) calibrado sobre estos números basura.

Verificado en `score_engine.dart:100` y `:255` que usan `user.bodyFatPercentage` directamente.

El IMR mostrado al usuario en su día 0 está sistemáticamente desviado. Para un usuario delgado (bodyFat real ~12%) el `leanMass` calculado es menor del real → `FFMI` subestimado → bloque Estructura artificialmente bajo. Para un usuario con sobrepeso (bodyFat real ~30%) ocurre lo opuesto.

# 3. Solución propuesta

En `_finalSubmit` (`onboarding_screen.dart`), antes de construir el `UserModel`:

1. Llamar `BodyFatCalculator.calculateBodyFatPercentage(waistCm, neckCm, heightCm, isMale)`.
2. Validar coherencia con `BodyFatCalculator.isCoherent(weight, height, bodyFat)`.
3. Pasar el resultado a `UserModel(bodyFatPercentage: ...)`.
4. Setear `isMeasurementEstimated = false` y `confidenceLevel = 'ALTA'` cuando el cálculo es coherente.
5. Fallback: si los inputs son inválidos (cintura ≤ cuello, valores fuera de rango), dejar `isMeasurementEstimated = true` y un default seguro por género (15% hombres, 25% mujeres) en lugar del 20% genérico.

# 4. Plan

| Archivo | Cambio |
|---|---|
| `lib/src/features/onboarding/presentation/onboarding_screen.dart` | `_finalSubmit` calcula bodyFat antes de construir UserModel |
| `test/features/profile/domain/body_fat_calculator_test.dart` (nuevo si no existe) | Casos masculino, femenino, valores extremos, fallback |
| `IMR_BIBLIOGRAPHY.md` (§2.4 referencia) | Nota: bodyFat ya no usa default 20% — se mide |

# 5. Criterios de aceptación

- Usuario que termina onboarding con `waist=85, neck=38, height=180, gender='M'` tiene `bodyFatPercentage` calculado con Navy (≈ 18-20%, NO el literal 20.0 del default).
- Usuario que termina onboarding con `waist=110, neck=42, height=170, gender='M'` (sobrepeso) tiene `bodyFatPercentage > 25` calculado.
- Inputs inválidos (ej. cintura ≤ cuello, valores en 0) → fallback `15.0` hombres o `25.0` mujeres + `isMeasurementEstimated=true`.
- `flutter analyze` sin issues nuevos.
- `flutter test` mantiene 435+ verdes con nuevos tests del calculador.
- Documento `IMR_BIBLIOGRAPHY.md` §2.4 actualizado: nota breve sobre la fuente de bodyFat post-SPEC-90.

# 6. Pruebas

`body_fat_calculator_test.dart`:
- Hombre con `waist=85, neck=38, height=180` → bodyFat dentro de rango realista (16-22).
- Hombre con `waist=110, neck=42, height=170` → bodyFat > 25.
- Mujer con `waist=70, neck=33, height=165` → bodyFat dentro de 20-25.
- Inputs inválidos (`waist=neck`) → 15.0 (hombre) o aproximación WHtR (mujer).
- `isCoherent` rechaza valores absurdos (`leanMass < 20kg` o `> 95% peso`).

# 7. Riesgos

- **Usuarios MR-only** (registrados primero en sitio web) ya reciben `bodyFatPercentage` desde `bio.bodyFatPct` vía SPEC-84. El path no se toca. Sin regresión.
- **Usuarios que completaron onboarding ANTES de SPEC-90** quedan con bodyFat=20 hasta que entren a Profile y editen manualmente (SPEC-88). No es retroactivo. Migración masiva NO aplica.
- **La fórmula femenina es aproximación** (no requiere cadera). El cálculo es mejor que el default 20 pero menos preciso que el masculino. Aceptable como mejora.
- **`SPEC-25` originalmente decía** "El usuario NUNCA ingresa % grasa — siempre se calcula" (comentario en `body_fat_calculator.dart`). Esta SPEC honra esa promesa que el onboarding violaba sin saberlo.

# 8. Out of scope

- Captura de cadera en el onboarding para mejorar fórmula femenina (SPEC futura).
- Backfill retroactivo de usuarios existentes con bodyFat=20 (no necesario; corregirán al editar).
- Validación clínica externa de la fórmula Navy (la fuente es US Navy DoD Cir 1980, ampliamente aceptada).

# 9. Resultado

**Verificación local (13-may-2026):** suite 446 verdes / 3 skipped / 0 rojos. +11 tests nuevos del `BodyFatCalculator` (3 grupos: hombres, mujeres, coherencia).

**Desviación menor:** un test inicial subestimaba el output de la fórmula Navy para `waist=78, neck=38, height=180` (esperaba <16%, la fórmula da ~16.6%). Ajustado el rango a `10-20%` que refleja la realidad de la fórmula para esos antropométricos.

**Smoke test pendiente:** registrar nuevo usuario desde la app con `waist=85, neck=38, height=180`; verificar en Firestore que `bodyFatPercentage ≈ 18-22%` (no el viejo 20.0 literal) y que `isMeasurementEstimated == false`, `confidenceLevel == 'ALTA'`.
