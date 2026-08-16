# SPEC-300 — Progreso: de filas-menú a tendencia + boletín

**Estado:** IMPLEMENTED (falta analyze/tests de Carlos y validar en simulador).
**Fecha:** 2026-08-16
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Pedido de Carlos

La pantalla Progreso "se ve muy básica" y, en una primera propuesta, quedaba
idéntica al Dashboard (Hoy). Explorar más opciones. Elegió **A (Tendencias) + C
(Boletín semanal)**.

## 2. Diagnóstico

- Progreso eran tres filas de menú idénticas (Insignias / Resultados / Hábitos):
  ícono + título + subtítulo + chevron. Parecía ajustes, no progreso.
- El dato clave (Score del día) iba escondido como subtítulo, sin jerarquía ni
  visual.
- Clave conceptual (está en el propio código): Progreso es **revisión
  histórica, no motivacional** — eso vive en Hoy. Así que no debe repetir el
  anillo del Dashboard; debe mostrar **evolución en el tiempo**.

## 3. Implementación

Reescritura de `analysis_screen.dart`: header + `ScoreTrendCard` +
`WeeklyReportCard` + `BadgesEntryCard` (strip de insignias/racha) +
`GlucoseEntryCard` (se autooculta). Se retiran de la pantalla `ResultsEntryCard`,
`HabitosEntryCard` y `WeeklyCoachingCard` (su navegación la absorben las dos
cards nuevas). Los archivos viejos quedan, sin enlazar.

### 3.1 ScoreTrendCard (opción A) — `widgets/score_trend_card.dart`
Línea del Score del Día en el rango (CustomPainter, dominio fijo 0–100) con
valor actual, promedio del periodo y chip de tendencia (▲/▼ vs el inicio del
rango). Fuente canónica `resolvedDailyScoreSeriesProvider` (SPEC-219). Estado
vacío honesto si hay pocos días. Toca → `/analysis/resultados`.

### 3.2 WeeklyReportCard (opción C) — `widgets/weekly_report_card.dart`
Boletín de la semana: **nota general** (A…E, derivada del promedio de los 5
pilares) + las 5 filas de pilar (barra de 7 niveles + % + delta vs semana
pasada) + bloque de **foco** accionable. Reusa el motor existente
`weeklyCoachingProvider` / `WeeklyCoachingInsight` (SPEC-153) — solo cambia la
presentación. Toca → `/analysis/habitos`.

## 4. Por qué no repite a Hoy
Hoy = estado en vivo (anillos del día). Progreso = **historia**: la línea del
Score en el tiempo y el boletín semanal con deltas vs la semana anterior. Ningún
anillo del día.

## 5. No-regresión
- Navegación preservada: Resultados y Hábitos siguen alcanzables (ahora desde la
  card del Score y la del boletín). Insignias intacta.
- Sin cambios de dominio/datos ni de reglas: solo presentación + un provider ya
  existente.

## 6. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/analysis
```

En simulador: abre Progreso → la línea del Score arriba (con datos reales del
histórico de ciclos), el boletín con nota + pilares + foco, y la fila de
insignias. Con pocos días de datos, la línea muestra su estado vacío.
