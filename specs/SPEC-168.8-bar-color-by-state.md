# SPEC-168.8 — Color de barra por estado (cumplido / no cumplido)

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Refinamiento visual de BarChartCard
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~30 min
**Padre:** SPEC-168
**Referencia visual:** Apple Fitness "Actividad" — barras Moverse/Ejercicio/Pararse con dos tonos

---

## 1. Contexto

Apple Fitness pinta cada barra en dos tonos según si alcanzó el objetivo del día:
- **Cumplido** (valor ≥ target): color brillante del pilar.
- **No cumplido** (valor < target): mismo color pero opaco/oscuro (~35 % alpha).

Lectura instantánea de adherencia sin leer números. Encaja directo con SPEC-168.2 (línea de objetivo): la línea dice "esto era la meta", el color dice "cuándo la pegué".

## 2. Decisiones de diseño

### 2.1 — Solo aplica si hay targetValue

Si `targetValue == null`, todas las barras se pintan con `accent` brillante (comportamiento actual). Sin target no hay criterio binario de cumplido/no.

### 2.2 — Umbral exacto vs umbral soft

Apple usa `value >= target` como umbral exacto (no parcial). Mantenemos esa convención para evitar ambigüedad. Si quedó en 99 % del target, se pinta opaco. Decisión consciente: refuerza la disciplina del "hit the goal" sin medias tintas.

### 2.3 — Tonos

- **Cumplido:** `accent` (color base del pilar, 100 % alpha).
- **No cumplido:** `accent.withValues(alpha: 0.35)`.

Probamos primero con 0.35; si en device se ve muy apagado, ajustamos a 0.45.

### 2.4 — Compatibilidad con TimeSeriesPoint sin sampleCount

`TimeSeriesPoint.sampleCount` ya existe. Si `sampleCount == 0` (bucket vacío sin registros), la barra no se pinta (sigue como ahora, regular flujo). Solo aplica el dual-color cuando hay valor real.

## 3. Cambios concretos

### 3.1 — BarChartCard

Sin nuevo param: reusa el `targetValue` de SPEC-168.2.

`_BarsPainter.paint` modifica el loop de barras:

```dart
for (int i = 0; i < n; i++) {
  final v = values[i].clamp(0.0, yMax);
  final barHeight = (v - yMin) / (yMax - yMin) * plotHeight;
  if (barHeight <= 0) continue;
  final x = plotLeft + i * (barWidth + _barGap);
  final y = plotBottom - barHeight;
  // SPEC-168.8: color por estado vs target.
  final paint = (targetValue != null && values[i] < targetValue!)
      ? Paint()..color = accent.withValues(alpha: 0.35)
      : Paint()..color = accent;
  final rect = RRect.fromRectAndCorners(
    Rect.fromLTWH(x, y, barWidth, barHeight),
    topLeft: const Radius.circular(3),
    topRight: const Radius.circular(3),
  );
  canvas.drawRRect(rect, paint);
}
```

Mover el `barPaint` fuera del loop ya no es viable — ahora se construye por barra. Costo cero en CPU para series de hasta ~100 buckets.

## 4. Validación

### 4.1 — Visual
- Carlos en device: días con barra brillante = días que cumplió el objetivo. Días con barra opaca = días que no llegó.
- Carlos confirma visualmente que la diferencia es clara pero no agresiva.

### 4.2 — No-regresión
- Cards sin `targetValue` (no aplica todavía) siguen pintando todas las barras brillantes.

## 5. Riesgo

- **Confusión "es bug o es feature"**: el usuario podría leer la barra opaca como "estoy fallando, esto está malo". Mitigación: copy del hero arriba lo contextualiza ("PROMEDIO 2.3 días de ayuno · Objetivo 5 d/sem"). El color es un complemento, no el mensaje principal.
- **Daltonismo**: usar tono (brillante vs opaco) en vez de hue diferente garantiza accesibilidad para usuarios con daltonismo rojo-verde. Mantener el principio.

## 6. Cierre

- [ ] _BarsPainter.paint con dual-color por barra
- [ ] Validación visual Carlos
- [ ] LineChartCard NO se toca (no aplica para líneas continuas)
