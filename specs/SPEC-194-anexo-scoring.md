# SPEC-194 · Anexo — Pesos y funciones de scoring (propuesta)

**Estado:** APPROVED-DESIGN — pendiente de implementación (Ola B).
**Relación:** desarrolla el RF-194-03 (motor de scoring) con números concretos.
**Filosofía:** mismo estándar que `IMR_BIBLIOGRAPHY` — cada peso lleva justificación y **nivel de confianza**, y los que son heurística pura se marcan como `ENGINEERING JUDGMENT` para recalibrar con datos reales (telemetría SPEC-193).

---

## 1. Fórmula

> **Precedencia:** los pesos de esta sección quedan **sustituidos por `SPEC-194-adenda-circadiano §2`** cuando ambas specs estén vigentes. La adenda añade el término `circadianImpact` y rebalancea. Este anexo conserva la fórmula base (sin circadiano) como referencia de diseño.

Cada componente se normaliza a `[0,1]`. Los tres positivos suman 1; la fatiga es penalización.

```
score = 0.35 · urgency
      + 0.35 · relevance
      + 0.15 · confidence
      − 0.15 · fatigue
```

Rango efectivo del score: `[−0.15, 1.0]`.

### 1.1 — Justificación de los pesos macro

| Peso | Valor | Confianza | Razón |
|---|---|---|---|
| `w_urgency` | **0.35** | ENGINEERING JUDGMENT | Un coach que llega tarde no sirve. Co-domina con relevancia: la oportunidad correcta en el momento correcto. |
| `w_relevance` | **0.35** | ENGINEERING JUDGMENT | Una acción a tiempo pero irrelevante para *este* usuario es ruido. Co-iguala a urgencia a propósito: ninguna domina sola. |
| `w_confidence` | **0.15** | MEDIUM | Bajo porque casi todos los candidatos ya vienen de fuentes citadas; actúa como riel de seguridad y desempate, no como motor principal. |
| `w_fatigue` | **0.15** | ENGINEERING JUDGMENT | Penaliza repetir lo ignorado sin suprimir del todo lo importante. Calibrado para apagar tras ~3 ignoradas. |

> **Nota honesta (estilo IMR_BIBLIOGRAPHY):** el split 0.35/0.35/0.15/0.15 es decisión de equipo, sin estudio que lo valide. Es defendible (urgencia≈relevancia > confianza≈fatiga) pero su calibración exacta es **ENGINEERING JUDGMENT** y debe re-ajustarse con la tasa de acciones completadas que mida SPEC-193.

---

## 2. Funciones componente (cómo se calcula cada `[0,1]`)

### 2.1 — `urgency(candidate)` — sensibilidad al tiempo

Base por tipo + multiplicador de proximidad al deadline:

| Tipo de candidato | Base | Ejemplo |
|---|---|---|
| Deadline duro (ventana cerrando, eTRF cutoff) | 0.80 | "Cierra tu ventana" |
| Oportunidad de fase biológica | 0.55 | "Vas por autofagia (16h)" |
| Hábito / longitudinal | 0.30 | "Tu pilar débil es sueño" |
| Ajuste de protocolo (AdaptiveEngine) | 0.25 | "Listo para subir a 16:8" |

Para los de deadline: `urgency = base + (1 − base) · proximidad`, con `proximidad = 1 − (minutos_al_deadline / ventana_aviso)`, `ventana_aviso = 120 min`. Ej.: faltan 30 min → proximidad 0.75 → urgency `0.80 + 0.20·0.75 = 0.95`.

### 2.2 — `relevance(candidate, snapshot)` — encaje con este usuario ahora

```
relevance = 0.50 · pillarFit + 0.30 · actionability + 0.20 · goalAlignment
```

| Subcomponente | Cálculo |
|---|---|
| `pillarFit` | 1.0 si `candidate.pillar` == pilar más débil de la semana · 0.6 si es el 2.º más débil · 0.3 en otro caso |
| `actionability` | 1.0 si la acción es ejecutable *ahora* según fase/hora (ej.: "cerrar ventana" solo si la ventana está abierta) · 0.2 si no |
| `goalAlignment` | 1.0 si el pilar mapea a la meta declarada del usuario · 0.5 si no |

`pillarFit` pesa la mitad porque atacar el punto débil del usuario es el corazón de la personalización.

### 2.3 — `confidence(candidate)` — nivel de evidencia (de la bibliografía)

| Nivel | Valor |
|---|---|
| HIGH | 1.00 |
| MEDIUM | 0.70 |
| LOW | 0.40 |
| ENGINEERING JUDGMENT | 0.20 |

El `confidence` lo hereda el candidato de la cita que lo respalda en `IMR_BIBLIOGRAPHY` / `CIRCADIAN_BIBLIOGRAPHY`.

