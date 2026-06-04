# SPEC-168.3 — Indicador "X de N cumplidos" en chart card

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Refinamiento visual de BarChartCard
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1 hora
**Padre:** SPEC-168
**Referencia visual:** Apple Fitness "Actividad" — "1 de 31 días", "6 de 7 días"

---

## 1. Contexto

Apple Fitness pinta arriba de cada chart de Actividad un contador discreto del tipo `1 de 31 días`, `6 de 7 días`, `0 de 7 días`. Lectura instantánea de adherencia al objetivo. Encaja con la línea de objetivo (SPEC-168.2) y el color por estado (SPEC-168.8) que ya implementamos: el contador es el **resumen numérico** del coaching visual ("cumpliste 3 de las 7 barras brillantes que ves").

## 2. Decisiones de diseño

### 2.1 — Aplica solo si hay target activo

Sin target no hay criterio de "cumplido" — el contador no se renderiza. Coherente con SPEC-168.2 y SPEC-168.8.

### 2.2 — Umbral exacto vs target

Coherente con SPEC-168.8: un bucket cuenta como cumplido si `value >= target`. Sin medias tintas.

### 2.3 — Posición y estilo

Esquina superior derecha del bloque hero, alineado con la línea del `label` (PROMEDIO / TOTAL). Estilo: tag pequeño 11pt, color del pilar al 85 % de alpha, sin background.

Formato copy según `aggregationMode`:
- `daily`: `X de N días`
- `weekly`: `X de N semanas`
- `monthly`: `X de N meses`

### 2.4 — Solo BarChartCard

`LineChartCard` no aplica — line charts representan outcomes continuos (IMR, peso) donde la noción "cumplido por día" no es la dimensión relevante. Coherente con SPEC-168.8.

## 3. Cambios concretos

### 3.1 — `chart_hero_computer.dart`

Nuevo helper:

```dart
/// SPEC-168.3: cuenta cuántos buckets de la serie cumplieron el target.
/// Retorna null si `target` es null o la serie está vacía.
/// El bucket cuenta como cumplido si `point.value >= target`. Buckets
/// con `sampleCount == 0` (vacíos) no se cuentan ni como cumplidos ni
/// como denominador.
static ({int achieved, int total})? computeAchievement(
  MetricSeries series,
  double? target,
) {
  if (target == null) return null;
  final filled = series.points.where((p) => p.sampleCount > 0).toList();
  if (filled.isEmpty) return null;
  final achieved = filled.where((p) => p.value >= target).length;
  return (achieved: achieved, total: filled.length);
}
```

Helper de formato según mode:

```dart
static String formatAchievementLabel(
  int achieved,
  int total,
  AggregationMode mode,
) {
  switch (mode) {
    case AggregationMode.daily:
      return total == 1 ? '$achieved de $total día' : '$achieved de $total días';
    case AggregationMode.weekly:
      return total == 1 ? '$achieved de $total sem' : '$achieved de $total sem';
    case AggregationMode.monthly:
      return total == 1 ? '$achieved de $total mes' : '$achieved de $total meses';
  }
}
```

### 3.2 — `chart_hero_block.dart`

Param opcional `achievementLabel`. Cuando no es null, se renderiza alineado a la derecha del bloque del label, mismo baseline:

```dart
Row(
  children: [
    Text(label, ...),
    if (achievementLabel != null) ...[
      const Spacer(),
      Text(achievementLabel, ...),
    ],
  ],
)
```

### 3.3 — `BarChartCard`

Computar achievement internamente con `ChartHeroComputer.computeAchievement(series, targetValue)`. Si retorna no null, formatea con `formatAchievementLabel` y pasa a `ChartHeroBlock`.

Recibir `aggregationMode` (ya lo tiene desde SPEC-168.1) para el copy correcto.

### 3.4 — `analysis_screen.dart`

Sin cambios: el cómputo vive en el card.

## 4. Validación

### 4.1 — Visual
- Cada BarChartCard con target activo muestra `X de N (días/sem/meses)` arriba a la derecha del bloque hero.
- Sin target activo: no aparece nada.
- En modo daily con rango de 30 días donde el usuario cumplió 12 → `12 de 30 días`.
- En modo weekly con rango de 3 meses donde cumplió 8 semanas de 13 → `8 de 13 sem`.

### 4.2 — No-regresión
- LineChartCard sin cambios (no aplica).
- Cards sin target: hero block idéntico al actual.

## 5. Cierre

- [ ] Helper computeAchievement + formatAchievementLabel
- [ ] ChartHeroBlock con param opcional
- [ ] BarChartCard cablea internamente
- [ ] Validación visual Carlos
