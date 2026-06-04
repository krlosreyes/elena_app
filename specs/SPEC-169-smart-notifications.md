# SPEC-169 — Notificaciones inteligentes con cita bibliográfica

**Estado:** CLOSED 2026-06-04
**Versión:** 1.1 (reescritura de copies — feedback Carlos "muy robóticas, queremos cercanía")
**Tipo:** Active coaching — segunda ola post-pivot. Convierte el lockscreen en canal de coaching educativo.
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2.5 (delivery 2026-06-04, doc `docs/PLAN_DELIVERY_2026_06_04.md`)
**Estimación:** 1 día (MVP1, sin deep-link). Deep-link a ExplainerSheet va a SPEC-169.next.
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §1-§5, `IMR_BIBLIOGRAPHY.md` §13.
**Depende de:** SPEC-05 (NotificationService), SPEC-149 (Día Metabólico), SPEC-150 (patrón pool de mensajes con cita).
**Bloquea:** SPEC-169.next (deep-link ExplainerSheet), SPEC-147 (insights adaptativos Ola 3 — reusan el patrón).

---

## 1. Contexto

El pivot estratégico de 2026-06-01 (passive logging → active coaching) abrió la pregunta: *¿dónde recibe el usuario coaching de verdad fuera de la pantalla?* SPEC-150 implementó la primera notificación educativa (hidratación con cita), validando el patrón. Esta SPEC extiende el patrón al resto de notificaciones del producto.

Hoy `NotificationScheduler` programa 7 notificaciones circadianas + 3 hitos de ayuno + N slots de hidratación. Las circadianas y los hitos son **operacionales** ("Cerraste tu ventana", "12h de ayuno"): le dicen al usuario qué pasa, no por qué. Eso contradice el pivot: el usuario sigue percibiendo a Elena como cuaderno, no como coach.

**El problema concreto:** el usuario abre la notificación, lee "🔥 18 horas — Cetosis activa" y queda igual. Sin cita, sin pegar el "por qué". El conocimiento de Elena (los blueprints Metabolic Clock + Biological Dial, los autores Mattson, Walker, Sutton, Lopez-Minguez) no llega al usuario en el momento donde más decide su comportamiento (lockscreen, fuera de la app).

## 2. Decisiones de producto

### 2.1 — Cita bibliográfica en TODAS las notificaciones circadianas y de ayuno

Patrón unificado: `body = "{mensaje accionable} · {cita corta}"`. Igual a SPEC-150 (hidratación). Esto da continuidad visual + cognitiva: el usuario aprende a leer "· Sutton 2018" como marca de coaching educativo.

### 2.2 — Nueva notificación: autofagia confirmada (hora 16 de ayuno)

Hoy `scheduleFastingMilestones` programa 12h, 18h, 24h. La autofagia se cita en 24h, pero la evidencia clínica sólida la pone más cerca de las **16 horas** de ayuno (Levine 2017 *Cell Metabolism*). Agregamos el hito 16h con cita explícita y mantenemos 24h como "autofagia profunda".

### 2.3 — Nueva notificación: eTRF pre-sueño (3h antes de `sleepTime`)

Patrón eTRF (early Time-Restricted Feeding, Sutton 2018 *Cell Metabolism*; Hutchison 2019 *Obesity*): cerrar la ventana de comida al menos 3h antes de dormir mejora glucemia, lipidemia y sueño. La app ya programa `lastMealWarning` 30min antes de `lastMealGoal`, pero no enseña por qué la ventana cierra ahí. Agregamos una notificación adicional a **`sleepTime - 3h`** con cita.

Si `sleepTime - 3h` cae después del `lastMealGoal` ya programado, no se agrega (sería redundante). Caso típico: sleep 23:00 → eTRF a 20:00; lastMealGoal típico 20:30 → ventanas se solapan, la eTRF gana porque viene antes.

### 2.4 — Ventana cerrándose: ancla al ciclo metabólico cuando hay ciclo abierto

