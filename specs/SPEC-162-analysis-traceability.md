# SPEC-162 — Análisis como trazabilidad + causa-efecto

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Reescritura conceptual completa de Análisis
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 4-6 horas (esta sesión foco en Fase 1)
**Marco normativo:** `CONSTITUTION.md`. Retira los widgets snapshot (SPEC-152 a 161) del flujo principal.

---

## 1. Contexto

Carlos verbalizó el 2026-06-02 el problema real de la pantalla Análisis después de varias iteraciones (SPEC-152 a 161):

> "No estamos siendo claros con el usuario, si uno abre Análisis se pierde. Veo números pero no entiendo qué me está pasando ni qué hago al respecto. El deber ser de Análisis es poder hacer trazabilidad de mis hábitos, de cómo he mejorado o empeorado mis hábitos y cómo eso afecta mis resultados."

Las SPECs anteriores intentaron resolver UX (8 cards → 3 tabs → refinamiento visual) sin tocar el modelo conceptual. El problema es de **propósito**: Análisis necesita responder tres preguntas, no exponer datos.

## 2. Propósito reformulado

**Análisis = trazabilidad de hábitos + efecto en resultados.**

Tres preguntas concretas que debe responder:

1. **¿Cómo han evolucionado mis 5 hábitos en el tiempo?** (los 5 pilares como inputs longitudinales — no "esta semana")
2. **¿Cómo han cambiado mis resultados — IMR, peso, composición — en el mismo lapso?**
3. **¿Qué hábito impulsó qué resultado?** (causa-efecto detectada por el sistema)

Todo sobre el **mismo eje X (tiempo)**, con un único selector de rango temporal que aplica a toda la pantalla.

## 3. Decisión de diseño

### 3.1 — Una sola vista lineal (sin tabs)

Reemplaza la pantalla actual con 3 secciones apilables sobre el mismo eje temporal:

**Bloque 1 — Tus resultados:** IMR + Peso longitudinales con tendencia.
**Bloque 2 — Tus hábitos:** 5 sparklines de los pilares oficiales.
**Bloque 3 — Insights detectados:** patrones causa-efecto que el motor encuentra cruzando bloques 1 y 2.

### 3.2 — Selector temporal único

Chips horizontales arriba: `30d  3m  6m  1a  Todo`. Default: 3 meses (suficiente para detectar patrones, no abruma al inicio).

### 3.3 — Granularidad de las series: semanal

Las series usan agregación semanal:
- **30 días** → 4-5 puntos
- **3 meses** → 13 puntos
- **6 meses** → 26 puntos
- **1 año** → 52 puntos
- **Todo** → todas las semanas con data

Semana ISO (lunes-domingo). Si una semana tiene 0 logs de la métrica, se omite (no se rellena con 0 — falsearía la tendencia).

### 3.4 — Estado "arrancando" (< 30 días de data)

Si el usuario tiene menos de 30 días con cualquier registro, la vista muestra:
- Mensaje explicativo
- Progreso "12 de 30 días"
- Snapshot mínimo (IMR + peso actual + mejor/peor pilar)

Sin trazabilidad ni insights — el motor no detecta patrones con poca data.

### 3.5 — Patrones que detecta el motor (`CausalInsightDetector`)

