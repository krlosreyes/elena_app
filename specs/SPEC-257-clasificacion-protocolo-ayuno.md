# SPEC-257 — Clasificación y tabla de recomendación de protocolo de ayuno

**Estado:** IMPLEMENTED (2026-07-13) — ver §9 para el detalle de qué se implementó tal cual, qué se mapeó al catálogo existente, y qué queda explícitamente fuera de esta iteración.
**Origen:** Carlos pidió un análisis de fondo de cómo se clasifican hoy las recomendaciones de protocolo de ayuno (ver hallazgos en el hilo previo), y luego investigar en la web + "El Código de la Obesidad" (Jason Fung) + Frank Suárez para proponer una clasificación y tabla coherente. Carlos luego pidió implementar todo el documento en loop, con este SPEC como única fuente de verdad para la recomendación de protocolos de ayuno — lo que no estuviera alineado debía desaparecer.

---

## 1. Diagnóstico: lo que existe hoy (recordatorio)

El análisis previo encontró **tres ejes independientes que nunca se cruzan**, más una capa informativa sin lógica:

1. **Autoselección en onboarding** (`IntroProtocolStep`): el usuario elige entre 14/10, 16/8 u 18/6 sin ningún criterio de perfil, antes de dar ningún dato.
2. **Sistema nervioso pasivo/excitado** (SPEC-137, `nervous_system.dart`): 5 preguntas → clasifica pasivo/excitado/unknown. Solo bloquea (con advertencia, no prohibición) el salto directo a 20:4 en perfil excitado.
3. **Motor adaptativo por comportamiento** (`AdaptiveEngine`, SPEC-08): sube un escalón (`Ninguno→12:12→14:10→16:8`) si adherencia ≥85% + IMR estable 6/7 días ≥75. **Nunca baja** (`simplify` no implementado) y su recomendación no llega a ninguna pantalla visible hoy.
4. **`ProtocolSelectorSheet`**: catálogo educativo estático (Ninguno→OMAD) con etiqueta de dificultad, sin ningún gate real.

**Gap más importante:** las patologías que el usuario declara en onboarding (prediabetes, diabetes T2, hipotiroidismo, SOP, etc.) se capturan y se muestran en el perfil, pero **no restringen ni modulan ningún protocolo**. Solo hay un disclaimer genérico de "esto es para adultos sanos" mostrado una vez.

---

## 2. Lo que dice la bibliografía

### 2.1 Jason Fung (*The Obesity Code*, *The Diabetes Code*, *The Complete Guide to Fasting*, The Fasting Method)

Fung no prescribe un protocolo único: **calibra la duración del ayuno a la severidad de la resistencia a la insulina**, no al gusto del usuario. Cuanto más severo el caso metabólico, más largo (y más supervisado) el ayuno que prescribe; para mantenimiento, protocolos más cortos.

**Escalera de intensidad (de su práctica clínica):**

| Nivel | Protocolo | Para quién | Frecuencia |
|---|---|---|---|
| 1 — Entrada | 16:8 (TRF diario) | Punto de partida para casi cualquier persona sana; mejora gradual de sensibilidad a la insulina | Diario, sostenible indefinidamente |
| 2 — Moderado | 24h ("Eat Stop Eat") | Resistencia a la insulina más marcada; meseta de peso | 1-2×/semana |
| 3 — Avanzado | Días alternos (24h cada 48h) | Casos de resistencia a la insulina significativa; el caso publicado en BMJ 2018 (3 pacientes con diabetes tipo 2 que descontinuaron insulina) usó este patrón | Días alternos |
| 4 — Terapéutico/clínico | 3-10+ días | Enfermedad metabólica severa, meseta persistente | Bajo supervisión médica directa; Fung reporta ayunos de hasta un mes supervisados |

**Contraindicaciones que Fung marca como no-negociables (no fasting sin supervisión médica explícita, y en varios casos evitarlo del todo):**

