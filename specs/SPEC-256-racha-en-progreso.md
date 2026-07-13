# SPEC-256 — Seguimiento visual de la racha en Progreso

**Estado:** IMPLEMENTED (2026-07-13) — ver §8 y §9 Notas de implementación
**Versión:** 1.2 — v2 del gráfico (barras) reemplazó al heatmap original tras feedback
**Líder:** Carlos · **Investigación y propuesta:** Claude
**Depende de:** SPEC-255 (racha comprensible y sostenible — ya implementado), SPEC-112 (calendario mensual), SPEC-113 (heatmap por pilar, hoy código muerto)
**Prioridad:** Media-alta — gap real de producto, no solo mejora cosmética (ver §1)
**Estimación:** ver §4

---

## 1. Diagnóstico: qué hay hoy (y un hallazgo colateral)

Se revisó el código para responder "¿hacemos seguimiento de la racha como debería ser?". Resultado: **la racha hoy solo existe como un número en tiempo real** (la flama del header, Dashboard) — no tiene ninguna vista histórica.

1. **`analysis_screen.dart` (pantalla "Progreso") no tiene ningún tile ni sección de racha.** El overview solo trae Score/IMR/Composición corporal + 5 tiles de hábito (ayuno, sueño, hidratación, ejercicio, comidas). Cero mención de racha.
2. **Hallazgo colateral — código huérfano:** `StreakSummaryCard` (el card con racha actual/récord/reservas, construido en SPEC-255 RF-01/RF-02) **no está montado en ningún árbol de widgets de la app** — confirmado por grep, cero instanciaciones. Se construyó asumiendo (por una memoria del proyecto de una sesión anterior) que vivía en Análisis, pero nunca se conectó. El ⓘ, el indicador de reservas y todo lo demás que se le agregó son invisibles para el usuario ahora mismo.
3. **Ya existe infraestructura de calendario reutilizable:** `MonthlyCalendarScreen` (SPEC-112) — grid mensual con mini-anillo de IMR por día, navegable con chevrons — pero solo pinta IMR, no si el día calificó para racha ni si fue protegido por una reserva (SPEC-255 RF-02).
4. **También existe `PillarsHeatmap` (SPEC-113)** — heatmap estilo GitHub por pilar — pero es **código muerto**: el propio comentario en `sleep_quality_card.dart` dice que fue reemplazado por `WeeklyCoachingCard` (SPEC-153) y nunca se borró.

En resumen: no falta "agregar una gráfica" desde cero — falta **conectar y consolidar** piezas que ya se construyeron dos veces y ninguna quedó visible.

## 2. ¿Es necesario el seguimiento visual? Sí — por qué

- **"Don't break the chain"** (la técnica que popularizó Jerry Seinfeld, difundida por Brad Isaac en Lifehacker 2007): el mecanismo motivacional NO es la racha en sí, es *verla* como cadena — la regla era literalmente tachar un calendario físico. Un contador numérico solo (lo que Elena tiene hoy) es una versión empobrecida del mismo principio.
- **Sesgo de consistencia** (Cialdini, *Influence*, 1984): comprometerse visualmente con una secuencia refuerza la identidad ("soy alguien que hace esto") más que un número aislado.
- **Aversión a la pérdida** (Kahneman/Tversky — ya es la base de SPEC-255): una cadena visible de 40 días duele más de romper que un "40" en una esquina de la pantalla. El efecto es más fuerte cuando SE VE la longitud, no solo se lee.
- **Por qué un heatmap y no solo un número más grande:** un heatmap comunica *patrón* (¿fallo los lunes? ¿rachas cortas que se repiten?) que un contador no puede. Por esto GitHub, Streaks, Way of Life y prácticamente toda app de hábitos moderna convergieron en el mismo formato de grid de calendario coloreado.

Nota de rigor: encontré cifras específicas tipo "+42% retención" / "+117% vs checkbox" en blogs de marketing sobre heatmaps de hábitos — **no las incluyo** porque no pude verificar el estudio original citado (el "British Journal of Health Psychology 2023" que citan no aparece en ninguna búsqueda directa). Me quedo con los mecanismos psicológicos verificables arriba, no con estadísticas no verificables — mismo estándar que ya aplica el proyecto en `IMR_BIBLIOGRAPHY.md`.

## 3. Propuesta

### RF-256-01 — Montar `StreakSummaryCard` en Progreso (quick win)

Cero código nuevo: ya existe, ya tiene ⓘ + indicador de reservas (SPEC-255). Agregarlo a `_buildContent()` en `analysis_screen.dart`, sección nueva "Tu racha" antes o después de "Hábitos". Complejidad trivial.

### RF-256-02 — Heatmap de racha, estilo GitHub (la pieza que falta de verdad)

Nueva sección debajo del `StreakSummaryCard`: grid de ~12 semanas (84 días — el historial de `streakProvider` ya trae 90) con una celda por día. Reutiliza el patrón visual de `PillarsHeatmap` (alpha proporcional a `dailyQualityScore`) pero a nivel de racha, no por pilar:

- Celda llena (verde) = día que calificó (`qualifiesForStreak`).
- Celda con borde punteado = sin registro ese día.
- Celda con un pequeño glyph de escudo (ámbar) = día perdonado por una reserva (SPEC-255 RF-02) — el dato ya existe, solo hay que exponerlo desde `StreakEngine`.
- Tap en una celda → mini tooltip/sheet con el detalle del día (pilares completados), reutilizando la lógica de `StreakEntry`.

### RF-256-03 (alternativa a RF-256-02, no ambas) — Extender el calendario mensual existente

En vez de un heatmap nuevo, agregar un segundo indicador (punto/borde de color) al `CalendarDayCell` del `MonthlyCalendarScreen` ya existente, superpuesto al anillo de IMR, marcando si ese día calificó para racha. Reusa más código, pero es mensual (corta la racha visualmente en cada cambio de mes) en vez de una cadena continua — menos fiel al principio "don't break the chain" de §2.

**Recomendación:** RF-256-02 (heatmap nuevo tipo GitHub). Es el patrón que la propia literatura de hábitos usa porque muestra la cadena de forma continua, y el esfuerzo real es bajo — la lógica de color ya existe en `PillarsHeatmap` (código muerto, se reutiliza en vez de reinventarse) y el freeze state ya lo calcula `StreakEngine`. RF-256-03 queda como alternativa de menor esfuerzo si Carlos prefiere no agregar un componente nuevo.

### RF-256-04 (housekeeping) — Borrar `pillars_heatmap.dart`

Confirmado código muerto (0 usos, reemplazado por SPEC-153). Si se aprueba RF-256-02, su lógica de color se migra al nuevo heatmap y el archivo original se elimina — evita dejar una tercera pieza huérfana en el repo.

## 4. Qué deliberadamente NO se propone

- **No un tercer lugar para la racha.** Ya se corrigió una duplicación real esta semana (ForYouSection en Dashboard + Análisis) — no repetir el patrón con la racha. Vive en Progreso (histórico); Dashboard mantiene solo el número en vivo, coherente con el propio comentario de cabecera de `analysis_screen.dart`: *"función de revisión histórica (NO motivacional — eso vive en Hoy)"*.
- **No RF-256-02 y RF-256-03 a la vez** — son dos formas de resolver lo mismo, elegir una.
- **No tocar `StreakEngine.computeCurrentStreakWithFreezes` ni la regla de qué califica** — esto es solo visualización sobre datos que ya se calculan bien (SPEC-255).

## 5. Mapa técnico (para cuando se apruebe — nada tocado en esta sesión)

| Archivo | Cambio |
|---|---|
| `features/analysis/presentation/analysis_screen.dart` | Montar `StreakSummaryCard` (RF-01) + nueva sección heatmap (RF-02) |
| `features/analysis/presentation/widgets/streak_heatmap.dart` | Nuevo — heatmap de racha, reutiliza paleta de `pillars_heatmap.dart` |
| `features/streak/domain/streak_engine.dart` | Exponer qué fechas están protegidas (ya calculado internamente en `computeCurrentStreakWithFreezes`, falta exponerlo como set público) |
| `features/analysis/presentation/widgets/pillars_heatmap.dart` | Eliminar (RF-04, código muerto) |

## 6. Estimación

RF-01: trivial (<1h). RF-02: baja-media (reutiliza paleta y datos existentes, ~1 día). RF-04: trivial. Total: menos de 2 días de trabajo real — la mayor parte ya estaba construida, solo desconectada.

## 7. Fuentes

