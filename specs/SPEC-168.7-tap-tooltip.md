# SPEC-168.7 — Tooltip al tap en charts

**Estado:** CLOSED 2026-06-04
**Versión:** 1.1
**Tipo:** Drill-down ligero en BarChartCard y LineChartCard
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1.5 horas
**Padre:** SPEC-168
**Referencia visual:** Apple Fitness/Health — pill "TOTAL 0,03 km · 4/06/2026"

---

## 1. Contexto

Hoy el usuario ve la barra de un día específico, pero no sabe el valor exacto (lectura del eje Y aproximada) ni la fecha exacta. El tooltip al tap resuelve ambas en un mismo gesto: tocás una barra, aparece un pill con `valor unidad · fecha` y se cierra al tocar fuera o después de 3 s.

## 2. Decisiones de diseño

### 2.1 — Gesto

`GestureDetector.onTapUp` sobre el `CustomPaint` del chart. Detectamos la posición x, calculamos a qué bucket corresponde y guardamos el índice en state. Tap fuera del plot → cierra el tooltip (selectedIndex = null).

### 2.2 — Indicador visual del bucket seleccionado

La barra/punto seleccionado se resalta con una capa adicional (alpha 1.0 + outline blanco). El resto del chart queda intacto.

### 2.3 — Pill del tooltip

- Caja redondeada blanca con texto negro (estilo Apple).
- Posicionada arriba de la barra/punto, con cola triangular apuntando.
- Si la barra está cerca del borde derecho/izquierdo, el pill se desplaza para no salirse del chart.
- Contenido: `{valor formateado} {unit} · {fecha humana}`.

### 2.4 — Formato de fecha

- Modo daily: `5 jun. de 2026`
- Modo weekly: `Sem del 5 jun.`
- Modo monthly: `jun. 2026`

### 2.5 — Auto-dismiss

Timer de 3 s tras el tap. Si el usuario toca otra barra antes, reinicia el timer en la nueva barra. Si toca fuera del plot, cierra inmediatamente.

### 2.6 — Aplica solo a charts de buckets temporales

- `BarChartCard` ✓ (todas las barras)
- `LineChartCard` ✓ (puntos discretos en la línea — detectamos el punto más cercano al tap)
- `NutritionPieCard` ✗ (no es chart de buckets)
- `NutritionTrendBarCard` ✓ (mismo patrón que BarChartCard)
- `TrendComparisonCard` ✗ (no muestra buckets)

## 3. Cambios concretos

### 3.1 — `BarChartCard` y `LineChartCard`

Convertir de `StatelessWidget` a `StatefulWidget`. Agregar `_selectedIndex: int?` y `_timer: Timer?` al state.

Envolver el `CustomPaint` del chart con `GestureDetector(onTapUp: (details) => _handleTap(details.localPosition))`.

Método `_handleTap(Offset pos)`:
- Calcula bucket index según la x dentro del plot.
- Si está fuera del plot → `setState(() => _selectedIndex = null)`.
- Si dentro → `setState(() => _selectedIndex = idx)` + reinicia `_timer` a 3 s.

Painter recibe `selectedIndex`. Si `!= null`, pinta:
- La barra (o punto) seleccionada con outline blanco 1.5 px.
- El tooltip pill arriba.

### 3.2 — Helper de formato

`String _formatTooltipDate(DateTime weekStart, AggregationMode mode)`:
- daily → `5 jun. de 2026`
- weekly → `Sem del 5 jun.`
- monthly → `jun. 2026`

### 3.3 — `NutritionTrendBarCard`

Mismo patrón que BarChartCard. Replicar `_handleTap` y `selectedIndex`.

## 4. Validación

### 4.1 — Manual
- Tap en una barra del chart de Ayuno → aparece `16.4 h · 5 jun. de 2026`.
- Tap fuera de las barras → el tooltip se cierra.
- Espera 3 s sin interactuar → se cierra solo.
- Tap en línea de IMR → tooltip con valor del punto más cercano.

### 4.2 — No-regresión
- Cards sin tap (TrendComparisonCard, NutritionPieCard) sin cambio.

## 5. Cierre

- [x] `ChartTooltip` widget creado (`lib/.../widgets/chart_tooltip.dart`).
- [x] Helper `ChartHeroComputer.formatTooltipDate(weekStart, mode)`.
- [x] `BarChartCard` → StatefulWidget, tap + selectedIndex + outline blanco + tooltip.
- [x] `LineChartCard` → StatefulWidget, tap por punto más cercano + ring marker + tooltip.
- [x] `NutritionTrendBarCard` → StatefulWidget, tap + outline + tooltip (unit `%`).
- [x] Auto-dismiss 3 s + tap fuera del plot cierra.
- [ ] Validación visual Carlos (pendiente — correr la app).

## 6. Decisiones de implementación

- **Geometría duplicada en state y painter:** el `_handleTap` necesita los
  mismos valores que `paint` (yAxisRightWidth=36, xAxisHeight=22, slotWidth).
  Si cambia uno, hay que cambiar el otro. Aceptamos la duplicación a
  cambio de mantener el painter puro (sin Riverpod) y el cálculo de tap
  sin pasar por canvas.
- **Tooltip como `Positioned.fill` + `IgnorePointer`:** así el pill
  queda en el espacio del chart pero los taps siguen llegando al
  `GestureDetector` debajo. Permite tocar otra barra sin tocar primero
  el pill.
- **`CustomMultiChildLayout` para clamp horizontal:** el pin se centra
  en `anchorX` y se desplaza si tocaría salir del plot por la derecha o
  izquierda. La cola triangular siempre apunta a `anchorX` exacto, sin
  importar el clamp del pin (patrón Apple Fitness).
- **`LineChartCard` busca el punto más cercano por distancia en x**
  (no por slot), porque los puntos están a posiciones fijas
  (`i/(n-1)*plotWidth`) y no hay "slot" entre puntos.
