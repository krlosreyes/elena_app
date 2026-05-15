# SPEC-97 — Corrección de hora de inicio de ayuno sin romper el intervalo

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Bug fix funcional MVP
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §2 (cronología del ayuno), SPEC-96 (coherencia).

---

# 1. Contexto

El botón "Corregir hora de inicio" del card "Ayuno Consciente" (Dashboard, pilar Ayuno) está cableado a `_showManualTimePicker(context, ref, isFeeding: false)`. Su intención de producto es permitir al usuario que arrancó un ayuno tarde editar la hora real de inicio (ej. "Empecé a las 18:00 pero abrí la app a las 19:00").

Reporte de Carlos: al tocar el botón mientras hay ayuno activo, la app **cierra el ayuno y abre una ventana de alimentación** con la hora pickeada como `startTime` de la ventana. Comportamiento totalmente contrario a la intención.

# 2. Problema

`dashboard_screen.dart:1271`:

```dart
if (isFeeding) {
  ref.read(fastingProvider.notifier).confirmFeedingEnd(finalDateTime);
} else {
  if (fastingState.isActive) {
    // ❌ Esto NO corrige la hora de inicio.
    // confirmManualFastingEnd transita el storage a isFasting=false,
    // crea un nuevo FastingInterval con isFasting=false y
    // startTime=finalDateTime, lo cual ABRE ventana de alimentación.
    ref.read(fastingProvider.notifier).confirmManualFastingEnd(finalDateTime);
  } else {
    ref.read(fastingProvider.notifier).startFastingManual(finalDateTime);
  }
}
```

Tres defectos:

**2.1 `confirmManualFastingEnd` está mal nombrado para este uso.**
Su semántica es "finaliza el ayuno con esa hora" (cierra el intervalo de ayuno + crea uno de ventana de comida + agenda notification de cierre). El botón "Corregir hora de inicio" la invoca como si fuera "actualiza el startTime del intervalo activo".

**2.2 Caso bordeline "no hay ayuno activo".**
Hoy el botón aparece igual cuando `isActive==false`. En esa rama llama a `startFastingManual` que SÍ inicia un ayuno con hora retroactiva — comportamiento OK, pero el label "Corregir hora de inicio" es confuso porque no hay nada que corregir.

**2.3 Falta una operación pura `updateLastIntervalStartTime`.**
El repo solo expone `transitionTo` que abre/cierra intervalos. No hay forma de mutar el `startTime` del último intervalo en su lugar.

# 3. Solución propuesta

**3.1 Nueva operación a nivel data source.**

`FastingIntervalDataSource.updateLastIntervalStartTime({uid, newStartTime})`:
- Busca el doc más reciente del usuario.
- Si existe y está abierto (`endTime == null`): actualiza solo `startTime`.
- Si no existe o ya está cerrado: lanza `StateError` ("no hay intervalo abierto que corregir") — el caller debe verificar antes.

**3.2 Repo expone `correctOpenIntervalStartTime({uid, newStartTime})`.**

Delega al data source. Es una operación distinta a `transitionTo` (no abre/cierra; muta).

**3.3 `FastingNotifier.correctStartTime(DateTime newStart)`.**

- Verifica `state.isActive == true`. Si no, no-op (defensivo).
- Verifica `newStart < now` y `newStart > now - 24h` (rango sano).
- Llama a `repo.correctOpenIntervalStartTime`.
- Actualiza el state local con `startTime: newStart` y `duration: now - newStart`, recomputa `phase` con la nueva duración.
- Reagenda notifications de hitos de ayuno (12h, 18h, 24h) desde el nuevo `startTime`.

**3.4 Cambios UI en `dashboard_screen.dart`.**

- Botón "Corregir hora de inicio" **solo aparece si `fastingState.isActive == true`**.
- Su `onPressed` llama a una función nueva `_showCorrectStartTimePicker` que:
  - Abre date+time picker con `initialTime = state.startTime`.
  - Valida rango (entre `now - 24h` y `now`).
  - Si la nueva hora cae fuera del óptimo (SPEC-96), muestra snackbar informativo.
  - Llama a `correctStartTime(newDateTime)`.
- Renombra label si está activo: "Corregir hora de inicio del ayuno".

