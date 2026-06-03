# SPEC-163 — Análisis con gráficos estilo Apple Fitness

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Refinamiento visual de SPEC-162 — adopta lenguaje Apple Fitness
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 2-3 horas
**Marco normativo:** `CONSTITUTION.md`. Reemplaza widgets de presentación de SPEC-162 sin tocar capa de datos.

---

## 1. Contexto

Carlos validó la arquitectura de SPEC-162 (trazabilidad + causa-efecto + 3 bloques) pero rechazó el lenguaje visual: "se ven terribles". Pidió explícitamente "algo como Apple Fitness" para los gráficos.

Esta SPEC reemplaza los widgets de presentación (`MetricRow`, `SparklineChart`) por dos nuevos (`BarChartCard`, `LineChartCard`) que adoptan los patrones de Apple Fitness sin tocar la capa de datos.

## 2. Patrones de Apple Fitness aplicados

### 2.1 — Barras para comportamiento, líneas para outcomes

Apple separa rigurosamente:

| Tipo de métrica | Visualización | Por qué |
|---|---|---|
| Comportamiento discreto (ej: días de ayuno por semana) | **Barras verticales** | Cada barra es un evento. El gap entre barras comunica "días distintos". |
| Outcome continuo (ej: peso, frecuencia cardíaca) | **Línea** | El valor evoluciona suavemente — la línea comunica continuidad. |

**En Elena:**

| Métrica | Tipo | Widget |
|---|---|---|
| IMR | Outcome continuo | `LineChartCard` |
| Peso | Outcome continuo | `LineChartCard` |
| Ayuno (d/sem) | Comportamiento | `BarChartCard` |
| Nutrición (% A) | Comportamiento | `BarChartCard` |
| Hidratación (%) | Comportamiento | `BarChartCard` |
| Ejercicio (min/d) | Comportamiento | `BarChartCard` |
| Sueño (h) | Comportamiento | `BarChartCard` |

### 2.2 — Jerarquía del header

Apple Fitness usa tres líneas tipográficas:

```
PROMEDIO                  ← label 11pt, gris, letterSpacing alta
4.2  días/sem             ← valor 32-36pt, peso 700, sin fontFamily monospace
Ayuno · 3 MESES   ↑1.4    ← contexto 13pt, label de métrica + período + delta
```

Reemplaza completamente la fila condensada actual (`MetricRow`) que mete label, valor, delta y sparkline en una línea.

### 2.3 — Gráfico de altura generosa

Apple usa **140-180pt de alto** para el área del gráfico. Mi sparkline de 44pt era el problema. Nueva altura: **150pt**.

### 2.4 — Ejes visibles

- **Eje Y:** 3-4 valores discretos en gris alpha 40%, alineados a la izquierda del área del chart.
- **Eje X:** labels de mes o semana ("mar", "abr", "may") en gris alpha 50% debajo del chart.
- **Grid horizontal:** líneas alpha 6% que cortan a las marcas del eje Y.

Sin esto el usuario no sabe qué semana es qué barra. Apple SIEMPRE muestra eje X con contexto temporal.

### 2.5 — Una métrica por card

Apple Fitness dedica una card completa por métrica. NO comprime varias métricas en el mismo card. Esto da:
- Foco visual claro.
- Espacio para header completo + gráfico grande + eje.
- Jerarquía evidente (más importante = arriba).

### 2.6 — Selector temporal arriba, prominente

Pills con padding generoso, espaciadas. Activo con fill del color de acento + texto blanco. Inactivo con fondo gris muy sutil + texto gris claro.

```
[ 30D ]  [ 3M ]  [ 6M ]  [ 1A ]  [ Todo ]
```

### 2.7 — Color sólido del acento de la métrica

Cada métrica conserva su color (verde ayuno, azul hidratación, etc.). Pero ahora se usa **sólido en barras**, no gradiente. La transparencia solo aparece en grid horizontal y barras "vacías" (futuras semanas si se llegara a mostrar el rango completo).

## 3. Decisión de diseño

### 3.1 — Layout de `BarChartCard`

```
┌──────────────────────────────────────────────┐
│                                               │
│  PROMEDIO                                     │ ← 11pt, gris
│                                               │
│  4.2  días/sem                                │ ← 32pt, blanco
│  Ayuno · 3 MESES        ↑1.4 vs inicio        │ ← 13pt, contexto + delta
│                                               │
│                                               │
│   7┤                                          │
│    │                       ▌  ▌    ▌▌▌▌       │
│   5┤            ▌      ███████████▍           │
│    │            ▌  ▌▌  █████████████          │
│   3┤   ▌  ▌  ▌▌▌█▌█▌█████████████████         │
│    │ ▌ █  █▌▌█████████████████████████        │
│   1┤▌███▌█████████████████████████████        │
│    └──┬─────────┬─────────┬─────────┬───────  │
│       mar       abr       may       jun       │
│                                               │
└──────────────────────────────────────────────┘
```

