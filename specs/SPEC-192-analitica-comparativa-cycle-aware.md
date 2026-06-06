# SPEC-192 — Refactor completo: `DailySummaryDoc` → `CycleSummaryDoc`

**Estado:** DRAFT v2.0 — pendiente aprobación de decisiones de migración
**Severidad:** P1 — coherencia arquitectónica del modelo §1 a lo largo de todo el stack analítico
**Estrategia elegida por Carlos:** **B — Schema completo** (vs A minimalista que se descartó).
**Esfuerzo estimado:** ~50-80h totales, split en sub-SPECs entregables incrementalmente.
**Relacionado con:** SPEC-184 (Constitución §1), SPEC-149 (feedback consolidado), SPEC-190 (TODOs originados).

---

## 1. Cambio de premisa

El refactor minimalista (A) habría dejado el historial calendárico vivo. **Carlos eligió B = coherencia total**: todo el stack analítico opera por ciclos cerrados. El concepto "día calendárico" desaparece del producto.

**Implicación profunda:** el heatmap del calendario mensual, la strip semanal, el trend chart — todos pasan a ser **vistas cíclicas**, no calendáricas. El usuario ya no ve "lunes 5 jun" como una celda; ve "ciclo cerrado el 5 jun" como una entrada cronológica con su feedback.

---

## 2. Decisiones de producto pendientes (CRÍTICAS)

Antes de redactar plan de bloques necesito resolver 7 decisiones. Algunas tienen impacto en migración:

### D1 — Migración de usuarios existentes

| Opción | Descripción | Tradeoff |
|--------|-------------|----------|
| **A — One-shot reagrupar al login** | Job que toma `daily_summary` histórico y lo reasigna a ciclos cerrados según los timestamps | Caro al primer login pero preserva historial completo |
| **B — Doble esquema en paralelo** | Mantener `daily_summary` vivo durante 90 días + `cycle_summary` nuevo desde el deploy | Más complejo, pero da tiempo a usuarios para que se acumule data nueva |
| **C — Borrar y arrancar limpio** | Eliminar `daily_summary` al deploy, mostrar "tu historial empieza ahora" | Sin migración, pero pierde historial. Aceptable solo si MVP no tiene usuarios activos |

### D2 — Granularidad del `AnalysisPeriod`

| Opción | Week / Month / Quarter actual | Equivalente cycle-aware |
|--------|-------------------------------|--------------------------|
| **A — Fijo en ciclos** | 7 días → 7 ciclos · 30 días → 30 ciclos · 90 días → 90 ciclos | Predecible. Pero "30 ciclos" puede ser 15-60 días reales |
| **B — Adaptable** | Definir "month" como "últimos 4 períodos de 7 ciclos" | Más coherente conceptualmente, complejo en código |

### D3 — Nombre y forma de la nueva colección

| Opción | Descripción |
|--------|-------------|
| **A — `cycle_summary` separada** | Nueva collection con un doc por ciclo cerrado, key = `cycleId` |
| **B — Extender `metabolic_cycles` existente** | Reusar la collection actual, agregando los campos analíticos al doc del ciclo |

### D4 — Historial calendárico: ¿qué pasa con heatmap/strip/trend chart?

Estos widgets actualmente muestran "una fila por día calendárico". En el modelo B:

| Opción | Descripción |
|--------|-------------|
| **A — Renombrar a "vista por ciclo"** | Cada celda = ciclo cerrado, ordenado por `closedAt`. El usuario ve "ciclo 5 jun, ciclo 4 jun..." |
| **B — Reemplazar con timeline cronológico** | Lista vertical de ciclos con tarjetas (más narrativa, menos densa) |
| **C — Mantener vista calendárica + agregar vista cíclica** | El usuario elige qué ver. Duplica trabajo de UI |

### D5 — Goals (`goal_progress_computer`)

Las metas actualmente se evalúan sobre `daily_summary` por día. En B:

| Opción | Descripción |
|--------|-------------|
| **A — Metas se cumplen por ciclo** | "X ciclos con IMR ≥ 80" en lugar de "X días con IMR ≥ 80" |
| **B — Metas se mantienen calendáricas** | Goals queda como excepción documentada (similar a Transformation 30d) |

### D6 — Cómo se entrega el refactor

| Opción | Descripción |
|--------|-------------|
| **A — Sub-SPECs incrementales** | 192.1 (dominio + servicios), 192.2 (persistencia + migración), 192.3 (providers analítica), 192.4 (widgets). Cada una commitable independiente, **feature flag** para activar el nuevo flujo cuando esté completo. |
| **B — Una sola SPEC con feature flag** | Todo bajo `kEnableCycleSummary = false` hasta entregar todo. Más arriesgado por integración. |

### D7 — Timing

¿Cuándo se hace este refactor? Opciones:

| Opción | Descripción |
|--------|-------------|
| **A — Ola 4 dedicada** | Después de cierre de SPEC-138 + validación visual + SPEC-181 E2E. ~2 semanas dedicadas al refactor. |
| **B — Intercalado con otras SPECs** | Avanzar las sub-SPECs entre otros entregables. Tarda más pero no bloquea otros progresos. |

---

## 3. Plan de sub-SPECs propuesto (asume A en D6)

| Sub-SPEC | Alcance | Esfuerzo | Bloquea a |
|----------|---------|----------|-----------|
| **SPEC-192.1 — Domain & Services** | `CycleSummaryDoc` model + `CycleSummaryComputer` que mapea desde `MetabolicCycle.feedback` + tests | ~6h | 192.2 |
| **SPEC-192.2 — Persistencia + Migración** | Repository + Firestore impl + script de migración según D1 + índices + reglas de seguridad | ~12h | 192.3 |
| **SPEC-192.3 — Providers analítica** | `cycleComparisonProvider`, refactor de `weekly_coaching_provider` y `period_comparison_provider`, `cycle_score_computer` | ~10h | 192.4 |
| **SPEC-192.4 — Widgets analítica** | Refactor de heatmap, strip, trend chart, goals según D4+D5 | ~20h | 192.5 |
| **SPEC-192.5 — Cleanup + Deprecación** | Marcar `DailySummaryDoc` y todo su stack como `@Deprecated`, eliminar fallbacks calendáricos, feature flag flip | ~3h | — |
| **TOTAL** | | **~51h** | |

---

## 4. Riesgo

- **Alto.** 32 archivos tocados. Migración Firestore. Compatibilidad con usuarios existentes. Posibles regresiones en widgets que llevan meses estables.
- Mitigación: feature flag `kEnableCycleSummary` que arranca en `false` y se flippea solo cuando 192.1-192.4 están en producción + validados visualmente.

---

## 5. Lo que NO está en SPEC-192 (boundary)

- ❌ Cambios al `MetabolicCycle.feedback.magnitudes` (ese formato es la fuente). Si Carlos quiere agregar campos, va a sub-SPEC aparte.
- ❌ Re-diseño visual de Analysis tab (eso sería SPEC-193+ con diseñador).
- ❌ Eliminación física de docs `daily_summary` de Firestore (depende de D1).

---

## 6. Decisión necesaria

Para arrancar SPEC-192.1 necesito tus respuestas a las 7 decisiones (D1-D7). Sin esto codifico a ciegas.

Sin presiones — esto es estratégico y vale gastar tiempo en alinear bien antes de los 51h de trabajo.

---

## 7. Referencias

- `docs/METABOLIC_DAY_CONSTITUTION.md §1`
- `specs/SPEC-190-*.md` §3.4, §3.5
- `lib/src/features/analysis/data/daily_summary_doc.dart` (schema actual)
- `lib/src/features/metabolic_cycle/domain/metabolic_cycle.dart` (feedback consolidado)
