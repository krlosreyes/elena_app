# SPEC-261.2 — Estrategia de usabilidad del Protocolo de Consumo Consciente

## Problema que corrige
La primera implementación (SPEC-261) construyó el **motor** (registro, cálculo,
impacto) y expuso capacidades sueltas en el notifier (`setBudget`,
`advancePhase`, `computeLastCall`) que **ningún flujo invocaba**. Había máquina
sin recorrido. Este spec define el viaje del usuario y conecta esas capacidades.

## Principio
Un **viaje guiado, lineal y contextual**. En cada fase la app muestra **una**
acción principal y avanza sola con las señales obvias. Reducción de daño: sin
moralizar, opt-in, honesto con el costo.

## Máquina de estados (fase)
`inactive → antes → durante → después → recuperación → (cerrar) → inactive`

| Transición | Disparador |
|---|---|
| inactive → antes | Botón **Activar protocolo** |
| antes → durante | Botón **Empezar a registrar** *o* registrar el 1er trago (auto) |
| durante → después | Botón **Terminé por hoy** |
| después → recuperación | Botón **Buenas noches** |
| recuperación → inactive | Botón **Cerrar protocolo** / acción **Cerrar** del AppBar |

El indicador de fase (stepper) es visible siempre que la sesión está activa.

## Fases

### A · Antes (preparación, ~30 s)
- **Meta de la noche**: slider 1–8 UEA → `setBudget`.
- **Hora de dormir**: time picker → `setBedtime`, que calcula y muestra el
  **último trago sugerido** (`bedtime − 3 h`).
- **Preparación**: toggles hidratación y comida → `setHydratedBefore`,
  `setAteBefore` (alimentan el factor de mitigación).
- CTA: **Empezar a registrar**.

### B · Durante (en vivo)
- **Resumen**: UEA vs meta, gramos, "tiempo para volver a cero", impacto.
- **Banner de último trago**: cuenta regresiva a `lastCallTarget`; cuando pasa,
  cambia a aviso de cierre.
- **Registro**: catálogo por categorías (chips de un toque) + lista con
  **deshacer**. Nudge 1:1 (agua por trago) en el resumen.
- CTA: **Terminé por hoy**.

### C · Después (cierre de la noche)
- **Riesgo de sueño** (`sleepRisk`): none / bajo / alto según último trago vs
  hora de dormir, con mensaje sin juicio.
- Recordatorios: agua + electrolitos; margen antes de dormir.
- CTA: **Buenas noches**.

### D · Recuperación (día siguiente)
- Toggle **ayuno de recuperación** → `setRecoveryFastPlanned`.
- Tips: hidratación, movimiento ligero (no intenso), autofagia.
- **Nota honesta de IMR**: puntos que costó la noche al Score del Día.
- CTA: **Cerrar protocolo**.

## Entrada al viaje
- `AlcoholProtocolCard` (dashboard) aparece en franja social o si la sesión está
  activa → navega a `/protocolo-alcohol`.

## Nivel de guía (decisión: guiada y contextual)
- Auto-avance en la señal obvia (1er trago → Durante). El resto de transiciones
  son un toque en la CTA principal, no un menú de fases.
- Nudges **en pantalla** por ahora (1:1, último trago, riesgo de sueño).

## Fuera de alcance en esta tanda (siguientes incrementos)
- **Nudges push** vía `NotificationScheduler` (recordatorio de agua, "tu último
  trago es en 20 min", empujón de recuperación matutino).
- **Auto-avance por reloj** a Después/Recuperación (hoy son manuales por CTA).
- Enriquecer el **trigger** con historial personal (hoy usa franja horaria).
- Persistir la sesión como documento `ConsumoSession` (hoy los metadatos de fase
  son estado local; los tragos sí persisten).
- Enganche del costo al **IMR longitudinal** canónico (hoy solo Score del Día).