**3.5 Eliminar la rama `else > else` confusa.**
`_showManualTimePicker` queda solo para el flujo de "Finalizar ayuno con hora manual" (botón rojo cuando isActive=true) y "Iniciar ayuno con hora pasada" (caso futuro no MVP). El nuevo `_showCorrectStartTimePicker` es independiente.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Agregar `updateLastIntervalStartTime` al contrato | `lib/src/features/dashboard/data/sources/fasting_interval_data_source.dart` |
| 2 | Implementar en Firestore v1 source | `lib/src/features/dashboard/data/sources/firestore_fasting_interval_v1_source.dart` |
| 3 | Agregar `correctOpenIntervalStartTime` al repo (contrato + impl) | `domain/fasting_interval_repository.dart` + `data/fasting_interval_repository_impl.dart` |
| 4 | Agregar `correctStartTime` al notifier | `lib/src/features/dashboard/application/fasting_notifier.dart` |
| 5 | Refactor UI del card de ayuno: botón condicional + handler nuevo | `lib/src/features/dashboard/presentation/dashboard_screen.dart` |
| 6 | Test del notifier con fake repo | `test/features/dashboard/application/fasting_notifier_correct_start_time_test.dart` |

# 5. Criterios de aceptación

1. Tocar "Corregir hora de inicio" con ayuno activo → modifica el `startTime` del intervalo actual SIN cerrarlo.
2. El intervalo persistido en Firestore conserva `isFasting=true` y NO tiene `endTime`.
3. El `duration` del state se recalcula con la nueva hora.
4. La fase de ayuno (`postAbsorption / transition / fatBurning / autophagy`) se recomputa.
5. Las notifications de hitos (12h/18h/24h) se reagendan desde el nuevo `startTime`.
6. El botón NO aparece si `isActive == false`.
7. Hora pickeada > `now` → snackbar "La hora no puede ser futura" y no se guarda.
8. Hora pickeada < `now - 24h` → snackbar "Hora demasiado antigua, máximo 24h atrás" y no se guarda.
9. Hora pickeada fuera del óptimo del protocolo (SPEC-96) → guarda + snackbar warning no bloqueante.
10. `flutter analyze` sin issues nuevos. `flutter test` mantiene ≥522 verdes + tests nuevos.

# 6. Pruebas

`fasting_notifier_correct_start_time_test.dart`:
- Setup: notifier con ayuno activo (startTime = now - 2h, isActive=true).
- Caso happy: `correctStartTime(now - 5h)` → `state.startTime == now - 5h`, `state.duration ≈ 5h`, `phase == fatBurning` (si umbral 18h-24h adaptado por la nueva duración → en este caso seguiría `postAbsorption` por <12h, ajustar test).
- Caso defensivo: `state.isActive == false` → llamada es no-op, state no cambia.
- Caso bordeline: `correctStartTime(now + 1h)` → no-op + (idealmente) excepción que el caller traduce a snackbar.
- Caso boundary: `correctStartTime(now - 25h)` → no-op.

(Los tests de UI / integration con Firestore real quedan fuera; el repo se mockea.)

# 7. Riesgos

**7.1 Documento de Firestore se mueve por orden de `startTime`.**
`streamLatest` ordena `descending` por `startTime`. Si el usuario corrige el `startTime` a una hora MUY pasada, ese doc podría dejar de ser "el más reciente" si tiene otros docs con `startTime` mayor. Mitigación: `updateLastIntervalStartTime` busca el último doc **abierto** (endTime null), no el más reciente por startTime. Eso garantiza que se mute el correcto.

**7.2 Reagendar notifications puede dejar duplicados.**
`NotificationScheduler.scheduleFastingMilestones` debe cancelar las anteriores antes de programar las nuevas. Verificar y ajustar si no lo hace ya.

**7.3 Cambio de hora cruza fase de ayuno.**
Si el usuario estaba en fase `transition` (12-18h) y corrige a una hora que lo mueve a `fatBurning` (18-24h), la UI debe reflejar el cambio inmediatamente. Como `phase` se recalcula desde `duration`, esto pasa automáticamente.

**7.4 Coherencia con SPEC-96.**
Si el usuario corrige a una hora que rompe coherencia circadiana (ej. inicia ayuno a las 03:00 cuando su protocolo 18:6 sugiere 20:30), la app NO bloquea — solo muestra warning. Bloquear sería paternalista en una corrección retroactiva.

# 8. Out of scope

- "Iniciar ayuno retroactivamente cuando no hay ayuno activo" (Carlos confirmó: el botón solo aparece con ayuno activo en MVP).
- Editar la hora de fin de un ayuno ya cerrado (historial).
- Editar la hora de inicio de una ventana de comida (otro SPEC potencial).
- Auditoría de cambios manuales (registro de quién y cuándo editó qué — out of scope MVP).

# 9. Resultado

(Se completa al cerrar el SPEC.)
