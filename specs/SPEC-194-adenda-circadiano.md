# SPEC-194 · Adenda — Conciencia circadiana del coach (prioritario)

**Estado:** APPROVED-DESIGN — pendiente de implementación (Ola B).
**Relación:** revisa el §1 del Anexo de scoring (los pesos macro) e introduce un componente nuevo. Sustituye la fórmula previa.
**Anclaje en código:** `CircadianEngine` (fuente única de fases), `score_engine.dart` (bloque de conducta), `IMR_BIBLIOGRAPHY §4.6`, `CIRCADIAN_BIBLIOGRAPHY`.

---

## 1. Por qué el circadiano es prioritario (no es opinión, está en el IMR)

El propio motor del IMR ya lo dice:

- El **factor circadiano pesa 0.38 del bloque de conducta** — el componente individual más grande (vs. sueño 0.20, ejercicio 0.20, hidratación 0.10, nutrición).
- La revisión clínica externa (SPEC-70.5) **subió ese peso de 0.28 a 0.38** y catalogó el circadiano como **"el eje"** de la salud metabólica.
- Cruzar el **bloqueo intestinal (21:30)** corta el factor circadiano de **1.0 a 0.5** instantáneamente — la penalización más severa del bloque de conducta. Comer temprano da bonus (1.1).

**Conclusión de diseño:** el coach debe ponderar el circadiano *al menos tan fuerte como el IMR lo hace.* Por eso esta adenda lo convierte en un componente explícito del score, no en una fuente más entre otras.

---

## 2. Fórmula revisada (v1.1)

Se añade `circadianImpact` como término propio y se rebalancean los pesos:

```
score = 0.28 · urgency
      + 0.27 · relevance
      + 0.30 · circadianImpact      ← NUEVO, el peso positivo más alto
      + 0.15 · confidence
      − 0.12 · fatigue
```

| Peso | v1.0 | **v1.1** | Razón del cambio |
|---|---|---|---|
| `w_urgency` | 0.35 | **0.28** | Cede espacio; gran parte de la urgencia circadiana ya la captura el nuevo término. |
| `w_relevance` | 0.35 | **0.27** | Sigue alto (pilar débil), pero el circadiano absorbe parte de la "relevancia metabólica". |
| `w_circadianImpact` | — | **0.30** | **El más alto, espejo del 0.38 que el circadiano pesa en el bloque de conducta del IMR.** El coach prioriza lo que el IMR premia. |
| `w_confidence` | 0.15 | 0.15 | Sin cambio. |
| `w_fatigue` | 0.15 | 0.12 | Leve baja: nunca se debe silenciar por fatiga una acción circadiana de alto impacto. |

> **Principio:** *el coach pondera el circadiano alto porque el IMR lo hace.* Esto mantiene la coherencia "lo que recomiendo = lo que mido", clave para la explicabilidad y la marca "científico y verificable".

---

## 3. `circadianImpact(candidate, snapshot)` — cómo se calcula

Mide **cuánto protege o mejora la acción el factor circadiano del usuario** (el mismo `circadianScore` que entra al IMR), `[0,1]`:

| Situación de la acción | circadianImpact | Por qué |
|---|---|---|
| Protege un límite circadiano que se va a cruzar (cerrar ventana antes de 21:30) | **1.0** | Evita la caída 1.0 → 0.5 — el mayor daño evitable. |
| Captura el bonus de comer temprano (primera comida en ventana óptima) | **0.85** | Habilita el bonus 1.1. |
| Alinea la actividad a su fase óptima (entrenar en MOTOR/FUERZA 15–20h) | **0.75** | Ejercicio en su pico circadiano. |
| Protege el inicio de sueño (bajar ritmo cerca de 22:30) | **0.80** | Sueño acoplado al circadiano. |
| Acción neutra respecto a la fase (hidratar a media tarde) | **0.30** | No daña ni potencia el eje. |
| Acción contra-fase (cena pesada 21:00, ejercicio intenso 22:00) | **0.0** | El motor NO la genera como positiva; queda deprior­izada. |

El valor se deriva de la fase actual (`CircadianEngine.currentPhase`) y de los minutos al próximo límite (`timeUntilLock`, inicio de SUEÑO). El candidato hereda su `circadianImpact` de una tabla fase × tipo-de-acción, citada en `CIRCADIAN_BIBLIOGRAPHY`.

---

## 4. Mapa fase → acción óptima (el "menú" circadiano del coach)

`CircadianCandidateGenerator` propone, según la fase activa:

