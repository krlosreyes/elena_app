# Plan de Delivery — actualización 2026-06-04

**Líder:** Carlos
**Implementación:** Claude
**Pivot vigente:** passive logging → active coaching (memoria `strategic-pivot-passive-to-active-coaching`, 2026-06-01)

Este documento cierra formalmente Ola 1, audita lo entregado de Ola 2 (vs plan original), y propone el delivery para las próximas 2-3 semanas. Sustituye el roadmap del 2026-06-01 sin contradecirlo: lo que se entregó por fuera del plan se contabiliza, lo pendiente queda visible.

---

## 1. Ola 1 — Estabilización · CERRADA con 1 ítem externo BLOCKED

| Pieza | SPEC | Estado |
|---|---|---|
| Persistencia histórica unificada | SPEC-143 | CLOSED 2026-06-01 |
| Auditoría Firestore indexes | SPEC-145 | CLOSED 2026-06-01 |
| Auth + App Check hardening | SPEC-146 | CLOSED 2026-06-01 |
| Día Metabólico + coaching closure | SPEC-149 | CLOSED 2026-06-01 |
| Día Metabólico hotfix coaching | SPEC-149.1 | CLOSED 2026-06-02 |
| Cycle-aware streams pilares | SPEC-149.2 | CLOSED 2026-06-02 |
| Recordatorios de hidratación cada 30 min | SPEC-150 | CLOSED 2026-06-01 |
| HealthKit observers + background delivery | SPEC-132.next | **BLOCKED externo** |

**SPEC-132.next bloqueada** por capability "Background Delivery" pendiente en Apple Developer Portal + regenerar provisioning profile. NO es deuda de código: el SPEC está redactado y aprobado, falta el unlock administrativo. Memoria `project_spec_132_next.md` cubre el contexto. Cuando Apple destrabe, la implementación + tests toman ~3-4 días (ya estimados en el SPEC).

### Deuda técnica heredada — vigente

**`dailyScoreProvider` sigue calendárico** (`lib/src/features/streak/application/daily_score_provider.dart`):

- Lee `streakProvider` → `StreakEntry` indexado por día calendárico (SPEC-138 `DayBoundaryResolver`).
- El Día Metabólico (SPEC-149) entrega coaching al cierre del ciclo, pero el badge "Score del Día" en el header de PILARES HOY sigue refrescándose a medianoche calendárica.
- Decisión 2026-06-01: postergar a Ola 2 para no romper el render del header durante estabilización.
- **Estado al 2026-06-04: la deuda sigue abierta.** Es candidata #1 para Ola 2.5 (ver §3).

---

## 2. Ola 2 entregada vs plan original

El plan del 2026-06-01 enumeró 7 piezas para Ola 2. Lo que pasó entre 06-01 y 06-04 fue distinto: Carlos detectó que la pantalla Análisis era el cuello de botella del coaching visual y pivotó el sprint hacia rediseñarla completamente al patrón Apple Fitness/Health. El resultado es un sprint de ~30 SPECs no previstas, todas alineadas con el pivot "active coaching" desde la palanca visual.

### 2.1 — Plan Ola 2 original (06-01)

| Plan original | Estado real al 06-04 |
|---|---|
| BodyCompositionTrendChart | ✅ CLOSED SPEC-152 |
| WeeklyAdherenceHeatmap | ✅ Ya existía (PillarsHeatmap, SPEC-113) |
| PeriodComparisonCard | ✅ Cubierto por SPEC-153 WeeklyCoachingCard |
| GoalsProgressDashboard | ✅ CLOSED SPEC-154 |
| Notificaciones inteligentes (autofagia/eTRF/cierre ventana) | ⏸ **Pendiente** |
| SPEC-142 UI dual de scores acelerada | ⏸ **Pendiente** (nunca redactada) |
| SPEC-138 ultra-procesados nutrición | ⏸ **Pendiente** |

### 2.2 — Sprint Análisis-como-coach (no previsto, entregado igual)

Todas CLOSED entre 2026-06-02 y 2026-06-04. 16 SPECs:

- **SPEC-151** Continue fasting past target
- **SPEC-155** Cleanup legacy insights
- **SPEC-156** Cycles history card
- **SPEC-157** Body composition + WHTR + masa magra (clinical metrics)
- **SPEC-158** Meals ratio A:E card
- **SPEC-159** Sleep quality card
- **SPEC-160** Analysis tabs reorganization (Hoy / Pilares / Tendencia / Resultados)
- **SPEC-161** Pillars coherence (hidratación L, ejercicio min, ayuno h)
- **SPEC-162** Analysis traceability + causa-efecto
- **SPEC-163** Apple Fitness style base
- **SPEC-164** Temporal aggregation (daily/weekly/monthly)
- **SPEC-165** Apple Fitness visual refresh
- **SPEC-166** Nutrition dual indicator
- **SPEC-167** Bar chart Y-axis magnitude fix
- **SPEC-168 (0–8)** Apple Health refresh con 13 sub-SPECs cerradas (goals integration, hero block, target line, achievement indicator, overview anteriores, trend comparison, tap tooltip, bar color by state)

### 2.3 — Coherencia con el pivot

El sprint cumple la promesa "active coaching" mejor que algunas piezas del plan original: cada chart muestra promedio + delta + objetivo + cumplimiento (X de N días) y permite drill-down al tocar una barra. La pantalla pasó de "estado actual" a "tu cambio reciente", que era el criterio del pivot.