Hoy `lastMealWarning` se ancla a `profile.lastMealGoal` (hora fija del perfil). Si el usuario inició su ayuno antes del horario típico (caso protocolo 18:6 abierto a 12:30 vs apertura real 14:30), el aviso de cierre puede caer fuera de su ventana real.

**Mejora MVP1:** si hay ciclo metabólico abierto (`currentMetabolicCycleProvider != null`), calcular el cierre de ventana como `cycle.startedAt + (24h - protocolHours)`. Si no hay ciclo abierto (caso usuario primer día o protocolo "Ninguno"), usar `profile.lastMealGoal` como hoy. La cita siempre es Mattson 2017.

Esto NO requiere refactor del `dailyScoreProvider` (deuda Ola 2.5 separada): solo lee `currentMetabolicCycleProvider` al programar.

### 2.5 — MVP1 sin deep-link a ExplainerSheet

Las notificaciones de MVP1 abren el app en `/dashboard` como hoy. **Deep-link al ExplainerSheet del Score del Día con la cita completa va a SPEC-169.next** (~1 día adicional, requiere route + payload + sheet wiring). El motivo: el patrón actual de SPEC-150 ya valida "cita corta + push directo" como suficiente. Deep-link es nice-to-have, no bloquea el pivot.

### 2.6 — Tono humano-cercano, no clínico

**Criterio explícito (memoria `notification-tone-human-not-clinical`):** la audiencia de Elena son personas con historial de problemas de salud, sobrepeso o dificultad para crear hábitos. Las notificaciones tienen que sentirse como un coach que las acompaña — no como un manual médico. Reglas concretas:

1. **Hablar a la persona en segunda persona (tú).** "Faltan 30 minutos para cerrar tu ventana", no "Cierre de ventana inminente".
2. **Reconocer el esfuerzo, celebrar logros chicos.** "12 horas. Tu cuerpo ya cambió de marcha — y tú llegaste hasta acá" en vez de "Insulina en mínimos. Gluconeogénesis activa."
3. **Sin culpa, sin alarmas.** "Si comiste antes, lo estás haciendo bien" en lugar de "Última oportunidad antes del bloqueo".
4. **Imperativos suaves o sugerencias, no órdenes.** "Cerrar la ventana ahora ayuda a que el descanso sea mejor" mejor que "Cerrá tu ventana ya".
5. **Jerga médica al ExplainerSheet, no al lockscreen.** "Tu cuerpo empieza a limpiar y reparar" mejor que "Inicia limpieza glinfática". La palabra técnica vive en el sheet con cita completa.
6. **Cita al final, en gris discreto.** El body es humano; la cita es respaldo, no la voz principal.

Los emojis existentes (☀️🍽️🌙) se mantienen para continuidad visual. Algunos cambian a versiones más cálidas (🔒 candado → 🌙 luna en bloqueo intestinal). NO agregamos exclamaciones ni emojis de alarma.

## 3. Lo que NO se hace (límites duros)

- **NO deep-link al ExplainerSheet.** Va a SPEC-169.next.
- **NO refactor del `dailyScoreProvider` a ciclo metabólico.** Va al refactor §3.1 del PLAN_DELIVERY 2026-06-04. Esta SPEC solo lee el ciclo para programar.
- **NO cambio del intestinalLock hardcoded a 21:30** (SPEC-70.5 vigente). Las notificaciones de bloqueo intestinal mantienen sus horas; solo se les agrega cita.
- **NO modificación de SPEC-150.** Hidratación ya tiene su pool con citas, no se toca.
- **NO se internacionaliza la cita** (todas las citas hardcoded en español; la app es ES-only por ahora).
- **NO se mide adherencia a las notificaciones** (qué notif se abre vs ignora). Telemetría sale del scope.

## 4. Requisitos funcionales

### RF-169-01 — Copies humano-cercanos en notificaciones circadianas

Modificar `NotificationScheduler.scheduleCircadianDay`. Cada notificación tiene title y body nuevos (más cálidos) con cita al final del body.