| Fase (hora) | Qué empuja el coach | Cita |
|---|---|---|
| **ALERTA** (6–9) | Hidratar al despertar; luz natural; no comer aún si está en ayuno | Biological Dial §3 |
| **COGNITIVO** (9–13) | Trabajo profundo; primera comida si toca abrir ventana | Sutton 2018 |
| **RECESO** (13–15) | Comida principal más temprana; evitar siesta larga | Lopez-Minguez 2018 |
| **MOTOR / FUERZA** (15–20) | Entrenar / fuerza — pico físico del día | Facer-Childs 2018 |
| **CREATIVIDAD** (20–22:30) | **Cerrar la cocina antes de 21:30**; bajar luces; preparar sueño | Lopez-Minguez 2018 / Mattson 2017 |
| **SUEÑO** (22:30–6) | Proteger el descanso; no comer; no pantallas | Walker 2017 |

Dos usuarios en la misma fase pueden recibir acciones distintas (depende de su pilar débil y estado), pero **ninguna acción contradice la fase** — esa es la conciencia circadiana.

---

## 5. Guardarraíl: el bloqueo intestinal es override duro

Se extiende la regla de override (§3 del Anexo): además de "ventana cerrando", el **acercamiento al bloqueo intestinal de 21:30 con ventana aún abierta** dispara override → acción principal forzada, porque cruzarlo es el golpe circadiano más grande al IMR.

```
si (ventana abierta) y (minutos_a_21:30 ≤ 60):
    principal := "Cierra tu cocina antes de las 21:30"  // override, salta el score
```

---

## 6. Explicabilidad: el coach cuantifica el efecto en el IMR

Toda recomendación circadiana **dice su consecuencia en el IMR**, no solo el qué:

- Preventiva: *"Cierra tu ventana antes de las 21:30. Después de esa hora tu factor circadiano cae de 1.0 a 0.5 — y el circadiano es el mayor componente de tu IMR (38% de tu conducta)."*
- De oportunidad: *"Son las 16:00, tu pico de fuerza. Entrenar ahora rinde más que en la noche."*

El "saber más" abre el `ActionExplainerSheet` con la cita completa (`CIRCADIAN_BIBLIOGRAPHY`).

---

## 7. Feedback de cierre con lectura circadiana

`CoachingFeedbackService` reporta el efecto circadiano del día contra la base del usuario:

- Positivo: *"Cerraste a las 20:40, antes del bloqueo. Tu factor circadiano se mantuvo en 1.0 — así se sostiene el IMR."*
- Correctivo (sin culpa): *"Hoy cenaste 21:50; el circadiano bajó a 0.5. Mañana, cerrar antes de 21:30 recupera ese punto."*

---

## 8. Cambios concretos sobre SPEC-194

- `CoachingSnapshot` gana campos circadianos explícitos: `currentPhase`, `minutesToIntestinalLock`, `minutesToSleepOnset`, `liveCircadianScore`.
- Nuevo `CircadianCandidateGenerator` (tabla §4) y nuevo término `circadianImpact` en `CoachingDecisionEngine`.
- Override de 21:30 (§5).
- Constantes nuevas:

```dart
// SPEC-194 Adenda circadiana — pesos v1.1 (ENGINEERING JUDGMENT, recalibrar con SPEC-193)
const double kWUrgency = 0.28, kWRelevance = 0.27, kWCircadian = 0.30,
             kWConfidence = 0.15, kWFatigue = 0.12;

// circadianImpact por situación
const double kCircProtectBoundary = 1.00, kCircEarlyMealBonus = 0.85,
             kCircPhaseAlignedActivity = 0.75, kCircProtectSleep = 0.80,
             kCircNeutral = 0.30, kCircCounterPhase = 0.00;

// Override bloqueo intestinal
const int kIntestinalLockOverrideMin = 60; // minutos antes de 21:30
```

---

## 9. Nota de honestidad (estilo IMR_BIBLIOGRAPHY)

El peso `circadianImpact = 0.30` se elige por **espejo** del 0.38 que el circadiano tiene en el bloque de conducta del IMR (MEDIUM, validado por SPEC-70.5). El mapa fase→acción se apoya en `CIRCADIAN_BIBLIOGRAPHY` (Metabolic Clock + Biological Dial como fuente normativa). El rebalanceo exacto de los cinco pesos sigue siendo **ENGINEERING JUDGMENT** y se recalibra con la tasa de acciones completadas por fase (SPEC-193).
