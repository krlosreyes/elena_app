# SPEC-253 — Guardia definitiva anti-pérdida silenciosa de comidas

**Estado:** IMPLEMENTED — pendiente validación en device (Carlos)
**Fecha:** 2026-07-08
**Relacionado:** SPEC-251 (persistencia/orden de escritura), SPEC-252 (replaceMeal),
SPEC-206 (offline-first), SPEC-149 (Día Metabólico)

## 1. Contexto

Tras cerrar SPEC-252 (que arregló un bug real y confirmado en `replaceMeal`),
Carlos reportó que el síntoma seguía ocurriendo por una vía distinta:

> "Sigue igual, creo dos comidas con diferentes horas y al registrar la
> segunda la primera se borraaaa"

Se descartaron, en orden, las siguientes hipótesis:

1. **Hot reload vs Hot Restart** (state rot) — descartado. Carlos confirmó
   "Ya reinicie todo" y adjuntó 3 capturas mostrando el bug persistiendo
   después de un restart completo de la app.
2. **El bug era solo en el flujo de edición (SPEC-252)** — descartado. Las
   capturas muestran el flujo de registro NORMAL ("Registrar Almuerzo",
   sin pasar por "Editar plato"): se registra el desayuno, luego el
   almuerzo a otra hora, y el desayuno desaparece del historial y del
   contador ("1 Comidas" en vez de 2).
3. **Transición de ciclo metabólico** (`MetabolicCycleEvaluatorProvider`
   reabriendo/cerrando el ciclo y angostando la ventana de consulta) —
   investigado a fondo (evaluador de 404 líneas, servicio de ciclo,
   `bootstrapIfMissing`) sin encontrar un disparador automático que
   explique un cambio de ventana durante el registro de una comida. La
   reapertura automática de ciclo solo ocurre para
   `ClosureReason.manualNextFasting` / `protocolChanged`, ambos gatillados
   por acción explícita del usuario. Tampoco es concluyente: no se pudo
   confirmar ni descartar con certeza.

Se agregó logging de diagnóstico (`[nutritionDebug]`, commit `40ea005`) y se
pidió a Carlos reproducir con la consola abierta. Antes de recibir esos
logs, Carlos reportó que el bug **también** afecta ahora la edición
("al edittar se desaparecen las comidas") y pidió explícitamente parar el
ciclo de diagnóstico y **implementar una solución definitiva**:

> "SIgue igual y al edittar se desaparecen las comidas. Analiza, revisa a
> fondo e implementa una solución definitiva"

## 2. Decisión de diseño

No se pudo aislar con certeza el mecanismo exacto de la anomalía (posible
candidato: el stream `watchSinceLogs` de Firestore emitiendo, dentro de la
MISMA suscripción/query, un snapshot más chico que el anterior — ya sea por
caché local desincronizada, latencia de escritura vs. lectura, o alguna
interacción no identificada con el ciclo metabólico). En vez de seguir
apostando a un diagnóstico exacto sin logs de device, se implementó una
**garantía estructural** en el notifier: pase lo que pase en el stream, un
log que el usuario ya vio en pantalla NUNCA desaparece de la vista salvo
que el propio notifier haya pedido su eliminación.

Esto es deliberadamente una guardia de **síntoma**, no un fix de causa
raíz — documentado así en el código para que quede claro que si en el
futuro se identifica la causa exacta, esta guardia puede simplificarse o
quitarse, pero mientras tanto el usuario no puede volver a perder datos
visibles por esta vía.

## 3. Implementación

Archivo: `lib/src/features/nutrition/application/nutrition_notifier.dart`

- **`_explicitlyRemovedIds`** (nuevo `Set<String>` de campo): ids que el
  propio notifier pidió borrar, poblado por `deleteMealById`,
  `replaceMeal` (marca `oldId`) y `removeLastMeal` (marca
  `state.todayLogs.last.id`) — siempre ANTES de disparar el borrado real,
  para que la guardia nunca "gane la carrera" contra el snapshot que
  confirma el borrado.

- **`_subscribeFor`**: mantiene un baseline `confirmedForThisSubscription`
  que se resetea en cada llamada a `_subscribeFor` (es decir, en cada
  transición LEGÍTIMA de ventana/ciclo metabólico — el angostamiento
  cycle-aware intencional de la Constitución del Día Metabólico sigue
  funcionando sin cambios). Dentro de la MISMA suscripción, cada snapshot
  nuevo se combina con el baseline vía `_mergeWithBaseline` antes de
  actualizar el state.

- **`_mergeWithBaseline(baseline, fresh)`**: si `fresh` no incluye algún id
  que sí estaba en `baseline` y ese id NO está en `_explicitlyRemovedIds`,
  se re-agrega al resultado (con warning de log). Si el snapshot es igual
  o más grande, o si la ausencia corresponde a un borrado explícito, no
  hace nada — el comportamiento normal (incluyendo borrados reales del
  usuario) queda intacto.

- Se conserva el logging `[nutritionDebug]` agregado en la ronda anterior
  (bajo costo, útil para diagnosticar regresiones futuras de la ventana de
  consulta).

## 4. Qué protege y qué NO rompe (protocolo "no regresión")

| Caso | Comportamiento |
|---|---|
| Snapshot de Firestore "olvida" un log sin borrado explícito | Se preserva en `state.todayLogs` (guardia activa) |
| `deleteMealById(id)` | El log SÍ desaparece — `id` está en `_explicitlyRemovedIds` |
| `removeLastMeal()` | El último log SÍ desaparece — se marca antes del borrado |
| `replaceMeal(oldId: ...)` | El log viejo SÍ desaparece — se marca antes de `logMeal` |
| Transición real de ciclo metabólico (nuevo ayuno) | La ventana se angosta con normalidad — nueva baseline vacía en `_subscribeFor` |
| Usuario cambia de cuenta / logout | Nueva baseline vacía (nuevo `_subscribeFor` vía listener de usuario) |

## 5. Tests

Archivo: `test/features/nutrition/application/nutrition_notifier_test.dart`,
grupo `'NutritionNotifier guardia anti-pérdida-de-datos (SPEC-253)'` (3 tests
nuevos):

1. Un snapshot posterior que omite un log sin borrado explícito → el log se
   preserva en `state.todayLogs` (simula la anomalía inyectando
   directamente vía `fakeRepo.emit()`, sin pasar por ningún método de
   borrado del notifier).
2. `deleteMealById` sí reduce la lista — la guardia no resucita un borrado
   real.
3. `removeLastMeal` marca el log correcto como eliminado explícito — no lo
   preserva la guardia.

## 6. Verificación pendiente (Carlos, en device)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
git push origin mvp-core-clean
flutter analyze
flutter test test/features/nutrition
```

Y reproducción manual: crear 2+ comidas a horas distintas por el flujo
normal de "Registrar", y también editar una comida existente — verificar
que ninguna comida previa desaparece del historial ni del contador, con y
sin restart de la app.

## 7. Seguimiento

Si el bug persistiera incluso con esta guardia (lo cual indicaría que la
pérdida ocurre en un punto que esta guardia no cubre — por ejemplo, si el
propio `since` de la query cambiara de forma que un log quede FUERA de la
ventana en vez de ausente del snapshot), el próximo paso sería revisar los
logs `[nutritionDebug]` de una reproducción real en device, ahora que el
síntoma visible debería estar contenido.
