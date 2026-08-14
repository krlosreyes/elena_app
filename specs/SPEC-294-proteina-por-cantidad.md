# SPEC-294 — Proteína real por porción y escalado por cantidad

**Estado:** IMPLEMENTED (dominio + UI + tests). PENDIENTE analyze/test de Carlos.
**Fecha:** 2026-08-14
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Problema (pregunta de Carlos)

"Si el usuario se comió 3 huevos, ¿suma la misma proteína que un huevo?" Sí — porque **no existía** cálculo de proteína consumida: `targetProteinG` era solo el objetivo, `proteinFraction` solo estaba en 12/173 alimentos y no se usaba en ningún cálculo. La cantidad (SPEC-293) no afectaba nada.

## 2. Cambio

- `domain/food_protein.dart` (nuevo): tabla de **gramos de proteína por porción de referencia** para los **173 alimentos** (verificado: cobertura total, sin ids fantasma). `proteinPerPortion(Food)` y `platedProteinG(items)` — este último **escala por `quantity`** (huevo ×3 = 3 × 6 g = 18 g).
- `presentation/meal_plan_screen.dart`:
  - Cada comida muestra la proteína REAL del plato: `38 g / ~15 g proteína` (plato vs meta).
  - El encabezado del día muestra `Proteína del día: {consumida} g de ~{meta} g`, sumando la proteína (escalada por cantidad) de las comidas marcadas como comidas.
- Tests: `food_protein_test.dart` (escala ×3, suma multi-ítem, cobertura total).

## 3. Alcance

Es un cálculo/visualización. **No** cambia el score/IMR (sigue siendo por adherencia, SPEC-274). Los gramos son por porción de referencia (sin pesar), fieles al enfoque metabólico. Si luego se quiere que la proteína consumida alimente el score, es un paso aparte.

## 4. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition
flutter test test/features/nutrition
```
