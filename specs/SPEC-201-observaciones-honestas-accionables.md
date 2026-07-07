# SPEC-201 — Observaciones honestas y accionables (rework del motor causal)

**Estado:** IMPLEMENTED (2026-06-11) — RF-01/02/03/05 implementados. `ObservationDetector` + `observation_detector.dart` + `observation_tile.dart`. Reemplaza `CausalInsightDetector`. commit 15fc542.
**Versión:** 0.1 (draft)
**Tipo:** Análisis — calidad de insights. Reemplaza correlaciones espurias por observaciones auto-referenciales + accionables.
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Pulido de Análisis (post-SPEC-200).
**Estimación:** ~1.5 días.
**Depende de:** SPEC-162 (motor causal actual), SPEC-200 (serie del Score del Día), SPEC-199 (coach accionable — destino de las micro-acciones), `daily_summaries` / streak (fuentes de datos).
**Reemplaza:** los detectores de correlación por pares de `CausalInsightDetector`.

---

## 1. Contexto — por qué el actual no aporta

La sección **"Observaciones"** de Análisis (`causalInsightsProvider` → `CausalInsightDetector`) genera ruido que el usuario percibe como inútil. Captura real (10-jun-2026):

> ⚠️ Tu Peso cambió fuerte la semana del 7 jun. — Peso: 78.5 → 80.3 kg. Hidratación: 2.5 → 1.8 L. · *EFSA 2010 + Popkin 2010*
> ⚠️ Tu Peso cambió fuerte la semana del 7 jun. — Peso: 78.5 → 80.3 kg. Ejercicio: 120 → 61.0 min. · *OMS 2020 + AHA 2018*
> ⚠️ Tu IMR cambió fuerte la semana del 3 jun. — IMR: 42.0 → 31.0. Nutrición A: 100 → 50.0 %. · *Frank Suárez + Jenkins 2002*

Problemas concretos del motor:

1. **Correlación espuria con n minúsculo.** `_detectWeeklyDrop` cruza *cada* outcome (Peso, IMR) con *cada* hábito (5 pilares) = 10 combinaciones, y dispara cuando ambos se movieron ≥15% en **una sola semana**. Con pocas semanas, coincidencia ≠ causa. Es un generador de falsos patrones.
2. **Duplicación por evento.** El mismo cambio de Peso sale 2+ veces (coincidió con varios hábitos). No hay dedup por (métrica, semana).
3. **Citas decorativas.** `_citationForHabit` pega un paper a cualquier par. EFSA 2010 (consumo de agua) no valida "tu peso subió mientras registraste menos agua". Es autoridad de pega.
4. **Confunde registrar con vivir.** "Hidratación 2.5 → 1.8 L" es lo que el usuario *anotó*, no lo que tomó. Correlacionar dips de logging con outcomes es doblemente vacío.
5. **No accionable.** Repite números que ya están en las gráficas, sin "y por eso, haz X".
6. **Lenguaje causal sin evidencia causal.** "cambió fuerte… [hábito] bajó" implica causa que el dato no sostiene.

---

## 2. Principio rector

**Dejar de fingir causalidad.** Pasar de "teatro de correlaciones" a **observaciones honestas, auto-referenciales y accionables**. Cada observación debe cumplir las 4:

- **Verdadera** sin sobre-interpretar (una métrica, o asociación con señal real).
- **Auto-referencial** (tú vs tu propia base/meta), no causalidad inter-métrica forzada.
- **Accionable** (termina en una micro-acción concreta).
- **Honesta con el dato** (sin cita pegada a una observación de datos del usuario; sin afirmar causa).

---

## 3. Lo que NO se hace aquí

- **NO** se conservan los detectores de correlación por pares (`_detectWeeklyDrop`, `_detectSustainedImprovement` en su forma actual de 1 lapso).
- **NO** se pegan citas bibliográficas a observaciones de los datos del usuario. La ciencia vive en el explainer del pilar, no estampada sobre "tu peso se movió".
- **NO** se inventan patrones cuando faltan datos — se muestra un estado honesto de "seguí registrando".
- **NO** se afirma causa-efecto. A lo sumo, asociación tentativa ("tiende a coincidir") y solo con señal estadística real.

