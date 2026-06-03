# SPEC-161 — Coherencia de Pilares: 5 oficiales + Composición a Tendencia

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Corrección de fundamento — coherencia con identidad del producto
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 3-4 horas
**Marco normativo:** `CONSTITUTION.md` + project instructions ("5 pilares: ayuno, ejercicio, nutrición, sueño e hidratación").

---

## 1. Contexto

Carlos detectó el 2026-06-02 una incoherencia conceptual grave en SPEC-160:

El tab "Pilares" mostraba 4 chips:
- ✅ Ayuno
- ✅ Nutrición
- ✅ Sueño
- ❌ **Cuerpo** ← NO es un pilar (es outcome)

Y faltaban dos pilares oficiales: **Hidratación** y **Ejercicio**.

Las instrucciones del proyecto son explícitas: "5 pilares: ayuno, ejercicio, nutrición, sueño e hidratación". La app debe tratar los 5 con el mismo peso. Composición corporal (peso, cintura, %grasa, WHTR, masa magra) es el OUTCOME que cambia *como consecuencia* del trabajo en los 5 pilares — no un pilar en sí mismo.

Esta SPEC corrige la incoherencia.

## 2. Decisión de diseño

### 2.1 — Tab Pilares = 5 chips oficiales

```
Ayuno  Nutri  Hidrat  Ejerc  Sueño
─────                                ← underline en activo
```

Mapeo de chips a widgets:

| Chip | Widget |
|---|---|
| Ayuno | `CyclesHistoryCard` (existente — SPEC-156) |
| Nutrición | `MealsRatioCard` (existente — SPEC-158) |
| **Hidratación** | `HydrationWeeklyCard` ← **nuevo** |
| **Ejercicio** | `ExerciseWeeklyCard` ← **nuevo** |
| Sueño | `SleepQualityCard` (existente — SPEC-159) |

Default activo: **Ayuno** (orden de pilares del producto).

### 2.2 — Tab Tendencia incorpora Composición Corporal

Composición corporal NO es pilar — es OUTCOME longitudinal. Pertenece junto al IMR trend en el tab Tendencia.

```
Semana  Mes  3 Meses

[Hero IMR con sparkline]
[ImrTrendChart]

─────────────────────────

COMPOSICIÓN CORPORAL

[BodyCompositionTrendChart con 5 tabs internas]
```

Ambos son métricas que el usuario **observa cambiar** vs los pilares que el usuario **controla**.

### 2.3 — Widgets nuevos: patrón Sleep / Meals

Los 2 widgets nuevos siguen el patrón ya establecido en SPEC-158 (`MealsRatioCard`) y SPEC-159 (`SleepQualityCard`):
- Header con título + período (7 DÍAS).
- Headline con métrica principal + sub-métrica.
- 7 filas (una por día) con barra discreta + valor.
- Insight adaptativo por tier con headline + acción + cita.
- Empty state si no hay logs.

#### 2.3.1 — `HydrationWeeklyCard`

- Headline: litros promedio + % vs target diario (`weight * 0.035`).
- 7 filas: día abreviado + barra discreta 10 niveles + litros + % logrado.
- Tier por % promedio del target:
  - `severelyLow` < 60% → "Tu hidratación compromete cetonas y cortisol."
  - `low` 60-80% → "Estás bajo el target. Riesgo de retención y cansancio."
  - `adequate` 80-100% → "En rango. Sostené la cadencia."
  - `optimal` ≥ 100% → "Excelente. La constancia regula el sistema linfático."
- Citas: EFSA 2010, Popkin 2010 (mismas que SPEC-150).

#### 2.3.2 — `ExerciseWeeklyCard`

- Headline: minutos promedio + comparativa vs `user.exerciseGoalMinutes`.
- 7 filas: día abreviado + barra discreta + minutos + tipo (si presente).
- Tier por % promedio del target del usuario:
  - `sedentary` < 50% → "Movimiento insuficiente. Insulina sin regulación."
  - `low` 50-80% → "Cerca pero corto. Sumá 10 min más al día."
  - `meetsTarget` 80-120% → "En target. Sostené el ritmo."
  - `aboveTarget` > 120% → "Volumen alto. Verificá recuperación."
- Citas: OMS 150 min/sem, AHA 2018, Mattson 2017.

### 2.4 — Cero cambios en widgets existentes

`CyclesHistoryCard`, `MealsRatioCard`, `SleepQualityCard`, `BodyCompositionTrendChart` quedan intactos. Solo cambia su **ubicación** en los tabs.

