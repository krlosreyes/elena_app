# SPEC-293 — Cantidad editable por ingrediente (huevo ×3)

**Estado:** IMPLEMENTED (dominio + UI + tests). PENDIENTE analyze/test de Carlos.
**Fecha:** 2026-08-14
**Rama:** `feat/pilar-alimentacion-minuta`
**Decisión de Carlos:** opción B — capturar cantidad por ingrediente (no solo adherencia).

## 1. Problema

"Si el usuario se comió 3 huevos, ¿cómo los registra?" El modelo era solo adherencia (Comí/Cambié/Me salté); no había forma de indicar la cantidad.

## 2. Cambio

- `domain/meal_plan.dart`: `PlanItem.quantity` (int, default 1; JSON omite cuando 1; `copyWith`; ==/hashCode). `MealPlan.setItemQuantity(slot, foodId, qty)` (acota a ≥1, inmutable).
- `application/meal_plan_notifier.dart`: `setQuantity(slot, foodId, qty)` offline-first.
- `presentation/meal_plan_screen.dart`:
  - La hoja de edición del ingrediente (`_AlternativesSheet`, ahora stateful) trae un **stepper − N +** de cantidad, con la referencia de "cada una: {porción}". Es parte del CRUD (editar cantidad, cambiar, quitar) en un solo lugar.
  - La fila del ingrediente muestra la cantidad: `3× 1 huevo mediano`.
  - Al cambiar el alimento se **conserva** la cantidad.
- Tests: `meal_plan_quantity_test.dart`.

## 3. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition
flutter test test/features/nutrition
```

Simulador: Minuta → tocar un ingrediente → subir la cantidad a 3 → la fila muestra "3×"; se guarda en la minuta.