| Notif | Title nuevo | Body nuevo |
|---|---|---|
| Despertar | `☀️ Buenos días` | `Tu cuerpo se despertó con la energía justa. Aprovéchala para algo que te importe hoy. · Biological Dial §3` |
| Primera comida | `🍽️ Tu ventana abrió` | `Si tienes hambre, este es el momento. Tu cuerpo está listo para recibir. · Sutton 2018` |
| 30 min cierre ventana | `⏰ 30 minutos para cerrar tu ventana` | `Si te falta algo, ahora es buen momento — sin culpa. · Mattson 2017` |
| Bloqueo intestinal 60 min | `🌙 Una hora para soltar el día` | `En una hora tu cuerpo entra en modo reparación. Si vas a cenar, hagamos que sea ya. · Lopez-Minguez 2018` |
| Bloqueo intestinal 30 min | `🌙 30 minutos para soltar` | `Tu cuerpo está a media hora de concentrarse en repararse. Si comiste antes, lo estás haciendo bien. · Lopez-Minguez 2018` |
| Bloqueo intestinal activo | `🌙 Modo reparación activado` | `Tu cuerpo empieza a hacer lo suyo: limpiar y reparar. Esto pasa mientras descansas. · Xie 2013` |
| Recordatorio de sueño | `🌙 Hora de descansar` | `Las primeras dos horas son las que más reparan. Mereces ese descanso. · Walker 2017` |

### RF-169-02 — Hito de autofagia hora 16

En `scheduleFastingMilestones`, **agregar** hito `fasting16h` entre `12h` y `18h`:

Tabla unificada (los 4 hitos con title y body humano-cercanos):

| ID | Title | Body |
|---|---|---|
| `fasting12h` | `⚡ 12 horas` | `Tu cuerpo ya cambió de marcha — y tú llegaste hasta acá. · Cahill 2006` |
| `fasting16h` (nuevo) | `✨ 16 horas — Limpieza profunda` | `Tu cuerpo empezó una limpieza profunda gracias a lo que estás haciendo hoy. · Levine 2017` |
| `fasting18h` | `🔥 18 horas — Cabeza clara` | `Tu cuerpo encontró otro combustible. Tu cabeza lo va a notar pronto. · Mattson 2018` |
| `fasting24h` | `✨ 24 horas — Reparación profunda` | `La limpieza llegó a su punto más alto. Esto es trabajo profundo del que pocas veces te das cuenta. · Mizushima 2008` |

### RF-169-03 — Notificación eTRF pre-sueño

Nueva función pública en `NotificationScheduler`. Se llama desde `scheduleCircadianDay` (igual que el resto). ID nuevo `NotificationIds.eTRFPreSleep`.

```dart
// Dentro de scheduleCircadianDay, tras programar lastMealWarning:
final sleepTime = profile.sleepTime;
final eTRFCutoff = DateTime(2000, 1, 1, sleepTime.hour, sleepTime.minute)
    .subtract(const Duration(hours: 3));

// Si la ventana eTRF cae después del lastMealGoal del usuario, no agendamos
// — el aviso de cierre 30 min ya cubre la advertencia.
final lastMeal = profile.lastMealGoal;
final lastMealDt = lastMeal == null
    ? null
    : DateTime(2000, 1, 1, lastMeal.hour, lastMeal.minute);
if (lastMealDt == null || eTRFCutoff.isBefore(lastMealDt)) {
  await _scheduleCircadian(
    id: NotificationIds.eTRFPreSleep,
    hour: eTRFCutoff.hour,
    minute: eTRFCutoff.minute,
    title: '🌙 3 horas antes de dormir',
    body:
        'Si cierras la ventana ahora, tu descanso te lo va a agradecer. · Sutton 2018',
  );
}
```

### RF-169-04 — Anclaje al ciclo metabólico para "30 min cierre ventana"

