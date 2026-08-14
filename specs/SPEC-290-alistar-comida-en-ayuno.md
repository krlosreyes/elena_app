# SPEC-290 — Alistar la comida durante el ayuno (dejar de bloquear el pilar)

**Estado:** IMPLEMENTED (UI). PENDIENTE analyze/simulador de Carlos.
**Fecha:** 2026-08-13
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Problema (feedback de Carlos)

Durante el ayuno, el pilar de Alimentación se bloqueaba entero (card atenuada + diálogo "termina tu ayuno para registrar"). Eso impide justo lo útil: **prever y alistar** lo que se comerá al abrir la ventana.

## 2. Investigación

Apps de ayuno (Window, Just Fast, Zero) muestran una **cuenta regresiva de la ventana** y dejan **planear/preparar** la comida durante el ayuno; el "comer/registrar" es lo que espera a la ventana. Alineamos a ese patrón.

## 3. Cambio

- `fasting_status.dart`: getters `eatingWindowOpensAt` y `timeUntilWindowOpens`.
- `comidas_pillar_card.dart` (dashboard): en ayuno YA NO se atenúa ni se abre diálogo de bloqueo. Nuevo `_PrepDuringFastBanner` (verde) que invita a alistar y muestra "tu ventana abre en {Xh Ym}" + acceso "Ver ayuno". La tarjeta "Tu próxima comida" se reencuadra como **"Al abrir tu ventana"** (con el tiempo restante) y queda **habilitada** (ver plato, ingredientes, preparación, cambiar, agregar). Botón "Alistar mi comida".
- `meal_plan_screen.dart` (Minuta): durante el ayuno se puede ver/cambiar/editar/agregar; el ciclo **Comí/Cambié/Me salté** se reemplaza por un aviso `_FastingMealHint` ("podrás marcarla cuando abra tu ventana"). Solo se gatea el marcar/comer, no la preparación.

`meals_locked_dialog.dart` queda huérfano (ya no se usa) — se puede borrar en una limpieza.

## 4. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/dashboard lib/src/features/nutrition/presentation/meal_plan_screen.dart lib/src/features/fasting/domain/fasting_status.dart
```

Simulador: con ayuno activo → dashboard: banner verde "alistar", tarjeta "Al abrir tu ventana (en Xh)" abrible; Minuta: platos editables, sin ciclo Comí, con aviso. Al terminar el ayuno → vuelve el ciclo normal.
