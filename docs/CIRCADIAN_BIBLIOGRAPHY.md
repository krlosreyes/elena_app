# Bibliografía Circadiana — Bases científicas de Elena App

**Última actualización:** 14 de mayo de 2026
**Marco normativo:** `CONSTITUTION.md` — todo fundamento de producto debe ser verificable.

Este documento canoniza los dos blueprints que rigen el comportamiento circadiano de la app. Cualquier feature relacionada con ayuno, ventana de alimentación, sueño, ejercicio o notificaciones DEBE consultar esta bibliografía y referenciar las secciones correspondientes en su SPEC.

Documentos fuente (versionados en `docs/references/`):
1. **Metabolic Clock Product Blueprint** — mapa cronológico del ayuno y respuesta hormonal.
2. **The Biological Dial** — ciclo de 24 horas, picos hormonales, cognitivos y motores.

---

## §1 — Principios fundacionales

### §1.1 Modelo hormonal, no calórico

> "Bajar la insulina es la única forma de reconfigurar el sistema sin ralentizar el metabolismo basal." — Metabolic Clock §2.

Implicación de producto: la app NO calcula déficit calórico como métrica primaria. El IMR pondera estructura, ayuno, hábitos y alineación circadiana — todos los cuales modulan insulina indirectamente.

### §1.2 El metabolismo NO baja con el ayuno corto

> "El metabolismo basal aumenta hasta un 14% después de 4 días de ayuno." — Metabolic Clock §4.

Implicación de UX: el copy en pantallas de ayuno nunca usa el término "modo inanición" como amenaza. La adrenalina sube; el cuerpo acelera, no se ralentiza.

### §1.3 Reloj universal — Premio Nobel 2017

> "Todos compartimos un reloj intrínseco. Estar despierto de noche es una desincronización biológica." — Biological Dial §2.

Implicación de producto: la app NO acepta el mito "soy lechuza". Las ventanas óptimas son universales (con tolerancias individuales en `wakeUpTime` / `sleepTime` del perfil), pero la app empuja activamente hacia el ciclo natural.

---

## §2 — Cronología del ayuno (6 fases)

| Fase | Horas | Biología | Estado UI Elena App | Pilar primario |
|---|---|---|---|---|
| 1. Post-absorción | 0 – 12h | Insulina desciende, glucosa en sangre se consume, glucógeno hepático se llena | Neutro / base. Círculo en cian (azul tranquilo). Sin notifs intrusivas. | Ayuno (track silencioso) |
| 2. Transición | 12 – 18h | Glucógeno se agota; cambio de combustible hacia grasas | Alerta de transición. Push: "El hambre es ola hormonal temporal". Sugerencia: agua mineral o té verde. | Ayuno + Hidratación |
| 3. Quema de grasa | 18 – 24h | Gluconeogénesis temprana, pico de adrenalina + GH | Gamificación. Medalla "Quema de grasa activa". Alerta obligatoria de electrolitos (Na, K, Mg). | Ayuno + Hidratación |
| 4. Cetosis profunda | 24 – 48h | Cuerpos cetónicos al cerebro (hasta 75%). Inflamación baja drásticamente | "Flujo Óptimo". Snippet educativo sobre barrera hematoencefálica. Sugerencia 36h para adaptados. | Ayuno |
| 5. Autofagia | 48 – 72h | Macrófagos reciclan organelas defectuosas. IGF-1 baja | Modo Clínico. Check-in obligatorio de síntomas. Bloqueado para novatos (<10 ayunos previos). | Ayuno |
| 6. Ayuno prolongado | 72h+ | Estrés metabólico extremo, riesgo de arritmias | Restricción. Pop-up desaconsejando >72h sin supervisión. NO se gamifica. | (Bloqueado MVP) |

**Implementación actual relacionada:**
- `lib/src/features/dashboard/domain/fasting_status.dart` define `FastingPhase` con 5 valores (none, postAbsorption, transition, fatBurning, autophagy, survival). **Falta**: alinear los thresholds y agregar comportamiento UI distinto por fase.
- `lib/src/core/engine/score_engine.dart` usa horas de ayuno como input del bloque metabólico pero NO distingue fases para puntuar.

