# SPEC-254 — Causa raíz real: transición de ciclo sin aviso al usuario

**Estado:** IMPLEMENTED — pendiente validación en device (Carlos)
**Fecha:** 2026-07-08
**Relacionado:** SPEC-149 (Día Metabólico), SPEC-253 + SPEC-253.1 (guardia
anti-pérdida, ahora reclasificada — ver §4)

## 1. Resumen ejecutivo

Después de tres rondas de fixes (SPEC-251, SPEC-252, SPEC-253, SPEC-253.1)
sobre la hipótesis de que el stream de Firestore perdía datos, Carlos
compartió capturas directas de Firestore (colecciones `nutrition_history`
y `metabolic_cycles`) que permitieron identificar la causa real:

**No hay pérdida de datos.** Las comidas siguen siempre en Firestore. Lo
que ocurre es que se abre un **ciclo metabólico nuevo** cuyo `startedAt`
cae DESPUÉS de una comida ya registrada — y por diseño (SPEC-149,
Constitución del Día Metabólico §1), la vista de "Hoy" en Nutrición se
ancla al ciclo metabólico activo. Cuando el ciclo cambia, la ventana de
consulta (`since`) avanza, y una comida registrada en el ciclo ANTERIOR
dejar de estar en la ventana del ciclo NUEVO. Sigue en Firestore, pero
"Hoy" ya no la incluye — visualmente indistinguible de "se borró".

## 2. Evidencia

Capturas de Firestore Console (2026-07-08) para el usuario de prueba
(`charlie2@gmail.com`):

- `users/{uid}/nutrition_history`: el documento del desayuno
  (`timestamp: 8 de julio de 2026, 9:45:00 a.m. UTC-5`) sigue presente,
  intacto, con sus `plateItemIds`. Nunca se borró.
- `users/{uid}/metabolic_cycles`: hay un documento con id
  `2026-07-08T16:01:37.499879Z` (= **11:01:37 a.m. hora local**,
  UTC-5) — un ciclo que abrió **1h16min DESPUÉS** del desayuno. El ciclo
  anterior (`2026-07-07T23:30:34.235037Z` = 6:30pm del 7 de julio) cubría
  la noche completa + el desayuno sin problema.
- El historial completo de `metabolic_cycles` (semanas de datos) muestra
  MUCHOS ciclos por día, algunos con **7 segundos** de diferencia entre
  sí (`2026-06-02T23:21:58` y `2026-06-02T23:22:05`) — imposible que sea
  un tap manual deliberado. Esto es consistente con un patrón repetido de
  testing activo del pilar Ayuno (taps en "Iniciar ayuno" / "Empezar mi
  siguiente ayuno" durante sesiones de prueba), no con un bug que cree
  ciclos por sí solo — se auditó el código (`metabolic_cycle_service.dart`,
  `metabolic_cycle_evaluator_provider.dart`) y se confirmó que un ciclo
  NUEVO solo se abre por: (a) `Case 1` sin ciclo previo + fasting
  explícito, o (b) `manualNextFasting`/`protocolChanged` al cerrar uno
  existente — ambos exigen una acción consciente del usuario, nunca un
  tick automático del pulso de 10s.

## 3. El bug real: falta de aviso, no pérdida de datos

El botón "Iniciar ayuno" (`FastingConsciousnessCard._handleFastingPrimaryTap`,
rama `!isActive`) y el botón "Empezar mi siguiente ayuno" del
`CycleClosureCard` (mostrado automáticamente cuando un ciclo cerró por
fallback y no fue descartado) llaman a `startFasting()` **sin ninguna
confirmación**, a diferencia de "Terminar ayuno" que sí tiene
`EarlyFastingEndDialog`. Un tap — deliberado o exploratorio durante
testing — inicia el ciclo nuevo al instante y mueve "Hoy" hacia adelante,
sin avisar que las comidas ya registradas van a dejar de verse.

Esto explica el patrón exacto que reportó Carlos: registrar una comida,
tocar en algún momento (quizás sin asociarlo) el botón de ayuno, y ver
la comida anterior "desaparecer" al registrar la siguiente.

## 4. Reclasificación de SPEC-253 / SPEC-253.1

Esas guardias (merge-with-baseline en `NutritionNotifier._subscribeFor`,
y el fix de que el baseline sobreviva reconexiones del stream) **no eran
la causa de este bug específico**, pero siguen siendo correctas y se
mantienen: protegen contra una categoría real, aunque distinta, de
anomalía (un snapshot de Firestore que narrowea dentro de la MISMA
ventana/ciclo sin que el usuario haya borrado nada — p.ej. por un blip de
reconexión). No se revierten.

## 5. Fix implementado

Nuevo diálogo `NewCycleMealsWarningDialog`
(`lib/src/features/dashboard/presentation/widgets/new_cycle_meals_warning_dialog.dart`),
en el mismo estilo que `EarlyFastingEndDialog` (SPEC-101). Se muestra
**solo si** `nutritionProvider.state.todayLogs` no está vacío en el
momento de iniciar el ayuno, con el mensaje:

> "Tenés N comida(s) registrada(s) en tu Día Metabólico actual. Al
> iniciar el ayuno arrancás un nuevo Día Metabólico. Esas comidas van a
> quedar fuera de la vista de 'Hoy' — se conservan en tu historial, no se
> borran."

Botones: "Cancelar" (no hace nada) / "Sí, iniciar ayuno" (procede con
`startFasting()`).

Cableado en los dos puntos de entrada de "iniciar ayuno AHORA" (no se
tocó el flujo de "viaje en el tiempo" / hora manual, que ya pasa por un
TimePicker deliberado — ver §6 pendientes):

- `dashboard_screen.dart` — botón "Empezar mi siguiente ayuno" del
  `CycleClosureCard`.
- `fasting_consciousness_card.dart._handleFastingPrimaryTap` — botón
  principal "Iniciar Ayuno" de la card del pilar Ayuno.

## 6. Pendiente / seguimiento

- Los flujos de `startFastingManual(horaElegida)` ("viaje en el tiempo",
  usado también para testing) NO tienen esta advertencia todavía. Son
  multi-paso (abren un TimePicker) así que el riesgo de toque accidental
  es menor, pero el mismo problema de fondo aplica si el usuario elige
  una hora posterior a comidas ya registradas. Candidato para una
  iteración futura si se repite el reporte.
- `FastingPromptSheet` (`lib/src/features/nutrition/presentation/fasting_prompt_sheet.dart`)
  está definido pero NO se invoca desde ningún lado (código muerto) — se
  documenta acá por si en el futuro se retoma esa idea (prompt tras
  registrar la última comida del día), para que el mismo aviso se integre
  ahí también.
- Los ~7 segundos de diferencia entre algunos ciclos del historial no se
  investigaron a fondo (no bloquean este fix) — si Carlos confirma que
  NUNCA tocó el botón de ayuno tan seguido, valdría una ronda de
  diagnóstico dedicada a un posible doble-disparo del tap.

## 7. Verificación

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
rm -f .git/refs/remotes/origin/mvp-core-clean.lock
git push origin mvp-core-clean
flutter analyze
flutter test test/features/nutrition test/features/dashboard
```

Reproducción manual: registrar 1+ comidas, tocar "Iniciar Ayuno" — debe
aparecer el diálogo de aviso antes de arrancar el ciclo nuevo. Cancelar
debe dejar todo intacto; confirmar debe iniciar el ayuno normalmente.