## 3. Cambios técnicos

### 3.1 — Capa domain (pure Dart)

`lib/src/features/dashboard/domain/hydration_weekly_insight.dart`:
- `HydrationInsightTier` enum (empty, severelyLow, low, adequate, optimal).
- `HydrationWeeklyBreakdown` value object: litros por día (Map<DateTime, double>), promedio, target diario, tier.
- `HydrationCoachingMessage` con headline + action + citation por tier.

`lib/src/features/exercise/domain/exercise_weekly_insight.dart`:
- `ExerciseInsightTier` enum (empty, sedentary, low, meetsTarget, aboveTarget).
- `ExerciseWeeklyBreakdown` value object: minutos por día, tipos predominantes, promedio, target, tier.
- `ExerciseCoachingMessage` por tier.

### 3.2 — Capa application

`hydration_weekly_computer.dart` (pure Dart):
- `compute(logs, targetLiters, rangeStart, rangeEnd) → HydrationWeeklyBreakdown`.
- Agrupa logs por día. Suma litros por día. Calcula promedio.
- `pickTier(percentVsTarget)` con umbrales §2.3.1.

`exercise_weekly_computer.dart` (pure Dart):
- `compute(logs, targetMinutes, rangeStart, rangeEnd) → ExerciseWeeklyBreakdown`.
- Agrupa por día. Suma minutos. Calcula promedio + tipo predominante.
- `pickTier(percentVsTarget)` con umbrales §2.3.2.

Providers:
- `lastWeekHydrationProvider` consume `hydrationRepositoryProvider.watchSince(uid, now-7d)` + `currentUserStreamProvider` para target.
- `lastWeekExerciseProvider` consume `exerciseRepositoryProvider.watchSince(uid, now-7d)` + `currentUserStreamProvider` para target.

### 3.3 — Capa presentation

`hydration_weekly_card.dart`:
- ConsumerWidget watchea `lastWeekHydrationProvider`.
- Header + headline (litros prom + % target) + 7 filas + insight + empty state.
- Color del pilar: azul claro `#38BDF8` (coherente con PillarsHeatmap legacy).

`exercise_weekly_card.dart`:
- Patrón equivalente.
- Color del pilar: teal `#14B8A6`.

### 3.4 — Reorganización de tabs

`analysis_pillars_tab.dart`:
- Enum `_ActivePillar` cambia a `{ fasting, nutrition, hydration, exercise, sleep }`.
- Chips ahora son 5 (orden oficial del producto).
- Switch agrega casos hydration → `HydrationWeeklyCard`, exercise → `ExerciseWeeklyCard`.

`analysis_trend_tab.dart`:
- Después del `ImrTrendChart`, agregar divider + header "COMPOSICIÓN CORPORAL" + `BodyCompositionTrendChart`.

### 3.5 — Tests

Pure Dart. Cubren los 2 computers:
- Hydration: empty, agrupación por día, promedio, tiers (4 ramas).
- Exercise: empty, agrupación, promedio, tipo predominante, tiers.

## 4. Criterios de aceptación

1. Tab Pilares muestra exactamente 5 chips: Ayuno / Nutri / Hidrat / Ejerc / Sueño en ese orden.
2. Cada chip mapea al widget correcto (sin "Cuerpo").
3. Tab Tendencia incluye IMR trend + Composición corporal con divider intermedio.
4. `HydrationWeeklyCard` muestra litros promedio + 7 días + insight con cita.
5. `ExerciseWeeklyCard` muestra minutos promedio + 7 días + insight con cita.
6. Tests cubren computers (~10 casos cada uno).
7. `BodyCompositionTrendChart` ya no aparece en Pilares — solo en Tendencia.

### 4.1 — Sobre tests

Pure Dart. Sin widget test.

## 5. Out of scope

- **Refinamiento visual anti-ladrillo** (lo que pediste antes): SPEC-162 separada para no mezclar la corrección conceptual con el refinamiento visual.
- **Comparativa entre pilares** (ej: "tu mejor pilar de la semana"): futura.
- **Sub-tabs por pilar** (ej: hidratación con sub-vistas por tipo de líquido): no requerido.

## 6. Rollout

Sin breaking changes. Sin migración. Push directo + validación visual.

## 7. Changelog

### v1.0 — 2026-06-02

Corrección de fundamento tras feedback Carlos: tab Pilares debe reflejar los 5 pilares oficiales del producto, no agregar lo que no es pilar ni omitir los que sí lo son.
