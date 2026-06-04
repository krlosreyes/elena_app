# SPEC-168.2 — Línea horizontal de objetivo (dashed)

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Refinamiento visual de BarChartCard + LineChartCard
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1 hora
**Padre:** SPEC-168
**Referencia visual:** Apple Fitness "Actividad" — Objetivo 1.000 cal, Objetivo 90 min, Objetivo 12 h

---

## 1. Contexto

Apple Fitness pinta sobre los charts de Actividad una línea horizontal dashed al nivel del objetivo del día (1 000 cal, 90 min, 12 h pararse), con label `Objetivo 1.000` flotando a la derecha. Saca al usuario del "¿voy bien?" subjetivo y lo lleva a comparar contra meta absoluta. Encaja directo con nuestro modelo: cada pilar tiene un target operacional (16 h ayuno, 2.5 L hidratación, 30 min ejercicio, 8 h sueño, 80 % calidad nutricional como meta soft).

## 2. Decisiones de diseño

### 2.1 — Trazo dashed horizontal

Sobre el plot, en la posición `y = plotBottom - (target - yMin) / (yMax - yMin) * plotHeight`, dibujar línea horizontal de `plotLeft` a `plotRight` con:

- Color: `accent.withValues(alpha: 0.55)` (mismo color del card, alfa reducido).
- StrokeWidth: 1.2.
- Patrón: 4-on / 3-off (dashes cortos, lectura Apple).

### 2.2 — Label "Objetivo X"

A la derecha del plot, junto al axis derecho (no fuera de la card):

```dart
Text('Objetivo $targetLabel',
  style: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: accent.withValues(alpha: 0.85),
  ),
)
```

Posición vertical: alineado al centro de la línea dashed.
Formato `targetLabel`: usa el mismo helper `_fmtTick` que el axis (ej. "1.000", "8", "16 h").

### 2.3 — Expandir yMax si target > maxV

Si el usuario nunca llega al objetivo en el rango actual, `maxV` real podría ser menor que `target`. En ese caso:

```dart
final effectiveMax = max(maxV, targetValue);
final yMax = _niceUpperBound(effectiveMax * 1.05); // 5% headroom
```

Esto garantiza que la línea siempre se vea dentro del plot.

### 2.4 — API

Nuevo param opcional en BarChartCard y LineChartCard:

```dart
final double? targetValue;
final String? targetLabel; // override; default formatea con _fmtTick
```

Si `targetValue == null`: no se pinta línea ni label (comportamiento actual).

## 3. Cambios concretos

### 3.1 — BarChartCard / LineChartCard

- Añadir `final double? targetValue` y `final String? targetLabel` al constructor.
- En `_BarsPainter`/`_LinePainter`, después del grid y antes de las barras/línea:
  ```dart
  if (targetValue != null) _drawTargetLine(canvas, ...);
  ```
- Implementar `_drawTargetLine` que pinta dashes con `Path` + `PathMetrics`.

### 3.2 — Helper de path dasheado

```dart
Path _dashedHorizontal(double x0, double x1, double y) {
  const dash = 4.0, gap = 3.0;
  final path = Path();
  double x = x0;
  while (x < x1) {
    path.moveTo(x, y);
    path.lineTo(math.min(x + dash, x1), y);
    x += dash + gap;
  }
  return path;
}
```

### 3.3 — analysis_screen.dart

Pasar targetValue por card:

| Pilar | targetValue | Unit | Fuente |
|-------|-------------|------|--------|
| Ayuno (días/sem) | 5.0 | "d/sem" | hábito sugerido (5 ayunos cumplidos por semana) |
| Nutrición (%) | 80.0 | "%" | umbral A-dominante saludable (Frank Suárez) |
| Hidratación (%) | 100.0 | "%" | meta 2.5 L = 100 % |
| Ejercicio (min) | 30.0 | "min" | OMS guideline diario |
| Sueño (h) | 8.0 | "h" | rango óptimo adulto |
| Peso (kg) | userProfile.targetWeight | "kg" | de UserProfile si está definido |
| IMR | 75.0 | "" | meta operacional definida en SPEC-141 |

Targets de Ayuno y Nutrición son **soft goals** (no clínicos), usados solo para coaching visual.

## 4. Validación

### 4.1 — Visual
- Línea dashed visible en cada card que tenga targetValue.
- Label "Objetivo X" a la derecha, sin solaparse con axis.
- Si maxV << target, plot expande para mostrar la línea con headroom.

### 4.2 — No-regresión
- Cards sin targetValue (ej. card de tendencia libre) no muestran línea — comportamiento idéntico al actual.

## 5. Riesgo

- **Visual ruido**: si target y barras coinciden, la línea puede confundirse con tope de barra. Mitigación: alpha 0.55 garantiza diferenciación.
- **Targets hard-coded en analysis_screen**: SPEC-168.3 introducirá `userGoalsProvider` que centraliza targets. Por ahora hard-code es aceptable (sprint inmediato).

## 6. Cierre

- [ ] Param targetValue/targetLabel agregado a ambos charts
- [ ] _drawTargetLine implementado con dashes
- [ ] yMax expandido cuando target > maxV
- [ ] analysis_screen cablea targets por pilar
- [ ] Validación visual Carlos
