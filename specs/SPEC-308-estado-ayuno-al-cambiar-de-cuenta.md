# SPEC-308 — Estado del ayuno al cambiar de cuenta

Estado: IMPLEMENTED (27-nov-2026) · Versión: Elena 1.0.1

## Problema (reproducido en el simulador)
Cuenta nueva, primer uso: Hoy mostraba "Ventana abierta · abrió 7:33" y el ayuno al 100 %.

## Causa raíz
1. `FastingState.copyWith(startTime: null)` no borraba nada (`startTime ?? this.startTime`). Los tres sitios que intentaban limpiar la hora de inicio no la limpiaban.
2. `fastingProvider` sobrevive al cierre de sesión. La cuenta nueva heredaba hora de inicio, `completedToday` y `closedProgressToday` de la anterior.

## Cambios
- `copyWith(clearStartTime: true)` para borrar de verdad.
- Sin ningún intervalo de ayuno: también `completedToday = false` y `closedProgressToday = 0`.
- Al cambiar el uid de la sesión, el estado del ayuno se reinicia.