`scheduleCircadianDay(user)` no tiene acceso al ciclo abierto (no recibe `Ref`). Para no romper la firma, **agregamos sobrecarga** `scheduleCircadianDay(user, {MetabolicCycle? openCycle})`. Si `openCycle != null` y `openCycle.fastingProtocol != 'none'`:

- Calcular `windowCloseFromCycle = openCycle.startedAt + Duration(hours: 24 - protocolFastingHours(openCycle.fastingProtocol))`.
- Si `windowCloseFromCycle` cae hoy entre `[wakeUpTime, sleepTime]`, usar esa hora en vez de `profile.lastMealGoal` para el `lastMealWarning`.
- Sino, fallback al `profile.lastMealGoal` actual.

`protocolFastingHours` es un helper local (16, 18, 20 según protocolo). Si protocolo `'none'` o desconocido, retorna null y el código usa el fallback.

El `notification_provider.dart` que invoca `scheduleCircadianDay` ya tiene acceso al `Ref`; lee `ref.read(currentMetabolicCycleProvider.future)` (o lo expone como state) y lo pasa como parámetro opcional.

### RF-169-05 — `NotificationIds` extensiones

En `notification_service_mobile.dart` y `notification_service_web.dart`:

```dart
static const int fasting16h = ...;       // nuevo (entre fasting12h y fasting18h)
static const int eTRFPreSleep = ...;     // nuevo (en rango circadiano)
```

Sin colisión con los rangos `hydrationStart=400 / hydrationEnd=419`.

### RF-169-06 — Tests

- `test/core/services/notification_scheduler_smart_test.dart` (nuevo):
  - `scheduleCircadianDay` con `openCycle == null` programa `lastMealWarning` usando `profile.lastMealGoal` (como hoy).
  - `scheduleCircadianDay` con `openCycle != null` (protocolo `16:8`, startedAt 12:30) programa `lastMealWarning` 30 min antes de 20:30 (cycle window close = startedAt + 8h).
  - `scheduleCircadianDay` con `sleepTime 23:00` y `lastMealGoal 22:00` programa `eTRFPreSleep` a 20:00 (sleep - 3h, antes de lastMealGoal).
  - `scheduleCircadianDay` con `sleepTime 22:00` y `lastMealGoal 19:00` NO programa `eTRFPreSleep` (sleep - 3h = 19:00, no antes de lastMealGoal).
  - `scheduleFastingMilestones` programa 4 hitos (12, 16, 18, 24h) en orden.
- Tests existentes de `notification_scheduler_hydration_test.dart` siguen pasando sin tocar.

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Agregar IDs `fasting16h` y `eTRFPreSleep` | `lib/src/core/services/notification_service_mobile.dart` + `_web.dart` |
| 2 | Modificar bodies de las 7 notifs circadianas con cita | `lib/src/core/services/notification_scheduler.dart` |
| 3 | Agregar hito 16h en `scheduleFastingMilestones` con cita | `lib/src/core/services/notification_scheduler.dart` |
| 4 | Ajustar bodies de los 3 hitos existentes (12, 18, 24h) con cita | `lib/src/core/services/notification_scheduler.dart` |
| 5 | Agregar `_scheduleETRFPreSleep` helper interno | `lib/src/core/services/notification_scheduler.dart` |
| 6 | Sobrecarga `scheduleCircadianDay(user, {MetabolicCycle? openCycle})` | `lib/src/core/services/notification_scheduler.dart` |
| 7 | `notification_provider.dart` lee `currentMetabolicCycleProvider` y pasa al scheduler | `lib/src/core/providers/notification_provider.dart` |
| 8 | Tests smart notifications | `test/core/services/notification_scheduler_smart_test.dart` (nuevo) |

## 6. Criterios de aceptación