- Menores de edad / adolescentes (requieren nutrientes constantes para crecer).
- Embarazo y lactancia.
- Trastornos alimentarios o historial de ellos.
- Bajo peso: **IMC < 18.5** = no ayunar. Margen de seguridad: **IMC < 20 → nunca ayunos de más de 24h**.
- Pacientes medicados con insulina o sulfonilureas: riesgo real de hipoglucemia severa; requieren supervisión y ajuste de dosis antes de ayunar, nunca ayuno "libre".

**Principio general:** *"a medida que el ayuno se alarga, el riesgo de complicaciones aumenta"* — la progresión debe ser gradual y el usuario debe conocer las señales de alarma (temblores, palpitaciones, mareo = señal de hipoglucemia, parar).

### 2.2 Frank Suárez (MetabolismoTV / NaturalSlim / *Pregúntale a Frank*)

Fuente primaria consultada: artículo "El Ayuno Intermitente" (preguntaleafrank.com) y blog NaturalSlim. Complementa (no reemplaza) la bibliografía A/E y sistema nervioso ya integrada en el proyecto (`reference_frank_suarez.md`).

- **El protocolo con más evidencia, según Suárez, es 16 horas** — cita el estudio de John Johnson (2006) como el más controlado. Coincide con Fung en que 16:8 es el punto de entrada mejor respaldado.
- **Frecuencia canónica: 2 de 7 días, no diario.** Suárez recomienda explícitamente el esquema "2-5" (ayuno 2 días/semana, comer normal 5 días), con la opción de subir a 3 días/semana para quienes buscan más efecto (ganancia muscular, explosividad atlética). Más de 3 días/semana → recomienda supervisión de un profesional de la salud o nutricionista.
- **Progresión gradual explícita:** "Puedes empezar incluso en 8 e ir después en aumento a 12 y 14 hasta lograr las 16 a lo largo de las semanas." Esto **coincide exactamente** con la escalera que ya existe en `AdaptiveEngine` (`Ninguno→12:12→14:10→16:8`) — es una validación externa de esa escalera, no una crítica.
- **Contraindicación/señal de alarma:** hipoglucemia. Explica que parte de la población tiene baja capacidad hepática de almacenar glucógeno y puede marearse o sentir palpitaciones al ayunar — su instrucción textual es *"si le empieza a dar algo como de temblequeo o palpitaciones o hipoglucemia, ¡quítese!, todo el mundo no lo puede hacer."* No es una lista de diagnósticos, es una regla de "detente ante síntomas", igual que Fung.
- **Romper el ayuno es un acto delicado:** advierte explícitamente contra romper un ayuno de 16h con comida pesada/azucarada (su ejemplo: panqueques con sirope y tocineta) — riesgo de "crisis" durante la desintoxicación. Recomienda reintroducir comida ligera. Esto no es una restricción de protocolo, es una regla de UX para el botón "Romper Ayuno" que la app ya tiene (`early_fasting_end_dialog.dart`).
- **Preparación antes de ayunar:** hidratación, magnesio y potasio, limpieza previa de cándida — relevante para el pilar Hidratación pero no cambia la clasificación del protocolo en sí.
- Su "clasificación de perfil" real para personalizar el ayuno es la **prueba de metabolismo propietaria de NaturalSlim** (no pública, comercial) — no es replicable ni éticamente citable como si fuera ciencia abierta. El sustituto ya construido en ElenaApp (sistema nervioso pasivo/excitado, SPEC-137) cumple un rol análogo y sí está documentado.

### 2.3 Lo que ya vive en `docs/CIRCADIAN_BIBLIOGRAPHY.md` (Metabolic Clock Blueprint)

El proyecto ya tiene, sin conectarlo a este análisis, una tabla de fases del ayuno (§2) que es compatible con Fung: post-absorción (0-12h) → transición (12-18h) → quema de grasa (18-24h) → cetosis profunda (24-48h) → autofagia (48-72h, "bloqueado para novatos <10 ayunos previos") → ayuno prolongado (72h+, bloqueado en el producto). Esto ya es, en esencia, la escalera de severidad de Fung traducida a fases biológicas. **No hace falta inventar una nueva** — hace falta conectarla con el resto del sistema.

