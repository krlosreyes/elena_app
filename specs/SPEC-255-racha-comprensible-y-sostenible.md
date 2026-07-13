# SPEC-255 — Racha comprensible y sostenible: de contador silencioso a hábito visible

**Estado:** IMPLEMENTED (2026-07-13) — ver §9 Notas de implementación
**Versión:** 1.0
**Líder:** Carlos · **Investigación y propuesta:** Claude
**Depende de:** SPEC-65 (StreakEntry + magnitudes), SPEC-220 (celebración 3/5 pilares — ya anticipaba "streakMilestone (7, 14, 30 días)" como extensión futura, §5), SPEC-197/198 (tiers y paywall)
**Prioridad:** Alta — retención es la causa raíz #1 identificada en la auditoría de producto del 2026-07-12 (`project_auditoria_producto_crecimiento_2026_07_12`)
**Estimación:** ver fases en §7

---

## 1. Por qué esta propuesta

La revisión línea a línea del sistema de racha (2026-07-13) encontró un mecanismo con sustancia real — no es un contador vanidoso, está anclado a evidencia (ayuno/sueño como pilares de mayor peso hormonal) y alimenta clasificaciones reales de engagement e IMR longitudinal — pero incompleto como *mecánica de motivación*. Cuatro gaps concretos:

1. **La regla es invisible.** Nada en la UI explica que se necesitan 3/5 pilares con ayuno o sueño entre ellos (o 4+/5 sin restricción). Un usuario que hace 3 pilares "fáciles" y no ve subir su racha no tiene cómo entender por qué.
2. **No hay protección de racha.** Un solo día de viaje o enfermedad la manda a cero. Es exactamente el patrón que más frustra y hace abandonar apps de hábitos.
3. **El copy de paywall/trial usa la racha como gancho de conversión, pero la racha no está gateada.** `feature_gate.dart` no tiene ningún flag relacionado a streak — Free, Trial y Premium la calculan igual. "Suscríbete para no perder tu racha" promete algo que no pasa.
4. **No hay hitos.** El crecimiento del número (día 8, día 15, día 45...) no tiene puntos de quiebre emocionales más allá de una etiqueta "RÉCORD" silenciosa.

Esta propuesta ataca los cuatro, con investigación de respaldo para cada decisión — el mismo estándar de rigor que ya usa el proyecto para ayuno/sueño/nutrición (`docs/CIRCADIAN_BIBLIOGRAPHY.md`, `NUTRITION_BIBLIOGRAPHY.md`).

## 2. Qué dice la evidencia

### 2.1 Las rachas funcionan — con o sin gancho artificial

Duolingo reporta que usuarios con racha de 7+ días retienen a 2.4x la tasa de quienes nunca la establecen. Su propio experimento controlado ("Streak Wager") mostró una mejora estadísticamente significativa de retención Día-7 (+14%) solo por ofrecer un mecanismo de compromiso alrededor de la racha. El mecanismo funciona porque explota **aversión a la pérdida** (Kahneman/Tversky): perder algo duele aproximadamente el doble de lo que place ganar lo equivalente. Elena ya tiene el ingrediente correcto (una racha real, anclada a comportamiento real) — le falta el resto del diseño alrededor.

### 2.2 La aversión a la pérdida es un arma de doble filo

La misma investigación que explica por qué las rachas retienen, explica por qué también generan ansiedad y abandono cuando se rompen sin salida digna: "una racha de 100 días se siente como un trofeo que hay que proteger", y ese apego puede volverse insano si no hay una vía de recuperación. La línea entre diseño ético y patrón oscuro está en si existe una red de seguridad — o si el usuario queda "atrapado" por su propio éxito.

### 2.3 Streak freeze: la red de seguridad que sí retiene

Apps con mecánica de "congelar" la racha (perdonar un día sin penalización) muestran datos concretos: usuarios que pasan 7 días de racha promedian 17.2 días de racha total si tienen freeze disponible, contra 11.6 sin él; pasados 14 días, la brecha crece a 30.6 vs 18.9. Esta función por sí sola se ha medido con **+23% de retención a largo plazo**. El diseño ético recomendado: freezes que se **ganan** por consistencia (no se compran con dinero), y opciones de "recuperación" que piden un pequeño esfuerzo, no un pago.

### 2.4 Autonomía, competencia y relación — por qué el gating puede sabotear la motivación

