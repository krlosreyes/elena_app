# SPEC-271 — Capa de datos de la Minuta Diaria (mealPlans)

**Estado:** IMPLEMENTED — modelo + repo + tests. PENDIENTE de `flutter analyze` + `flutter test` por Carlos.
**Versión:** 1.0
**Fecha:** 2026-08-07
**Autor:** Claude (líder de proyecto / full-stack) + Carlos (aprobación)
**Pilar:** Nutrición
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-270 (intake). **Habilita:** SPEC-272 (motor), SPEC-273 (UI), SPEC-274 (score).

## 1. Contexto

Segundo peldaño de la reestructuración: definir el MODELO de la Minuta Diaria y su persistencia por día, sin todavía generar contenido (eso es SPEC-272) ni pintarlo (SPEC-273). Es la estructura sobre la que el motor escribe y la UI marca adherencia.

## 2. Modelo

`MealPlan` (agregado raíz, un documento por día):

- `date` ('yyyy-MM-dd', también el id del documento), `version`, `generatedFrom { intakeVersion, phase }`, `window { first, last }`, `status` (proposed/accepted/logged), `generatedAt`.
- `meals: List<MealPlanEntry>` — cada una con `slot` (reutiliza `MealSlot` de SPEC-270), `targetProteinG`, `items: List<PlanItem>`, `swappedFrom` (trazabilidad del reemplazo suave), `rationale` (texto humano) y `adherence` (`AdherenceMark?`).
- `PlanItem`: `foodId` (→ `FoodCatalog`), `role` (protein/veg/fat/other), `portion` (`HandPortion`: palma/puño/pulgar… — nada de gramos).

Enums: `PlanStatus`, `AdherenceMark` (ate/changed/skipped, con `isAdherent` — "cambié" cuenta como cumplido, "me salté" no), `PlanItemRole`, `HandPortion`. Todos con `wire`/`fromWire` tolerantes.

Lógica de dominio: `markAdherence(slot, mark)` (inmutable, pasa el plan a `logged`), `adherentCount` / `markedCount` (insumo del score SPEC-274), `MealPlan.dateId(DateTime)`.

## 3. Persistencia

`users/{uid}/mealPlans/{yyyy-MM-dd}` — un documento por día. Repo delgado (mismo patrón que `NutritionIntakeRepositoryImpl`): `watchPlan`, `getPlan`, `savePlan`.

**Reglas Firestore:** ninguna nueva. La catch-all `match /users/{userId}/{allPaths=**}` cubre `mealPlans` (no está en la lista de exclusión) para create/update/delete del dueño — verificado leyendo `firestore.rules`.

**Índices:** ninguno. Las lecturas son por id de documento (la fecha); no hay `where + orderBy` que requiera índice compuesto (checklist SPEC-145 cumplido). Cuando SPEC-275 agregue vistas por rango de fechas se evaluará ahí.

## 4. Archivos

Nuevos:

- `lib/src/features/nutrition/domain/meal_plan.dart`
- `lib/src/features/nutrition/domain/meal_plan_repository.dart`
- `lib/src/features/nutrition/data/meal_plan_repository_impl.dart`
- `test/features/nutrition/domain/meal_plan_test.dart`
- `specs/SPEC-271-minuta-capa-datos.md`

No se modificó ningún archivo existente (ni rules ni índices).

## 5. Tests

`meal_plan_test.dart`: round-trip JSON (anidados + todos los enums por su wire), parsing permisivo (payload mínimo → defaults; adherencia desconocida → null), adherencia (`markAdherence` marca + pasa a `logged` sin mutar el original; slot inexistente = no-op; `adherentCount` cuenta ate/changed y no skipped), y `dateId`.

Verificación pendiente (Carlos):

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze
flutter test test/features/nutrition
```

## 6. Siguiente paso

SPEC-272: motor de generación (reemplazo suave, 100% determinístico) que consume `intake` + `UserModel` + `FoodCatalog` y escribe un `MealPlan` con este modelo.
