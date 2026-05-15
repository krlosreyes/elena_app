# SPEC-113 — Pantalla Análisis: tendencia + heatmap + insights

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-15
**Tipo:** Rediseño de pantalla
**Marco normativo:** SPEC-110 (vista "Hoy"), SPEC-111 (persistencia diaria), SPEC-112 (vista calendario). Filosofía: **Dashboard = "ahora", Análisis = "patrón e interpretación"**.

---

# 1. Contexto

La pantalla Análisis post SPEC-110 muestra el día actual con un anillo central de IMR y 5 satélites de pilar. Análisis decorativo: el usuario ve los mismos números que ya tiene en Dashboard. La pestaña no responde las preguntas que un usuario real trae a una sección de Análisis:

- ¿Cómo voy esta semana / mes?
- ¿Estoy mejorando o me estanqué?
- ¿Cuál es mi pilar fuerte y cuál arrastra al resto?
- ¿Cuándo tuve mi mejor día y qué hice ese día?

Con SPEC-111 (persistencia diaria) en producción, ya tenemos histórico real. Esta SPEC convierte la pantalla en una herramienta de **interpretación y aprendizaje sobre uno mismo**.

# 2. Visión

Cuatro secciones que se actualizan según un selector temporal global:

```
┌─ Selector ─────────────────────────────────────────┐
│  [Hoy]  [Semana]  [Mes]  [3 Meses]                 │
└────────────────────────────────────────────────────┘

┌─ Hero comparativo ─────────────────────────────────┐
│   IMR PROMEDIO ESTA SEMANA                         │
│         72         ↑ +5                            │
│                    vs semana anterior              │
│   Mejor día: Jue 14 · IMR 78                       │
│   Peor día:  Lun 11 · IMR 54                       │
└────────────────────────────────────────────────────┘

┌─ Tendencia ────────────────────────────────────────┐
│   IMR DÍA A DÍA                                    │
│                              ╱                     │
│                       •  ╱──•                      │
│              •──•   ╱                              │
│         •   ╱                                      │
│   L   M   M   J   V   S   D                        │
└────────────────────────────────────────────────────┘

┌─ Heatmap pilares × días ───────────────────────────┐
│   CUMPLIMIENTO POR PILAR                           │
│            L    M    M    J    V    S    D        │
│   Ayuno    ■    ■    ■    ■    ■    ▢    ▢        │
│   Sueño    ■    ▣    ■    ■    ▣    ▢    ▢        │
│   Hidrat.  ▣    ▢    ▣    ■    ▢    ▢    ▢        │
│   Ejerc.   ■    ■    ■    ■    ■    ▢    ▢        │
│   Comidas  ■    ■    ■    ■    ▣    ▢    ▢        │
└────────────────────────────────────────────────────┘

┌─ Insights ─────────────────────────────────────────┐
│   🔥 Tu pilar más constante: Ayuno (5/5 días)      │
│   ⚠️ Tu pilar a trabajar: Hidratación (2/5 días)   │
│   🏆 Tu mejor día: Jueves 14 — IMR 78              │
└────────────────────────────────────────────────────┘
```

# 3. Componentes

## 3.1 Selector temporal

Segmented buttons en la parte superior con 4 opciones:
- `Hoy` — solo el día actual (modo legacy SPEC-110 disponible como subsection si Carlos lo quiere conservar).
- `Semana` — últimos 7 días (incluido hoy).
- `Mes` — últimos 30 días.
- `3 Meses` — últimos 90 días.

State local del screen, no provider (es UI puro).

## 3.2 Hero comparativo

Value object puro `PeriodComparison`:
```dart
class PeriodComparison {
  final int imrAverage;           // promedio del período actual
  final int? imrAveragePrevious;  // promedio del período anterior (mismo length)
  final int? bestDayImr;
  final DateTime? bestDayDate;
  final int? worstDayImr;
  final DateTime? worstDayDate;
  final int daysWithData;
  final int daysInPeriod;

  int? get delta => imrAveragePrevious != null
      ? imrAverage - imrAveragePrevious!
      : null;
}
```

Calculado por `PeriodComparisonService.compute(docs, periodLength)`. Función pura, recibe la lista de docs del período + período anterior.

Provider: `periodComparisonProvider(AnalysisPeriod)` que combina dos `historicSummariesProvider` (período actual + anterior) y compone.

UI:
- IMR promedio en tipografía grande.
- Delta con flecha arriba/abajo y color (verde si +, rojo si −, gris si =).
- Mejor/peor día con fecha legible.

## 3.3 Gráfico de tendencia

CustomPaint puro:
- Eje X: días del período (etiquetas L M M J V S D para Semana; números 1-30 para Mes; numeradas cada 7 días para 3M).
- Eje Y: IMR 0..100, escalado al rango visible.
- Línea verde uniendo los puntos con data.
- Días sin data: gap visible (sin punto).
- Dot grande sobre el día con IMR más alto del período + label "Mejor: 78".

Sin animación en MVP.

## 3.4 Heatmap pilares × días

Grid 5 filas × N columnas. Cada celda:
- Color de fondo por % de cumplimiento del pilar ese día:
  - ≥80%: verde sólido.
  - 50-79%: amarillo / verde medio.
  - 1-49%: naranja / rojo claro.
  - 0% o sin data: gris muy tenue.
- Label de fila (Ayuno/Sueño/Hidratación/Ejercicio/Comidas) a la izquierda.
- Labels de columna (L M M J V S D / números).

Para períodos largos (Mes, 3M) el heatmap se vuelve ancho — debe scrollear horizontal.

## 3.5 Insights automáticos

Servicio puro `InsightsService.generate(List<DailySummaryDoc>) → List<Insight>`.

