# SPEC-193 — Analytics de negocio + eventos de conducta

**Estado:** IN-PROGRESS (Fase 1 — fundación)
**Versión:** 1.0
**Tipo:** Medición. Ola A del plan de lanzamiento (doc `docs/analisis-liderazgo/09_PLAN_DE_ACCION`). Bloquea monetización (Ola C) y el feedback del coach (SPEC-194).
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** 4 días (fundación 1 día · wiring por feature 3 días).
**Depende de:** Firebase ya inicializado (`main.dart`), patrón `CrashlyticsService`.
**Bloquea:** SPEC-193.1 (alinear Privacy Label), SPEC-193.2 (dashboard), SPEC-194 (feedback loop y personalización usan estos eventos), Ola C (monetización).

---

## 1. Contexto

El proyecto no mide comportamiento de negocio: no hay Firebase Analytics. Sin embudo (instalación→registro→pilar→día-7→suscripción) no se puede decidir con datos ni validar retención/conversión en el soft-launch. Además, el pivot a coach (SPEC-194) necesita medir **si las recomendaciones cambian conducta** — eso requiere eventos de coaching desde el inicio.

Existe además una inconsistencia: el Privacy Label de tienda (`docs/LAUNCH_LISTINGS.md`) ya declara "Analytics" que el código no implementa. Esta SPEC la resuelve (vía SPEC-193.1, tras integrar Analytics).

## 2. Decisiones de producto

### 2.1 — Firebase Analytics como base
Mismo ecosistema que Crashlytics/Firestore. Sin SDK de terceros en MVP.

### 2.2 — Catálogo de eventos tipado (no strings sueltos)
Un único archivo `analytics_events.dart` con nombres y parámetros como constantes. Prohibido `logEvent('algo')` con string literal fuera del catálogo. Garantiza consistencia y evita typos que rompen reportes.

### 2.3 — Eventos de conducta de coaching desde el día 1
Aunque SPEC-194 aún no exista, el catálogo ya define `coaching_action_shown / followed / completed` y `coaching_feedback_shown`. Cuando el coach se implemente, solo dispara; la medición ya está.

### 2.4 — Privacidad: sin PII
Ningún parámetro contiene email, nombre ni datos de salud crudos. Solo identificadores y categorías. `setUserId` usa el uid de Firebase (ya pseudónimo).

## 3. Lo que NO se hace
- **NO** dashboard custom (es SPEC-193.2).
- **NO** edición del Privacy Label (es SPEC-193.1, requiere Analytics ya activo).
- **NO** A/B testing / Remote Config (post-PMF).
- **NO** se loguea PII ni datos de salud.

## 4. Catálogo de eventos (RF-193-01)

| Evento | Cuándo | Params |
|---|---|---|
| `app_open` | bootstrap | `platform` |
| `signup_complete` | registro OK | `method` |
| `login` | login OK | `method` |
| `onboarding_complete` | fin onboarding | `seconds`, `from_mr` |
| `fasting_started` | inicia ayuno | `protocol` |
| `fasting_completed` | cierra ayuno con target | `hours` |
| `meal_logged` | registra comida | `quality_bucket` |
| `imr_calculated` | snapshot IMR | `imr_bucket` |
| `pillar_logged` | registra cualquier pilar | `pillar` |
| `paywall_shown` | se muestra paywall | `trigger` |
| `trial_started` | inicia trial | — |
| `subscription_started` | compra | `plan` |
| `subscription_cancelled` | cancela | `plan` |
| `coaching_action_shown` | coach muestra acción | `action_id`, `source`, `pillar`, `phase` |
| `coaching_action_followed` | usuario toca CTA | `action_id`, `source` |
| `coaching_action_completed` | acción se cumple | `action_id`, `pillar` |
| `coaching_feedback_shown` | feedback de cierre | `outcome` |

## 5. Requisitos funcionales

### RF-193-01 — `analytics_events.dart` (catálogo)
Constantes de nombres y claves de parámetro. Fuente única.

### RF-193-02 — `AnalyticsService` (wrapper)
Estático, mismo patrón que `CrashlyticsService`: `init()`, `logEvent(name, params)`, `setUserId(uid)`, `setCurrentScreen(name)`. No-op seguro en web/debug si aplica. Nunca lanza (try/catch interno que delega a `AppLogger`).

### RF-193-03 — Init en `main.dart`
Tras `CrashlyticsService.init()`, llamar `AnalyticsService.init()` y disparar `app_open`.

### RF-193-04 — Wiring por feature (fase 2)
Disparar cada evento en su punto: auth (`signup_complete`/`login`), onboarding (`onboarding_complete`), pilares (`pillar_logged`, `fasting_*`, `meal_logged`), engine (`imr_calculated`). Monetización y coaching se cablean al implementar Ola C / SPEC-194.

## 6. Tests
- `AnalyticsService` no lanza si Analytics falla (mock/try-catch).
- El catálogo no tiene nombres duplicados (test de unicidad).
- `from_mr` y `quality_bucket` se calculan en buckets, sin PII.

## 7. Criterios de éxito
- 13 eventos base + 4 de coaching definidos en el catálogo.
- `app_open` visible en consola Firebase (DebugView).
- Cero PII en parámetros.
- Privacy Label alineado (vía SPEC-193.1).

## 8. Estado de implementación
- [x] Fundación: catálogo + `AnalyticsService` + init + `app_open`.
- [x] Wiring tope de embudo: `login`, `signup_complete` (auth), `onboarding_complete` con `from_mr` (onboarding), `setUserId` reactivo (app.dart).
- [x] Wiring pilares acción-directa: `pillar_logged` hidratación/ejercicio, `meal_logged` con `quality_bucket` (nutrición).
- [ ] Wiring pilares stream-driven: `fasting_started/completed`, `pillar_logged` sueño + engine `imr_calculated` (incremento 3).
- [ ] SPEC-193.1 Privacy Label · SPEC-193.2 Dashboard.
