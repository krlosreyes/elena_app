# SPEC-103 — Color del progreso por estado + fondo día/noche en el reloj

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** UX visual + comunicación de estado
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §3 (cronograma 24h).

---

# 1. Contexto

Dos problemas visuales reportados por Carlos en el `CircadianClock`:

1. **Color ambiguo del arco activo.** Hoy el arco que muestra el progreso del ayuno usa `phaseColor` que varía según la fase: azul → naranja → verde → indigo. Cuando el ayuno está en fase **transition** (12-18h), el arco se pinta NARANJA — exactamente el mismo color que la ventana de alimentación. El usuario no puede distinguir si está viendo ayuno o ventana.

2. **No hay comunicación de día/noche en el reloj.** El usuario ve un reloj de 24h con marcas horarias y fases circadianas, pero el fondo es uniforme. No hay anclaje visual al ritmo natural sol/luna. El reloj se siente "neutro" cuando debería "respirar" con el ciclo solar.

# 2. Solución propuesta

**2.1 Arco activo con color fijo por estado.**

- **Ayuno activo** (`fastingState.isActive == true`) → arco SIEMPRE verde (`AppColors.metabolicGreen`). La fase ya no afecta el color.
- **Ventana de alimentación** → arco NARANJA (ya lo hace el `EatingWindowPainter`).

La información de fase se sigue comunicando por:
- Hitos visuales en la barra (`water_drop` 12h, `fire` 18h, `recycle` 24h) — ya implementado en `FastingRingPainter`.
- Etiqueta "Estado actual: <fase>" en el card de Ayuno (de SPEC-101).

**2.2 Fondo día/noche con SweepGradient sutil.**

En `BiologicalCyclesPainter`, antes de pintar marcas y fases, pintar un disco de fondo con un `SweepGradient` rotado para que empiece en 00:00 (norte, `-π/2`). Paradas:

| Hora | Color | Alpha | Interpretación |
|---|---|---|---|
| 00:00 - 04:00 | `#1E3A8A` (azul profundo) | 0.07 | Noche profunda |
| 06:00 | `#FBBF24` (amarillo cálido) | 0.05 | Amanecer (pico de cortisol según `CIRCADIAN_BIBLIOGRAPHY.md` §3) |
| 10:00 | `#FEF3C7` (cremoso) | 0.05 | Día (pico cognitivo) |
| 14:00 | `#FEF3C7` (cremoso) | 0.05 | Día (pico físico) |
| 18:00 | `#F97316` (naranja suave) | 0.05 | Atardecer (presión arterial pico) |
| 22:00 - 24:00 | `#1E3A8A` (azul profundo) | 0.07 | Noche / bloqueo intestinal |

Alpha bajo (0.05-0.07) para que NO compita con el arco activo, las fases ni el IMR central. La transición entre tonos es suave por la interpolación del gradient.

El disco se pinta en el área entre el centro y el anillo de fases, así no tapa nada de las capas superiores.

# 3. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Cambiar `phaseColor` a verde fijo en `circadian_clock.dart` | `circadian_clock.dart` |
| 2 | Eliminar `_getPhaseColor` (queda muerto) | `circadian_clock.dart` |
| 3 | Agregar `_drawDayNightBackground` en `BiologicalCyclesPainter` | `biological_cycles_painter.dart` |
| 4 | Verificar que no rompe la jerarquía visual | smoke en device |

# 4. Criterios de aceptación

1. Con ayuno activo en cualquier fase (postAbsorption / transition / fatBurning / autophagy), el arco del progreso es verde.
2. Con ventana de alimentación activa, el arco es naranja.
3. El reloj tiene un fondo sutil que indica día (zona inferior) vs noche (zona superior).
4. El fondo NO interfiere con la lectura del arco activo, marcas horarias, fases circadianas ni IMR central.
5. `flutter analyze` y `flutter test` sin regresiones.

# 5. Riesgos

**5.1 Alpha demasiado alto se ve invasivo.**
Mitigación: empezar en 0.05-0.07. Si en device se ve agresivo, bajar a 0.04. Fácil de iterar visualmente.

**5.2 Cambio de color del arco rompe la asociación visual con la fase.**
Mitigación: el card de Ayuno ya muestra "Estado actual: <Cetogénesis temprana>" via SPEC-101. La fase sigue siendo comunicada — solo no por el color del arco.

**5.3 El gradient agrega cómputo en cada frame.**
Mitigación: el `BiologicalCyclesPainter` tiene `shouldRepaint` que solo se invalida si cambia hora/minuto. Costo despreciable.

# 6. Out of scope

- Animación del fondo en transición de hora (sería overhead innecesario).
- Toggle "Tema Solar Sutil" en settings.
- Diferenciar verano/invierno por latitud.
- Modo día (light theme) — la app es dark-only.

# 7. Resultado

(Se completa al cerrar el SPEC.)
