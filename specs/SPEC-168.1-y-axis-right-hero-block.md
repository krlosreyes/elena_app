# SPEC-168.1 — Eje Y a la derecha + bloque hero PROMEDIO/TOTAL

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Refinamiento visual de BarChartCard + LineChartCard
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1.5 horas
**Padre:** SPEC-168
**Referencia visual:** Apple Health "Carbohidratos", Apple Fitness "Actividad"

---

## 1. Contexto

Los cards actuales tienen el eje Y a la izquierda y un headline conversacional pequeño. Apple usa la convención opuesta: **eje Y a la derecha** (el ojo LTR aterriza ahí al final) y **bloque hero PROMEDIO/TOTAL grande** arriba del chart con el agregado y la fecha-range del bucket actual.

## 2. Decisiones de diseño

### 2.1 — Eje Y al lado derecho

`bar_chart_card.dart` y `line_chart_card.dart`:

- Cambiar `_yAxisWidth = 28` (lado izquierdo) por:
  - `_yAxisRightWidth = 36`
  - `_yAxisLeftPadding = 0`
- Plot horizontal: `[0, size.width - _yAxisRightWidth]`.
- Labels: `_drawYLabel(canvas, plotRight + 6, y, text)` con `textAlign: TextAlign.left` (los números se alinean leyendo desde la izquierda).
- Grid lines: igual, de `plotLeft = 0` a `plotRight = size.width - 36`.

### 2.2 — Bloque hero arriba del chart

Encima del CustomPaint, agregar un Column:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(heroLabel, // "PROMEDIO" o "TOTAL"
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.white.withValues(alpha: 0.50),
      )),
    Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(heroValue, // "177"
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.0,
          )),
        const SizedBox(width: 4),
        Text(heroUnit, // "g", "h", "%", "min"
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.50),
          )),
      ],
    ),
    Text(heroDateRange, // "7 a 13 jul. de 2026"
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.50),
      )),
    const SizedBox(height: 16),
  ],
)
```

### 2.3 — Cálculo del agregado hero

Nuevo enum opcional `HeroAggregation` por card:
- `HeroAggregation.avg` → label "PROMEDIO"
- `HeroAggregation.sum` → label "TOTAL"
- `HeroAggregation.last` → label "ÚLTIMO"
- `HeroAggregation.max` → label "MÁXIMO"

Default: `avg` para % y unidades continuas; `sum` para conteo de días/eventos.

Cálculo: itera `series.points`, ignora puntos con `sampleCount == 0`, aplica función de agregación.

### 2.4 — Formateo de rango de fechas

Helper `_formatDateRange(List<TimeSeriesPoint> points, AggregationMode mode)`:
- Daily, span < 14 días: "5 a 11 jun. de 2026"
- Daily, span ≥ 14: "may. a jun. de 2026"
- Weekly: idem (toma weekStart de primer y último bucket)
- Monthly: "jul. de 2025 a jun. de 2026"

## 3. Cambios concretos

### 3.1 — Domain
`lib/src/features/analysis/domain/hero_aggregation.dart` (nuevo):

```dart
enum HeroAggregation { avg, sum, last, max }
```

Helper estático `String labelFor(HeroAggregation a)`.

### 3.2 — BarChartCard / LineChartCard

Param nuevo:

```dart
final HeroAggregation heroAggregation;
final String? heroUnit; // override; default usa series.unit
```

Constructor con `this.heroAggregation = HeroAggregation.avg`.

### 3.3 — analysis_screen.dart

Cada llamada existente recibe `heroAggregation`:
- IMR (line): `HeroAggregation.avg`, label "PROMEDIO"
- Peso (line): `HeroAggregation.last`, label "ÚLTIMO"
- Ayuno (bar): `HeroAggregation.sum`, label "TOTAL", unit ajustado a "d"
- Nutrición (bar): `HeroAggregation.avg`, label "PROMEDIO", unit "%"
- Hidratación (bar): `HeroAggregation.avg`, label "PROMEDIO", unit "%"
- Ejercicio (bar): `HeroAggregation.avg`, label "PROMEDIO", unit "min"
- Sueño (bar): `HeroAggregation.avg`, label "PROMEDIO", unit "h"

## 4. Validación

### 4.1 — Visual
- Cada card muestra hero arriba con label en MAYÚSCULAS, número 34pt y unit pequeña.
- Eje Y a la derecha del chart con labels alineados.
- Grid horizontal sin labels en el lado izquierdo.

### 4.2 — No-regresión
- Headline conversacional existente (SPEC-165 §2.6) NO se elimina — queda como sub-headline opcional debajo del hero. Si Carlos prefiere quitarlo, lo decidimos en revisión visual.
- IMR (line) sigue calculando avg correctamente.

## 5. Riesgo

- Ancho del eje derecho: si labels tipo "100" o "10000" varían en ancho, alinear con `TextAlign.left` y `minWidth: 32`. Mitigación: probar visual con valor extremo.

## 6. Cierre

- [ ] HeroAggregation enum creado
- [ ] BarChartCard y LineChartCard refactorizados (eje + hero)
- [ ] Cada card del analysis_screen mapeado a su heroAggregation
- [ ] Validación visual Carlos en device
