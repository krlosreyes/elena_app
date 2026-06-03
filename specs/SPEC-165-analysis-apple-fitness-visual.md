# SPEC-165 — Análisis con lenguaje visual Apple Fitness (Fase 1)

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Refinamiento visual de SPEC-163 — adopta calidez Apple Fitness
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~2 horas

---

## 1. Contexto

Carlos compartió 4 screenshots de Apple Fitness pidiendo "intuitivo, amigable, fácil de entender, que motive, que rete, que informe". Mi versión actual de SPEC-163 tiene la información correcta pero el tono es frío: UPPERCASE, fondo gris, cards con borders, headlines técnicas.

**Reformulación importante (Carlos):** Análisis NO debe competir con Hoy. Análisis es **revisión histórica** (trazabilidad + causa-efecto). Hoy es **motivación del momento** (anillos activos, rachas, próxima acción).

Esta SPEC aplica solo los cambios visuales que refuerzan la función de Análisis. Lo motivacional/gamificado va en Hoy.

## 2. Decisiones de diseño

### 2.1 — Fondo negro puro

Reemplazo `AppColors.backgroundDark` por `Color(0xFF000000)` en `analysis_screen.dart`. Apple Fitness usa negro puro porque maximiza contraste en OLED y hace que el contenido respire. El gris oscuro hace todo "barroso".

### 2.2 — Header gigante mixed-case

Reemplazo el AppBar con título "ANÁLISIS" 14pt UPPERCASE por un header in-page:

```dart
Text(
  'Análisis',
  style: TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
  ),
)
Text(
  'miércoles, 4 de junio',
  style: TextStyle(
    fontSize: 14,
    color: Colors.white.withValues(alpha: 0.55),
    fontWeight: FontWeight.w500,
  ),
)
```

Patrón Apple: título dominante + subtítulo de contexto pequeño.

### 2.3 — Cards minimalistas sin border

Refactor de `BarChartCard` y `LineChartCard`:
- `border` removido completamente.
- `color`: `Color(0xFF0C0C0E)` — apenas más claro que negro.
- `borderRadius`: 18 (de 16).
- `padding`: 22 (de 20) — más respiración.

### 2.4 — Segmented control estilo iOS

Reemplazo `RangeSelectorChips` por un widget que replica el `UISegmentedControl` nativo:
- Container con fondo `Color(0xFF1A1A1C)`, border-radius pill 12.
- Item activo con fondo blanco `withAlpha(0.10)` + sombra sutil.
- Item inactivo: texto gris claro, sin fondo.
- Animación de slide del pill (Material curve).

### 2.5 — Color por métrica respetando tu paleta actual

Mantengo los colores ya definidos pero los uso con más intensidad en headers y valores:
- IMR: `metabolicGreen`
- Peso: `#60A5FA` (cyan)
- Ayuno: `metabolicGreen`
- Nutrición: `#FB923C` (naranja)
- Hidratación: `#38BDF8` (cyan claro)
- Ejercicio: `#14B8A6` (teal)
- Sueño: `#818CF8` (púrpura suave)

### 2.6 — Headlines conversacionales

Reemplazo "PROMEDIO" / "ACTUAL" + valor frío por frases. Tipos según métrica:

| Métrica | Headline conversacional |
|---|---|
| IMR | "Tu IMR promedio fue 67 en los últimos 3 meses." |
| Peso | "Pesás 84.5 kg. Bajaste 2.4 kg en este período." |
| Ayuno | "Cumpliste 5 días de ayuno por semana en promedio." |
| Nutrición | "El 71% de tus comidas fueron A-dominantes." |
| Hidratación | "Tomaste 84% de tu meta hídrica en promedio." |
| Ejercicio | "Hiciste 22 min de ejercicio por día en promedio." |
| Sueño | "Dormiste un promedio de 7.1 h por noche." |

Patrón: frase declarativa en segunda persona, mixed-case, con el valor integrado. Apple usa exactamente este patrón.

Subtítulo debajo: período en gris suave ("Últimos 3 meses") sin UPPERCASE.

### 2.7 — Secciones mixed-case

Reemplazo "TUS RESULTADOS" / "TUS HÁBITOS" / "INSIGHTS DETECTADOS" por:
- "Resultados"
- "Hábitos"
- "Observaciones"

Peso 700, tamaño 20pt, sin letterSpacing, sin UPPERCASE.

## 3. Cambios técnicos

### 3.1 — `analysis_screen.dart`

- `backgroundColor: Colors.black`.
- AppBar removido o transparente con back button minimal.
- Header in-page con título + fecha.
- Secciones con tipografía nueva.

### 3.2 — `chart_card_header.dart`

Reescritura completa con headline conversacional:
```
[Headline conversacional 16pt regular, color blanco 90%]
[Período · Delta] 12pt gris 55%
```

### 3.3 — `bar_chart_card.dart` y `line_chart_card.dart`

- Sin border.
- Background `Color(0xFF0C0C0E)`.
- Padding 22.
- Border radius 18.

### 3.4 — `segmented_control.dart` (nuevo)

Widget reusable que reemplaza `RangeSelectorChips`. iOS-style:
- Container con fondo `Color(0xFF1A1A1C)` border-radius 10.
- Children: lista de etiquetas.
- Item activo: fondo `Color(0xFF3A3A3C)` + texto blanco bold.
- Inactivo: texto gris 55%.

## 4. Criterios de aceptación

1. Pantalla con fondo negro puro `#000000`.
2. Título "Análisis" 34pt mixed-case + subtítulo fecha.
3. Cards sin border visible, fondo `#0C0C0E`.
4. Segmented control replica look iOS.
5. Headlines de cards son frases conversacionales.
6. Sin UPPERCASE en headers de sección.

### 4.1 — Sobre tests

Cambios puramente visuales. Tests existentes siguen aplicando.

## 5. Out of scope (para fase 2)

- Anillo IMR motivacional (va en Hoy).
- Sección "Logros" con rachas (va en Hoy).
- Trainer Tips contextuales (van en Hoy).
- Drill-down al tocar una métrica.
- Animación de slide del pill activo del segmented control (efecto puede emerger en fase 2).

## 6. Changelog

### v1.0 — 2026-06-02

Rediseño visual fase 1. Análisis adopta calidez Apple Fitness sin invadir territorio de Hoy.