**Lo que el sprint NO resolvió y sigue pendiente del pivot:**
- Notificaciones con cita bibliográfica (autofagia, eTRF, cierre ventana).
- UI dual visible de scores (Score del Día calendárico vs IMR semanal). Hoy conviven en distintas pantallas sin contraste explícito.
- Clasificación nutricional ultra-procesados (SPEC-138).

---

## 3. Ola 2.5 — Cierre técnico + 3 pendientes del pivot

Propuesta para las próximas ~2 semanas. Combina la deuda técnica vigente con los pendientes del plan Ola 2 que sí mueven la aguja del pivot.

### 3.1 — Refactor `dailyScoreProvider` a ciclo metabólico (3 días)

Resolver SPEC-149 §13.7. Hoy el header de PILARES HOY refresca a medianoche; debe refrescar al cierre del ciclo metabólico.

**Por qué primero:** el resto de Ola 2.5 (notificaciones, dual scores) depende de tener una sola fuente de verdad del "ahora" del usuario. Si las notificaciones se anclan al día calendárico mientras el coaching se ancla al ciclo, el usuario va a recibir mensajes incoherentes.

**Riesgo:** rompe sitio Astro Metamorfosis Real si no se cuida la separación `DayBoundaryResolver` (sigue dueño de `daily_summary/{YYYYMMDD}`) vs `MetabolicCycleResolver` (dueño del coaching). SPEC-149 §13.5 ya tiene la tabla de responsabilidades — hay que respetarla.

### 3.2 — SPEC-169 Notificaciones inteligentes (4 días)

Reemplaza el ítem "notificaciones inteligentes" del plan original. Cada notificación lleva cita bibliográfica accesible vía "saber más" → ExplainerSheet (patrón ya usado en SPEC-140 y SPEC-149).

**Cadencia mínima viable:**
- Aviso ventana de comida cerrándose: 1h y 30min antes del objetivo → cita Mattson 2017.
- Aviso autofagia alcanzada: hora 16 de ayuno → cita Levine 2017.
- Aviso eTRF óptimo: 3h antes de dormir → cita Sutton 2018 / Hutchison 2019.
- Aviso hidratación cíclica: ya implementado en SPEC-150, agregarle cita.

**Decisión a tomar antes de implementar:** ¿el SPEC-150 actual mantiene cadencia 30min o pasa a cadencia adaptativa (cada 90min si el usuario ya tomó agua)? Resolverlo al redactar el SPEC.

### 3.3 — SPEC-170 UI dual de scores explícita (2 días)

Hoy el Score del Día (motivacional, 0-100, llega a 100) vive en el header del Dashboard. El IMR (longitudinal) vive en el badge de Perfil y en la pantalla Análisis. El usuario no entiende por qué hay dos números.

**Propuesta:** en el header del Dashboard, mostrar ambos lado a lado con etiqueta clara ("HOY 87" / "IMR 64") y un explainer único que aclare la diferencia. Reusa el patrón de `PillarRing` con dos rings concéntricos o adyacentes.

**Por qué importa:** el pivot "active coaching" requiere que el usuario entienda qué métrica está optimizando en cada acción. Sin contraste visible, el Score del Día se siente arbitrario.

### 3.4 — SPEC-138 Ultra-procesados (postpuesto a Ola 3)

Lo dejamos fuera de Ola 2.5 porque requiere base de datos de ingredientes / scanner, que es trabajo pesado. La feature está documentada en SPEC-138 desde el principio y sigue siendo deseable, pero no es la palanca de mayor retorno ahora.

---

## 4. Ola 3 — Validación clínica + retención (~4-6 semanas a partir del cierre Ola 2.5)

Sin cambios vs plan 2026-06-01:

- **SPEC-141 IMR longitudinal** implementado detrás de feature flag interno + disclaimer "validación pendiente".
- **Contactar especialista clínico** con producto funcional para firma.
- **SPEC-147** Insights adaptativos semanales con cita.
- **SPEC-148** Comparativa antes/después 30 días.
- **Onboarding redefinido** para reflejar la promesa de coach (no de cuaderno).
- **SPEC-138** ultra-procesados desbloqueado tras Ola 2.5.

---

## 5. Decisión para el delivery inmediato

**Recomendación: arrancar SPEC-169 (notificaciones inteligentes) ANTES que el refactor del `dailyScoreProvider`.**

Razón: las notificaciones se pueden anclar al ciclo metabólico desde el día 1 (los providers de SPEC-149 ya exponen el ciclo abierto y su `startedAt`), sin tocar el `dailyScoreProvider`. El refactor del score puede ir después porque su impacto es menor (un badge) que el de las notificaciones (cada usuario las ve varias veces por día).

Alternativa: si Carlos prefiere cerrar la deuda técnica primero por higiene, arrancamos por §3.1. El delivery total no cambia, solo el orden.

**Próximo paso operativo:** Carlos decide §3.1 o §3.2 como primera SPEC del bloque. Claude redacta el SPEC formal, lo aprueba Carlos, ejecutamos.

---

## 6. Referencias

- Memoria: `strategic-pivot-passive-to-active-coaching` (decisión 2026-06-01)
- Memoria: `spec-149-metabolic-day` (deuda dailyScoreProvider §13.7)
- Memoria: `imr-dual-architecture` (Score del Día vs IMR)
- Memoria: `project_spec_132_next` (HealthKit BLOCKED Apple)
- Bibliografía: `docs/CIRCADIAN_BIBLIOGRAPHY.md`, `docs/NUTRITION_BIBLIOGRAPHY.md`, `IMR_BIBLIOGRAPHY.md`
- SPECs activos vigentes: SPEC-141 (APPROVED-DESIGN, Ola 3), SPEC-132.next (BLOCKED externo)