La Teoría de la Autodeterminación (Deci & Ryan) es el marco más citado para gamificación en salud: la gamificación motiva de forma sostenida solo cuando satisface autonomía, competencia y relación. Un estudio con 307 usuarios de apps de salud confirmó las tres vías como predictoras significativas de motivación intrínseca. Y el hallazgo más relevante para Elena: **"apps que usan rachas y castigos para forzar el uso diario producen cumplimiento de corto plazo pero apelan a culpa y vergüenza; apps que conectan el ejercicio con metas personalmente significativas y construyen progresión de competencia producen cambio de conducta sostenido."** Esto es literalmente el argumento a favor del pivot "passive logging → active coaching" que ya está documentado en la memoria del proyecto — la racha debe reforzar ese pivot, no contradecirlo con presión artificial.

### 2.5 El mito de los 21 días (y por qué importa corregirlo)

La cifra popular de "21 días para formar un hábito" no tiene base empírica sólida. El estudio de referencia (Lally et al. 2010, *European Journal of Social Psychology*) encontró que la automatización de un hábito nuevo toma en promedio **66 días**, con un rango de 18 a 254 días según la persona y la conducta. Cualquier copy de hitos que Elena muestre debería evitar prometer "en 21 días esto será automático" — no es cierto, y el propio estándar de rigor científico del proyecto (Frank Suárez ✅ operacional en copy pero no en el score; toda cifra clínica con cita verificable) exige no repetir el mito.

### 2.6 Autocompasión: qué decir cuando la racha se rompe

Investigación en adherencia a dietas y ejercicio muestra que la autocompasión — reconocer el lapso sin juicio, entender la causa, y recomprometerse en la siguiente oportunidad — predice mejor la continuidad que la autocrítica. El mecanismo cognitivo es concreto: pasar de "fallé" a "me salté uno, retomo en el siguiente". Hoy Elena no dice nada cuando la racha se rompe — el badge del header simplemente desaparece. Eso es mejor que un mensaje de culpa, pero es una oportunidad perdida de aplicar exactamente este hallazgo.

## 3. Propuesta

### RF-255-01 — Explicar la regla (transparencia)

Agregar un ⓘ junto al badge de racha del header y a `StreakSummaryCard` (mismo patrón ya usado en `DailyScoreExplainerSheet` — reutilizar el componente, no inventar uno nuevo) que abra un sheet explicando en el tono cálido ya establecido (`feedback_copy_voice_tone`):

> "Tu racha cuenta los días donde avanzas de verdad en tu metabolismo: al menos 3 de tus 5 pilares, y entre ellos, ayuno o sueño — son los dos con más evidencia científica detrás (Sutton 2018, Walker 2017). Si completas 4 o 5 pilares, ese día siempre cuenta, sin importar cuáles."

Sin cambiar la regla — solo hacerla visible. Complejidad baja.

### RF-255-02 — Reserva de racha (freeze ganada, no comprada)

Cada 7 días de racha activa consecutiva, el usuario gana **1 "reserva"** (tope 2 acumuladas) que perdona automáticamente el siguiente día que no califique, sin que el usuario tenga que hacer nada. Se consume en silencio — el badge del header no baja a 0, muestra un indicador sutil ("racha protegida hoy"). Disponible para **todos los tiers**, no solo Premium — dado el hallazgo de §RF-255-05 (la racha nunca estuvo gateada), condicionarla a pago ahora sería introducir el mismo problema de credibilidad que se está corrigiendo. Complejidad media (toca `StreakEntry`, `StreakEngine.computeCurrentStreak`, `StreakNotifier`).

### RF-255-03 — Reencuadre al romperse (autocompasión, no silencio)

Cuando `StreakNotifier` detecta que una racha activa se rompió (racha anterior > 0, hoy no calificó y no hay reserva disponible), la próxima vez que el usuario abre el Dashboard, un mensaje breve — no un banner de alarma, algo del tono de `EngagementService` — reemplaza el silencio actual:

> "Tu racha de {N} días se pausó, no se borró. Ese récord sigue siendo tuyo (`longestStreak`). Hoy es un buen día para empezar la siguiente."

Se muestra una sola vez (one-shot, mismo patrón que `CelebrationEvent`). Complejidad baja-media.

### RF-255-04 — Hitos nombrados (extiende lo que SPEC-220 ya anticipó)