---

## 3. Tensión que hay que resolver (decisión de producto, no técnica)

Suárez recomienda el 16:8 **2 días por semana**, no como ventana diaria. ElenaApp implementa los protocolos como **ventana diaria (TRF)** — `fastingHoursForProtocol('16:8') == 16` se evalúa cada día del `StreakEntry`. Fung sí valida el TRF diario como punto de entrada legítimo, así que no hay conflicto ahí, pero la escalera de Suárez para intensificar es por **frecuencia semanal** (2→3 días de ayuno más largo) mientras que la escalera actual del producto (y la de Fung para intensificar) es por **duración de la ventana diaria** (16:8→18:6→20:4). Son dos ejes distintos de progresión que hoy se mezclan implícitamente. La tabla de la sección 4 los mantiene separados a propósito — Carlos debe decidir si el producto solo escala duración (como hoy) o si en el futuro también ofrece escalar frecuencia (ayunos largos ocasionales tipo 24h, 1-2×/semana) como una vía alternativa de intensificación, que es justamente el nivel 2 de Fung y el approach que Suárez más respalda con evidencia.

---

### 3.1 Resolución propuesta: días de ayuno programados para el nivel Novato

**Origen:** Carlos observó que exigirle ayuno diario a un principiante no es coherente si la recomendación científica de entrada es frecuencia semanal reducida — y que, en un día sin ayuno programado, el anillo de Ayuno y el score del día deberían poder llegar a 100% sin que eso signifique "fingir" que ayunó.

**Grounding científico (ya citado en §2, no se repite investigación):** Suárez recomienda explícitamente 2-3 días de ayuno por semana como el esquema canónico para empezar, con progresión gradual de horas (8→12→14→16) antes de pensar en volverlo diario. Fung valida el TRF diario como punto de entrada legítimo, pero su nivel 2 de intensidad (24h) es intrínsecamente de baja frecuencia (1-2×/semana), nunca diario. Ninguno de los dos autores respalda exigir ayuno los 7 días de la semana a alguien que recién empieza — hacerlo hoy en el producto no tiene respaldo bibliográfico, es un artefacto de que `StreakEngine.evaluateFasting` se evalúa igual todos los días sin importar el nivel del usuario.

**Alcance — a quién aplica:** únicamente al nivel **Novato** del Eje B (protocolos 12:12 y 14:10). A partir de Intermedio (16:8 en adelante), tanto Fung como Suárez tratan la ventana como hábito diario, y así lo trata ya el producto — no se tocan esos protocolos.

**Mecánica propuesta, verificada contra el código existente para que sea coherente con la arquitectura actual, no un sistema paralelo más:**