Cada `Insight` es un value object:
```dart
class Insight {
  final IconData icon;
  final Color accent;
  final String title;       // ej. "Tu pilar más constante"
  final String description; // ej. "Ayuno: 5/5 días al 100%"
}
```

Heurísticas MVP (4 insights básicos):
1. **Pilar más constante** del período: pilar con mayor cantidad de días ≥80%.
2. **Pilar a trabajar**: pilar con menor cantidad de días ≥80%.
3. **Mejor día**: el día con IMR máximo.
4. **Racha de IMR**: días consecutivos con IMR ≥65 (reutiliza `streakProvider` si aplica).

Heurísticas aspiracionales (post-MVP):
- "Cuando duermes >7h, tu IMR sube +X% en promedio."
- "Tus mejores 5 días coinciden con ayunos >18h."
- "Tu jueves promedio es +12% vs tu lunes promedio."

(Out of scope esta SPEC. SPEC futura cuando haya suficiente data como para correlaciones estadísticamente válidas — mínimo 30 días con data densa.)

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Enum `AnalysisPeriod` con `daysCount` y `label` | `lib/src/features/analysis/domain/analysis_period.dart` |
| 2 | Value object `PeriodComparison` + service puro | `lib/src/features/analysis/domain/period_comparison.dart` + `application/period_comparison_service.dart` |
| 3 | Provider `periodComparisonProvider` | `application/period_comparison_provider.dart` |
| 4 | Value object `Insight` + service de heurísticas | `domain/insight.dart` + `application/insights_service.dart` |
| 5 | Tests puros de los services (comparison + insights) | `test/features/analysis/application/` (2 archivos) |
| 6 | Widget selector temporal | `presentation/widgets/period_selector.dart` |
| 7 | Widget hero comparativo | `presentation/widgets/period_hero_card.dart` |
| 8 | Widget gráfico de tendencia (custom paint) | `presentation/widgets/trend_chart.dart` (sustituye el archivo huérfano del mismo nombre que quedó de SPEC-109) |
| 9 | Widget heatmap | `presentation/widgets/pillars_heatmap.dart` |
| 10 | Widget card de insight individual | `presentation/widgets/insight_card.dart` (sustituye el archivo huérfano) |
| 11 | Reescritura del shell de Análisis con las 4 secciones | `presentation/analysis_screen.dart` |

# 5. Criterios de aceptación

1. Selector temporal en la parte superior con 4 opciones; el botón activo se destaca.
2. Cambiar el período actualiza todas las secciones (hero, tendencia, heatmap, insights) en tiempo real.
3. Hero muestra IMR promedio, delta vs período anterior (con color), mejor y peor día.
4. Gráfico de tendencia renderea N puntos (uno por día). Días sin data dejan gap. Mejor día destacado.
5. Heatmap muestra 5 filas (pilares) × N columnas (días). Color por % de cumplimiento.
6. Insights muestra entre 3 y 4 cards con frases concretas basadas en heurísticas del período.
7. Si no hay docs en el período (usuario nuevo), las secciones muestran un placeholder "Estamos recopilando tus datos. Tu análisis estará disponible en X días." con count regresivo razonable.
8. La pantalla mantiene el AppBar con botón calendar (SPEC-112) y el BottomNavigationBar.
9. `flutter analyze` sin issues nuevos. `flutter test` con +N tests de los services.

# 6. Pruebas

**`period_comparison_service_test.dart`:**
- Período con 7 días con data, calcular promedio, mejor y peor día.
- Período con 0 días → todos los campos null o 0.
- Período anterior con menos días que actual (transición de uso) → delta puede ser null.
- Delta positivo, negativo y cero — verificar signo.

**`insights_service_test.dart`:**
- Lista vacía → lista de insights vacía o con mensaje "Aún sin data".
- 7 días con un pilar al 100% siempre → "Pilar más constante" lo detecta.
- 7 días con un pilar en 0% siempre → "Pilar a trabajar" lo detecta.
- Mejor día: máximo IMR en el período.
- Empate de mejor día: gana el más reciente (decisión documentada).

# 7. Riesgos

**7.1 Días sin data al inicio.**
Usuarios nuevos no tienen suficiente data para ningún período. El estado "vacío" debe ser motivacional, no frustrante. Mostrar conteo de días persistidos vs días necesarios.

**7.2 Heatmap ancho en Mes / 3M.**
30-90 columnas no caben en pantalla. Solución: scroll horizontal con `SingleChildScrollView` orientation horizontal. Etiquetas de fila fijas a la izquierda usando `Row` + `Expanded`.

**7.3 Cálculo de "pilar más constante" sin data.**
Si todos los pilares tienen 0 días al 100%, devolver "Aún sin pilar constante — sigue registrando". Sin crashear.

**7.4 Período anterior puede no existir.**
Si el usuario lleva 5 días en la app y el selector es "Semana" (7 días), el "período anterior" no tiene data. El delta debe ser null y la UI dice "(sin comparación disponible)".

**7.5 Sobrecarga visual.**
4 secciones + selector pueden sentirse densas. Mitigación: padding generoso, jerarquía tipográfica clara, cada sección con espacio de respiración.

# 8. Out of scope

- Correlaciones estadísticas reales ("cuando duermes >X, tu IMR sube Y%").
- Drill-down al tap de pilar o día.
- Personalización de qué insights mostrar.
- Exportar/compartir reporte semanal.
- Notificaciones push de "tu informe semanal está listo".
- Animaciones de transición entre períodos.
- Comparar mes vs mes anterior con overlay en el gráfico.

# 9. Resultado

(Se completa al cerrar el SPEC.)