`CelebrationType.streakThreshold` ya existe para el cruce diario de 3/5. Agregar `CelebrationType.streakMilestone` para 3, 7, 14, 30, 60 y 100 días de racha activa, con copy y visual distintos (más celebratorio, quizás con el ícono de fuego creciendo de tamaño). Evitar cualquier promesa de "a partir de aquí ya es automático" (§2.5) — el copy debe celebrar el logro pasado, no prometer facilidad futura. Ejemplo día 7: "7 días seguidos — tu cuerpo empieza a notar el ritmo." Complejidad baja (el mecanismo de `celebrationEventProvider` ya existe, solo se agrega el tipo y el trigger).

### RF-255-05 — Corregir el copy de paywall y trial banner

`paywall_screen.dart:236` y `trial_banner.dart:161` prometen que suscribirse evita perder la racha — no es cierto, la racha nunca estuvo gateada. Reemplazar por lo que sí es verdad y sí se pierde: coaching ilimitado, feedback de cierre de ciclo, histórico/longitudinal en Análisis, auto-sync de wearables. Ejemplo: *"Te quedan {N} días — suscríbete para no perder el coaching y tu histórico completo."* Complejidad trivial (cambio de copy), pero prioridad alta — es un problema de confianza, no solo de precisión.

### RF-255-06 — Instrumentación

Hoy no existe ningún evento de analytics relacionado a racha en `analytics_events.dart` — no hay forma de saber si esta mecánica retiene a nadie. Agregar (bucketed, sin PII, siguiendo el patrón ya establecido): `streak_milestone_reached` (bucket de días), `streak_broken`, `streak_freeze_used`, `streak_explainer_opened`. Esto es lo que permite, en unas semanas, medir si RF-01 a RF-05 realmente mueven la retención D7/D14 — el mismo tipo de métrica que Duolingo publicó para justificar su propio diseño.

### RF-255-07 (opcional, fase posterior) — Pista visual de qué pilares "anclan" hoy

En `DashboardPillarsRow`, un indicador sutil (no un badge nuevo, algo como el borde del ring de Ayuno/Sueño) quede visualmente distinto cuando ese pilar es el que le falta al usuario para calificar el día. Ayuda a que la regla de §RF-255-01 se sienta, no solo se lea una vez. Complejidad media — requiere pasar el resultado de `qualifiesForStreak` parcial (qué falta) hasta el widget.

## 4. Qué deliberadamente NO se propone

- **No vender reservas de racha con dinero real.** Ya existe un problema de credibilidad con la racha y el paywall (§RF-255-05) — resolverlo introduciendo una nueva versión pagada del mismo problema sería peor, no mejor.
- **No leaderboards ni comparación social.** Fuera de alcance para esta propuesta y en tensión directa con `feedback_pillar_nutrition` (la audiencia de Elena tiene historial de sobrepeso/salud — comparación social en ese contexto es un riesgo, no un incentivo).
- **No mensajes de culpa ni rachas "castigadas".** Cualquier copy nuevo pasa el mismo filtro de `feedback_copy_voice_tone` que ya rige el resto del producto.
- **No se toca la regla de qué cuenta como racha** (3/5 con ayuno/sueño, o 4+/5). Sigue siendo la protección correcta contra "inflar" la racha solo con pilares de bajo impacto metabólico — eso no es parte del problema, es parte de lo que ya funciona bien.

## 5. Mapa técnico (para cuando se apruebe — nada de esto se tocó en esta sesión)

| Archivo | Cambio |
|---|---|
| `features/streak/domain/streak_entry.dart` | Campo `freezesAvailable`/`freezeUsedToday` (RF-02) |
| `features/streak/domain/streak_engine.dart` | `computeCurrentStreak` considera reservas al evaluar huecos (RF-02) |
| `features/streak/application/streak_notifier.dart` | Detectar racha rota sin reserva (RF-03), otorgar reserva cada 7 días (RF-02), disparar `streakMilestone` (RF-04) |
| `core/providers/celebration_providers.dart` / nuevo `celebration_event.dart` | `CelebrationType.streakMilestone` (RF-04) |
| nuevo: `features/streak/presentation/widgets/streak_explainer_sheet.dart` | RF-01, mismo patrón que `daily_score_explainer_sheet.dart` |
| `core/widgets/elena_header.dart`, `streak_summary_card.dart` | ⓘ hacia el explainer (RF-01), indicador de reserva activa (RF-02) |
| nuevo widget de reencuadre en `dashboard_screen.dart` | RF-03 |
| `features/billing/presentation/paywall_screen.dart:236`, `trial_banner.dart:161` | Copy corregido (RF-05) |
| `core/analytics/analytics_events.dart` | 4 eventos nuevos (RF-06) |
| `features/dashboard/presentation/widgets/dashboard_pillars_row.dart` | Indicador de pilar-ancla (RF-07, opcional) |