- [The Heatmap Effect: How Habit Visualization Changes Behavior — NERVUS.IO](https://nervus.io/blog/heatmap-effect-habits) — mecanismos citados (Hawthorne, loss aversion, dopamina incremental); cifras de porcentaje NO usadas por no poder verificar la fuente primaria citada.
- [GitHub Style Habit Tracker with Visual Heatmaps — HabitHeat](https://habitheat.com/github-style-habit-tracker/)
- [How to Build a Habit Tracker Calendar Your Users Will Actually Love — RapidNative](https://www.rapidnative.com/blogs/habit-tracker-calendar)
- [STREAKS — The to-do list that helps you form good habits](https://streaksapp.com/)
- [7 Best Streak Tracker Apps in 2026 — Habi](https://habi.app/insights/best-streak-tracker-apps/)

## 8. Notas de implementación (2026-07-13)

Se implementó RF-256-01, RF-256-02 y RF-256-04. RF-256-03 (alternativa) no se hizo — se eligió RF-256-02 (heatmap nuevo), como recomendaba §3.

**RF-01:** `StreakSummaryCard` montado en `analysis_screen.dart`, nueva sección "Tu racha" al final del overview (después de Hábitos).

**RF-02:** Nuevo `lib/src/features/analysis/presentation/widgets/streak_heatmap.dart` — grid de 12 semanas × 7 días, estilo GitHub contribution graph, con scroll horizontal que arranca mostrando la semana actual (`reverse: true`). Celda llena = `qualifiesForStreak`; celda tenue proporcional a `pillarsCompleted/5` si hubo registro parcial; hueco con borde punteado si no hay registro; punto ámbar superpuesto si el día fue perdonado por una reserva.

Para pintar los días protegidos hubo que exponer esa información: `StreakEngine.computeCurrentStreakWithFreezes` (SPEC-255) calculaba internamente qué fechas quedaban protegidas pero nunca las devolvía — solo el conteo agregado. Se refactorizó extrayendo el "paso 1" (recorrido cronológico) a un helper privado compartido `_forwardPassProtection` (devuelve un record `({Set<String> protectedDates, int banked})`), y se agregó `StreakEngine.computeProtectedDates(history)` como función pública nueva que lo reusa. Cambio de comportamiento: ninguno — `computeCurrentStreakWithFreezes` sigue devolviendo exactamente lo mismo que antes, solo se movió el cuerpo del bucle a un método compartido.

**RF-04:** `pillars_heatmap.dart` eliminado (`git rm`) — confirmado código muerto (0 referencias reales, solo comentarios que lo mencionaban en `weekly_strip.dart`, `sleep_quality_card.dart`, `weekly_coaching_card.dart`, ninguno de los tres lo importa).

**No se tocó** ninguna regla de qué cuenta para la racha, ni `computeCurrentStreak` (el que alimenta IMR longitudinal) — esto fue puramente visualización sobre datos que ya existían.

**Sin tests nuevos** (mismo motivo que SPEC-255: no había tests previos de `analysis_screen.dart` en la porción de overview, ni de `streak_engine.dart` sobre los que apoyarse para esta pieza específica). `flutter analyze`/`test`/`build` pendientes de Carlos — sandbox sin SDK de Flutter.

**REDISEÑO v1 (2026-07-13, mismo día) — feedback directo: "esta gráfica es un asco, no comunica nada".** Screenshot real reveló 4 bugs concretos en la v1: (1) labels de día (L/X/V) desalineados de las celdas — vivían en dos `Column` hermanas con distinto ritmo vertical; (2) `SingleChildScrollView` + `Expanded` dejaba la mayor parte de la card vacía (12 semanas de celdas de 13px caben sobradas sin scroll); (3) labels de mes cortados ("ab"/"r") por muy poco ancho; (4) el degradado continuo de alpha para "registró pero no calificó" se veía como un café/oliva sucio sobre el fondo oscuro, no como "naranja tenue". Fix: una sola fila por día de semana (label y celdas en el mismo `Row`, imposible desalinear), `LayoutBuilder` calcula el tamaño de celda para llenar el ancho disponible sin scroll, columna de mes = celda+gap completos, y dos colores SÓLIDOS y distintos (naranja = calificó, gris pizarra = registró sin calificar) en vez de una mezcla continua. Se agregó también un anillo blanco sutil en la celda de "hoy" para orientar al usuario.

## 9. Cambio de tipo de gráfico (v2, mismo día): heatmap → barras

El fix de alineación/color de v1 **no fue suficiente** — feedback: "no mejoró nada, necesitamos otro tipo de gráfico". Diagnóstico de fondo (no un bug puntual esta vez): una grilla de celdas pequeñas tipo GitHub es un patrón visual **ajeno al lenguaje de esta app**. El resto de Análisis (los 8 tiles de detalle, `bar_chart_card.dart`/SPEC-163) usa consistentemente "barras + eje + línea de referencia" — un patrón que el usuario ya sabe leer en esta misma pantalla. Meter un segundo lenguaje visual (grilla de cuadraditos de color) para un solo widget nuevo obligaba al usuario a aprender un código nuevo, y en una card angosta de mobile las celdas de ~13-20px son intrínsecamente difíciles de comparar entre sí de un vistazo.

**Reemplazo:** `pillars_heatmap.dart` → borrado. `streak_heatmap.dart` → borrado. Nuevo `streak_bar_chart.dart`: gráfico de barras de 30 días, altura = pilares completados (escala fija 0-5, no dinámica — así "3" siempre cae en el mismo lugar), con una **línea de referencia horizontal punteada en 3** (el mínimo de racha). La lectura es directa: la barra cruza la línea o no la cruza, sin memorizar qué color significa qué. Naranja sólido = calificó, gris pizarra sólido = registró pero no llegó al mínimo, sin barra (solo un tick plano en la base) = sin registro ese día, punto ámbar sobre la barra = día perdonado por una reserva. Eje X con 3 labels (inicio del rango, mitad, "hoy").

Mismos datos que v1 (`streakProvider.history` + `StreakEngine.computeProtectedDates`), ningún cambio en la capa de dominio — esto fue puramente un cambio de widget de presentación.

Lección para memoria del proyecto: cuando una visualización nueva no sigue el lenguaje visual ya establecido en la misma pantalla, corregir bugs puntuales (alineación, color) no alcanza — el problema es la elección del tipo de gráfico en sí, no la implementación.
