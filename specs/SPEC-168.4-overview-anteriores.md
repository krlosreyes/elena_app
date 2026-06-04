# SPEC-168.4 — Overview "Anteriores" con sparklines

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Refactor de navegación de Análisis
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~2 horas
**Padre:** SPEC-168
**Referencia visual:** Apple Health "Anteriores" — lista de Agua / Azúcar / Carbohidratos / Fibra

---

## 1. Contexto

Hoy `analysis_screen.dart` apila 7 cards a altura completa (IMR, Peso, Ayuno, Nutrición pie, Hidratación, Ejercicio, Sueño). El usuario necesita scrollear mucho para llegar al pilar que quiere ver y, cuando llega, no tiene contexto del resto.

Apple Health resuelve esto con una pantalla intermedia "Examinar / Anteriores" donde cada métrica es un **tile compacto** con sparkline + último valor + fecha. Tap entra al detalle con chart completo.

## 2. Decisiones de diseño

### 2.1 — Estructura nueva de `analysis_screen.dart`

```
Header (sin cambios)
SegmentedRangeControl (sin cambios)
"Tendencias →" botón (sin cambios)

Resultados
  ▸ IMR        76  ▁▂▃▄▅█  →
  ▸ Peso     78.4  ▁▂▁▂▁▁  →

Hábitos
  ▸ Ayuno    16.4h  ▆▆▇▇▆█  →
  ▸ Nutrición  82%  ◐        →   ← mini pie circular
  ▸ Hidratación 2.2L ▅▆▇▆▇█  →
  ▸ Ejercicio  35min ▃▅▇█▅▆  →
  ▸ Sueño     7.1h  ▆▇▆▆▇▆  →

Observaciones (sin cambios)
```

### 2.2 — Tile

`PillarOverviewTile` widget (~72 px de altura):
- Emoji a la izquierda (32 px).
- Label + valor agregado del período + fecha-range pequeña.
- Mini-sparkline a la derecha (60×32 px). Para Nutrición: mini-pie 32 px en su lugar.
- Chevron `›` al final.
- Fondo `#0C0C0E`, padding interno, border-radius 14.
- Tap → `context.push('/analysis/pillar/$id')`.

### 2.3 — Pantalla de detalle `AnalysisPillarDetailScreen`

Una pantalla **paramétrica** que recibe `ChartMetric` como parámetro de ruta.
- Header con back + título del pilar.
- `SegmentedRangeControl` heredado (estado global Riverpod).
- Chart completo (LineChartCard / BarChartCard / NutritionPieCard según pilar).
- Bottom nav NO se muestra (subpantalla).

Ventaja: una sola pantalla que dispatch al widget correcto en lugar de 5 pantallas.

### 2.4 — Routing

Nueva entrada en `app_router.dart`:

```dart
GoRoute(
  path: '/analysis/pillar/:metric',
  name: 'analysis-pillar',
  builder: (context, state) {
    final metricName = state.pathParameters['metric']!;
    final metric = ChartMetric.values.firstWhere(
      (m) => m.name == metricName,
      orElse: () => ChartMetric.imr,
    );
    return AnalysisPillarDetailScreen(metric: metric);
  },
),
```

### 2.5 — Estado vacío del tile

Si la serie está vacía para un pilar, el tile muestra "Aún sin registros" en lugar del valor y omite la sparkline.

## 3. Cambios concretos

### 3.1 — Nuevos archivos

- `lib/src/features/analysis/presentation/widgets/sparkline_inline.dart` — mini-sparkline reusable.
- `lib/src/features/analysis/presentation/widgets/pillar_overview_tile.dart` — tile (acepta MetricSeries + variante para Nutrición pie).
- `lib/src/features/analysis/presentation/analysis_pillar_detail_screen.dart` — pantalla detalle paramétrica.

### 3.2 — `analysis_screen.dart`

Reemplazar todos los `LineChartCard` / `BarChartCard` / `NutritionPieCard` por `PillarOverviewTile`. La pantalla queda mucho más corta.

### 3.3 — `app_router.dart`

Nueva ruta `/analysis/pillar/:metric` apuntando a `AnalysisPillarDetailScreen`.

## 4. Validación

Manual en device:
- Lista de Análisis con 7 tiles compactos (todos visibles en una pantalla con scroll mínimo).
- Tap en cualquier tile → entra al detalle con chart completo.
- Back vuelve a la lista preservando posición.
- El rango temporal se preserva entre lista y detalle (estado global).

## 5. Riesgos

- **Sparkline en cards muy chicos** podría perder legibilidad. Usamos 60×32 px mínimo y sin axis.
- **Conservar el pie chart de Nutrición** en su detalle (no convertirlo en bar chart).

## 6. Cierre

- [ ] sparkline_inline.dart
- [ ] pillar_overview_tile.dart
- [ ] analysis_pillar_detail_screen.dart
- [ ] analysis_screen refactor
- [ ] router con ruta paramétrica
- [ ] Validación visual Carlos