| Tipo | Disparador | Ejemplo de copy | Cita |
|---|---|---|---|
| `sustainedImprovement` | Hábito X subió ≥20% en 4-8 sem **y** outcome Y mejoró | "Subiste tu ayuno de 3 a 5 d/sem en abril. Tu IMR pasó de 52 a 67." | Mattson 2017 + Sutton 2018 |
| `criticalDrop` | Hábito X cayó ≥20% en 2-4 sem | "Tu ejercicio cayó 4 semanas seguidas. Esperá retroceso en composición." | AHA 2018 + Mattson 2017 |
| `bestPeriod` | Mejor tramo del outcome (IMR o peso) en el rango + hábito X estuvo alto | "Tu mejor IMR fue 8–22 may. Coincide con tu mejor racha de sueño (7.4h, ★4)." | Walker 2017 |
| `convergence` | 2+ hábitos mejoran simultáneamente con outcome mejora | "Sueño + nutrición ambos subieron en abril. -1.8 kg en mayo." | Mattson 2017 |
| `dissociation` | Hábitos ≥70% pero outcome estancado o peor | "Tus hábitos están bien pero el peso no se mueve. WHTR cuenta — chequeá cintura." | Ashwell 2012 |
| `weeklyDrop` | Outcome bajó ≥X% en 1 semana **y** hábito X bajó misma semana | "Tu IMR cayó 18 puntos del 1 al 7 may. Hidratación bajó 35% esa semana." | Popkin 2010 |

El detector emite hasta 3 insights por render — los de mayor "fuerza" (delta + correlación). Si no detecta ninguno, muestra mensaje neutro: "Seguí registrando — Elena necesita más patrones para devolverte conclusiones."

### 3.6 — Drill-down al tocar un hábito (Fase 2)

Tap en un hábito del bloque 2 abre pantalla dedicada con:
- Dimensiones desagregadas (ej: sueño en duración + calidad por separado)
- "Efectos observados" — insights filtrados a ese hábito específico

**Out of scope para esta SPEC** (Fase 1). Se documenta acá para anclar el diseño futuro.

## 4. Cambios técnicos

### 4.1 — Capa domain

`lib/src/features/analysis/domain/time_series_point.dart`:
```dart
class TimeSeriesPoint {
  final DateTime weekStart;
  final double value;
  final int sampleCount;
}
```

`lib/src/features/analysis/domain/metric_series.dart`:
```dart
class MetricSeries {
  final String label;
  final String unit;
  final List<TimeSeriesPoint> points;
  final double? initialValue;
  final double? currentValue;
  double? get delta;
}
```

`lib/src/features/analysis/domain/causal_insight.dart`:
```dart
enum CausalInsightType { sustainedImprovement, criticalDrop, bestPeriod,
                         convergence, dissociation, weeklyDrop }

class CausalInsight {
  final CausalInsightType type;
  final String headline;
  final String detail;
  final String citation;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double strength; // 0..1 — el detector ordena por esto
}
```

`lib/src/features/analysis/domain/analysis_range.dart`:
```dart
enum AnalysisRange { d30, m3, m6, y1, all }

extension on AnalysisRange {
  int? get daysFromToday;
  String get label;
}
```

### 4.2 — Capa application

**`WeeklyAggregator`** (pure Dart, `lib/src/features/analysis/application/weekly_aggregator.dart`):
- `aggregateByWeek<T>(logs, weekOfFn, valueFn, agg) → Map<weekStart, double>`
- Soporta agregaciones: `sum`, `avg`, `count`, `lastValue`.

**Series builders** — cada uno toma logs/docs + range → `MetricSeries`:
- `imrSeriesProvider` — IMR semanal promedio de `daily_summary`.
- `weightSeriesProvider` — peso semanal último de `biometric_history`.
- `fastingHabitSeriesProvider` — % de días cumplidos por semana (fastingProgress ≥ 0.95).
- `nutritionHabitSeriesProvider` — % A-dominante por semana.
- `hydrationHabitSeriesProvider` — % vs target diario promediado por semana.
- `exerciseHabitSeriesProvider` — minutos promedio por día, agregados semanalmente.
- `sleepHabitSeriesProvider` — horas promedio + calidad promedio por semana.

**`CausalInsightDetector`** (pure Dart, `lib/src/features/analysis/application/causal_insight_detector.dart`):
- `detect(habits, outcomes) → List<CausalInsight>` ordenado por `strength` descendente, top 3.
- Implementa los 6 tipos del §3.5.

**`causalInsightsProvider`** combina las 7 series y delega al detector.

**`analysisRangeProvider`** (`StateProvider<AnalysisRange>`) — selector global.

### 4.3 — Capa presentation

