# SPEC-190 — Analítica semanal por ciclos metabólicos cerrados

**Estado:** DRAFT v1.0 — pendiente aprobación
**Severidad:** P1 (alineación de analítica con modelo §1)
**Origen:** Decisión estratégica de Carlos 2026-06-05 (Tier 2 del refactor "cero reloj").
**Relacionado con:** SPEC-184 (Constitución §1), SPEC-189 (Tier 1 — operación sin reloj), SPEC-158, SPEC-161, SPEC-153.

---

## 1. Resumen ejecutivo

Toda la analítica retrospectiva ("últimos 7 días") está actualmente atada al reloj calendárico — `now.subtract(Duration(days: 7))` + `DayBoundaryResolver.startOfDay`. Esto viola §1 de la Constitución del Día Metabólico.

**Cambio:** la analítica cuenta **los últimos N ciclos cerrados**, no los últimos N días. Cada barra del chart, cada métrica de comparativa, cada insight semanal, se computa sobre la lista `MetabolicCycle[]` cerrada, ordenada por `closedAt` desc.

**Implicación clave:** si el usuario solo ha cerrado 3 ciclos en su vida, la "vista semanal" muestra 3 puntos, no 7. El widget se adapta. No inventamos días.

---

## 2. Decisiones de producto que necesito de Carlos

Antes de codificar, 4 decisiones que impactan UX:

| # | Decisión | Opción A | Opción B | Recomendación |
|---|----------|----------|----------|---------------|
| **D1** | ¿Cuántos ciclos por defecto? | "7 ciclos" (paralelo al 7-day) | "Ciclos del último mes" (variable según ritmo del usuario) | **A — 7 ciclos.** Más simple, predecible. |
| **D2** | ¿Incluir el ciclo abierto? | Solo ciclos cerrados | Cerrados + actual (pero etiquetado "en curso") | **A — solo cerrados.** La comparativa requiere data final, no parcial. |
| **D3** | ¿Qué pasa si < 7 ciclos? | Mostrar los N que hay + placeholder "necesitas más historial" | Bloquear card hasta tener 7 | **A — mostrar los N.** No bloquear; mostrar progreso aún con poca data. |
| **D4** | ¿Granularidad de barras en charts? | Cada barra = 1 ciclo cerrado | Cada barra = 1 ciclo, etiquetada con fecha de cierre | **B — etiquetar con fecha.** El usuario puede ver "este ciclo cerró el 5/junio" sin perder el cycle-aware. |

---

## 3. Cambios concretos por archivo

### 3.1 — Nueva API en `metabolic_cycle_repository.dart`

```dart
abstract class MetabolicCycleRepository {
  // ... existentes
  
  /// SPEC-190: stream con los últimos N ciclos CERRADOS del usuario,
  /// ordenados por closedAt descendente (más reciente primero).
  /// Excluye el ciclo abierto (`closedAt == null`).
  Stream<List<MetabolicCycle>> watchLastClosedCycles(
    String userId, {
    int limit = 7,
  });
}
```

Implementación Firestore: query `where('closedAt', isNotNull).orderBy('closedAt', desc).limit(N)`. Requiere índice compuesto (SPEC-145).

### 3.2 — `last_week_meals_ratio_provider.dart`

**Actual:** consume `nutritionRepository.watchSinceLogs(uid, now - 7d)`.

**Después:** consume `metabolicCycleRepository.watchLastClosedCycles(uid, 7)` + para cada ciclo extrae las magnitudes nutricionales del feedback consolidado (`cycle.feedback.magnitudes.nutritionMagnitude`).

Si necesitamos los logs raw para granularidad fina, hacemos un fan-out: `watchSinceLogs(uid, cycles.first.startedAt, until: cycles.last.closedAt)` y particionamos los logs por ciclo. Más caro pero más fiel.

**Decisión técnica:** empezar con el camino simple (magnitudes consolidadas del feedback). Si la analítica pierde resolución, hacer fan-out después.

### 3.3 — `last_week_hydration_provider.dart` y `last_week_exercise_provider.dart`

Mismo patrón: leer magnitudes consolidadas de los últimos 7 ciclos cerrados.

### 3.4 — `weekly_coaching_provider.dart` ⚠️ PARCIAL

**Hallazgo durante implementación:** consume `DailySummaryDoc[]` que es agregación por día calendárico (`users/{uid}/daily_summary/{date_iso}`). Migrar a ciclos requiere arquitectura nueva (nueva colección `cycle_summary` o re-agrupación al vuelo).

**Decisión:** queda PARCIALMENTE migrado en SPEC-190 — solo se actualiza el copy del card para no prometer "última semana calendárica" sino "última actividad". Lógica del cómputo intacta. Refactor completo se aborda en **SPEC-192** (Tier 4 — analytics infrastructure).

### 3.5 — `period_comparison_provider.dart` ⚠️ PARCIAL

Mismo problema arquitectural que 3.4. Migrar a "últimos 7 ciclos vs los 7 anteriores" requiere repensar el modelo `DailySummaryDoc`. Postpuesto a **SPEC-192**.

Para SPEC-190: TODO comment + warning en consola. Sin cambio funcional.

### 3.6 — Tests

Por cada provider migrado: smoke test con fake repository que retorna 7 ciclos cerrados sintéticos. Verificar que el cómputo es correcto.

---

## 4. Lo que NO cambia (preservar)

- `MetabolicCycle.feedback.magnitudes` — el feedback consolidado del ciclo ya existe (SPEC-149 §RF-149-08). Lo aprovechamos.
- El catálogo de alimentos, los pesos del IMR, los copies — intactos.
- La Transformation Card 30d (SPEC-148) sigue siendo "30 días calendáricos" porque ahí el contraste es contra cambios biométricos (peso, cintura) que sí son time-based fisiológicamente. Esto es **excepción consciente**.

---

## 5. Plan de entrega

- **Bloque A** (~30 min): nueva API `watchLastClosedCycles` en abstract + impl Firestore + test del repo + índice si necesario.
- **Bloque B** (~30 min): refactor de los 3 `last_week_*` providers (meals, hydration, exercise) para usar la nueva API.
- **Bloque C** (~25 min): refactor de `weekly_coaching_provider` con magnitudes consolidadas.
- **Bloque D** (~25 min): refactor de `period_comparison_provider` con 14 ciclos.
- **Bloque E** (~20 min): adaptar widgets para mostrar fecha de cierre del ciclo en cada barra + placeholder "necesitás más ciclos" cuando hay < N.
- **Bloque F** (~15 min): tests + flutter analyze + actualizar constitución §7 + commit.

Total estimado: **~2h 25min**.

---

## 6. Riesgo de UX

- **Usuario nuevo:** verá las cards de analítica con placeholder "necesitás cerrar más ciclos para ver tu evolución" durante sus primeros 7 ciclos. Es coherente con §1 pero requiere copy que invite, no que decepcione.
- **Usuario con ciclos cortos (ej. 16h):** completa 7 ciclos en ~4-5 días reales. La "vista semanal" muestra una semana metabólica que en calendario son menos días. Es por diseño.
- **Usuario con ciclos largos (ej. ayuno extendido 30h):** 7 ciclos son ~10 días reales. La vista cubre más territorio biográfico.

---

## 7. Decisión

Para implementar requiero `ok recomendación` o ajustes específicos a las 4 decisiones de §2.

## 8. Referencias internas

- `docs/METABOLIC_DAY_CONSTITUTION.md §1`
- `specs/SPEC-149-*.md` (feedback consolidado)
- `specs/SPEC-158/SPEC-161/SPEC-153/SPEC-162` (consumidores actuales)
