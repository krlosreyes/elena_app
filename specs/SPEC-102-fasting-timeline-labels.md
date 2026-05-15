# SPEC-102 — Etiquetas sutiles de inicio/fin en el progress del ayuno

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Mejora UX
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §6 (Regla 2 "desmitificar el vacío").

---

# 1. Contexto

El card "Ayuno Consciente" muestra el timer corriendo (`12:24:19`), el protocolo (`18:6`), una barra lineal de progreso y `69% completado`. El usuario NO ve la hora real de inicio ni la hora estimada de fin. Si abrió la app a las 06:00 y su 18:6 termina a las 12:00, no tiene un anclaje temporal absoluto.

Carlos pidió: investigar buenas prácticas y mostrar hora de inicio y fin "de una manera coherente que no sea invasiva y que cumpla con el objetivo de informar. Muy sutil."

# 2. Patrones investigados

| Patrón | Apps que lo usan | Veredicto |
|---|---|---|
| Etiquetas en los extremos de la barra | Apple Health (Mindful Minutes), Google Fit Sleep, Oura, Whoop, Strava | ✅ Mejor — visualmente ancla las horas a la geometría del progreso |
| Subtitle inline "% · 18:00→12:00" | Notion timestamps | ⚠️ Verbose, ambiguo cross-day |
| Tooltips en hitos del progress | Headspace, Calm | ❌ Requiere interacción |
| Caption relativo "iniciado hace Xh" | Twitter/X, Slack | ❌ Pierde la hora absoluta |
| Etiquetas con flecha "→" | Spotify Wrapped | ⚠️ Bonito pero verbose |

# 3. Solución

Fila pequeña justo debajo de la barra de progreso con:
- Izquierda: `HH:mm` del `state.startTime`.
- Derecha: `HH:mm` de `state.startTime + targetHours` + sufijo `·mañana` si cae al día siguiente.
- Estilo: `Colors.white` con alpha 0.45, fontSize 10, fontWeight w600, letterSpacing 0.4.
- Solo aparece cuando hay ayuno activo (`state.isActive == true`).

Helper privado `_buildFastingTimeline` en `dashboard_screen.dart`. Otro helper `_formatHHmm`.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Agregar fila timeline bajo la barra de progreso | `dashboard_screen.dart` |
| 2 | Helper `_buildFastingTimeline` y `_formatHHmm` | `dashboard_screen.dart` |

# 5. Criterios de aceptación

1. Cuando hay ayuno activo, debajo de la barra aparece `18:00` (izq) y `12:00` (der).
2. Si cruza día, el lado derecho muestra `12:00 ·mañana`.
3. Texto con alpha 0.45 — visible pero no compite con el timer principal.
4. Cuando NO hay ayuno activo, el card NO muestra esta fila.
5. Al corregir la hora de inicio (SPEC-97), las etiquetas se actualizan reactivamente.
6. `flutter analyze` y `flutter test` sin regresiones.

# 6. Riesgos

**6.1 Cross-day se ve mal en formato 12h.**
La app usa 24h (`HH:mm`). Si en el futuro se localiza a inglés con AM/PM, hay que revisar. Out of scope.

**6.2 Si el targetHours cambia mientras hay ayuno activo.**
SPEC-98 lo bloquea. Sin riesgo.

# 7. Out of scope

- Mostrar hora de fin durante la ventana de comida (el card sólo se renderea cuando hay ayuno; ventana usa otro layout).
- Indicadores de hitos (12h, 18h, 24h) en la barra — eso ya vive en el reloj circular del Dashboard.
- Animación al cambiar la hora.

# 8. Resultado

(Se completa al cerrar el SPEC.)
