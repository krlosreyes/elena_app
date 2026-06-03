# SPEC-164 — Agregación temporal adaptativa por rango

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Fix conceptual de SPEC-162 — agregación adaptativa estilo Apple Fitness
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1 hora

---

## 1. Contexto

Carlos reportó que los gráficos se ven vacíos. Auditoría confirmó que las queries son correctas — el problema es **diseño de agregación**.

SPEC-162 agrupaba TODO por semana ISO. Si el usuario llevaba 7 días usando la app, había máximo 2 puntos en cada gráfico. Apple Fitness no tiene este problema porque **adapta la unidad de agregación al rango seleccionado**.

## 2. Decisión de diseño

Reemplazar `WeeklyAggregator` fijo por `TemporalAggregator` con 3 modos: `daily`, `weekly`, `monthly`.

Cada `AnalysisRange` mapea a un modo:

| Rango | Modo de agregación | Cantidad esperada de buckets |
|---|---|---|
| 30D | daily | hasta 30 |
| 3M | weekly | hasta 13 |
| 6M | weekly | hasta 26 |
| 1A | monthly | hasta 12 |
| Todo | monthly | variable |

Patrón idéntico a Apple Fitness (vista D/W/M/6M/Y).

## 3. Cambios técnicos

### 3.1 — Nuevo enum `AggregationMode`

`lib/src/features/analysis/domain/aggregation_mode.dart`:
- `daily`, `weekly`, `monthly`.
- Helper estático `forRange(AnalysisRange)`.

### 3.2 — `TemporalAggregator` reemplaza `WeeklyAggregator`

Mismo API que `WeeklyAggregator.aggregate` + parámetro `mode`. Los buckets se calculan según el modo:
- `daily`: lunes 00:00 → 24h.
- `weekly`: lunes ISO 00:00 → 7 días.
- `monthly`: primer día del mes 00:00 → mes completo.

### 3.3 — Refactor de `analysis_series_providers`

Cada serie llama `TemporalAggregator.aggregate(..., mode: AggregationMode.forRange(range))`.

### 3.4 — `WeeklyAggregator` queda deprecado

Se mantiene en disco para compatibilidad de tests existentes. Nuevos callers usan `TemporalAggregator`.

## 4. Criterios de aceptación

1. Rango 30D → barras diarias (hasta 30).
2. Rango 3M/6M → barras semanales.
3. Rango 1A/Todo → barras mensuales.
4. Eje X muestra labels apropiados al bucket (día/semana/mes).
5. Tests cubren los 3 modos.

## 5. Out of scope

- Selector D/W/M independiente como Apple (forzaríamos al usuario a elegir dos cosas). El mapeo automático es más simple.

## 6. Changelog

### v1.0 — 2026-06-02

Fix del problema "gráficos vacíos" reportado por Carlos. Replica patrón Apple Fitness.
