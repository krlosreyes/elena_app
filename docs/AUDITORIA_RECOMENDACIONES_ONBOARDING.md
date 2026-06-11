# Auditoría — Qué le recomendamos al usuario tras el onboarding

**Fecha:** 2026-06-10
**Alcance:** `GoalSuggestionEngine` (objetivos sugeridos al cerrar onboarding) + `PillarGoalResolver`.
**Tipo:** Auditoría de producto (no modifica código).
**Líder:** Carlos · **Auditor:** Claude

---

## 1. Resumen

Tras capturar los datos del onboarding (peso, altura, cintura, cuello, género, fecha de nacimiento, horarios circadianos, protocolo de ayuno), `GoalSuggestionEngine.suggest(user)` genera **7 objetivos personalizados** con umbrales científicos (ACSM, OMS, NIH, WHTR, fisiología de hidratación).

**No existe una "tipología" única de usuario.** El motor segmenta **por pilar**; de cada segmento sale un objetivo. El driver principal es la **composición corporal** (% grasa + WHTR).

---

## 2. Tipologías por composición corporal → objetivos de peso y grasa

Zonas ACSM (`_fatZoneLabel` / `_nextFatZoneTarget`). Peso objetivo = masa magra / (1 − %grasa objetivo / 100).

| Género | Zona (% grasa) | % grasa objetivo | ¿Se activa solo? | Peso objetivo |
|---|---|---|---|---|
| Hombre | Alto ≥25% | → 20% | Sí | preserva masa magra |
| Hombre | Promedio 18–24% | → 17% | Sí | preserva masa magra |
| Hombre | Fitness 14–17% | → 13% | No (umbral activación = 18%) | mantener |
| Hombre | Atlético 6–13% | mantener | No | mantener |
| Mujer | Alto ≥32% | → 28% | Sí | preserva masa magra |
| Mujer | Promedio 25–31% | → 24% | Sí | preserva masa magra |
| Mujer | Fitness 21–24% | → 20% | No (umbral = 25%) | mantener |
| Mujer | Atlético 14–20% | mantener | No | mantener |

**Riesgo metabólico** (etiqueta del peso, vía WHTR = cintura/estatura): ≥0.56 alto · 0.50–0.56 moderado · <0.50 saludable.

---

## 3. Objetivo sugerido por pilar

| Pilar | "Actual" sale de | Segmentos | Regla del objetivo | ¿Activa solo? |
|---|---|---|---|---|
| Ayuno (días/sem) | `weeklyAdherence × 7` | ≤1 sin protocolo · <4 baja · <6 moderada · ≥6 alta | ≥5 → fija 5; si no, actual +1 (tope 2–6) | si <4 |
| Ejercicio (min/día) | `exerciseGoalMinutes` | <15 sin actividad · <30 bajo OMS · <45 en rango · ≥45 alto | (actual +10), acotado 30–60, redondeo 5 | si <30 |
| Sueño (h/noche) | estimado de hora dormir/despertar | <6 privación · <7 bajo · 7–9 óptimo · >9 excesivo | <7 → 7.5; >9 → 8; en rango → mantener | si <7 |
| Hidratación (L/día) | 1.5 L fijo ("sedentario") | — | 35 ml × kg (redondeo 0.25, tope 1–4 L) | siempre |
| Nutrición (%A-dominante) | histórico reciente, o 50% si nuevo | <50 baja · <70 media · <85 buena · ≥85 alta | <60→70 · <75→80 · <85→85 · ≥85 mantener | si <75 |

Cada sugerencia trae además: `currentValue`, `suggestedTarget`, `rationale` (1 línea en 2ª persona, sin jerga) y `currentStatusLabel`.

---

## 4. Hallazgos

1. **Varios "valores actuales" son placeholders, no datos reales del día 0.** Hidratación arranca en 1.5 L fijo; nutrición en 50%; ejercicio del *goal* (no de actividad real); ayuno de `weeklyAdherence` (= 0 en usuario nuevo → "sin protocolo"). La comparación "actual vs objetivo" puede sentirse inventada al inicio.
2. **% grasa cae a fallback poblacional (15% H / 25% M)** sin medidas → peso y grasa objetivo quedan poblacionales, no personales (mismo hardcode que en Composición Corporal del perfil).
3. **Target de ayuno para principiante real (0 días) = 2 días/sem** — poco ambicioso para instalar el hábito.
4. **Zona "Fitness" no se activa pero sí sugiere bajar** (incoherencia menor): a un hombre con 16% le sugiere 13% pero no marca el objetivo como activo → mensaje mixto.
5. **Hidratación siempre `shouldActivate = true`**, sin importar el perfil.
6. **Sin persona holística:** segmentación solo por pilar. No clasificamos al usuario en un perfil unificado (ej. "sedentario alto riesgo" vs "atlético en mantenimiento").

---

## 5. Recomendaciones

- **Corto plazo (coherencia):** quitar/etiquetar los "actuales" placeholder del día 0 como "estimado/sin registro" para no comparar contra inventados; subir el target de ayuno del principiante a 3 días; resolver la incoherencia de la zona Fitness (activar o no sugerir bajada).
- **Medio plazo (personalización real):** alimentar los "actuales" desde HealthKit (peso/actividad reales, ya integrado en SPEC-132.next/203) en vez de placeholders.
- **Si se quiere una persona holística (#6):** plantear un SPEC que combine composición + actividad + riesgo (WHTR) + edad en 3–4 tipologías con un copy de coaching dedicado.

---

## 6. Referencias de código

- `lib/src/features/goals/application/goal_suggestion_engine.dart` (el motor).
- `lib/src/features/goals/application/pillar_goal_resolver.dart` (resolución de meta efectiva por pilar).
- `lib/src/features/onboarding/presentation/onboarding_screen.dart` (`_buildUserModelFromState` + uso de `GoalSuggestionEngine.suggest`).
- `lib/src/features/goals/domain/user_goal.dart` (`GoalType`).
