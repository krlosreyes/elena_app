# SPEC-298 — Registrar la hora de cada comida y anclar la ventana

**Estado:** IMPLEMENTED (falta analyze+tests de Carlos y validar en simulador).
**Fecha:** 2026-08-14
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Pedido de Carlos

"Los registros de alimentación no están dejando registro de la hora en que se
consume cada comida; tenemos el vacío de recomendación y registro en este
aspecto y debemos corregirlo de forma coherente al objetivo de la app."

## 2. Diagnóstico

- Marcar una comida en la Minuta (Comí / Cambié / Me salté) guardaba **solo la
  marca** — `MealPlanEntry.adherence` es un enum sin hora. No quedaba registro
  de a qué hora se comió.
- Peor: la **ventana de alimentación** (pilar) se ancla a
  `nutritionProvider.todayLogs`, el **registrador viejo retirado** en SPEC-277.
  La Minuta nunca lo alimentó (`markAdherence` guarda en `mealPlans` sin crear
  log). Para quien usa la Minuta (flujo actual), la ventana caía a la proyección
  teórica de `firstMealGoal` en vez de a la primera comida real.
- Sin hora, no había recomendación de timing (última comida vs cierre circadiano
  ~21:30 — ver `reference_circadian_bibliography`).

## 3. Decisión de Carlos

Captura de hora **automática (now) con opción de editar** (lápiz + selector).

## 4. Implementación

**Modelo (`meal_plan.dart`).** `MealPlanEntry.consumedAt` (DateTime?). JSON
round-trip. `markAdherence(slot, mark, {at})` sella la hora al comer/cambiar y la
limpia al saltarse. `setConsumedAt(slot, when)` para el lápiz. Getters
`firstConsumedAt` / `lastConsumedAt`. Todas las mutaciones existentes
(replaceItem, setItemQuantity, removeItem, addItem) preservan `consumedAt`;
`setMealRecipe` la limpia (es otro plato).

**Notifier.** `markAdherence` pasa `DateTime.now()`. Nuevo `editMealTime(slot,
when)` offline-first.

**UI (`meal_plan_screen.dart`).** Bajo el ciclo, cuando la comida está marcada
como consumida: "Comido a las HH:mm" + "Editar hora" (showTimePicker). En el
header, aviso de timing si la última comida pasó el cierre de la ventana.

**Ventana (`eating_window_provider.dart`).** La fuente principal del "primer
registro real" pasa a ser la Minuta (`plan.firstConsumedAt`); el registrador
viejo queda solo como fallback legacy. `EatingWindowState.compute` ya sabía
anclar honestamente a `firstMealLoggedToday` — solo estaba desnutrido de datos.

## 5. No-regresión

- La ventana conserva el fallback a `todayLogs` para datos legacy.
- `EatingWindowState` no cambió; solo cambia de dónde llega su input.
- `consumedAt` se omite del JSON cuando es null (planes viejos intactos).

## 6. Tests
`test/features/nutrition/domain/meal_plan_consumed_at_test.dart`: sella/limpia
hora, edita, first/last, round-trip, preservación en mutaciones, y que cambiar
de plato limpia la hora.

## 7. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition lib/src/features/fasting test/features/nutrition
flutter test test/features/nutrition/domain/meal_plan_consumed_at_test.dart
```

En simulador (sin ayuno activo): marca una comida → aparece "Comido a las HH:mm"
con lápiz; el anillo/ventana de alimentación debe arrancar en esa hora real, no
en el horario teórico.