1. **Frecuencia semanal:** el nivel Novato asigna N días de ayuno por semana (3 por defecto, ajustable 2-4 dentro del rango que Suárez respalda sin pedir supervisión adicional). Este valor ya existe en el dominio como `GoalType.fastingDaysPerWeek` (`goal_suggestion_engine.dart`) — hoy es una tarjeta motivacional huérfana, desconectada del motor de scoring. Esta propuesta la conecta por primera vez a algo real.
2. **Qué días:** se asignan automáticamente, no consecutivos (ej. lunes/miércoles/viernes) — el propio ejemplo de Suárez en la fuente primaria usa días alternos (martes y viernes), y evita que el usuario tenga que decidir esto por su cuenta. Editable desde Perfil si el usuario prefiere otros días.
3. **Días NO programados → renormalización, no relleno falso.** `StreakEntry.dailyQualityScore` (SPEC-65) YA renormaliza sobre las magnitudes disponibles cuando una viene `null` — es el mecanismo exacto que hace falta, sin inventar uno nuevo: si en un día de descanso se guarda `fastingCompleted: false` pero `fastingMagnitude: null` (en vez de un valor bajo), el score del día se recalcula automáticamente sobre los 4 pilares restantes y SÍ puede llegar a 1.0 (100%) sin ayuno ese día. Es el mismo patrón que ya usa el motor para entradas legacy sin magnitudes — se reutiliza, no se duplica.
4. **El anillo necesita un tercer estado visual**, no solo completado/incompleto: "día de descanso programado". Esto es deliberado y no es solo estética — Ayuno es uno de los dos pilares "ancla" del sistema de racha (`dashboard_pillars_row.dart`, SPEC-255 RF-07), y si un día de descanso se pinta idéntico a un ayuno real completado, el histórico (Progreso, detalle del pilar) terminaría mostrando que el usuario ayunó cuando no fue así. Un badge distinto (ej. un check de "descanso" en vez del relleno de "completado") logra el objetivo de Carlos — anillo cubierto, sin penalización — sin comprometer la honestidad de los datos.
5. **`pillarsCompleted` / `qualifiesForStreak` necesitan el mismo tratamiento de fondo, con cuidado:** hoy `pillarsCompleted` es un conteo plano sobre 5 pilares fijos. En un día de descanso, la forma coherente de extender esta lógica es que ese día se evalúe sobre 4 pilares aplicables, no 5 — mismo principio que la renormalización de `dailyQualityScore`, aplicado también al conteo binario. Esto es lo que requiere más cuidado en la implementación porque `pillarsCompleted`/`qualifiesForStreak` alimentan además la racha histórica y `computeAdherenceTrend` (IMR longitudinal) — hay que verificar que renormalizar ahí no infle artificialmente la adherencia de alguien que simplemente tiene menos días exigidos. No se resuelve el detalle exacto en este documento (ver §7).

**Por qué esto es coherente con los objetivos del proyecto, no solo una concesión de UX:** el pilar de fondo de ElenaApp es "modelo hormonal, no calórico, con fundamentos científicos y verificables" (`CIRCADIAN_BIBLIOGRAPHY §1.1`). Exigir ayuno diario a un Novato sin respaldo bibliográfico para esa exigencia rompía ese principio silenciosamente. Esta resolución no relaja el rigor — lo alinea con lo que las dos fuentes consultadas realmente prescriben para ese nivel.

---

## 4. Propuesta: clasificación de perfil (4 ejes, no 1)

A diferencia del sistema actual (3 ejes que no se hablan), la propuesta es que **cada usuario tenga un perfil compuesto de 4 variables independientes**, evaluadas en este orden porque cada una puede *restringir* lo que decide la siguiente:

### Eje A — Elegibilidad médica (gate binario, bloquea; ninguno de los otros ejes puede saltárselo)

| Condición declarada | Regla | Fuente |
|---|---|---|
| Menor de edad | Protocolo "Ninguno" únicamente, sin excepción en producto | Fung |
| Embarazo / lactancia | Protocolo "Ninguno" únicamente | Fung |
| Trastorno alimentario (declarado u observado) | Protocolo "Ninguno" + copy de derivación a profesional, nunca gamificar | Fung |
| IMC < 18.5 | Bloquear cualquier ayuno | Fung |
| IMC 18.5–20 | Tope duro en 24h, nunca más | Fung (margen de seguridad) |
| Diabetes tratada con insulina o sulfonilureas | Tope en 14:10, banner persistente "consulta a tu médico antes de extender tu ventana" — nunca autoprogresión silenciosa del motor adaptativo | Fung |
| Otras patologías declaradas (hipotiroidismo, SOP, prediabetes, hígado graso, hipertensión, anemia, resistencia a la insulina) | No bloquean protocolo — son informativas para el pilar Nutrición (ya el rol que cumplen hoy) | Suárez trata estas como manejables con ayuno + Dieta 3x1, no contraindicadas |

Esto es enteramente nuevo: hoy `_pathologies` se captura y no hace nada. Aquí es donde reparamos el gap más serio detectado en el análisis.

