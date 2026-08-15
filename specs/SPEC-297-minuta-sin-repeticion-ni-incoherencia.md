# SPEC-297 — Minuta: sin recetas repetidas ni ingredientes incoherentes

**Estado:** IMPLEMENTED (falta que Carlos corra analyze+tests y valide en simulador).
**Fecha:** 2026-08-14
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Pedido de Carlos

"Estamos haciendo sugerencias incoherentes y/o repetidas en los platos sugeridos."

## 2. Diagnóstico (causa raíz)

Ambas en `MealPlanGenerator`.

**Repetidas.** El motor elegía la receta de cada comida de forma independiente y
sin memoria del día. Muchas recetas encajan en almuerzo Y cena
(`pollo_plancha_ensalada`, `salmon_brocoli_vapor`, `lentejas_guisadas_verduras`,
`pavo_kale_almendras`, `arroz_coliflor_pollo`, `sopa_pollo_verduras`,
`camaron_aguacate_ensalada`, `tofu_salteado_brocoli`, `tilapia_espinaca`). La
"variedad" era una semilla por comida (`dateId|slot`), así que con un pool de 3
había ~1/3 de probabilidad de que almuerzo y cena cayeran en la MISMA receta.

**Incoherentes.** `_entryFromRecipe` marcaba TODOS los ingredientes de la receta
como `PlanItemOrigin.fromUser`, incluso los que el usuario nunca seleccionó.
`requirePrincipal` (SPEC-291) garantiza que la proteína sea suya, pero los
acompañamientos (lechuga, tomate, coliflor, pimiento…) se mostraban como si él
los hubiera elegido.

## 3. Arreglo

### 3.1 Dedup por día + variedad de proteína (repetidas)
- `generate` lleva `usedRecipeIds` y `usedProteinIds` a lo largo de las comidas.
- Se pide al matcher TODAS las candidatas (`limit: RecipeCatalog.all.length`), no
  solo el top-3, para que el dedup tenga de dónde elegir.
- `_pickRecipe` ahora: (1) descarta recetas ya usadas hoy —si no queda ninguna,
  permite repetir para no dejar la comida vacía—; (2) preferencia SUAVE por una
  proteína principal distinta a las de hoy (si el usuario solo tiene una, se
  relaja y repite proteína pero con otra receta); (3) rota determinísticamente
  entre las mejores del pool (misma variedad diaria de antes).

### 3.2 Origins honestos (incoherentes)
- `_entryFromRecipe` recibe `userFoods` (repertorio real) y marca cada ítem
  `fromUser` solo si el usuario ya lo come; lo demás, `newSuggestion` → la UI lo
  pinta como "Nuevo" (sugerencia para probar), no como suyo. Alineado con el
  método: sí sugerimos vegetales/grasa que faltan, pero con honestidad.

## 4. No-regresión
- El score de nutrición NO usa `origin` (solo la UI: tag "Nuevo"/"Mejora").
- El determinismo se conserva (mismo día + intake → misma minuta).
- La proteína servida sigue siendo siempre del repertorio (requirePrincipal).

## 5. Tests
`test/features/nutrition/domain/meal_plan_generator_dedup_test.dart`:
- No repite receta entre comidas del día (15 días).
- Prefiere proteína principal distinta cuando se puede.
- Marca "Nuevo" lo no elegido y "suyo" solo lo elegido.

## 6. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition test/features/nutrition
flutter test test/features/nutrition/domain/meal_plan_generator_dedup_test.dart test/features/nutrition/domain/meal_plan_generator_test.dart test/features/nutrition/domain/meal_plan_generator_principal_test.dart
```

Luego en simulador: abrir la Minuta con un repertorio de ≥2 proteínas y
confirmar que desayuno/almuerzo/cena son platos distintos y que los ingredientes
no elegidos aparecen con el tag "Nuevo".