### 2.4 — `fatigue(candidate, snapshot)` — anti-cansancio

```
fatigue = min(1.0, 0.34 · ignoradasSeguidas + repetidaHoy · 0.5)
```

- `ignoradasSeguidas`: veces consecutivas que se mostró y NO se siguió (de telemetría SPEC-193). Se **resetea a 0 al seguirse.** → 0 / 0.34 / 0.68 / 1.0 (suprime tras 3 ignoradas).
- `repetidaHoy`: 1 si ya fue la principal hoy, 0 si no. Evita repetir la misma acción el mismo día.

---

## 3. Reglas de selección

1. **Override de deadline duro:** cualquier candidato con `urgency ≥ 0.90` (deadline inminente, ej. ventana cerrando en ≤30 min) es **siempre la principal**, sin pasar por el score. *Justificación:* perder un momento crítico es peor que la "óptima". Es la única regla que salta el scoring.
2. **Principal** = mayor `score` (si no hubo override).
3. **Secundaria** = se muestra solo si su `score ≥ 0.55` **y** ataca un pilar distinto al de la principal. Si no, solo principal.
4. **Período de gracia:** si `engagement == neutro` (< 3 días de datos), se suprime el motor y se muestra "Elena está aprendiendo tu ritmo".
5. **Desempate:** `confidence`, luego pilar más débil.

---

## 4. Ejemplos trabajados (la prueba de que personaliza)

**Mismo instante (19:30), dos usuarios distintos:**

### Usuario A — engagement excelente · pilar débil: ejercicio · ventana abierta cerrando 20:00 · protocolo 16:8

| Candidato | urgency | relevance | conf | fatigue | score | |
|---|---|---|---|---|---|---|
| Cerrar ventana (30 min) | **0.95** | 0.70 | 0.70 | 0.00 | — | **OVERRIDE → Principal** |
| Pilar débil: ejercicio | 0.30 | 0.86 | 0.70 | 0.00 | 0.51 | secundaria (pilar distinto, pero <0.55 → no se muestra) |

→ **A ve:** "Faltan 30 min para cerrar tu ventana." (deadline duro gana).

### Usuario B — engagement regular · pilar débil: sueño · sin evento de ventana (ya cerró) · 19:30

| Candidato | urgency | relevance | conf | fatigue | score | |
|---|---|---|---|---|---|---|
| Pilar débil: prepara tu descanso | 0.30 | **1.00** (pillarFit 1.0) | 0.70 (Walker) | 0.00 | **0.61** | **Principal** |
| eTRF pre-sueño | 0.55 | 0.50 | 1.00 (Sutton) | 0.00 | 0.59 | secundaria (>0.55, pilar distinto → se muestra) |
| Hidratación | 0.30 | 0.46 | 0.40 | 0.34 | 0.20 | descartada |

→ **B ve:** principal "Hoy bajemos el ritmo para dormir mejor" + secundaria "Cierra la cocina 3h antes de dormir".

**Misma hora, acciones distintas según estado.** Eso es el algoritmo, no una regla fija.

---

## 5. Cómo se recalibran estos números

Son un punto de partida, no dogma. Con la telemetría de SPEC-193 (mostradas vs. seguidas vs. completadas por tipo), se ajustan: si las acciones de "pilar débil" se completan mucho más que las de "deadline", subir `w_relevance`; si los usuarios ignoran las de baja confianza, subir `w_confidence`. Cuando haya suficiente señal por usuario, los pesos dejan de ser globales y pasan a aprenderse — eso es **SPEC-195 (personalización ML)**.

---

## 6. Constantes para `scoring_weights.dart`

```dart
// SPEC-194 §Anexo — pesos macro (ENGINEERING JUDGMENT, recalibrar con SPEC-193)
const double kWUrgency    = 0.35;
const double kWRelevance  = 0.35;
const double kWConfidence = 0.15;
const double kWFatigue    = 0.15;

// Bases de urgencia por tipo
const double kUrgencyDeadline = 0.80;
const double kUrgencyPhase    = 0.55;
const double kUrgencyHabit    = 0.30;
const double kUrgencyProtocol = 0.25;
const int    kUrgencyWindowMin = 120;

// Relevancia
const double kRelPillarFit = 0.50, kRelActionability = 0.30, kRelGoal = 0.20;

// Confianza por nivel de evidencia
const double kConfHigh = 1.00, kConfMedium = 0.70, kConfLow = 0.40, kConfEng = 0.20;

// Fatiga
const double kFatiguePerIgnore = 0.34, kFatigueRepeatToday = 0.50;

// Selección
const double kSecondaryThreshold = 0.55;
const double kHardOverrideUrgency = 0.90;
```