1. Las 7 notificaciones circadianas existentes incluyen `· {cita}` al final del body.
2. Hito de ayuno hora 16 se programa entre 12h y 18h con cita Levine 2017.
3. eTRF pre-sueño se programa cuando `sleepTime - 3h < lastMealGoal`, no se programa cuando ≥.
4. Usuario con ciclo abierto protocolo 16:8 iniciado 12:30 recibe `lastMealWarning` 20:00 (30 min antes del cierre 20:30 calculado desde ciclo).
5. Usuario sin ciclo abierto sigue recibiendo `lastMealWarning` a `lastMealGoal - 30min` (comportamiento legacy).
6. Cambio de perfil circadiano reprograma TODA la agenda nueva (no quedan notifs viejas).
7. `flutter analyze` sin issues nuevos.
8. `flutter test` mantiene baseline + ≥6 tests nuevos del scheduler smart.

## 7. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Citas en español pueden sonar pedantes en lockscreen | Media | Tono "claim + dato" probado por SPEC-150 sin pushback de Carlos. Si hay fricción visual, iterar copies en SPEC-169.1. |
| R-02 | Anclaje al ciclo puede dar avisos erráticos si el ciclo cambia durante el día | Baja | El scheduler se llama solo cuando cambia el perfil O al abrir/cerrar ciclo. `cancelCircadian` + reschedule es idempotente. |
| R-03 | Hito 16h coincide con horario social (ayuno 12h iniciado 20:00 → notif 12:00) | Baja | El hito es informativo, no crítico. Si el usuario está en almuerzo a esa hora, el copy ("autofagia inicial") es congruente con su decisión de comer. |
| R-04 | eTRF 3h puede caer durante actividad social (cena) | Media | La notif sugiere, no obliga. Y solo se programa si la eTRF cae **antes** del `lastMealGoal`, así que el usuario ya configuró su horario. |
| R-05 | Falta deep-link reduce el impacto educativo | Media | Aceptado para MVP1. SPEC-169.next lo agrega en ~1 día. Cita corta en body es suficiente para validar adopción. |

## 8. Out of scope (explícito)

- Deep-link a ExplainerSheet con cita completa → SPEC-169.next.
- Refactor del `dailyScoreProvider` al ciclo metabólico → tarea separada de Ola 2.5 §3.1.
- Modificación de SPEC-150 hidratación → ya tiene su pool y citas.
- Telemetría de adherencia a notificaciones → fuera de scope (SPEC-150.tail futuro).
- Localización de citas a inglés/portugués → app sigue siendo ES-only.
- Pool dinámico de copies para circadianas (como hidratación) → MVP usa copy fijo por notif; pool va a SPEC-169.2 si Carlos lo pide.

## 9. Bibliografía citada (referencias completas)

- **Biological Dial §3** — `docs/CIRCADIAN_BIBLIOGRAPHY.md` §3. Pico cognitivo 10:00.
- **Sutton 2018** — Sutton EF et al. *eTRF improves insulin sensitivity, blood pressure, and oxidative stress even without weight loss in men with prediabetes.* Cell Metabolism 27(6):1212-1221. Resumen IMR_BIBLIOGRAPHY §13.3.
- **Mattson 2017** — Mattson MP et al. *Impact of intermittent fasting on health and disease processes.* Ageing Research Reviews 39:46-58. CIRCADIAN_BIBLIOGRAPHY §2 fases del ayuno.
- **Lopez-Minguez 2018** — Lopez-Minguez J et al. *Timing of breakfast, lunch, and dinner. Effects on obesity and metabolic risk.* Nutrients 11(11):2624. CIRCADIAN_BIBLIOGRAPHY §3.
- **Xie 2013** — Xie L et al. *Sleep drives metabolite clearance from the adult brain.* Science 342(6156):373-377. Sistema glinfático nocturno.
- **Walker 2017** — Walker M. *Why We Sleep.* Cap. 5 sobre liberación de GH en sueño profundo.
- **Cahill 2006** — Cahill GF. *Fuel metabolism in starvation.* Annual Review of Nutrition 26:1-22. Gluconeogénesis temprana.
- **Levine 2017** — Levine B et al. *Biological functions of autophagy genes: a disease perspective.* Cell 176(1-2):11-42. Autofagia 16h+.
- **Mattson 2018** — Mattson MP et al. *Intermittent metabolic switching, neuroplasticity and brain health.* Nature Reviews Neuroscience 19(2):63-80. Cetosis nutricional 18h+.
- **Mizushima 2008** — Mizushima N, Komatsu M. *Autophagy: renovation of cells and tissues.* Cell 147(4):728-741. Autofagia profunda.

