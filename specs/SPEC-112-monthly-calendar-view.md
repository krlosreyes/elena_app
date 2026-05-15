# SPEC-112 — Vista calendario mensual del IMR

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-15
**Tipo:** Feature UI
**Marco normativo:** SPEC-111 (persistencia diaria). Inspiración: Apple Activity calendar.

---

# 1. Contexto

Tras SPEC-111 el usuario tiene snapshots diarios de su IMR en Firestore. La pantalla Análisis muestra solo el día actual. Falta una **vista panorámica mensual** — ver de un vistazo todos los días del mes con su mini-anillo de IMR, navegar entre meses y detectar patrones.

# 2. Diseño visual

```
        ┌─────────────────────────────┐
        │  ‹    Mayo 2026          ✕  │   ← header con navegación
        ├─────────────────────────────┤
        │  L   M   M   J   V   S   D  │   ← cabecera días
        │                              │
        │              1   2   3       │
        │              ◌   ◌   ◌       │
        │  4   5   6   7   8   9  10   │
        │  ◌   ◌   ◌   ◌   ◌   ◌   ◌   │
        │  11  12  13  14  ⓮  16  17   │ ← hoy destacado en verde
        │  ◌   ◌   ◌   ◌   ⊙   ◊   ◊   │ ← 11-15 con datos reales,
        │  18  19  20  21  22  23  24  │    16-17 placeholders futuros
        │  ◊   ◊   ◊   ◊   ◊   ◊   ◊   │
        │  25  26  27  28  29  30  31  │
        │  ◊   ◊   ◊   ◊   ◊   ◊   ◊   │
        └─────────────────────────────┘
```

Mini-anillo (◌/⊙) en cada celda:
- Color: verde proporcional al IMR del día (track tenue + arco coloreado).
- Día actual: número en color metabolicGreen + halo sutil.
- Días futuros: anillo gris alpha bajo (sin data).
- Días con data: anillo verde según valor del IMR (0..100).
- Días pasados sin data: anillo placeholder gris (alpha 0.10).

# 3. Acceso desde Análisis

En el AppBar de la pantalla Análisis se agrega un icono `Icons.calendar_month_rounded` a la derecha. Tap → push de la pantalla `MonthlyCalendarScreen` como `fullscreenDialog`.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Nueva pantalla del calendario | `lib/src/features/analysis/presentation/monthly_calendar_screen.dart` |
| 2 | Widget de celda (número + mini-anillo) | `lib/src/features/analysis/presentation/widgets/calendar_day_cell.dart` |
| 3 | Widget del header con chevrons + mes + cerrar | `lib/src/features/analysis/presentation/widgets/month_selector.dart` |
| 4 | Provider que dado un mes (year+month) construye el rango `[firstDay, lastDay]` y mapea al `historicSummariesProvider` | `lib/src/features/analysis/application/monthly_summaries_provider.dart` |
| 5 | Botón calendar en AppBar de Análisis con navegación al fullscreenDialog | `lib/src/features/analysis/presentation/analysis_screen.dart` |
| 6 | Tests puros del provider mensual (rango por mes) | `test/features/analysis/application/monthly_summaries_provider_test.dart` |

# 5. Criterios de aceptación

1. Tap en el icono calendar del AppBar de Análisis → abre pantalla calendario.
2. Pantalla calendario muestra el mes actual con grid 7×N.
3. Cada día tiene mini-anillo IMR (verde, proporcional) si hay data persistida; gris si no.
4. Día actual destacado.
5. Días futuros con anillo placeholder (gris muy tenue).
6. Chevron izquierdo (‹) → mes anterior. Chevron derecho (›) → mes siguiente.
7. Botón cerrar (✕) → vuelve a Análisis.
8. Nombre del mes en el header se actualiza al navegar.
9. Si no hay data del mes actual, el calendario igual se renderea con celdas vacías (no crashea).
10. `flutter analyze` sin issues nuevos. `flutter test` con tests del provider mensual.

# 6. Riesgos

**6.1 Latencia al cambiar de mes.**
Cada cambio dispara una query Firestore por rango. Aceptable para MVP — el rango es de máximo ~31 docs. Cache implícito por `StreamProvider.family` evita refetch si vuelves al mismo mes.

**6.2 Meses sin data.**
Usuarios nuevos no tendrán docs en `daily_summary` aún. El calendario debe renderearse con placeholders sin error.

**6.3 Cruce de meses al navegar.**
Si el usuario está en mayo 2026 y toca chevron derecho, debe ir a junio 2026 (no `mes+1` matemático que daría 13 inválido). Implementación con `DateTime` nativo lo maneja.

**6.4 Día actual en otro mes.**
Si el usuario navega a abril, el día 15 no debe destacarse como "hoy" porque hoy es 15 de mayo. La regla "es hoy" requiere comparar año + mes + día.

# 7. Out of scope

- Tap en una celda para ver detalle del día (drill-down → SPEC futura).
- Compartir captura del mes (botón export).
- Vista anual o múltiples meses lado a lado.
- Comparación mes vs mes anterior.
- Heatmap por pilar dentro del calendario (sería SPEC-113).

# 8. Resultado

(Se completa al cerrar el SPEC.)
