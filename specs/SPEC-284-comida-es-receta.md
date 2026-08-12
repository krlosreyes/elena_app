# SPEC-284 — La comida de la Minuta ES una receta

**Estado:** IMPLEMENTED (dominio + motor + notifier + tests). PENDIENTE analyze/test de Carlos.
**Fecha:** 2026-08-12
**Rama:** `feat/pilar-alimentacion-minuta`
**Decisión de producto:** Carlos eligió **1.C** (la comida siempre es una receta del recetario) + **2.A** (cambiar plato / editar ingrediente / agregar).
**Depende de:** SPEC-278 (recetario + matcher), SPEC-280 (elegir alternativa).

## 1. Problema

La Minuta mostraba cada comida como **alimentos sueltos** (Clara de huevo · Tinto · Queso crema · Acelga) — parece lista de mercado, no una comida. En paralelo, las recetas vivían en otra pantalla ("Recetas para esta comida"). Dos conceptos compitiendo.

## 2. Decisión

La unidad de la Minuta pasa a ser **la receta** (un plato con nombre, ingredientes y preparación). El motor deja de "componer un plato de alimentos" y pasa a **elegir la mejor receta** por comida, según lo que el usuario ya come (matcher SPEC-278), respetando dieta + vetos, con **variedad diaria** (rota de forma determinística entre las mejores). La composición de plato de SPEC-276 queda como **fallback** solo si ninguna receta encaja (caso raro: vetos extremos).

## 3. Cambios

- `domain/meal_plan.dart`
  - `MealPlanEntry.recipeId` (String?, opcional; JSON omite cuando null → compatible con planes viejos).
  - `MealPlan.setMealRecipe(slot, recipeId, items, {rationale})` — cambia el plato completo, limpia adherencia (es otro plato).
  - `MealPlan.addItem(slot, item)` — agrega un alimento extra sin duplicar (SPEC-287).
  - `replaceItem` preserva `recipeId`.
- `domain/meal_plan_generator.dart`
  - Receta-primero: por comida, `RecipeMatchService.match(slot)` → `_pickRecipe` (rotación diaria por `dateId|slot`) → `_entryFromRecipe` (recipeId + ítems centrales de la receta como `PlanItem` editables).
  - `_buildEntry` (plato coherente SPEC-276/282) queda como **fallback** cuando el matcher no devuelve recetas.
- `application/meal_plan_notifier.dart`
  - `chooseRecipe(slot, recipeId)` — cambia el plato (offline-first).
  - `addExtraFood(slot, foodId)` — agrega alimento (SPEC-287, offline-first).

## 4. Invariantes / tests

- `meal_plan_generator_test.dart` (reescrito): cada comida tiene `recipeId`; la receta encaja en el slot y la dieta; los ítems salen de la receta; determinismo por día; variedad en la semana.
- `meal_plan_generator_variety_test.dart` (reescrito): mismo día → misma receta; días distintos → varía.
- `meal_plan_generator_cautions_test.dart` (reescrito): **ninguna receta del recetario usa un alimento con cautela**; la minuta generada nunca sirve un alimento con cautela.

## 5. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition test/features/nutrition
flutter test test/features/nutrition
```

## 6. Sigue

- SPEC-285: Minuta como tarjetas de plato (nombre + ingredientes + preparación), quitar ingredientes sueltos, acciones Cambiar/Editar/Agregar.
- SPEC-286: Dashboard "Tu próxima comida".
- SPEC-287: UI de "agregar algo que no está" (motor ya listo: `addExtraFood`).
- Follow-up: ampliar el recetario para más variedad por slot×dieta.