Todas se incorporan a `IMR_BIBLIOGRAPHY.md` §14 (nueva sección "Notificaciones inteligentes — citas") al cerrar SPEC-169.

## 10. Cierre

Implementación completada en bloque único (~1.5h, 5 bloques A-E):

- [x] **A** — IDs `fasting16h` (203) y `eTRFPreSleep` (107) en `notification_service_mobile.dart` + `_web.dart`. 7 notificaciones circadianas reescritas con copies humano-cercanos + cita.
- [x] **B** — Hito ayuno 16h agregado en `scheduleFastingMilestones` (Levine 2017). Hitos 12/18/24h con copies v1.1 + citas (Cahill 2006, Mattson 2018, Mizushima 2008).
- [x] **C** — `eTRFPreSleep` con condición `sleepTime - 3h < lastMealDt` (skip si redundante con cierre de ventana).
- [x] **D** — Sobrecarga `scheduleCircadianDay(user, {MetabolicCycle? openCycle})` + helper público `protocolFastingHours`. `notification_provider.dart` escucha `currentMetabolicCycleProvider` y re-programa al abrir/cerrar ciclo.
- [x] **E** — `test/core/services/notification_scheduler_smart_test.dart` con 12 tests (protocolFastingHours, anclaje al ciclo, eTRF, IDs reservados). `IMR_BIBLIOGRAPHY.md` §14 con las 10 referencias.
- [ ] Validación visual en iPhone (Carlos — pendiente próxima sesión cuando corra la app).

## 11. Changelog

### v1.1 — 2026-06-04 (mismo día)

Carlos revisó v1.0 y rechazó el tono: *"Las notificaciones están muy robóticas, recuerda que estamos motivando personas que posiblemente han tenido problemas de salud o sobrepeso, personas que posiblemente crear hábitos se les dificulta — necesitamos notificaciones más humanas más cercanas."*

Cambios:
- §2.6 reescrita: "Tono humano-cercano, no clínico" con 6 reglas operacionales (segunda persona, reconocer esfuerzo, sin culpa, imperativos suaves, jerga al ExplainerSheet, cita discreta).
- 7 copies circadianos rescritos completos. Ejemplos: "☀️ Buenos días — Tu cuerpo se despertó con la energía justa, aprovéchala" (antes "Tu cortisol está al máximo. Pico cognitivo activo"); "🌙 Una hora para soltar el día" (antes "🔒 1 hora para el bloqueo intestinal").
- 4 hitos de ayuno reescritos. Ejemplos: "⚡ 12 horas — Tu cuerpo ya cambió de marcha y tú llegaste hasta acá" (antes "Insulina en mínimos. Gluconeogénesis activa"); "✨ 16 horas — Limpieza profunda" (antes "🧬 Autofagia inicial").
- eTRF pre-sueño reescrito: "🌙 3 horas antes de dormir — Si cierras la ventana ahora, tu descanso te lo va a agradecer" (antes "Cerrá tu ventana ahora para mejorar glucemia y sueño").
- Memoria nueva persistida: `notification-tone-human-not-clinical`. Aplica a TODAS las SPECs futuras de coaching (no solo notificaciones).

Sin cambios en arquitectura (anclaje al ciclo, hito 16h, eTRF pre-sueño) — solo voz.

### v1.0 — 2026-06-04

Documento inicial. Primer pase de notificaciones inteligentes con cita en lockscreen. MVP1 sin deep-link (postpuesto a SPEC-169.next). Anclaje al ciclo metabólico para `lastMealWarning` cuando hay ciclo abierto.