### Eje B — Nivel de adaptación (progresión temporal, gradual, reemplaza el tope actual en 16:8)

| Nivel | Definición operacional | Protocolo habilitado | Fuente |
|---|---|---|---|
| Novato | <2 semanas de constancia O <10 ayunos completados | Ninguno → 12:12 → 14:10 | Suárez ("empieza en 8, sube a 12 y 14") + `CIRCADIAN_BIBLIOGRAPHY §2` |
| Intermedio | 14:10 sostenido ≥2 semanas sin síntomas | 16:8 | Fung + Suárez coinciden: es el protocolo con más evidencia |
| Avanzado | 16:8 sostenido ≥4 semanas, sin síntomas de hipoglucemia reportados | 18:6, 20:4 | Fung (escalera de severidad) + `CIRCADIAN_BIBLIOGRAPHY §4` |
| Experto (uso ocasional, no ventana diaria) | Avanzado + IMR estable sostenido | 24h ocasional (1-2×/semana), NUNCA como ventana diaria de facto | Fung nivel 2 + Suárez "2-5" |
| Clínico | — | 36h+ | Solo con flag explícito de supervisión médica activa en el perfil. Nunca alcanzable solo por comportamiento en la app. |
| Bloqueado | — | >72h | Ya es la regla actual (`CIRCADIAN_BIBLIOGRAPHY §2`, fase 6) — mantener sin cambios |

**Diferencia clave con el `AdaptiveEngine` actual:** hoy la escalera topa en 16:8 y solo sube. Aquí se extiende la escalera hasta 20:4 (con Eje A como gate superior) y se agrega el descenso: si el usuario reporta síntomas de hipoglucemia (mareo, temblor, palpitaciones — la señal que TANTO Fung como Suárez usan como criterio de parada) o si el engagement cae a "crítico" sostenido, el nivel baja un escalón automáticamente. Esto por fin le da un trabajo real al `SuggestionType.simplify` que existe en el enum desde hace tiempo sin emitirse nunca.

### Eje C — Tono de sistema nervioso (modula tolerancia y ritmo, no bloquea — ya implementado en SPEC-137)

| Perfil | Efecto propuesto sobre la progresión | Cambio vs. hoy |
|---|---|---|
| Pasivo | Ritmo estándar del Eje B | Sin cambio |
| Excitado | Duplicar el tiempo mínimo de adaptación en cada escalón antes de habilitar el siguiente (hoy el guardrail solo existe en el salto a 20:4; se generaliza a toda la escalera) | Extiende el guardrail existente a todos los escalones, no solo 20:4 |
| Unknown | Tratar como "Excitado" (conservador) mientras no haya clasificación | Hoy el default es "Pasivo" (más permisivo); esta propuesta invierte el default hacia el lado seguro cuando falta información — es una decisión de producto que Carlos debe validar, no una corrección de bug |

### Eje D — Señal de comportamiento (dinámico, ya existe parcialmente)

