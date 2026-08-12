# SPEC-286 — Dashboard: "Tu próxima comida"

**Estado:** IMPLEMENTED (UI). PENDIENTE analyze/simulador de Carlos.
**Fecha:** 2026-08-12
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-284/285.

## 1. Problema (feedback de Carlos)

El pilar Comidas mostraba un botón genérico "Ver mi minuta de hoy" (no dice qué comer ahora) + mini-stats de conteo confusos (Próxima / En / Cociente A 0%).

## 2. Cambio

`comidas_pillar_card.dart`:

- Nuevo `_NextMealCard`: muestra **la próxima comida** de la minuta (primera comida sin marcar) — nombre del plato, meta (comida · minutos · proteína) y un desplegable **"Ver ingredientes y preparación"** (lee la receta de `RecipeCatalog`). Botón **"Ver plato y ajustar"** que abre la Minuta (donde viven Cambiar/Editar/Agregar de SPEC-285).
  - Si ya marcó todas: "¡Completaste tu minuta de hoy!".
  - Si no hay plan: invita a configurar la minuta.
- Se retiran los mini-stats `Próxima / En / Cociente A` y el `_estimateNextMealIn` + `_cocienteAColor` (y los imports `CocienteAService`, `MealIntervalRules`).
- El botón "Ver mi minuta de hoy" pasa a secundario **"Ver mi minuta completa"** (la minuta completa ya muestra platos, SPEC-285).
- Se conservan: barra de progreso (adherencia a la minuta), Racha de Calidad, "Último plato", historial y el bloqueo por ayuno activo.

Los cambios/edición/agregado no se duplican en el dashboard: se ofrecen a un tap, en la Minuta (fuente única), para no mantener dos UIs de mutación en paralelo.

## 3. Archivos

- `lib/src/features/dashboard/presentation/widgets/comidas_pillar_card.dart`

## 4. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/dashboard/presentation/widgets/comidas_pillar_card.dart
```

Simulador (Hoy → pilar Comidas): ver "Tu próxima comida" con el plato; desplegar ingredientes + preparación; "Ver plato y ajustar" abre la Minuta; al marcar comidas, avanza a la siguiente; al completar, mensaje de cierre.