---

## 4. Nuevos detectores (reemplazo)

Todos puros (Dart sin Flutter), testeables. Salida: `List<Observation>` deduplicada y ordenada por relevancia, máx 3.

**RF-201-01 — Tú vs tu base (baseline personal).** Por la métrica/pilar que más se desvió de su propio promedio del período: "Tu sueño esta semana (6.2 h) está por debajo de tu promedio (7.1 h)." Una sola métrica, sin causalidad. Micro-acción: "Adelantá tu hora de dormir 20 min hoy."

**RF-201-02 — Racha / consistencia.** Detecta la racha vigente más fuerte (días consecutivos cumpliendo un pilar / Score del Día ≥ umbral): "Llevas 5 días cerrando tu ayuno — tu mejor racha." Refuerzo positivo verdadero. Micro-acción opcional: "Mantené el impulso: tu ventana cierra a las 21:00."

**RF-201-03 — Cercanía a la meta.** Si el usuario quedó consistentemente cerca (o lejos) de una meta diaria: "Estás a 0.4 L de tu meta de agua los últimos 3 días." Micro-acción: registrar un vaso (enchufa al prompt accionable de SPEC-199).

**RF-201-04 — Asociación real (solo con señal).** Reemplaza la correlación por pares: requiere **≥ kMinWeeksForAssociation (8)** semanas y calcula correlación (Pearson o Spearman) sobre **toda** la serie outcome↔hábito. Solo emite **la más fuerte** si |r| ≥ kMinCorrelation (p. ej. 0.5). Tono tentativo, sin cita, sin "causa": "Tus mejores semanas de IMR tienden a coincidir con más ayuno." Si no hay señal, no emite nada.

**RF-201-05 — Dedup + piso de datos.** Una observación por (métrica). Si hay < kMinWeeksForObservations (~3) semanas de datos, no se fabrica nada: estado honesto "Seguí registrando — en ~N semanas te muestro patrones reales."

---

## 5. Arquitectura

```
analysis/
 ├── domain/
 │    └── observation.dart            # { type, headline, detail, action?, strength }  (sin `citation`)
 ├── application/
 │    ├── observation_detector.dart   # nuevos detectores puros (reemplaza CausalInsightDetector)
 │    └── observations_provider.dart   # arma series (streak + daily_summaries + biometría) y llama al detector
 └── presentation/widgets/
      └── observation_tile.dart        # render: headline + detail + chip de acción (sin cita)
```

`CausalInsightDetector` + `causal_insight.dart` + `causal_insights_provider.dart` se deprecan/eliminan. `insight_tile.dart` se reemplaza por `observation_tile.dart` (con CTA de acción).

---

## 6. Telemetría (SPEC-193)

- `observation_shown` { type }
- `observation_action_tapped` { type, action }

Permite medir qué observaciones generan acción real (y podar las que no).

---

## 7. Testing

- `observation_detector`: cada detector con series sintéticas — baseline (desvío vs promedio), racha (consecutivos), meta (cercanía), asociación (serie correlacionada vs serie aleatoria → solo la primera emite), piso de datos (<3 semanas → vacío), dedup (un evento no duplica). Puro.
- Widget test: `observation_tile` renderiza CTA y dispara la acción.

---

## 8. Decisiones abiertas (para Carlos)

- Umbrales: `kMinWeeksForAssociation` (8), `kMinCorrelation` (0.5), `kMinWeeksForObservations` (3) — ¿ajustamos?
- ¿La asociación (RF-04) entra ya, o arrancamos solo con baseline + racha + meta (RF-01/02/03) y sumamos asociación cuando haya usuarios con ≥8 semanas?
- ¿Las micro-acciones abren el pilar correspondiente, o disparan el prompt accionable de SPEC-199 directamente?
