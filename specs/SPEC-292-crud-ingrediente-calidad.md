# SPEC-292 — CRUD completo por ingrediente + asesor de "alimento malo"

**Estado:** IMPLEMENTED (dominio + UI + tests). PENDIENTE analyze/test de Carlos.
**Fecha:** 2026-08-13
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Pedido de Carlos

1. Cuando el usuario escoja un alimento poco ideal, avisarle **por qué** y darle **opciones para cambiarlo**.
2. **Autonomía total**: CRUD completo en cada ingrediente del plato.

## 2. Cambios

### Asesor de calidad
- `domain/food_quality.dart` (nuevo): `FoodQualityLevel {good, moderate, poor}` + `levelOf`, `isPoor`, `shortReason` (chip) y `explanation` (humana). `poor` = NOVA 4 o `qualityScore < 35`.

### CRUD por ingrediente (Minuta)
- **Create**: "Agregar algo" (`addExtraFood`, SPEC-287) — ya existía.
- **Read**: ingredientes visibles — ya existía.
- **Update**: tocar un ingrediente → hoja de alternativas (`chooseAlternative`, SPEC-280) — ya existía.
- **Delete** (nuevo): `MealPlan.removeItem` + notifier `removeFood`; en la hoja de alternativas, "Quitar … de la comida".

### Aviso de "malo"
- `meal_plan_screen.dart`: en el ingrediente, si es `poor`, un renglón de alerta ("Ultraprocesado · toca para cambiarlo") y el ícono de cambio en tono de alerta. La hoja de alternativas muestra la **explicación** (por qué) y las opciones (ya ordenadas por calidad).
- `intake_onboarding_screen.dart`: los alimentos `poor` llevan un ⚠ en su chip (no bloquea — autonomía).

## 3. Archivos

- `domain/food_quality.dart`, `domain/meal_plan.dart` (removeItem)
- `application/meal_plan_notifier.dart` (removeFood)
- `presentation/meal_plan_screen.dart`, `presentation/intake_onboarding_screen.dart`
- Tests: `food_quality_test.dart`, `meal_plan_remove_item_test.dart`

## 4. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition
flutter test test/features/nutrition
```
