# SPEC-168.5.1 — Tendencias en pantalla aparte (`/analysis/trends`)

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Refactor UX — refinamiento de SPEC-168.5
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1 hora
**Padre:** SPEC-168
**Bibliografía:** Apple Health iOS — Tendencias como vista opt-in, no en la home.

---

## 1. Contexto

SPEC-168.5 implementó "Tendencias" como sección inline en Análisis. Feedback de Carlos (2026-06-03): Apple lo hace **opt-in** — el usuario entra a una vista separada de Tendencias cuando quiere verlas, no las consume cada vez que abre Análisis. La home queda enfocada en lo que el usuario necesita ahora: resultados + hábitos + observaciones.

## 2. Decisiones de diseño

### 2.1 — Pantalla nueva `/analysis/trends`

`AnalysisTrendsScreen` con:
- Header `Tendencias` 34pt (mismo estilo que Análisis).
- Back button en la esquina superior izquierda.
- `SegmentedRangeControl` heredado (mismo `analysisRangeProvider` que Análisis — comparten estado).
- Lista vertical de `TrendComparisonCard` (Peso + IMR ahora; otros pilares en backlog).
- Sin bottom navigation bar (es una sub-screen, no una tab).

### 2.2 — Botón de entrada en Análisis

En el header de `AnalysisScreen`, a la derecha del título "Análisis", un botón sutil tipo Apple:

```
Análisis                    Tendencias  →
Jueves, 4 jun. de 2026
```

Estilo: 14pt regular `metabolicGreen`, decoración `arrow_forward_ios_rounded` 12px. Sin fondo, sin border. Tap → `context.push('/analysis/trends')`.

### 2.3 — Sacar Tendencias inline de Análisis

`_buildTrendsSection` se elimina de `analysis_screen.dart`. La estructura queda: header → range control → Resultados → Hábitos → Observaciones.

### 2.4 — Router

Agregar entrada en `app_router.dart`:

```dart
GoRoute(
  path: '/analysis/trends',
  builder: (context, state) => const AnalysisTrendsScreen(),
),
```

### 2.5 — Compartir state del rango

El rango temporal (`analysisRangeProvider`) es global Riverpod. Cuando el usuario cambia rango en Análisis y entra a Tendencias, ve el mismo rango. Reciprocidad: si cambia rango en Tendencias y vuelve, Análisis refleja el cambio. Coherente con cómo Apple Health propaga la selección de tiempo.

### 2.6 — Empty state

Si los dos trends están vacíos (poco data), la pantalla muestra mensaje:

```
📈
Aún no hay tendencias para mostrar.

Necesitamos al menos 4 mediciones
en el rango para detectar cambios.
```

## 3. Cambios concretos

### 3.1 — Nuevo archivo
`lib/src/features/analysis/presentation/analysis_trends_screen.dart`.

### 3.2 — Editar `analysis_screen.dart`
- Eliminar import de `trend_comparison_card`, `trend_comparison_computer`.
- Eliminar invocación de `_buildTrendsSection` (3 líneas).
- Eliminar el método `_buildTrendsSection`.
- Agregar botón "Tendencias →" en `_buildPageHeader`.

### 3.3 — Editar `app_router.dart`
- Importar `AnalysisTrendsScreen`.
- Agregar `GoRoute` para `/analysis/trends`.

## 4. Validación

### 4.1 — Manual en device
- Análisis no muestra sección Tendencias.
- Botón "Tendencias →" visible en el header.
- Tap navega a la nueva pantalla.
- Back button vuelve a Análisis.
- El rango temporal seleccionado se mantiene entre las dos pantallas.

### 4.2 — Estado vacío
- Sin data: mensaje correcto.

## 5. Cierre

- [ ] AnalysisTrendsScreen creada
- [ ] Botón de entrada en header de Análisis
- [ ] Ruta registrada
- [ ] `_buildTrendsSection` removido de Análisis
- [ ] Validación visual Carlos
