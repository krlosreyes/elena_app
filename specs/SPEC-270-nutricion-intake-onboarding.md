# SPEC-270 — Onboarding del Pilar de Alimentación: evaluación dietética (intake)

**Estado:** IMPLEMENTED — capa dominio + datos + servicio + tests. PENDIENTE de verificación (`flutter analyze` + `flutter test`) por Carlos, y de la UI de captura (fase 2 de este SPEC).
**Versión:** 1.0
**Fecha:** 2026-08-07
**Autor:** Claude (líder de proyecto / full-stack) + Carlos (aprobación de alcance)
**Pilar:** Nutrición
**Rama:** `feat/pilar-alimentacion-minuta` (todo el trabajo de la Minuta vive aquí)
**Documento marco:** `Elena_Reestructuracion_Pilar_Alimentacion.docx` (propuesta v2, §4/§5/§11).

## 1. Contexto

Reestructuración del pilar de Alimentación de "auditor" (registra y califica) a "prescriptor" (entrega una Minuta Diaria Personalizada). SPEC-270 es el cimiento: capturar el **retrato dietético** del usuario —qué come hoy, en qué cantidades, qué pica, qué bebe, qué no come y en qué contexto— para que el motor de la minuta (SPEC-272) lo transforme por reemplazo suave.

Decisiones ya cerradas por Carlos (propuesta v2 §9): la minuta reemplaza al MealRatio como métrica visible; generación 100% determinística; los snacks se retiran gradualmente; re-encuesta cada 4 semanas (activa) → 12 (mantenimiento). Estas afectan SPECs posteriores; SPEC-270 solo produce el insumo.

## 2. Alcance de este SPEC

**Incluido (esta entrega):**

1. **Dominio** `NutritionIntake` (agregado raíz) + tipos anidados (`IntakeMeal`, `IntakeItem`, `IntakeSnack`, `DrinksProfile`, `IntakeRestrictions`, `IntakeContext`, `DerivedTargets`) + enums (`MealSlot`, `PortionQty`, `ConsumptionFrequency`, `DietType`, `LevelLowMidHigh`). Clase Dart plana con `toJson`/`fromJson` permisivo (mismo criterio que `MealPreset`).
2. **Servicio proteico** `ProteinTargetService` (puro): peso ideal (Devine) desde estatura + sexo, y objetivo proteico (0.8/1.0/1.5 g/kg) desde `activityLevel`. Regla 2 del método (Jaramillo cap. 10).
3. **Persistencia** — interface `NutritionIntakeRepository` + impl Firestore en `users/{uid}/nutritionProfile/intake` (documento único) + provider.
4. **Aplicación** — `NutritionIntakeNotifier` offline-first: escucha el intake del usuario, y al guardar deriva los objetivos desde el `UserModel`.
5. **Tests** — `protein_target_service_test.dart` (anclado a los ejemplos del libro) y `nutrition_intake_test.dart` (round-trip + parsing permisivo + guardas de negocio).

**Fuera (siguiente entrega de SPEC-270 / otros SPECs):**

- UI del onboarding del pilar (6 bloques, progressive profiling) — fase 2 de SPEC-270.
- Motor de generación de la minuta — SPEC-272.
- `mealPlans/{date}` y su capa de datos — SPEC-271.

## 3. El onboarding de alta NO se toca

Verificado en código: el `UserModel` ya captura `height`, `gender`, `age`, `activityLevel` (default 1.2) y `firstMealGoal`/`lastMealGoal`. SPEC-270 los **lee**; no pide biometría nueva ni modifica el flujo de alta. `ProteinTargetService` y el notifier consumen esos campos y solo cachean el resultado en `NutritionIntake.derived`.

## 4. Modelo de datos

Documento único `users/{uid}/nutritionProfile/intake`:

```
intake = {
  version, updatedAt, mealsPerDay,
  meals:  [ { slot, timeApprox, items: [ { foodId?, qty, freeText? } ] } ],
  snacks: [ { foodId?|freeText?, frequency } ],
  drinks: { sugary, coffeeSweetened, alcoholRef? },   // alcoholRef → SPEC-261
  restrictions: { diet, excludes[], allergies[] },
  context: { cookTime, budget, cooksAtHome },
  derived: { idealWeightKg, targetProteinG, windowFirst, windowLast }  // caché
}
```