## 6. Fases sugeridas

**Fase 1 — bajo esfuerzo, corrige lo que ya está mal (1-2 días):** RF-05 (copy de paywall, es casi urgente por credibilidad), RF-01 (explainer), RF-06 (instrumentación — sin esto no hay forma de medir el resto).

**Fase 2 — el corazón de la propuesta (3-5 días):** RF-04 (hitos nombrados, mecanismo ya existe), RF-03 (reencuadre al romperse).

**Fase 3 — la pieza de mayor impacto medido pero más invasiva (3-4 días):** RF-02 (reserva de racha) — tocar `StreakEngine.computeCurrentStreak` es sensible (alimenta `weeklyAdherence`/`adherenceTrend`/IMR longitudinal), aplica el protocolo de no-regresión (`feedback_no_regression_protocol`) antes de tocarlo.

**Opcional, sin fecha:** RF-07.

## 7. Criterio de éxito

El informe de producto del 2026-07-12 ya definió el North Star: "semanas con hábito real", no solo retención cruda. Esta propuesta debería moverse en, como mínimo:

- Tasa de reengagement tras una racha rota (hoy no medible — RF-06 lo habilita).
- Retención D7/D14 comparando cohortes antes/después de Fase 2 (mismo tipo de medición que usó Duolingo para validar su Streak Wager).
- Tasa de apertura del explainer de racha (¿la gente realmente quiere entender la regla, o es indiferente?).

Ninguna de estas métricas existe hoy porque no hay instrumentación (§RF-255-06) — es la primera pieza que hay que construir, incluso antes de decidir si el resto de la propuesta se aprueba completa.

## 8. Fuentes

