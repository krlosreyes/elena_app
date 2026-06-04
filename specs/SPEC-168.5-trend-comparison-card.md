# SPEC-168.5 — Card "Tendencias" con comparación de promedios

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Widget nuevo en pantalla Análisis
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~2 horas
**Padre:** SPEC-168
**Referencia visual:** Apple Health "Tendencias" — "En promedio, bajaste de peso en los últimos 6 días"

---

## 1. Contexto

Apple Health en su sección "Tendencias" pinta cards con headline conversacional + comparación visual de dos promedios:

- Promedio largo (línea sutil): "Promedio de 22 días" — base de referencia.
- Promedio corto (línea destacada): "Promedio de 6 días" — reciente.

El headline narra qué cambió ("bajaste de peso", "caminaste menos") con la cantidad y la dirección.

Esto **resuelve un hueco** que el usuario nos planteó hace semanas: "veo números pero no entiendo qué me está pasando". Tendencias da contexto evolutivo sin que el usuario tenga que comparar mentalmente.

## 2. Decisiones de diseño

### 2.1 — Qué métricas tienen card de Tendencias

Inicialmente las dos más relevantes para el usuario MR:

- **Peso** — "En promedio, bajaste/subiste/mantuviste tu peso en los últimos X días."
- **IMR** — "Tu IMR promedio mejoró/cayó/se mantuvo en los últimos X días."

Hidratación/Ayuno/Nutrición/Ejercicio/Sueño pueden venir en SPEC-168.5.1 cuando se valide el patrón visual.

### 2.2 — Cómputo del trend

Dada una `MetricSeries` con N buckets:

- **Long window**: el rango completo (N buckets).
- **Short window**: los últimos K buckets, donde K depende del modo:
  - `daily`: K = min(7, N ÷ 3) — última semana o ~33% del rango.
  - `weekly`: K = min(4, N ÷ 3) — último mes.
  - `monthly`: K = min(3, N ÷ 3) — últimos 3 meses.
- Mínimo K = 2. Si N < 4, no se renderiza el card (poca data, ruidoso).

Promedios:
- `shortAvg = mean(últimos K buckets con sampleCount > 0)`
- `longAvg = mean(todos los buckets con sampleCount > 0)`

### 2.3 — Dirección de la tendencia

Param `betterIf` (`'up'` o `'down'`) que el caller pasa por métrica:

- Peso: `'down'` (bajar es mejor).
- IMR: `'up'` (subir es mejor).

Lógica de copy:

```
diff = shortAvg - longAvg
absDiff = diff.abs()

// Umbral de ruido: 1% del longAvg
if absDiff < longAvg * 0.01:
  headline = "Tu {label} se mantuvo estable en los últimos {K} {unitTime}."
elif diff > 0:
  // shortAvg > longAvg
  verb = (betterIf == 'up') ? 'mejoró' : 'subió'
  headline = "Tu {label} {verb} en los últimos {K} {unitTime}."
else:
  // shortAvg < longAvg
  verb = (betterIf == 'down') ? 'mejoró' : 'cayó'
  headline = "Tu {label} {verb} en los últimos {K} {unitTime}."
```

Para Peso (down=better) el copy es más natural:

- shortAvg < longAvg → "En promedio, bajaste de peso en los últimos 6 días."
- shortAvg > longAvg → "En promedio, subiste de peso en los últimos 6 días."
- estable → "Tu peso se mantuvo estable en los últimos 6 días."

### 2.4 — Visual

Card del mismo estilo Apple (fondo `#0C0C0E`, radio 18, padding 22). Contenido:

1. **Headline conversacional** (17pt regular blanco 92%, como chart cards).
2. **Visualización simple sin chart** — dos líneas horizontales:
   - Promedio largo: línea sutil de plotLeft a plotRight, color blanco alpha 0.35.
   - Promedio corto: línea destacada (color del pilar) que va desde un punto X% del plot hasta el final.
   - Cada línea tiene su valor numérico al lado (`80.21 kg` para la larga, `78.05 kg` destacado para la corta).
3. **Labels de ventana** debajo (11pt alpha 0.45):
   - Izquierda: "Promedio de N días"
   - Derecha: "Promedio de K días"

Sin axis Y, sin grid. La idea es comparación visual rápida, no exploración numérica.

### 2.5 — Estado insuficiente

Si N < 4, el card NO se renderiza (return null o SizedBox.shrink).

## 3. Cambios concretos

### 3.1 — Domain

`lib/src/features/analysis/domain/trend_comparison.dart`:

```dart
class TrendComparison {
  final double shortAvg;
  final double longAvg;
  final int shortWindow;
  final int longWindow;
  final String betterIf; // 'up' or 'down'

  TrendComparison({
    required this.shortAvg,
    required this.longAvg,
    required this.shortWindow,
    required this.longWindow,
    required this.betterIf,
  });

  double get diff => shortAvg - longAvg;
  bool get isStable => diff.abs() < longAvg.abs() * 0.01;
  bool get isImprovement => betterIf == 'up' ? diff > 0 : diff < 0;
}
```

### 3.2 — Application

`lib/src/features/analysis/application/trend_comparison_computer.dart`:

```dart
static TrendComparison? compute(MetricSeries series, AggregationMode mode, String betterIf) {
  final filled = series.points.where((p) => p.sampleCount > 0).toList();
  if (filled.length < 4) return null;
  final shortK = _shortWindowSize(filled.length, mode);
  if (shortK < 2) return null;
  final shortAvg = filled.sublist(filled.length - shortK).map((p) => p.value).avg();
  final longAvg = filled.map((p) => p.value).avg();
  return TrendComparison(...);
}

static int _shortWindowSize(int n, AggregationMode mode) {
  switch (mode) {
    case daily: return math.min(7, n ~/ 3);
    case weekly: return math.min(4, n ~/ 3);
    case monthly: return math.min(3, n ~/ 3);
  }
}
```

### 3.3 — Presentation

`lib/src/features/analysis/presentation/widgets/trend_comparison_card.dart`:

Recibe `label`, `unit`, `accent`, `trend: TrendComparison`, `mode: AggregationMode`. Renderiza Container + headline + visual + window labels.

### 3.4 — `analysis_screen.dart`

Nueva sección "Tendencias" entre "Hábitos" y "Observaciones":

```dart
const SizedBox(height: 36),
_sectionTitle('Tendencias'),
const SizedBox(height: 14),
if (weightTrend != null) TrendComparisonCard(...),
const SizedBox(height: 14),
if (imrTrend != null) TrendComparisonCard(...),
```

## 4. Validación

### 4.1 — Visual
- Card aparece cuando hay >= 4 buckets con data.
- Headline narra correctamente la dirección.
- Visual de 2 líneas con valores numéricos al lado.

### 4.2 — Casos límite
- N=3 → card no aparece.
- shortAvg == longAvg → "se mantuvo estable".
- shortAvg cerca de longAvg (diff < 1%) → estable.

## 5. Cierre

- [ ] Domain TrendComparison + helper
- [ ] Application TrendComparisonComputer
- [ ] Presentation TrendComparisonCard
- [ ] Integración en analysis_screen (Peso + IMR)
- [ ] Validación visual Carlos
