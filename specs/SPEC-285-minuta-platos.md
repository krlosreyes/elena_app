# SPEC-285 — La Minuta muestra PLATOS (no ingredientes sueltos)

**Estado:** IMPLEMENTED (UI). PENDIENTE analyze/simulador de Carlos.
**Fecha:** 2026-08-12
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-284 (la comida ES una receta).
**Incluye:** UI de SPEC-287 (agregar alimento).

## 1. Problema (feedback de Carlos con pantallas)

Cada comida se veía como una lista de alimentos sueltos (Clara de huevo · Tinto · Queso crema · Acelga) — parece mercado, no comida. Y las recetas vivían en un botón aparte.

## 2. Cambio

`meal_plan_screen.dart` → `_MealCard` reescrito como **tarjeta de plato**:

- Arriba: etiqueta de comida (Desayuno) + proteína, **nombre del plato** (receta) y resumen (`12 min · 1 porción`).
- Desplegable **"Ver ingredientes y preparación"** (`_DishDetails`): ingredientes centrales (editables, se tocan para cambiarlos) + condimentos de texto libre de la receta + preparación numerada.
- Acciones: **Cambiar plato** (`_showChangeDish` → hoja de recetas compatibles con "Elegir este plato" → `chooseRecipe`) y **Agregar algo** (`_showAddFood` → `_AddFoodSheet` → `addExtraFood`, SPEC-287).
- Se conserva el ciclo Comí / Cambié / Me salté.
- Se retira la lista de ingredientes sueltos y el botón "Recetas para esta comida" (ahora el plato ES la receta).

Editar un ingrediente puntual reutiliza SPEC-280 (`_showAlternatives` → `chooseAlternative`).

## 3. Archivos

- `lib/src/features/nutrition/presentation/meal_plan_screen.dart`

## 4. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition/presentation/meal_plan_screen.dart
```

Simulador: Minuta → cada comida es un plato con nombre; desplegar ingredientes + preparación; Cambiar plato (elegir otra receta); Agregar algo; tocar un ingrediente para cambiarlo; Comí/Cambié/Me salté.

## 5. Sigue

- SPEC-286: Dashboard "Tu próxima comida" (reemplaza el botón genérico).
