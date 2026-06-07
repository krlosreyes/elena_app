# SPEC-194 — Motor de Decisión de Coaching (MVP)

**Estado:** APPROVED-DESIGN — pendiente de implementación (Ola B).
**Versión:** 0.1 (draft)
**Tipo:** Active coaching — núcleo del pivot. Convierte la app de registro en coach: lee estado → recomienda → da feedback, personalizado por usuario.
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola B (Coaching Loop MVP) — entre medición (SPEC-193) y monetización.
**Estimación:** ~8–10 días (motor + surface + feedback + tests). Timebox duro: no se extiende a ML en esta SPEC.
**Marco normativo:** `IMR_BIBLIOGRAPHY.md`, `docs/CIRCADIAN_BIBLIOGRAPHY.md`, `docs/NUTRITION_BIBLIOGRAPHY.md`.
**Depende de:** SPEC-193 (telemetría de conducta — para el loop de feedback y futura personalización), Orchestrator (`Recommendation`, fases biológicas), `AdaptiveEngine`, `EngagementService`, `MetabolicCycleResolver`, `CycleFeedback`, SPEC-169 (patrón cita).
**Bloquea:** Ola C monetización (cobramos por coach, no por logger), SPEC-195 (personalización por ML — usa la telemetría que este motor empieza a generar).

---

## 1. Contexto

El pivot 2026-06-01 (passive logging → active coaching) avanzó en la pantalla de Análisis (retrospectiva) y en notificaciones (SPEC-169), pero el **loop de coaching diario sigue ausente**: la app muestra lo que el usuario hizo, no le dice proactivamente qué hacer *ahora* ni cierra el ciclo con feedback. El usuario sigue percibiendo a Elena como cuaderno.

Diagnóstico de código (análisis de liderazgo, jun-2026): **el cerebro del coach ya existe pero está desarmado.** `AdaptiveEngine` decide subir/bajar protocolo; el `Orchestrator` emite `Recommendation` tipadas por pilar y prioridad — pero su propio código declara que *no tiene textos de UI y depende de que presentación las mapee*, y hoy casi no se muestran. `EngagementService` clasifica al usuario; `CycleFeedback` da coaching al cierre. Son piezas sueltas, no un motor.

**Principio rector (decisión de Carlos):** la siguiente acción **no se hardcodea**. No todos los usuarios son iguales. Se necesita un algoritmo que *identifique el estado actual, recomiende y dé feedback personalizado*. Esta SPEC construye ese algoritmo como **motor de reglas + scoring determinista y explicable** (no ML en MVP).

### Por qué reglas+scoring y no ML ahora

- **Personalizado igual:** la recomendación depende del estado real de cada usuario, no de una regla fija.
- **Explicable y testeable:** coherente con la promesa "científico y verificable". Un coach que no puede justificar su recomendación erosiona la marca.
- **Shippeable:** reusa motores existentes; cabe en el timebox.
- **Habilita el ML después:** el feedback loop (RF-05) + la telemetría de SPEC-193 generan el dataset que un modelo necesitaría. ML = SPEC-195, post-PMF.

---

## 2. Decisiones de producto

### 2.1 — Un solo "Next Best Action" prominente en Home

El Home gana un card primario **"Tu siguiente paso"** que responde *¿qué hago ahora?*. Una acción principal (opcional una secundaria), con su *razón* y "saber más" (cita), reusando el patrón de SPEC-169. Es lo primero que ve el usuario, por encima de los registros.

### 2.2 — La acción se elige por estado, no por regla fija

El motor arma un `CoachingSnapshot` del usuario y puntúa candidatos de todas las fuentes. Gana el de mayor score *para ese usuario en ese momento*. Dos usuarios distintos —o el mismo usuario en dos momentos— reciben acciones distintas.

### 2.3 — Feedback personalizado que cierra el loop

Al cierre del ciclo metabólico (o al día siguiente), el motor compara la acción recomendada vs. lo que el usuario hizo vs. su propia base, y emite feedback ("ayer priorizaste sueño y tu pilar subió 8 puntos; hoy mantengamos la ventana"). Esto es lo que convierte el número en conducta.

### 2.4 — Explicabilidad obligatoria

Toda recomendación lleva: `reason` (por qué, en lenguaje humano), `pillar` (qué pilar ataca) y `confidence` (nivel de evidencia, de la bibliografía). El usuario siempre puede ver el "por qué".

### 2.5 — Anti-fatiga

