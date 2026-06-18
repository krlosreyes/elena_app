# SPEC-230: Auditoría y Corrección de Gráficas de Análisis

**Status**: IMPLEMENTED  
**Prioridad**: HIGH — afecta coherencia visual de todas las gráficas  
**Fecha**: 2026-06-18  
**Origen**: Auditoría post SPEC-229 para blindar el módulo de análisis completo.

---

## 1. Contexto

Tras corregir los 5 bugs de score coherence (SPEC-229), se auditaron ~90 archivos del módulo de análisis (providers, widgets, mappers, domain models) para detectar bugs de la misma familia o de naturaleza diferente.

Se encontraron **6 bugs** adicionales: 2 críticos, 3 medios, 1 bajo.

---

## 2. Bugs Encontrados y Corregidos

### BUG-230-A: Hydration + Exercise bucketing en UTC (CRÍTICO)

**Archivos**: `analysis_series_providers.dart`, líneas 413 y 448  
**Categoría**: TIMEZONE

**Mecanismo**: `hydrationHabitSeriesProvider` y `exerciseHabitSeriesProvider` hacen un pre-agrupamiento por día usando `_dateIso(log.timestamp)`. Pero `log.timestamp` es UTC (Firestore `Timestamp.toDate()`). Para UTC-5, un log de hidratación a las 11pm local = 4am UTC del día siguiente → se agrupa en el día equivocado.

Nota: el fix de SPEC-229 BUG-E en `temporal_aggregator._bucketStart` NO protege estos providers porque el daño ocurre ANTES del aggregator, en el pre-agrupamiento `byDay`.

**Fix**: `_dateIso(log.timestamp.toLocal())`

---

### BUG-230-B: Sleep chart no reacciona a cambio de rango (CRÍTICO)

**Archivo**: `analysis_series_providers.dart`, línea 484  
**Categoría**: STALE-DATA

**Mecanismo**: `sleepHabitSeriesProvider` usaba `ref.read(analysisRangeStartProvider)` dentro del `await for` loop. Todos los demás providers (fasting, nutrition, hydration, exercise) usan `ref.watch` fuera del loop, lo que causa re-evaluación automática cuando el rango cambia. Sleep era el único que no lo hacía.

**Resultado visible**: El usuario cambia de "Semana" a "3 Meses" y la gráfica de Sueño no se actualiza hasta que llega un nuevo log de Firestore.

**Fix**: Mover a `ref.watch(analysisRangeStartProvider)` fuera del `await for`. También se simplificó el filtro a `!l.wokeUp.isBefore(rangeStart)` (era `isAfter || ==` con null check innecesario).

---

### BUG-230-C: sleepQualityScore sin high water mark (MEDIO)

**Archivo**: `streak_notifier.dart`, línea 287  
**Categoría**: HWM-VIOLATION

**Mecanismo**: Las 4 magnitudes (fasting, hydration, exercise, nutrition) usan `maxMag(prev, new)` para que nunca bajen dentro del día (patrón high water mark de SPEC-229). Pero `sleepQualityScore` usaba `sleepQualityScore ?? prev?.sleepQualityScore` — si llegaba un nuevo valor no-null más bajo, sobreescribía el pico.

**Fix**: `sleepQualityScore: maxMag(prev?.sleepQualityScore, sleepQualityScore)`

---

### BUG-230-D: TrendChart division by zero con 1 dato (MEDIO)

**Archivo**: `trend_chart.dart`, líneas 83 y 124  
**Categoría**: NULL-GUARD

**Mecanismo**: `width / (data.length - 1)` y `size.width / (data.length - 1)` producen Infinity/NaN cuando `data.length == 1`. La gráfica se rompe o no pinta nada.

**Fix**: 
- `_handleTouch`: early return si `data.length < 2`
- `_LineChartPainter.paint`: dibuja un dot centrado cuando `data.length == 1`

---

### BUG-230-E: Cold-start race en StreakNotifier HWM (MEDIO)

**Archivo**: `streak_notifier.dart`, líneas 95-140 y 184  
**Categoría**: RACE-CONDITION

**Mecanismo**: En cold start:
1. `state.todayEntry = null` (StreakState vacío)
2. Un pilar emite antes de que el stream de Firestore entregue historial
3. `_evaluateToday()` corre con `prev = null` → HWM inefectivo
4. `_persistToday` podría sobreescribir entry real con magnitudes en 0

**Fix**: Flag `_historyLoaded = false` que se setea a `true` en la primera emisión de `watchHistory()`. Guard en `_evaluateToday`: `if (!_historyLoaded) return;`. Se resetea en logout. Se llama `_evaluateToday()` al recibir el historial para aplicar datos frescos de pilares.

---

### BUG-230-F: WeeklyAggregator dead code con bug timezone (BAJO)

**Archivo**: `weekly_aggregator.dart`, línea 77  
**Categoría**: TIMEZONE + DEAD-CODE

**Mecanismo**: `_startOfIsoWeek(DateTime date)` extraía componentes sin `.toLocal()`, mismo patrón que BUG-229-E. Ningún caller activo usa `WeeklyAggregator` (reemplazado por `TemporalAggregator`).

**Fix**: Marcado como DEPRECATED. Se aplicó `date.toLocal()` defensivo.

---

## 3. Archivos Modificados

| Archivo | Bug | Cambio |
|---------|-----|--------|
| `analysis_series_providers.dart` | A, B | `.toLocal()` en hydration/exercise + `ref.watch` para sleep |
| `streak_notifier.dart` | C, E | `maxMag` para sleep + `_historyLoaded` guard |
| `trend_chart.dart` | D | Guards para `data.length < 2` + dot fallback |
| `weekly_aggregator.dart` | F | Deprecated + `toLocal()` defensivo |

---

## 4. Archivos Verificados Sin Bugs

temporal_aggregator, merge_with_live, historic_summaries_provider, monthly_summaries_provider, daily_summary_provider, analysis_range_provider, chart_hero_computer, trend_comparison_computer, cycle_comparison_provider, cycle_summary_computer, goal_for_chart_provider, nutrition_pie_provider, observation_detector, observations_provider, transformation_provider/computer, weekly_coaching_computer/provider, period_comparison_provider/service, daily_summary_persistence_service, biometric_trend_provider, daily_summary_mapper, bar_chart_card, line_chart_card, sparkline_chart/inline, imr_trend_chart, pillars_heatmap, weekly_strip, calendar_day_cell, monthly_calendar_screen, analysis_screen, todos los tabs.

---

## 5. Invariantes Post-Fix

1. **Todo `_dateIso()` de timestamp Firestore** usa `.toLocal()` antes de extraer componentes
2. **Todos los habit series providers** usan `ref.watch(analysisRangeStartProvider)` fuera del `await for`
3. **Las 5 magnitudes del streak** usan `maxMag()` (high water mark consistente)
4. **`TrendChart`** maneja `data.length ∈ {0, 1}` sin crash
5. **`_evaluateToday()`** no persiste hasta que el historial de Firestore se cargó al menos una vez
6. **`WeeklyAggregator`** está deprecated; usar `TemporalAggregator` para nuevos desarrollos