Ya cubierto en el Eje B (sube/baja según engagement + IMR + síntomas reportados). La única pieza nueva de infraestructura es conectar `AdaptiveSuggestion` a una pantalla real (hoy no se muestra en ningún lado, ver hallazgo #2 del análisis previo) y agregar un mecanismo simple para que el usuario reporte "sentí mareo/palpitaciones" (podría vivir en el diálogo que ya existe en `early_fasting_end_dialog.dart` cuando alguien rompe el ayuno antes de tiempo).

---

## 5. Tabla de recomendación unificada (para consulta rápida)

| Protocolo | Horas | Nivel (Eje B) | Evidencia / fuente | Gate del Eje A que lo bloquea |
|---|---|---|---|---|
| Ninguno | — | Cualquiera | Base educativa | — |
| 12:12 | 12h | Novato | Suárez (punto de entrada) | — |
| 14:10 | 14h | Novato→Intermedio | Suárez (progresión gradual) | IMC 18.5–20 puede quedarse aquí como tope si hay ansiedad de seguridad adicional |
| 16:8 | 16h | Intermedio | Fung + Suárez — protocolo con más evidencia combinada | Diabetes medicada con insulina/sulfonilureas: tope en 14:10, no llega aquí sin ajuste médico de dosis |
| 18:6 | 18h | Avanzado | Fung (severidad creciente) | — |
| 20:4 | 20h | Avanzado, perfil Excitado con adaptación extendida en 16:8 y 18:6 primero | Fung + guardrail SPEC-137 ya existente | — |
| 24h ocasional (1-2×/sem) | 24h | Experto | Fung nivel 2 ("Eat Stop Eat") + Suárez "2-5" — la frecuencia semanal, no la ventana diaria | IMC < 20: tope duro, no exceder |
| 36h+ | 36h+ | Clínico | Fung nivel 4 | Solo con supervisión médica activa marcada en el perfil |
| >72h | — | — | Fung: complicaciones aumentan con la duración | Bloqueado en producto, sin excepción (ya es la regla actual) |

---

## 6. Qué NO cambia

- La clasificación A/E de alimentos y el sistema pasivo/excitado (SPEC-137) siguen siendo la fuente de verdad para el pilar Nutrición — esto es sobre el pilar Ayuno.
- El cierre de ventana 20:30 / bloqueo intestinal 21:30 (`CIRCADIAN_BIBLIOGRAPHY §3-4`) no se toca.
- El bloqueo total >72h se mantiene igual.
- Frank Suárez y Jason Fung no se citan nominalmente en código ni UI (mismo criterio ya aplicado a la guía NaturalSlim en `reference_frank_suarez_guia_oficial.md`) — la app usa el razonamiento, no la marca.

## 7. Lo que este documento NO resuelve todavía

- ~~La tensión de la sección 3~~ — resuelta en §3.1 para el nivel Novato (días de ayuno programados). Queda abierto si Experto (Eje B) también debería ofrecer explícitamente la vía de frecuencia semanal (24h ocasional) como alternativa a subir duración diaria, o si eso se deja solo como uso manual vía `ProtocolSelectorSheet`.
- El detalle exacto de cómo `pillarsCompleted`/`qualifiesForStreak`/`computeAdherenceTrend` renormalizan en un día de descanso programado (§3.1 punto 5) — identificado como el punto de mayor riesgo técnico, no resuelto aquí.
- El mecanismo de UI para el tercer estado visual del anillo ("día de descanso") y para editar qué días de la semana son de ayuno — RF de implementación futura.
- No se define aquí el mecanismo de UI para capturar "sentí mareo/palpitaciones" ni dónde vive el flag de "supervisión médica activa" — son RFs de una implementación futura, no de este análisis.
- No se ha verificado con Carlos si el default "Unknown → tratar como Excitado" (Eje C) es aceptable, dado que invierte el default actual del código.

---

## 8. Fuentes citadas

- Fung, J. — *The Obesity Code*, *The Diabetes Code*, *The Complete Guide to Fasting*; The Fasting Method (thefastingmethod.com); caso BMJ Case Reports 2018 (3 pacientes T2D descontinúan insulina).
- Suárez, F. — "El Ayuno Intermitente", preguntaleafrank.com (2018, actualizado 2023); "Ayuno Intermitente", blog NaturalSlim/metabolismo.com.
- `docs/CIRCADIAN_BIBLIOGRAPHY.md` §2-4 (Metabolic Clock Product Blueprint, ya versionado en el proyecto).
- `reference_frank_suarez.md`, `reference_frank_suarez_guia_oficial.md` (memoria del proyecto, ya validadas por Carlos).

---

## 9. Estado de implementación (RF-257-A a RF-257-VERIFICACION, 2026-07-13)

Implementado en una sola sesión de trabajo en loop, sin `build_runner` disponible (sandbox sin SDK Flutter/Dart) — toda la verificación fue lectura manual línea a línea, no hay compilación real. Carlos debe correr `flutter analyze && flutter test` antes de dar por buena esta iteración.

### 9.1 Eje A — gate médico (`fasting_eligibility.dart`, NUEVO)

Implementado tal cual §4 Eje A, con una decisión de mapeo: como `UserModel` es `@freezed` y no se podía regenerar código, las 4 condiciones nuevas (embarazo/lactancia, trastorno alimentario, diabetes medicada, supervisión médica activa) viven como strings nuevos dentro del `pathologies: List<String>` ya existente (`FastingPathologyFlags`), no como campos booleanos nuevos. Conectado a: opciones de onboarding (`_pathologyOptions`), clamp del protocolo elegido en `_buildUserModelFromState` (el paso 105 educativo elige protocolo ANTES de que se capturen patologías — el clamp ocurre al construir el `UserModel` final, único punto donde ambos datos ya existen), gate visual en `ProtocolSelectorSheet` (protocolos por encima del tope se muestran bloqueados con motivo, no ocultos), y tope duro en `AdaptiveEngine` (nunca sugiere por encima de `eligibility.maxProtocol`).

### 9.2 Eje B — escalera extendida + `simplify` real (`adaptive_engine.dart`)

La escalera de **auto-progresión** (`_fastingLevels`) se extendió de `[Ninguno,12:12,14:10,16:8]` a `[Ninguno,12:12,14:10,16:8,18:6,20:4]`. Decisión de mapeo de vocabulario (la app no tiene tipos de protocolo "24h"/"36h" — solo las 8 strings del catálogo existente): **Experto** (§4 Eje B, "24h ocasional") y **Clínico** (§4 Eje B, "36h+") NO se implementaron como niveles de auto-progresión — 22:2 y OMAD quedan reservados a elección MANUAL del usuario vía `ProtocolSelectorSheet`, gateados por Eje A (22:2 sin supervisión, OMAD solo con `supervisionMedicaActiva`). El motor de comportamiento nunca los sugiere solo por adherencia/IMR — es una decisión de producto, no una limitación técnica: subir automáticamente a un protocolo que el propio Eje A trata como "requiere supervisión" habría sido incoherente.

`SuggestionType.simplify` (existía en el enum sin emitirse nunca) ahora se emite en dos casos: `EngagementLevel.critico` sostenido (adherencia semanal <50%, la misma definición que ya usaba el enum) y reporte de hipoglucemia (Eje D, ver 9.4) — este último ignora el período de gracia y fuerza la bajada de inmediato. Un protocolo elegido a mano fuera de la escalera automática (22:2/OMAD) baja al tope de la escalera automática (20:4), no se queda sin sugerencia.

### 9.3 §3.1 — días de descanso programado, nivel Novato (`fasting_schedule.dart`, NUEVO)

Implementado tal cual: conecta `GoalType.fastingDaysPerWeek` (antes huérfano) a `StreakNotifier` — en día no programado, `fastingMagnitude` se guarda `null` (no un valor bajo), reutilizando la renormalización ya existente de `dailyQualityScore` (SPEC-65). `PillarRing` gana un tercer estado visual (`isRestDay`, insignia de luna en vez del check verde) y `DashboardPillarsRow` lo calcula en vivo re-derivando el mismo cálculo que `StreakNotifier`.

**Decisión sobre el punto de mayor riesgo técnico identificado en §3.1.5 (`pillarsCompleted`/`qualifiesForStreak`/`computeAdherenceTrend`):** verificado y **NO se tocó**. `qualifiesForStreak` ya exige `pillarsCompleted >= 3 && (fastingCompleted || sleepCompleted || pillarsCompleted >= 4)` (SPEC-245) — en un día de descanso, el usuario califica igual vía el ancla de sueño o completando los 4 pilares restantes, sin necesidad de renormalizar el conteo binario sobre 4 pilares. Renormalizarlo además de `dailyQualityScore` habría sido redundante y con más riesgo de inflar adherencia artificialmente sin beneficio claro. Queda documentado aquí en vez de en un "no resuelto" — es una decisión, no una omisión.

### 9.4 Eje D — síntomas + supervisión médica (`fasting_symptom_log.dart`, NUEVO)

Supervisión médica: cubierta por Eje A (`FastingPathologyFlags.supervisionMedicaActiva`, opción de onboarding). Síntomas: tras un cierre anticipado de ayuno (`early_fasting_end_dialog.dart`, único momento real donde Suárez ubica la señal de alarma — no en un cierre normal al 100%), se pregunta si hubo mareo/temblor/palpitaciones. Un "sí" se persiste en SharedPreferences (ventana de 7 días, no es dato clínico que deba sincronizarse) y fuerza `simplify` en `AdaptiveEngine` de inmediato.

### 9.5 Eje C — guardrail de sistema nervioso generalizado

Generalizado de "solo el salto exacto a 20:4 en onboarding" a "cualquier salto que suba de nivel por encima de 16:8", con `unknown` tratado como Excitado (conservador, solo para esta decisión — no cambia lo persistido en `nervousSystem`). Extendido también al cambio de protocolo desde el dashboard (`fasting_consciousness_card.dart`), que antes no tenía ningún guardrail — un usuario Excitado podía subir de protocolo fuera del onboarding sin ningún aviso.

**Lo que NO se implementó de §4 Eje C:** "duplicar el tiempo mínimo de adaptación en cada escalón" (una gate temporal que trackee semanas-por-nivel) no se construyó — habría requerido persistir fecha-de-entrada-a-nivel por usuario, una pieza de estado nueva no cubierta por los archivos hand-rolled existentes (`StreakEntry`/`UserGoal`). Lo implementado es el guardrail de confirmación (mismo mecanismo que ya existía, generalizado en alcance), no un temporizador. Documentado como pendiente si Carlos lo quiere en una iteración futura.

### 9.6 LIMPIEZA — incoherencias encontradas y corregidas

- **Bug pre-existente, no introducido por SPEC-257 pero expuesto por él:** la card de protocolo "14/10" del onboarding (`IntroProtocolStep`, paso 105) tenía `id: '14:8'` — no suma 24h y no coincidía con ningún string del catálogo real. Un usuario que elegía "14/10" en su primer gesto quedaba con un protocolo fantasma, invisible para el gate de Eje A y para el mecanismo de días de descanso. Corregido a `'14:10'` (código + test).
- `FastingSchedule.effectiveDaysPerWeek` ignoraba silenciosamente un goal fuera de `[2,4]` y caía al default (3) sin decírselo al usuario — ahora recorta (`clamp`) en vez de descartar.
- `GoalSuggestionEngine._fastingDaysSuggestion` sugería hasta 6-7 días/semana para CUALQUIER protocolo, contradiciendo directamente el esquema "2-5" de Suárez para nivel Novato — ahora es consciente del nivel (Novato: 2-4 días con rationale actualizado; 16:8+: sin cambios, sigue siendo hábito diario).
- `FastingEligibility._rank` tenía un bug latente: un protocolo no reconocido caía a rank 0 (igual que 'Ninguno'), así que `allows()` lo dejaba pasar SIEMPRE — lo opuesto de lo que `clamp()` prometía en su propio doc comment. Corregido antes de que tuviera consecuencias reales (atrapado por el test suite nuevo, no en producción).

### 9.7 Archivos nuevos

`lib/src/features/streak/domain/fasting_eligibility.dart`, `fasting_schedule.dart`, `fasting_symptom_log.dart` + tests en `test/features/streak/domain/`.

### 9.8 Verificación pendiente de Carlos

Sin SDK Flutter/Dart en el sandbox no hay compilación real — todo lo anterior es revisión manual línea a línea, no `flutter analyze`/`flutter test` reales. Antes de mergear: `flutter analyze`, `flutter test`, y una pasada manual del flujo de onboarding + cambio de protocolo desde dashboard en un device/emulador real, prestando atención particular a los diálogos de guardrail (Eje C) y al anillo de día de descanso (§3.1) con un usuario Novato real.