El motor no repite una recomendación que el usuario ignoró N veces seguidas, ni satura: máximo 1 principal + 1 secundaria por sesión de Home. La sensibilidad al tiempo puede reemplazar la principal del día.

---

## 3. Lo que NO se hace (límites duros)

- **NO ML / personalización aprendida.** Pesos globales fijos en MVP; el ajuste por usuario es SPEC-195.
- **NO se reescriben los motores existentes** (Orchestrator, AdaptiveEngine, EngagementService). El motor los *consume*; no los refactoriza.
- **NO refactor de `dailyScoreProvider`** (deuda Ola 2.5 separada; el motor lee, no la reescribe).
- **NO nuevas notificaciones** (SPEC-169 ya cubre lockscreen; este motor vive in-app). Integración push = SPEC-194.next.
- **NO se crea contenido clínico nuevo;** se reusan citas ya existentes en la bibliografía.

---

## 4. Arquitectura

Nueva feature `lib/src/features/coaching/` con la estructura canónica (CONSTITUTION §3):

```
coaching/
 ├── domain/
 │    ├── coaching_snapshot.dart        # estado actual del usuario (input)
 │    ├── coaching_action.dart          # recomendación tipada (output) + reason/pillar/confidence
 │    ├── action_source.dart            # enum de fuentes (orchestrator, adaptive, weakPillar, timeSensitive, cycleClose)
 │    ├── coaching_feedback.dart        # feedback de cierre de loop
 │    └── scoring/
 │         ├── candidate.dart           # ScoredCandidate(action, score, breakdown)
 │         └── scoring_weights.dart     # pesos globales (constantes, citadas)
 ├── application/
 │    ├── coaching_snapshot_builder.dart # ensambla el snapshot desde providers existentes
 │    ├── candidate_generators.dart      # cada fuente → List<CoachingAction>
 │    ├── coaching_decision_engine.dart  # genera → puntúa → rankea → selecciona
 │    ├── coaching_feedback_service.dart  # cierre de loop
 │    └── coaching_providers.dart        # Riverpod
 └── presentation/
      ├── next_best_action_card.dart     # card primario de Home
      └── action_explainer_sheet.dart    # "saber más" con cita
```

### Flujo

```
[providers existentes] → CoachingSnapshotBuilder → CoachingSnapshot
        → CandidateGenerators (N fuentes) → List<CoachingAction>
        → CoachingDecisionEngine.score()  → List<ScoredCandidate>
        → select top-1 (+top-2 secundaria)
        → NextBestActionCard (UI)
        → [usuario actúa] → SPEC-193 telemetría (shown/followed/completed)
        → CoachingFeedbackService (cierre ciclo) → CoachingFeedback
```

---

## 5. Requisitos funcionales

### RF-194-01 — `CoachingSnapshot` (lectura de estado)

`CoachingSnapshotBuilder` ensambla, sin lógica nueva de dominio, desde providers existentes:

| Campo | Fuente |
|---|---|
| `biologicalPhase`, `timeOfDay` | Orchestrator / `circadian_rules` |
| `fastingStatus`, `fastingHours`, `eatingWindowState` | `fasting` / `metabolic_cycle` |
| `weakestPillarThisWeek` | análisis semanal (pilar con menor adherencia/score) |
| `imrTrend` | `analysis` |
| `engagementLevel` | `EngagementService` |
| `cycleState` | `MetabolicCycleResolver` |
| `streak` | `streak` |
| `protocol`, `goals`, `bodyData` | `user` / `goals` |
| `recentRecommendations` | telemetría SPEC-193 (shown/followed) |

**Contrato:** función pura sobre los datos ya cargados; sin acceso directo a Firestore (CONSTITUTION §3.2).

### RF-194-02 — Generadores de candidatos

Cada fuente implementa `List<CoachingAction> generate(CoachingSnapshot s)`:

- **OrchestratorGenerator** — mapea `Recommendation` (id semántico → texto + cita) a `CoachingAction` según la fase. *(Resuelve el gap de "Recommendation sin UI".)*
- **AdaptiveGenerator** — envuelve `AdaptiveEngine.evaluateProtocolAdjustment` (level-up/simplify).
- **WeakPillarGenerator** — acción concreta sobre `weakestPillarThisWeek`.
- **TimeSensitiveGenerator** — ventana cerrándose, autofagia cerca, eTRF pre-sueño.
- **CycleCloseGenerator** — alimenta el feedback de cierre (RF-05).