- Padding 20pt todos los lados.
- Border radius 16pt.
- Background `surfaceDark`.
- Sin border.
- Cada barra: ancho dinámico según cantidad de puntos. Corner radius 3pt arriba.
- Gap entre barras: 2pt mínimo.
- Eje Y: máximo 4 ticks. Valores enteros si la métrica es int (días, minutos), 1 decimal si es float.

### 3.2 — Layout de `LineChartCard`

Idéntico al anterior excepto el área del chart:

```
   80│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
     │
   70│           ╱──╲    ╱──────
     │      ╱──╱    ╲___╱
   60│   ╱─╱
     │ ╱╱
   50│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
     │
   40│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
     └──┬─────────┬─────────┬───
        mar       abr       may
```

- Línea trazo 2.5pt sin gradient.
- Grid horizontal en gris alpha 6% en las marcas del eje Y.
- Punto destacado al final del trazo (círculo 4pt + halo alpha 30% radio 6pt).

### 3.3 — Selector temporal refinado

```
┌──────────────────────────────────────────────┐
│  [ 30D ]  [ 3M ]  [ 6M ]  [ 1A ]  [ Todo ]   │
│            ─────                              │
└──────────────────────────────────────────────┘
```

- Pills con padding horizontal 18pt, vertical 8pt.
- Fondo activo: `accent.withAlpha(0.18)`.
- Texto activo: `accent`.
- Inactivo: fondo `white.withAlpha(0.04)`, texto `white60`.
- Border radius 24pt (pill completa).
- Sin scroll horizontal — entran 5 chips bien en iPhone Pro Max.

### 3.4 — Estado "1 sola semana" o vacío

- **0 puntos en la serie:** "Sin datos en este rango." centrado en el área del gráfico.
- **1 punto en la serie:** "Necesitás 2+ semanas para ver tendencia." centrado.
- **2+ puntos:** render normal.

### 3.5 — Cero cambios en capa de datos

`MetricSeries` + providers + `CausalInsightDetector` + selector global → intactos. Esta SPEC solo refactoriza presentación.

## 4. Cambios técnicos

### 4.1 — Widgets nuevos

`lib/src/features/analysis/presentation/widgets/bar_chart_card.dart`:
- ConsumerWidget no, StatelessWidget — recibe `MetricSeries` + `accent` + `periodLabel`.
- Header completo (PROMEDIO + valor + contexto/delta).
- `CustomPaint` para barras + ejes.

`lib/src/features/analysis/presentation/widgets/line_chart_card.dart`:
- Mismo patrón con CustomPaint para línea + grid + ejes.

### 4.2 — Widgets retirados

`metric_row.dart` y `sparkline_chart.dart` quedan en disco sin uso (para no romper imports legacy si los hubiera) pero `analysis_screen.dart` deja de importarlos.

### 4.3 — Refactor de `range_selector_chips.dart`

Pills más prominentes según §3.3.

### 4.4 — Refactor de `analysis_screen.dart`

- Reemplazar `MetricRow(...)` por `LineChartCard(...)` para IMR y Peso.
- Reemplazar `MetricRow(...)` por `BarChartCard(...)` para los 5 hábitos.
- Spacing entre cards: 14pt vertical.
- Headers de sección "TUS RESULTADOS" / "TUS HÁBITOS" / "INSIGHTS DETECTADOS" con padding horizontal 4pt para alineación con los cards.

## 5. Criterios de aceptación

1. Cada métrica tiene su propia card de altura ~280pt (header + chart de 150pt + eje X).
2. Outcomes (IMR, Peso) usan LineChartCard.
3. Hábitos (5 pilares) usan BarChartCard.
4. Header de cada card tiene 3 líneas tipográficas: PROMEDIO (label) + valor grande + contexto/delta.
5. Eje X muestra labels temporales coherentes con el rango.
6. Eje Y muestra 3-4 ticks discretos.
7. Selector temporal arriba usa pills prominentes con activo destacado.
8. Si hay <2 puntos en la serie, mensaje claro en el área del chart.

### 5.1 — Sobre tests

Reorganización visual sin lógica nueva. Tests de `WeeklyAggregator` (SPEC-162) siguen aplicando. Validación visual en device.

## 6. Out of scope

- **Tap en gráfico para ver valor exacto** (tooltip): futura SPEC si emerge.
- **Drill-down al tocar un card:** SPEC-162.1 ya documentada.
- **Animación de barras al aparecer:** Material default basta.
- **Refinamiento de InsightTile:** queda como está (funciona).

## 7. Rollout

Sin breaking changes. Sin migración. Push directo + validación visual.

## 8. Changelog

### v1.0 — 2026-06-02

Adopta lenguaje visual Apple Fitness tras rechazo de las sparklines de SPEC-162. Cierra el ciclo de iteraciones visuales de Análisis.
