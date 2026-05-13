# SPEC-82 — Canonical mirror del doc `users/{uid}` para sitio web

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Autor:** Líder de Proyecto
**Marco normativo:** `CONSTITUTION.md`, `specs/systems/persistence.spec.md`
**Antecedente:** `AUDITORIA_SCHEMA_USERS_v1.0.md` (2026-05-13).

---

# 1. Contexto

ElenaApp y el sitio web Metamorfosis Real (repo separado, Astro 6) comparten el proyecto Firebase `elena-app-2026-v1`. La auditoría del 13-may-2026 detectó que el documento `users/{uid}` que la app escribe tiene un shape plano legacy (`{id, name, age, gender:'M'|'F', height, weight, waistCircumference, ..., profile:{wakeUpTime,...}}`) mientras que el sitio web espera un shape agrupado canónico (`{displayName, gender:'male'|'female', bio:{...}, habits:{...}, imr:{current,history}, meta:{schemaVersion}}`).

Ningún usuario creado desde la app es consumible desde el sitio: el sitio busca `imr.current.imrScore` y ese path no existe en el doc. El `ScoreEngine.calculateIMR` se ejecuta reactivamente en `imrProvider` pero su resultado vive sólo en memoria — únicamente `imrScore` (sin el resto del bloque) se persiste como subcampo de las subcolecciones `streak_history/{date}` y `biometric_history/{date}`.

# 2. Problema

El doc `users/{uid}` no contiene los campos canónicos. El sitio muestra "Sin diagnóstico" para todo usuario que se registra desde la app. Además, no se calculan ni `imc`, `tmb`, `metabolicAge`, `ica`. `ffmi` y `whtr` se calculan dentro de `ScoreEngine` pero se descartan tras usarse para el bloque Estructura.

# 3. Solución propuesta

Denormalización deliberada. Agregar los campos canónicos al mismo doc `users/{uid}`, en paralelo al shape legacy. La app sigue leyendo lo que lee (Freezed deserializa con los campos legacy, ignora keys desconocidas); el sitio lee el bloque canónico (`displayName`, `bio.*`, `habits.*`, `imr.current`, `meta.*`). Trade-off: ~2x espacio en los 6-7 campos duplicados. Aceptable a la escala actual.

Decisión clave de seguridad: el campo canónico `'male'|'female'` se escribe como `genderCanonical`, NO sobre `gender`. Así `UserModel.fromJson` (que ya lee `json['gender'] as String`) no se rompe ante un valor canónico que él no espera.

# 4. Plan

Siete pasos secuenciales, un commit por paso:

1. **Extender `IMRv2Result`** (`lib/src/core/engine/score_engine.dart`) con `imc, tmb, metabolicAge, ica, ffmi, whtr`. Constructor `const`. `IMRv2Result.empty()` también devuelve los nuevos campos en 0.
2. **`ScoreEngine.calculateIMR`** calcula esos derivados y los expone.
3. **`ScoreEngine.calculateBaseline(UserModel)`** estático: IMR con solo bloque Estructura, para el usuario que termina onboarding y aún no tiene data behavioral.
4. **Mapper escribe shape canónico** en paralelo al legacy (`user_profile_mapper.dart`). Función pura `userToCanonicalMirror(UserModel) -> Map`. Top-level: `displayName, genderCanonical, bio, habits, meta`. Sin colisiones con keys legacy.
5. **Persistencia `imr.current` debounced** en doc raíz cuando `imrProvider` recomputa. Nuevo provider `imrPersistenceProvider` con `Timer` de 15s. Nuevo método `UserProfileRepository.updateCurrentImr(uid, map)` que usa dotted-path Firestore.
6. **Baseline IMR al finalizar onboarding**. `OnboardingController.completeOnboarding` calcula `calculateBaseline(user)` después del `saveProfile` y persiste `imr.current` para que el sitio tenga score desde el día 0.
7. **Tests + bibliography**. Tres archivos de test nuevos. `IMR_BIBLIOGRAPHY.md` documenta TMB Mifflin-St Jeor, ICA/WHtR, FFMI canónico, `metabolicAge` (fórmula provisional).

# 5. Criterios de aceptación

- `flutter analyze` no introduce issues nuevos sobre baseline (108 issues post-SPEC-74).
- `flutter test` pasa 100%.
- Un usuario nuevo que termina onboarding tiene en `users/{uid}` AMBOS shapes: campos planos legacy + `displayName`, `genderCanonical`, `bio.*`, `habits.*`, `imr.current`, `meta.schemaVersion=1`.
- `imr.current` del baseline tiene `imrScore <= 50` (sólo bloque Estructura) y `label` del set `{OPTIMIZADO, EFICIENTE, FUNCIONAL, INESTABLE, DETERIORADO}`.
- Cuando `imrProvider` recomputa con data behavioral, `imr.current` se actualiza en Firestore dentro de 15s (debounce).
- `IMR_BIBLIOGRAPHY.md` documenta las nuevas fórmulas.
- Ninguna pantalla existente cambia de comportamiento: Dashboard, BodyComposition, Profile, Analysis, Progress siguen leyendo `UserModel` con la misma firma.
- `meta.schemaVersion: 1` queda escrito en cada save para versionado futuro.

# 6. Pruebas

Tres archivos nuevos en `test/`:

1. **`test/core/engine/score_engine_canonical_test.dart`** — `IMRv2Result.empty()` con campos nuevos en 0; `imc` con cálculo correcto; `tmb` Mifflin-St Jeor hombre y mujer; `ica = waist/height`; `metabolicAge` dentro de rango `[age-10, age+25]`; `calculateBaseline` retorna `metabolicScore = 0, behaviorScore = 0` y `totalScore <= 50`.
2. **`test/shared/data/mappers/user_profile_canonical_mirror_test.dart`** — `toMap` produce `displayName, genderCanonical, bio.*, habits.*, meta.schemaVersion=1` además del shape legacy intacto; `fastingProtocol` parsea a horas; `dinnerHour/lastMealHour` son hora float; `source` es `'self_report'`.
3. **`test/features/onboarding/onboarding_baseline_imr_test.dart`** — con `FakeFirebaseFirestore`: tras `completeOnboarding`, el doc tiene `imr.current` con `imrScore <= 50` y un label válido.

Los valores `expected` se obtienen ejecutando el código primero (no estimando mentalmente).

# 7. Riesgos

- **Fuente de verdad para `imr.current`**: el sitio web podría escribir el mismo campo. La app pisa lo que escribió el sitio en el próximo recompute. La regla operativa: la app es la fuente de verdad para users activos; el sitio sólo lee. Documentar y honrar.
- **Baseline IMR es necesariamente bajo**: sin `lastMealTime` real solo aplica el bloque Estructura (50% del total). Un usuario con estructura óptima ve baseline 50/100. No es bug — es la realidad numérica del modelo cuando faltan los otros bloques. Mostrar al usuario que "tu IMR completo se calcula con tu primera comida loggeada".
- **`updateCurrentImr` en doc inexistente**: si por alguna razón el doc `users/{uid}` no existe cuando intentamos actualizar `imr.current`, Firestore lanza `not-found`. En el flujo de onboarding el doc ya existe (lo creó `signUp` + `saveProfile`). El provider debounced verifica que `authStateProvider.value` no sea null antes de escribir.
- **Migración de usuarios existentes**: out-of-scope. Los users históricos quedan con shape legacy hasta que la app recompute su IMR (al loguear primera comida tras update). No bloquea esta SPEC.
- **Colisión con campo `gender`**: mitigada usando `genderCanonical`. Verificado.

# 8. Out of scope

- Migración masiva de users históricos al shape canónico (SPEC futura, si el sitio lo necesita antes de que se logueen).
- Backfill de `imr.history` desde `streak_history`/`biometric_history`.
- Recalibración del IMR baseline a algo que no sea "solo Estructura" (requiere decisión de producto).
- Cualquier refactor del `UserModel` para aplanar/quitar campos legacy.
- Si la auditoría detectó `bodyFatPercentage` con default 20.0 que el onboarding no sobrescribe (campo huérfano contaminando todos los IMR), ese es un bug pre-existente — se abre como SPEC-83 separada.

# 9. Commit

Granular por paso (siete commits), o uno solo al final. Mensaje del commit final cita el cierre del SPEC y los hallazgos relevantes.

# 10. Resultado

**Fecha de cierre:** 13-may-2026.

**Verificación local (en máquina de Carlos):**

- `flutter test`: **375 verdes / 3 skipped / 0 rojos**. Suite completa.
- Tests nuevos de esta SPEC: 12 (score_engine_canonical) + 13 (mapper_canonical_mirror) + 3 (onboarding_baseline_imr) = 28 tests verdes.
- `flutter analyze`: sin issues nuevos sobre baseline post-SPEC-74 (~108).

**Desviaciones del plan original:**

1. **`gender` legacy intacto, campo nuevo `genderCanonical`.** El prompt original sugería pisar `gender: 'M'|'F'` con el canónico `'male'|'female'`. Verificado en `user_model.g.dart:14` que `UserModel.fromJson` espera `gender as String` y no toleraría el cambio sin coerción. Decisión: dejar `gender` legacy y agregar `genderCanonical` como campo nuevo. Cero riesgo de deserialización rota.
2. **Constructor de `IMRv2Result` ahora es `const`.** No estaba en el plan explícitamente pero era necesario para que `IMRv2Result.empty()` siguiera siendo factory const y para soportar usos const en tests.
3. **`_getZone` y `_getDescription` pasaron a `static`.** Necesario para que `calculateBaseline` (también estático) los pudiera invocar. Los call sites internos a `ScoreEngine` siguen funcionando sin cambio.
4. **Test de "metabolicAge óptimo" tuvo que aflojar tolerancia a ±5 años.** El cálculo real con inputs realistas da `delta=3` en lugar de `~0` porque `s2 ≈ 0.64` (FFMI 20.8 vs baseline 17.0) en lugar de `~1.0`. Se hubiera necesitado un fisicoculturista (`bodyFat=8, weight=95`) para `s2=1.0`. La tolerancia ±5 sigue verificando el invariante "metabolicAge cerca de age cuando estructura sana" sin sobre-especificar inputs.
5. **No se agregó `imr.history`.** El plan canónico lo menciona pero el sitio web puede tolerar `imr.history` ausente (siempre que `imr.current` esté). Backfill de history queda fuera de scope (SPEC futura, si Astro lo necesita).

**Hallazgos out-of-scope detectados durante la implementación (candidatos a SPEC futura):**

- **`bodyFatPercentage` con default 20.0 que el onboarding nunca sobrescribe** (verificado en `user_model.g.dart:20`). Todo usuario sin biometría avanzada arranca con 20% literal, lo cual contamina el bloque Estructura. Es un bug pre-existente del onboarding, no de SPEC-82. Recomendación: SPEC-83 o ticket separado.
- **`imr.history` no se backfilea** desde `streak_history/{date}.imrScore` y `biometric_history/{date}.imrScore`. El sitio puede vivir sin historial al inicio pero eventualmente lo querrá. SPEC futura cuando el sitio lo demande.

**Próximo paso operativo:** Carlos ejecuta el bloque de commit y push. La SPEC pasa a `CLOSED` cuando el push completa.