Cada `CoachingAction` incluye: `id`, `title`, `actionText`, `reason`, `pillar`, `confidence`, `citation`, `source`, `intrinsicUrgency`.

### RF-194-03 — Motor de scoring

`CoachingDecisionEngine.score(candidate, snapshot)` → `double`, combinación lineal transparente:

```
score = w_urgency   * urgency(candidate)            // sensible al tiempo > hábito
      + w_relevance  * relevance(candidate, snapshot) // ¿ataca su punto débil? ¿accionable ahora?
      + w_confidence * confidence(candidate)          // HIGH > MEDIUM > ENGINEERING JUDGMENT
      - w_fatigue    * fatigue(candidate, snapshot)   // penaliza lo ya ignorado / repetido
```

Pesos en `scoring_weights.dart` como constantes documentadas (cada peso con su justificación, estilo `IMR_BIBLIOGRAPHY`). **Selección:** top-1 principal; top-2 como secundaria solo si su score supera un umbral. Empates → desempata `confidence`, luego `pillar` más débil.

### RF-194-04 — `NextBestActionCard` (surface)

Card primario en Home, sobre los registros. Muestra `title` + `actionText` + chip de pilar + botón "saber más" (→ `ActionExplainerSheet` con `reason` + `citation`). CTA que lleva al pilar correspondiente. Estado vacío durante período de gracia (`engagement == neutro`): "Elena está aprendiendo tu ritmo".

### RF-194-05 — Feedback personalizado (cierre de loop)

`CoachingFeedbackService`, disparado al cierre del ciclo (reusa hook de `CycleFeedback`): compara `recommendedAction` vs `userBehavior` (de telemetría) vs base del usuario, y produce `CoachingFeedback{message, outcome, nextNudge}`. Ejemplos:

- Seguida + mejoró: "Ayer priorizaste sueño y tu pilar subió 8 puntos. Hoy, mantengamos la ventana."
- No seguida: "Ayer te sugerí cerrar la ventana antes. Sin culpa — hoy probamos de nuevo, a tu ritmo."
- Tono humano-cercano (memoria `notification-tone-human-not-clinical`).

### RF-194-06 — Telemetría de conducta (con SPEC-193)

Emitir eventos: `coaching_action_shown`, `coaching_action_followed`, `coaching_action_completed`, `coaching_feedback_shown`. Son la base del GATE (tasa de acciones completadas) y de la personalización futura (SPEC-195).

---

## 6. Tests (desde la spec — CONSTITUTION §9)

- **Unit motor:** dado un `CoachingSnapshot` fijo, el engine selecciona el candidato esperado (≥15 casos cubriendo: usuario en ayuno vs ventana abierta, pilar débil distinto, engagement crítico vs excelente, ventana cerrándose, anti-fatiga tras 3 ignoradas).
- **Determinismo:** mismo snapshot → misma selección (sin aleatoriedad).
- **Cobertura de fuentes:** cada generador produce candidatos válidos y bien formados (con reason+citation+confidence).
- **Feedback:** seguida/no-seguida/mejoró/empeoró → mensaje correcto.
- **Golden:** `NextBestActionCard` en sus estados (principal, principal+secundaria, vacío/gracia).

---

## 7. Criterios de éxito

- El Home muestra una acción prescriptiva personalizada por estado, no fija.
- Dos snapshots distintos producen acciones distintas (verificado por test).
- Toda recomendación es explicable (reason + cita visibles).
- El loop cierra: el usuario recibe feedback sobre su acción previa.
- Telemetría de conducta fluyendo (habilita el GATE).
- **Métrica de producto (medida en soft-launch):** tasa de acciones recomendadas completadas — la señal de PMF del coach.

---

## 8. Riesgos

- **Pozo sin fondo de "coaching".** Mitigación: timebox + límites §3 (sin ML, sin reescribir motores).
- **Recomendaciones irrelevantes erosionan confianza.** Mitigación: anti-fatiga + explicabilidad + tests de selección.
- **Dependencia de SPEC-193.** El MVP del motor funciona sin telemetría (selección y surface), pero el feedback y la personalización la requieren. Secuenciar 193 antes.

---

## 9. Roadmap de evolución (fuera de esta SPEC)

- **SPEC-194.next:** integración push del Next Best Action (lockscreen).
- **SPEC-195:** personalización aprendida (pesos por usuario) usando la telemetría acumulada → de reglas a modelo.