**`analysis_screen.dart`** — reescritura completa, sin TabBar/TabController:
- AppBar con título + calendario.
- Chip selector temporal.
- `InsufficientDataView` si <30 días, sino:
  - `ResultsBlock` (IMR + Peso con sparklines + delta).
  - `HabitsBlock` (5 hábitos con sparkline + delta + tap para drill-down — placeholder en Fase 1).
  - `InsightsBlock` (lista de `CausalInsight` con icono + headline + detail + cita).
- BottomNavigationBar sin cambios.

**Widgets nuevos:**
- `sparkline_chart.dart` — CustomPaint genérico, recibe `List<TimeSeriesPoint>` + color.
- `range_selector_chips.dart` — chips horizontales con state global.
- `metric_row.dart` — fila reusable (label + valor + delta + sparkline).
- `insight_card.dart` — card de un `CausalInsight` (icono por tipo + headline + detail + cita).
- `insufficient_data_view.dart` — vista §3.4.

### 4.4 — Widgets retirados del flujo principal

Los siguientes widgets se mantienen en disco pero **no se montan en la pantalla nueva**:
- `WeeklyCoachingCard` (SPEC-153)
- `GoalsProgressDashboard` (SPEC-154) — quizás se mueve a Dashboard, fuera de scope SPEC-162
- `CyclesHistoryCard` (SPEC-156) — accesible via drill-down de Ayuno (Fase 2)
- `MealsRatioCard` (SPEC-158) — via drill-down de Nutrición (Fase 2)
- `SleepQualityCard` (SPEC-159) — via drill-down de Sueño (Fase 2)
- `HydrationWeeklyCard` (SPEC-161) — via drill-down (Fase 2)
- `ExerciseWeeklyCard` (SPEC-161) — via drill-down (Fase 2)
- `BodyCompositionTrendChart` (SPEC-152+157) — sus métricas viven en bloque 1 directamente
- `PeriodHeroCard` (SPEC-113) — su info vive en bloque 1
- `ImrTrendChart` (SPEC-113) — se convierte en parte de bloque 1
- 3 widgets de tabs (SPEC-160) — se eliminan, no hay tabs

Lo que conservamos del trabajo previo: **providers, repositorios, lógica de coaching y citas**. La capa data sigue igual.

## 5. Criterios de aceptación

1. Al abrir Análisis, si el usuario tiene ≥30 días de data, ve Resultados + Hábitos + Insights con el rango seleccionado.
2. Si tiene <30 días, ve `InsufficientDataView` con snapshot mínimo.
3. El chip selector cambia el rango y todos los gráficos refrescan en consecuencia.
4. Cada métrica muestra delta vs inicio del rango.
5. Sparklines son CustomPaint reales con color por categoría.
6. El detector emite hasta 3 insights con citas. Si no detecta, mensaje neutro.
7. Tests cubren `WeeklyAggregator` y `CausalInsightDetector` (~15 casos cada uno).

### 5.1 — Sobre tests

Pure Dart. Sin widget test. El detector se testea con series sintéticas que disparen cada tipo de patrón.

## 6. Out of scope

- **Drill-down de hábitos:** Fase 2 (SPEC-162.1).
- **Selector temporal personalizado** (fechas custom): Fase 2.
- **Exportar reporte:** futura SPEC.
- **Comparativa side-by-side de 2 períodos:** futura SPEC.
- **Movimiento de WeeklyCoaching y Goals al Dashboard:** SPEC separada si se decide.
- **Eliminar widgets retirados del disco:** se mantienen mientras estén accesibles vía drill-down futuro.

## 7. Rollout

Sin breaking changes (los widgets viejos no se borran, solo se desmontan). Sin migración. Push directo + validación visual.

## 8. Changelog

### v1.0 — 2026-06-02

Reescritura conceptual tras articulación clara de Carlos sobre el propósito real de Análisis. Cierra el ciclo de iteraciones UX (SPEC-152 a 161) atacando el modelo, no la presentación.
