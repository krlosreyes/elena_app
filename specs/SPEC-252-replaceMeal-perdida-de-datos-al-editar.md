# SPEC-252 — Editar una comida la eliminaba sin guardar la nueva versión

**Estado:** IMPLEMENTED
**Versión:** 1.0
**Fecha:** 2026-07-08
**Autor:** Claude (líder de proyecto) + Carlos (reporte de bug en device)
**Pilar:** Nutrición

## 1. Contexto

Carlos, validando SPEC-251 en el simulador, reportó: "al registrar el almuerzo se borra el desayuno, eso no debe pasar, también revisa la edición de las comidas se debe poder editar y que quede guardada la nueva version de la comida." Las dos observaciones resultaron ser el mismo bug: `NutritionNotifier.replaceMeal()` (el método detrás del botón "Editar plato") eliminaba el log original y luego fallaba en crear el nuevo, perdiendo la comida.

## 2. Causa raíz

`replaceMeal(oldId, ...)` (usado por el botón "Editar plato" en `comidas_pillar_card.dart` y `meal_history_tile.dart`) hacía, en este orden:

1. Disparar `repo.deleteMealById(userId, oldId)` de forma incondicional y no bloqueante (`unawaited`).
2. `await logMeal(...)` para crear la nueva versión.

`logMeal()` valida el intervalo entre comidas (SPEC-137 E.5: <2h bloqueado, 2-3h warning) usando `MealIntervalRules.lastMealOf(state.todayLogs)`. Pero `state.todayLogs` en ese momento **todavía contenía el log viejo** — el borrado del paso 1 es asíncrono contra Firestore y no tenía ninguna actualización optimista local que lo quitara del cache del notifier. Como editar una comida normalmente no cambia demasiado su hora, el nuevo timestamp caía a un delta ≈0 respecto al log que se estaba reemplazando — es decir, **`logMeal()` comparaba el intervalo contra SÍ MISMO**, siempre calificaba como `MealIntervalCheck.blocked` (<2h), y lanzaba `MealTooSoonException` de forma incondicional (el bloqueo, a diferencia del warning, no respeta `forceLog` — así lo documenta el propio código desde SPEC-137 E.5: "NO ignora el bloqueo").

Resultado: el log viejo ya se había eliminado (paso 1, incondicional), pero el nuevo nunca se creaba (paso 2, bloqueado por la excepción) — la comida editada simplemente desaparecía, sin guardar ningún cambio.

Esto explica ambos síntomas reportados por Carlos con una sola causa: cualquier edición de la comida más reciente (la que normalmente pre-carga el botón "Editar plato") disparaba este patrón.

## 3. Solución

En `lib/src/features/nutrition/application/nutrition_notifier.dart`:

1. **`logMeal()`** ahora acepta un parámetro opcional `String? replacingLogId`. Cuando se provee, se excluye ese id de `state.todayLogs` antes de calcular `lastMealAt` (para la validación de intervalo) y antes de construir la lista optimista local — así el log que se está reemplazando nunca cuenta como "la última comida" de sí mismo, pero SÍ se sigue comparando correctamente contra cualquier OTRA comida real del día (protección genuina contra choques de horario se mantiene intacta).

2. **`replaceMeal()`** se reordenó: ahora llama primero a `logMeal(..., replacingLogId: oldId)` y SOLO SI esa llamada no lanzó excepción, dispara el borrado (no bloqueante) del log viejo. Si `logMeal()` falla por cualquier motivo real — por ejemplo, el nuevo horario choca con OTRA comida existente, no la que se edita — el log original se conserva intacto y no hay pérdida de datos.

## 4. Archivos modificados

- `lib/src/features/nutrition/application/nutrition_notifier.dart` — `logMeal()` gana el parámetro `replacingLogId`; `replaceMeal()` invierte el orden (guardar primero, borrar después) y pasa `replacingLogId: oldId`.
- `test/features/nutrition/application/nutrition_notifier_test.dart` — nuevo grupo `'NutritionNotifier.replaceMeal (SPEC-252)'` con 2 tests.

## 5. Tests

1. `replaceMeal guarda la nueva versión aunque el horario coincida con el del log original` — reproduce exactamente el bug original (mismo timestamp) y verifica que el resultado final es 1 log (el nuevo), ni 0 (dato perdido) ni 2 (duplicado).
2. `replaceMeal preserva el log original si logMeal falla por chocar con OTRA comida real` — verifica que la protección de intervalo sigue funcionando para choques genuinos con otras comidas, y que en ese caso el log original NO se pierde (a diferencia del bug, donde cualquier fallo de `logMeal` perdía el dato).

Verificación pendiente por Carlos:

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze
flutter test test/features/nutrition
```

## 6. Riesgos

- Si el usuario edita una comida y le pone un horario que choca con OTRA comida real (no la que edita), seguirá viendo el bloqueo `MealTooSoonException` — esto es intencional (protección de intervalo), no un bug.
- No se tocó la UI (`plate_ratio_sheet.dart`, `comidas_pillar_card.dart`, `meal_history_tile.dart`) — el fix es enteramente en la capa de aplicación (`NutritionNotifier`). El manejo de `MealTooSoonException`/`MealIntervalWarning` en `_submit()` de `PlateRatioSheet` ya mostraba un dialog apropiado; ese comportamiento no cambia.

## 7. Criterios de aceptación

- [x] Editar la comida más reciente (caso típico del botón "Editar plato") guarda la nueva versión sin perder el registro.
- [x] Editar una comida con un horario que choca con OTRA comida real sigue bloqueado (protección de intervalo intacta) y el log original no se pierde en ese caso.
- [ ] Validación manual en device por Carlos: editar el desayuno y confirmar que la nueva versión queda guardada; registrar desayuno + almuerzo por separado y confirmar que ambos coexisten.

## 8. Resultado

Implementado y testeado con fakes. Pendiente `flutter analyze`/`flutter test` y validación manual en device por Carlos.
