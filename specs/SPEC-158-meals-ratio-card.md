# SPEC-158 — MealsRatioCard: distribución A:E semanal en Análisis

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Pieza de Ola 2 — expone clasificación Frank Suárez ya persistida
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 30-45 min
**Marco normativo:** `CONSTITUTION.md`. Consume `MealRatio` (SPEC-137) y `nutritionRepository.watchSinceLogs` (SPEC-149.2).

---

## 1. Contexto

Auditoría 2026-06-02 identificó que SPEC-137 (Tipo A / Tipo E de Frank Suárez) clasifica cada `NutritionLog` con un `MealRatio` (5 niveles: Todo A, 3 a 1, 2 a 1, 1 a 1, Todo E), persiste el valor en Firestore, y lo usa para calcular el Cociente A diario. Pero **el usuario no ve la distribución agregada en ningún lado**.

Esta SPEC añade `MealsRatioCard` debajo del `CyclesHistoryCard` en Análisis. Es la pieza que conecta el coaching del producto con el referente operacional Latinoamericano (Frank Suárez) sin reproducir su diseño visual (`reference_frank_suarez_guia_oficial`).

## 2. Decisión de diseño

### 2.1 — Layout

```
┌─────────────────────────────────────────────┐
│ TUS PLATOS                       7 DÍAS     │
│                                              │
│         84%                                  │
│       A-dominantes                           │
│                                              │
│  ████████████████████░░░░░░░                 │ ← stacked bar
│  ↑ Todo A · 3 a 1 · 2 a 1 · 1 a 1 · Todo E   │
│                                              │
│  Todo A   ▓▓▓▓▓▓░░  6                       │
│  3 a 1    ▓▓▓▓▓▓▓░  7                       │
│  2 a 1    ▓▓▓▓░░░░  4                       │
│  1 a 1    ▓▓░░░░░░  2                       │
│  Todo E   ░░░░░░░░  0                       │
│                                              │
│  💡 Tu semana fue A-dominante 84%.          │
│  Mantenete arriba del 70% para sostener     │
│  sensibilidad a la insulina.                │
│   — Frank Suárez (Tipo A/E)                  │
└─────────────────────────────────────────────┘
```

### 2.2 — Métrica principal: % A-dominante

Sigue el criterio de SPEC-137 (`MealRatio.isADominant`): suma los logs con `ratio ∈ {allA, a3e1, a2e1}` sobre el total. Es el número grande arriba — es lo que importa para el pilar Nutrición.

### 2.3 — Insight automático por umbral

| % A-dominante | Insight | Color |
|---|---|---|
| ≥ 80% | "Excelente semana A-dominante. Sostener este nivel desactiva la resistencia a la insulina." | verde |
| 70-79% | "Buen nivel A-dominante. Mantenete arriba del 70% para sostener sensibilidad a la insulina." | verde claro |
| 50-69% | "Tu semana tuvo demasiados platos E. Empezá por reemplazar uno por día con un Todo A." | ámbar |
| < 50% | "Tu semana fue E-dominante. Los alimentos refinados están dictando tu metabolismo." | rojo |
| Sin platos | "Registrá tus comidas para ver tu distribución A:E." | gris |

Todos los insights citan **Frank Suárez (Tipo A/E)** + cita complementaria de IG/CG (Jenkins 2002 — índice glucémico) cuando el copy lo permite.

### 2.4 — Stacked bar horizontal

Una barra única dividida en 5 segmentos proporcionales al conteo de cada `MealRatio`. Colores fijos:

| MealRatio | Color |
|---|---|
| Todo A | verde fuerte (metabolicGreen) |
| 3 a 1 | verde lima (#84CC16) |
| 2 a 1 | amarillo (#EAB308) |
| 1 a 1 | naranja (#F97316) |
| Todo E | rojo (#EF4444) |

El gradiente comunica "más A = mejor".

### 2.5 — Listado con conteos

5 filas con label + mini-barra discreta (proporcional al máximo de cualquier nivel) + número. Lectura rápida para confirmar el desglose.

### 2.6 — Período fijo: 7 días

Igual que `WeeklyCoachingCard`. Coherencia. Si emerge demanda de otros períodos, SPEC futura.

### 2.7 — Día de permitidos NO se excluye

Las comidas con `isCheatDay = true` se incluyen en el conteo. Son comidas reales que el usuario consumió. El cociente A diario las excluye del cálculo de `weeklyAdherence` (SPEC-137 §RF-137-07), pero **visualmente** queremos que aparezcan para que el usuario vea su semana completa. Si esto resulta confuso en validación, SPEC-158.1.

## 3. Cambios técnicos

### 3.1 — Nuevo dominio: `MealsRatioBreakdown`

`lib/src/features/nutrition/domain/meals_ratio_breakdown.dart`:

Value object con:
- `counts: Map<MealRatio, int>`
- `total: int`
- `aDominantCount: int`
- `aDominantPercent: double` (0..1)
- `rangeStart` / `rangeEnd`
- factory `empty()`

### 3.2 — `MealsRatioComputer`

`lib/src/features/nutrition/application/meals_ratio_computer.dart`:

Pure Dart. `compute(logs, rangeStart, rangeEnd) → MealsRatioBreakdown`.

Además `insightFor(percent) → MealsRatioInsight` (enum con headline + acción + cita).

### 3.3 — Provider

`lib/src/features/nutrition/application/last_week_meals_ratio_provider.dart`:

`StreamProvider.autoDispose<MealsRatioBreakdown>`. Consume `watchSinceLogs(uid, since=now-7d)` directamente del repo. Computa el breakdown.

### 3.4 — Widget `MealsRatioCard`

`lib/src/features/nutrition/presentation/widgets/meals_ratio_card.dart`:

ConsumerWidget. Header, % grande, stacked bar, 5 filas de listado, bloque de insight.

### 3.5 — Integración

En `analysis_screen.dart`, debajo del `CyclesHistoryCard`:

```dart
const CyclesHistoryCard(),
const SizedBox(height: 14),
const MealsRatioCard(),
const SizedBox(height: 14),
const BodyCompositionTrendChart(),
```

## 4. Criterios de aceptación

1. Análisis muestra `MealsRatioCard` debajo del `CyclesHistoryCard`.
2. % A-dominante grande arriba refleja conteo correcto sobre 7 días.
3. Stacked bar muestra los 5 segmentos proporcionales con colores fijos.
4. Lista de 5 filas con conteos correctos.
5. Insight cambia según umbrales del §2.3.
6. Empty state si no hay logs en la semana.
7. Tests cubren: counts por ratio, total, aDominantCount, insight por umbral.

### 4.1 — Sobre tests

Pure Dart. Cubre todos los thresholds + edge cases (0 logs, 1 solo log, mix).

## 5. Out of scope

- **Selector de período** (7d/14d/30d) — MVP fijo en 7d.
- **Heatmap día×día de A:E** — más complejo, SPEC futura.
- **Exclusión visual de cheat days** — incluidos en MVP por simplicidad.
- **Recomendación de plato específico** — el motor adaptativo lo hace en Dashboard, no se replica acá.

## 6. Rollout

Sin breaking changes. Sin migración. Push a `mvp-core-clean` + validación visual.

## 7. Changelog

### v1.0 — 2026-06-02

Conecta el referente Frank Suárez con la UI sin reproducir su diseño. Séptima entrega de Ola 2 hoy.
