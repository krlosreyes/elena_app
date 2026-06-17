# SPEC-219 — Desacoplar weeklyAdherence del IMR (romper circularidad)

**Estado:** IMPLEMENTED (2026-06-17)
**Versión:** 0.1
**Líder:** Carlos · **Implementación:** Claude
**Depende de:** SPEC-65 (magnitudes continuas), SPEC-141 (IMR longitudinal).
**Prioridad:** Alta — pre-launch.
**Estimación:** 3 SP

---

## 1. Problema

`StreakEngine.computeWeeklyAdherence()` cuenta días donde `isEngaged` es true, que requiere **IMR ≥ 60 Y ≥3 pilares**. Pero `weeklyAdherence` alimenta al `ScoreEngine` vía `MetabolicState`, que calcula... el IMR. Es una dependencia circular lógica (no técnica — Riverpod no cicla porque el cálculo se hace en un solo frame):

```
ScoreEngine.calculateIMR(state) → usa state.weeklyAdherence
weeklyAdherence ← computeWeeklyAdherence() ← entry.isEngaged ← entry.imrScore >= 60
```

**Consecuencia para el usuario:** Un usuario nuevo que cumple 4/5 pilares pero con IMR < 60 (por adherencia previa baja) no acumula adherencia semanal, lo cual mantiene su IMR bajo. Loop de castigo invisible: necesitas IMR alto para subir la adherencia que necesitas para tener IMR alto.

## 2. Solución

### 2.1 Separar métricas

Renombrar y separar en `StreakEngine`:

| Métrica | Criterio | Consumidor |
|---------|----------|------------|
| `weeklyCompletionRate` (NUEVA) | `qualifiesForStreak` (≥3 pilares, sin IMR) | `ScoreEngine` vía `MetabolicState.weeklyAdherence` |
| `weeklyEngagementRate` (NUEVA) | `isEngaged` (≥3 pilares + IMR ≥ 60) | Analytics, display en Análisis |

### 2.2 Cambios en archivos

**`streak_engine.dart`:**
- `computeWeeklyAdherence()` → renombrar a `computeWeeklyCompletionRate()`, cambiar `e.isEngaged` a `e.qualifiesForStreak`.
- Agregar `computeWeeklyEngagementRate()` con la lógica actual (`isEngaged`).

**`streak_notifier.dart` / `StreakState`:**
- `weeklyAdherence` → calculada con `computeWeeklyCompletionRate()`.
- Agregar `weeklyEngagementRate` → calculada con `computeWeeklyEngagementRate()`.

**`metabolic_state_provider.dart`:**
- Sin cambio — ya lee `streakProvider.select((s) => s.weeklyAdherence)`, que ahora será completion-only.

**UI (Analysis):**
- Donde se muestre "adherencia semanal", usar `weeklyEngagementRate` para el display más exigente, y explicar al usuario el criterio: "X de 7 días con IMR ≥ 60 y al menos 3 pilares".

### 2.3 Migración

Sin migración de datos. El campo `weeklyAdherence` en `StreakState` cambia de semántica (de engagement a completion), pero el `MetabolicState` ya se recalcula reactivamente.

## 3. Tests

- `streak_engine_test.dart`: caso donde un usuario tiene 5/7 días con ≥3 pilares pero solo 2/7 con IMR ≥ 60.
  - `computeWeeklyCompletionRate()` → `5/7 ≈ 0.714`
  - `computeWeeklyEngagementRate()` → `2/7 ≈ 0.286`
- Verificar que `ScoreEngine.calculateIMR` con adherencia 0.714 vs 0.286 produce scores distintos (el primero más alto).

## 4. Riesgos

- El IMR puede subir ligeramente para usuarios con adherencia previa baja (porque ya no se penaliza por IMR bajo). Esto es **intencional** — rompe el loop de castigo.
- `weeklyQualityScore` (SPEC-53) no cambia — ya usa un promedio continuo sin umbral de IMR.

## 5. Notas

- El nombre `weeklyAdherence` se mantiene en `MetabolicState` para no romper 15+ consumidores — solo cambia la semántica interna.
- `isEngaged` sigue existiendo en `StreakEntry` para analytics — no se elimina.