- [The Psychology of Streaks: How Sylvi Weaponized Duolingo's Best Feature Against Them — Trophy](https://trophy.so/blog/the-psychology-of-streaks-how-sylvi-weaponized-duolingos-best-feature-against-them)
- [App Teardown: How Duolingo's Streak Mechanic Actually Works — Apptitude](https://apptitude.io/blog/how-duolingos-streak-mechanic-actually-works/)
- [Duolingo — Streak System Detailed Breakdown & Design — Medium](https://medium.com/@salamprem49/duolingo-streak-system-detailed-breakdown-design-flow-886f591c953f)
- [Designing A Streak System: The UX And Psychology Of Streaks — Smashing Magazine](https://www.smashingmagazine.com/2026/02/designing-streak-system-ux-psychology/)
- [How Can Loss Aversion Psychology Transform App Retention? — Glance](https://thisisglance.com/learning-centre/how-can-loss-aversion-psychology-transform-app-retention)
- [The Psychology of Streaks: Why They Work (And When They Backfire) — Cohorty](https://blog.cohorty.app/the-psychology-of-streaks-why-they-work-and-when-they-backfire/)
- [The Dark Psychology Behind Your Everyday Apps — The Brink](https://www.thebrink.me/gamified-life-dark-psychology-app-addiction/)
- [Self-Determination Theory: Deci & Ryan's 6 Mini-Theories — Yu-kai Chou](https://yukaichou.com/gamification-analysis/self-determination-theory-guide-to-ryan-and-decis-motivation-framework/)
- [The Impact of Gamification-Induced Users' Feelings on the Continued Use of mHealth Apps: SEM with SDT — JMIR](https://www.jmir.org/2021/8/e24546)
- [The Impact of Gamification-Induced Users' Feelings on the Continued Use of mHealth Apps — PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC8391751/)
- [Tiny Habits by BJ Fogg: The Fogg Behavior Model Explained — EasyHabits](https://www.easyhabits.io/blog/tiny-habits-bj-fogg)
- [The Science of Habit Formation — Mindspacex](https://www.mindspacex.com/post/the-science-of-habit-formation-full-article)
- [The Role of Self-Compassion and its Individual Components in Adaptive Responses to Dietary Lapses — PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC10543633/)
- [Self-Compassion and Reactions to a Recalled Exercise Lapse — PubMed](https://pubmed.ncbi.nlm.nih.gov/34702786/)
- [Does self-compassion help to deal with dietary lapses among overweight and obese adults? — PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC8451927/)
- [Self-Compassion and Adherence in Five Medical Samples: the Role of Stress — PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6320740/)
- [Variable Reward Schedules: The Habit Science Slot Machines Use — FineStreak](https://finestreak.com/blog/reward-schedules-habit-reinforcement)
- [Variable rewards in product design: 5 strategies to boost engagement — Appcues](https://www.appcues.com/blog/variable-rewards)

## 9. Notas de implementación (2026-07-13)

Los 7 RFs se implementaron en la misma sesión que aprobó la propuesta ("trabaja en loop hasta terminar"). Un cambio de diseño respecto al §5 original, y por qué:

**RF-02 — se implementó SIN persistencia, como función pura derivada.** El mapa técnico original proponía campos `freezesAvailable`/`freezeUsedToday` en `StreakEntry` + escritura en Firestore. En la implementación real se optó por `StreakEngine.computeCurrentStreakWithFreezes(history)`: una función pura que, en un solo pase hacia adelante sobre el historial existente, calcula qué días quedan protegidos y cuántas reservas hay disponibles — sin escribir ningún campo nuevo a Firestore ni tocar `StreakEntry`.

Por qué es preferible: (1) cero riesgo de migración — no hay `freezesAvailable: 0` que backfillear en documentos viejos; (2) cero riesgo de desync — no puede haber un contador persistido que no coincida con lo que el historial real dice; (3) respeta al pie de la letra `feedback_no_regression_protocol` y `feedback_interface_extension` — no se tocó la firma de `StreakEntry`, así que los 7 call-sites de test que la construyen (`streak_engine_test.dart`, `daily_score_provider_test.dart`, `observation_detector_test.dart`, etc.) siguen compilando sin cambios; (4) propiedad de no-regresión matemática: mientras un usuario nunca acumule 7 días reales consecutivos, el set de fechas protegidas queda vacío y `computeCurrentStreakWithFreezes` devuelve exactamente lo mismo que `computeCurrentStreak` — el 100% de los usuarios actuales (todos con rachas cortas) ve cero cambio de comportamiento hasta que efectivamente se ganen una reserva.

**Separación deliberada de streams**: `computeCurrentStreak` (sin protección) sigue siendo la única función que alimenta `computeAdherenceTrend` → IMR longitudinal. `computeCurrentStreakWithFreezes` solo alimenta `StreakState.currentStreak` (lo que ve el usuario en header/card). Esto evita que el freeze — pensado como mecánica motivacional de UI — infle silenciosamente una métrica clínica.

**RF-03 y RF-04 reutilizan la infraestructura de `CelebrationEvent`/`celebrationEventProvider`** (SPEC-220) en vez de construir un sistema nuevo — se agregaron los tipos `streakMilestone` y `streakBroken` al enum existente. Conocido y aceptado: si un hito de racha y el umbral 3/5 pilares del día ocurren en el mismo tick, el `StateProvider` (single-slot) solo conserva el último — no hay cola. Trade-off documentado, no bloqueante (P3, revisar si telemetría muestra que ocurre seguido).

**Guard de "baseline"** (`_celebrationBaselineSet` en `StreakNotifier`): sin este guard, cualquier usuario que abriera la app con una racha ya existente de 7+ días dispararía de golpe los hitos 3 y 7 en su primer `_rebuildState` de la sesión. Se salta la detección de hitos/ruptura en el primer rebuild tras cada login.

**Archivos tocados** (además de los listados en §5, sin nuevos archivos salvo el explainer sheet): `lib/src/core/analytics/analytics_events.dart`, `lib/src/features/billing/presentation/paywall_screen.dart`, `lib/src/features/billing/presentation/trial_banner.dart`, `lib/src/features/streak/domain/streak_engine.dart`, `lib/src/features/streak/application/streak_notifier.dart`, `lib/src/core/providers/celebration_providers.dart`, `lib/src/features/dashboard/presentation/widgets/celebration_overlay.dart`, `lib/src/core/widgets/elena_header.dart`, `lib/src/features/analysis/presentation/widgets/streak_summary_card.dart`, `lib/src/features/dashboard/presentation/widgets/pillar_ring.dart`, `lib/src/features/dashboard/presentation/widgets/dashboard_pillars_row.dart`. Nuevo: `lib/src/features/streak/presentation/widgets/streak_explainer_sheet.dart`.

**No se creó ningún test nuevo** — no existían tests de `streak_notifier.dart`, `celebration_providers.dart` ni `celebration_overlay.dart` previos a esta sesión (confirmado por grep) sobre los cuales apoyarse o extender con el patrón ya establecido del proyecto. `flutter analyze`/`flutter test`/`flutter build` no se ejecutaron en este sandbox (sin SDK de Flutter/Dart disponible) — verificación pendiente de Carlos.