---

## §3 — Cronograma de 24 horas (Biological Dial)

| Hora | Evento biológico | Pilar Elena | Implicación UX |
|---|---|---|---|
| 04:30 | Temperatura corporal mínima. Sueño profundo. | Sueño | NO despertar. NO push. |
| 06:00 | Pico de cortisol → despertador biológico natural. | Sueño → Despertar | `wakeUpTime` del perfil debería caer entre 05:30–07:00. |
| 06:45 | Aumento de presión arterial — preparación para verticalidad. | Sueño | Cardio de alta intensidad NO recomendado aquí. |
| 07:30 | Glándula pineal corta melatonina al recibir luz. | Hidratación + Sueño | Push: "10-15 min de sol antes de las 8:00 AM = reset del reloj". |
| 08:30 | Movimiento intestinal desbloqueado. | (sin track directo) | Recomendar agua tibia al despertar. |
| 09:00 | Pico de testosterona. | Ejercicio | Sugerir HIIT corto / estiramientos. |
| 10:00 | **PICO COGNITIVO** — máxima atención y procesamiento. | Cognitivo (no es pilar, pero contexto) | NO push intrusivos entre 09:30–11:00. |
| 12:30 | Ventana de comida ideal abre (protocolo 16:8). | Ayuno → Comidas | `firstMealGoal` recomendado por la app. |
| 14:30 | Máxima coordinación motora. | Ejercicio | Sugerir agilidad, técnica fina, gimnasia. |
| 15:30 | Reflejos más rápidos. | Ejercicio | Sugerir entrenamiento reactivo. |
| 17:00 | **PICO FÍSICO** — máxima fuerza y eficiencia cardiovascular. | Ejercicio | Sugerir pesas pesadas, cardio largo. Ventana óptima 15:00–17:00. |
| 18:30 | Pico de presión arterial. | Ejercicio | Cierre del entrenamiento pesado. |
| 19:00 | Pico de temperatura corporal. | Sueño (prep) | Iniciar descompresión: bajar luz azul, ambiente fresco. |
| 20:30 | **CIERRE DE VENTANA OBLIGATORIO** — última comida del día. | Comidas → Ayuno | `lastMealGoal` recomendado por la app. |
| 21:00 | Reinicio de secreción de melatonina por glándula pineal. | Sueño | Sugerir 1-2h de luz tenue. |
| 22:00 | **BLOQUEO INTESTINAL** — cese parasimpático del tracto digestivo. | Sueño | Push si hay comida registrada después: "Tu intestino se está apagando, mañana refleja eso en tu IMR". |
| 02:00 | Sueño profundo, reparación celular y consolidación de memoria. | Sueño | Notifs prohibidas. |

---

## §4 — Ventanas óptimas por protocolo de ayuno

Derivadas del cierre obligatorio a las 20:30 (antes del bloqueo intestinal a las 22:00) y trabajando hacia atrás:

| Protocolo | Apertura ventana (ideal) | Cierre ventana (ideal) | Horas de ayuno | Notas |
|---|---|---|---|---|
| **Ninguno (educativo)** | 06:30 | 20:30 | 10h | Ventana de 14h. Solo prohibe snacks nocturnos. |
| **16:8** | 12:30 | 20:30 | 16h | El más común. Salta desayuno, mantiene cena social. |
| **18:6** | 14:30 | 20:30 | 18h | Almuerzo + cena, sin snacks intermedios largos. |
| **20:4** | 16:30 | 20:30 | 20h | One meal a day (OMAD) modificado. |
| **24h (cena-a-cena)** | — | — | 24h | Una sola comida al día siguiente. Sólo intermedios. |
| **36h (terapéutico)** | — | — | 36h | Requiere supervisión médica activada en app. |

**Regla de oro:** el cierre de ventana NUNCA debe ser después de las 21:00. Comer en el bloqueo intestinal destruye la calidad del sueño y el IMR de mañana.

**Regla de coherencia:** si el usuario configura `lastMealGoal` > 21:00, la app debe mostrar un warning y sugerir adelantarlo.

---