`derived` NO es fuente de verdad: se recalcula desde `UserModel` + `CircadianProfile` en cada guardado. `mealsPerDay` es informativo (el target operativo de comidas lo infiere `MealTargetService` del protocolo de ayuno).

**Reglas Firestore:** ninguna regla nueva. La catch-all `match /users/{userId}/{allPaths=**}` (líneas 236–244 de `firestore.rules`) cubre `nutritionProfile` para create/update/delete del dueño, porque NO está en la lista de exclusión (`metabolic_cycles`, `imr_history`, `badges`, `glucose_readings`). Verificado leyendo el archivo, no asumido.

## 5. Base científica (peso ideal + proteína)

- **Regla 2 (Jaramillo cap. 10):** proteína sobre peso IDEAL; 0.8–1.0 g/kg moderado, hasta 1.5 g/kg activo (rechaza 3 g/kg).
- **Peso ideal — fórmula de Devine** (Devine BJ, *Drug Intell Clin Pharm* 1974): hombre 50.0 kg + 2.3 kg/pulgada sobre 5 pies; mujer 45.5 + 2.3. Reproduce los ejemplos del libro: hombre 1.85 m → 79.5 kg (≈ "80"); mujer 1.60 m → 52.4 kg (≈ "55", ambos "más o menos" en el texto). Los tests anclan estos valores con tolerancia.
- **Factor de actividad** desde el PAL (`activityLevel`): <1.4 sedentario (0.8), 1.4–1.6 moderado (1.0), >1.6 activo (1.5).

## 6. Archivos

Nuevos:

- `lib/src/features/nutrition/domain/nutrition_intake.dart`
- `lib/src/features/nutrition/domain/protein_target_service.dart`
- `lib/src/features/nutrition/domain/nutrition_intake_repository.dart`
- `lib/src/features/nutrition/data/nutrition_intake_repository_impl.dart`
- `lib/src/features/nutrition/application/nutrition_intake_notifier.dart`
- `test/features/nutrition/domain/nutrition_intake_test.dart`
- `test/features/nutrition/domain/protein_target_service_test.dart`
- `specs/SPEC-270-nutricion-intake-onboarding.md`

No se modificó ningún archivo existente (onboarding, rules, score, UserModel).

## 7. Tests

`protein_target_service_test.dart`:
- Peso ideal ancla a los ejemplos del libro (hombre 1.85→~80, mujer 1.60→~55 aprox), clamp bajo 5 pies, género desconocido → promedio, sinónimos de género.
- Umbrales del PAL → nivel; g/kg por nivel (0.8/1.0/1.5).
- Objetivo proteico (hombre 1.85 moderado → ~80 g), monotonía activo > sedentario, `deriveTargets`.

`nutrition_intake_test.dart`:
- Round-trip JSON completo (anidados + todos los enums por su wire).
- Parsing permisivo (payload vacío → defaults; item corrupto se salta; enum desconocido → default).
- Guardas: `isComplete`, `IntakeItem.isMeaningful`, `allBanned`.

**Verificación pendiente (Carlos):**

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze
flutter test test/features/nutrition
```

## 8. Riesgo conocido

Esta entrega se escribió sin toolchain de Flutter en el entorno (no se pudo correr `analyze`/`test`). El código calca patrones existentes (`MealPreset`, `MealPresetRepositoryImpl`, `meal_preset_notifier`) y se verificaron las firmas de las APIs usadas (`currentUserStreamProvider`, `AppLogger.warning`, getters de `UserModel`). Cualquier ajuste de compilación se resuelve en el primer `flutter analyze` de Carlos.

## 9. Siguiente paso

Fase 2 de SPEC-270: UI del onboarding del pilar (6 bloques) que arma un `NutritionIntake` y llama `saveIntake`. Luego SPEC-271 (capa de datos de `mealPlans`).