## §5 — El Fenómeno del Amanecer

> "Justo antes de despertar, el hígado libera glucosa nueva. El apetito matutino es un reflejo condicionado, no una necesidad calórica." — Metabolic Clock §12.

**Push matutino canónico (entre `wakeUpTime` y `wakeUpTime + 30 min`):**
> "Tu cuerpo acaba de liberar energía natural. Si no tienes hambre real, tu desayuno puede esperar. Disfruta un café negro y prolonga tu quema de grasa."

Solo se dispara para usuarios con protocolo 16:8 o superior. NO para protocolo "Ninguno".

---

## §6 — Cuatro reglas de oro del producto

**Regla 1 — Recompensar el rango 16–24h.**
La magia metabólica sostenible vive ahí (cetosis nutricional, baja resistencia a insulina). El IMR debe puntuar mejor a un usuario que cierra 18h que a uno que apenas hace 12h.

**Regla 2 — Desmitificar el vacío.**
Cada hito (hambre punzante, ola hormonal, mareo) debe tener micro-copy contextual exacto. Ver `pillar_constants.dart` para los stubs actuales — falta mapearlos a las 6 fases de ayuno.

**Regla 3 — Gestión integral, no solo cronómetros.**
Cortisol → insulina. Sueño → cortisol. Ejercicio → cortisol. La app trackea los 5 pilares precisamente porque están entrelazados, no como features independientes.

**Regla 4 — Seguridad ante todo.**
- Hidratación intrusiva en ayunos >18h.
- Check-in obligatorio en autofagia.
- Bloqueo total en >72h sin supervisión.

---

## §7 — Diagnostic Matrix de síntomas

| Síntoma físico | Causa biológica | Intervención Elena App |
|---|---|---|
| Acidez / reflujo nocturno | Comida copiosa al romper ayuno | Botón "Romper Ayuno" sugiere porciones controladas + alerta "No recostarse por 30 min" |
| Mareos / debilidad / presión baja | Pérdida de fluidos y sodio | Push: "Bebe 1 taza de caldo de hueso o agua con sal/magnesio". Botón "Pausar Ayuno" disponible |
| Hambre punzante intensa (fase 2) | Pico de grelina | Botón SOS "Tengo Hambre" → trucos: agua mineral fría, café negro, té verde, chía hidratada |

---

## §8 — Gaps identificados vs. implementación actual

Para que el equipo sepa qué falta cuando lea esta bibliografía:

| Principio canónico | Estado en código | SPEC sugerida |
|---|---|---|
| 6 fases del ayuno con copy diferenciado | Solo enum `FastingPhase`, sin UX por fase | SPEC-96 (auto-cálculo + copy por fase) |
| Cierre obligatorio a 20:30 | `lastMealGoal` configurable sin límite | SPEC-96 (validación + sugerencia automática) |
| Apertura óptima por protocolo | `firstMealGoal` configurable sin guía | SPEC-96 (sugerir según protocolo) |
| Fenómeno del amanecer push | No implementado | SPEC-97 (notificaciones circadianas) |
| Diagnostic Matrix | No implementado | SPEC-98 (sheet de síntomas con intervenciones) |
| Ventana de entrenamiento PM 15-17 | `ExerciseNotifier` no sugiere hora | SPEC-99 (recomendación temporal de ejercicio) |
| Bloqueo intestinal 22:00 | Mensaje "CIERRE DE VENTANA OBLIGATORIO" existe pero no liga con `eatingWindow` | SPEC-96 |
| Bloqueo de ayunos >72h para novatos | No hay gate de experiencia | SPEC futura post-launch |

---

## §9 — Cómo usar este documento

- Antes de redactar cualquier SPEC relacionada con ayuno / ventana / sueño / ejercicio circadiano, leer las secciones §2 a §6.
- Citar este doc en la SPEC: `Marco normativo: docs/CIRCADIAN_BIBLIOGRAPHY.md §X.Y`.
- Si un principio entra en conflicto con un requerimiento de producto, ganar a la biología (no al revés).
- Si un nuevo blueprint llega (ej. revisión clínica), agregarlo a `docs/references/` y actualizar este índice.
