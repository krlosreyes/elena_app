# SPEC-199 — Coach Interactivo y Predictivo

**Estado:** APPROVED-DESIGN (2026-06-10) — diseño aprobado por Carlos. Sin implementar. Dos fases: **Fase A — Coach interactivo por notificación** (objetivo lanzamiento ~10-ago) y **Fase B — Superficies ambientales** (Isla Dinámica / widgets / Live Updates, post-lanzamiento).
**Versión:** 0.1 (draft)
**Tipo:** Coaching — interacción de bucle cerrado + capa predictiva contextual.
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola siguiente al lanzamiento (Fase A entra a v1 si el calendario lo permite; Fase B es fast-follow).
**Estimación:** Fase A ~3–4 días. Fase B ~spike + 1–2 semanas (código nativo iOS/Android).
**Depende de:** SPEC-169 (patrón de notificaciones), SPEC-150 (agenda de hidratación, IDs 400–419), SPEC-194 (motor de decisión de coaching), SPEC-149 (Día Metabólico / ciclo), SPEC-193 (telemetría).
**Bloquea:** la evolución de "coaching pasivo" a "coaching activo" del pivot estratégico (memoria: passive logging → active coaching).

---

## 1. Contexto

El coaching actual es **informativo, no interactivo**: tarjetas de texto que se auto-ocultan y notificaciones a hora fija cuyo único efecto al tocarlas es escribir un log de debug. El usuario es avisado, pero no puede **actuar** desde el aviso.

La dirección de producto (Carlos, 2026-06-10): evolucionar a un coach **interactivo y predictivo**. Caso canónico — hidratación:

> En vez de "Hora de tomar agua" (texto muerto), la notificación pregunta *"¿Ya tomaste tu vaso?"* con botones **Sí / Aún no**. **Sí** registra el vaso de una vez; **Aún no** te recuerda que lo tomes y te lo deja a un toque.

La buena noticia técnica: `HydrationNotifier.addWater(amount)` ya hace el registro completo (Firestore + analytics + avisa al coach vía `coachingCompletionProvider.onPillarActivity`). **La acción ya existe** — solo falta exponerla desde un prompt de un toque y cerrar el bucle.

---

## 2. Principio de diseño: Bucle Cerrado

Cada momento de coaching deja de ser texto pasivo y se vuelve **una pregunta con respuesta de un toque que ejecuta una acción real y la registra**. Mismo motor de decisión, varias superficies:

- **Notificación** (capa de *interrupción*: empuja a una hora/contexto). → Fase A.
- **Tarjeta in-app** (capa de *presencia*: cuando la app está abierta). → Fase A.
- **Superficies ambientales** (capa de *glance*: Isla Dinámica, widgets, Live Updates). → Fase B.

La unidad común es un **prompt accionable tipado**: `{ pregunta, opciones[], cada opción → acción }`, no un `String`.

---

## 3. Realidad técnica (lo que condiciona el diseño)

### 3.1 — Notificaciones accionables
- iOS: `DarwinNotificationCategory` + `DarwinNotificationAction`; los botones aparecen al **expandir / mantener presionada** la notificación (no son una ventana custom libre — eso exigiría un *Notification Content Extension* nativo, fuera de alcance). Requiere registrar categorías en `init()` y tocar el `AppDelegate`.
- Android: `AndroidNotificationAction` (botones inline).
- **El handler de acción en background de iOS es frágil** (issues documentados del plugin). Por eso **no** apostamos a escribir Firestore en background.

### 3.2 — El patrón de persistencia (innegociable)
La acción **nunca escribe Firestore directo desde el handler/extension**. Escribe a una **cola local** (`PendingActionQueue` en SharedPreferences; en iOS Fase B, App Group container). Al abrir/reanudar la app, se **vacía la cola** llamando al notifier correcto (`addWater`, etc.). "Sí" se siente instantáneo y sincroniza confiable. **Idempotente**: cada acción encolada lleva un `id` único (timestamp + tipo) para no duplicar el vaso si el usuario toca dos veces o si además abre la app.

### 3.3 — Superficies ambientales (Fase B) — todas exigen código nativo
- **Live Activities + Isla Dinámica (iOS 16.1+):** para **actividades continuas con duración** (no avisos sueltos) → encaja con el **ayuno**. Botones vía App Intents (iOS 17+) corren en background. Flutter: paquete `live_activities` + Widget Extension en Swift. Tope ~8h activas (hasta ~12h) → para ayuno de 16h actualizar por hitos, no por segundo, y manejar el caso >tope.
- **Widgets interactivos iOS (WidgetKit 17+):** widget de inicio/pantalla bloqueada con botón respaldado por App Intent → encaja con **hidratación** (+1 vaso de un toque). Flutter: `home_widget`.
- **Android 16 Live Updates / `Notification.ProgressStyle`:** notificación promovida con progreso en lockscreen + chip en status bar → análogo de Live Activities para el **ayuno**.
- **Android widgets (Jetpack Glance / `home_widget`):** widget de inicio interactivo → hidratación. **Nota:** Android no tiene "widgets de pantalla bloqueada" como tal; el equivalente es Live Updates + widget de inicio + notificación en lockscreen.

---

## 4. Lo que NO se hace aquí

- **NO** se escribe Firestore desde un handler/extension en background (siempre vía cola → flush en foreground).
- **NO** se reemplaza `NotificationService` ni la agenda de SPEC-150; se **extiende** con categorías accionables.
- **NO** se construye un Notification Content Extension custom en Fase A (botones nativos estándar bastan).
- **NO** se spamea: tope por día, supresión si ya cumplió la meta, respeto a la ventana de sueño.
- Fase B **NO** entra a v1 de lanzamiento (código nativo pesado; va de fast-follow).

---

## 5. Arquitectura

```
coaching/
 ├── domain/
 │    └── actionable_prompt.dart        # { id, pregunta, List<PromptOption> }, PromptOption { label, ActionType }
 ├── application/
 │    ├── pending_action_queue.dart     # cola en SharedPreferences; enqueue/flush idempotente por id
 │    ├── coaching_action_router.dart   # ActionType → notifier (addWater, closeFasting, ...)
 │    └── predictive_trigger_engine.dart# Fase A.4: decide si/ cuándo emitir un prompt (contexto)
core/services/
 └── notification_service_mobile.dart   # + categorías Darwin/Android, background entrypoint (@pragma vm:entry-point)
dashboard/presentation/widgets/
 └── interactive_coaching_card.dart     # reemplaza el texto fijo por pregunta + botones (slot de NextBestActionCard)
```

`predictive_trigger_engine` y `coaching_action_router` son Dart puro (testeables sin UI).

---

## 6. Requisitos funcionales

### Fase A — Coach interactivo por notificación (lanzamiento)

**RF-199-01 — Infra accionable.** `NotificationService` registra categorías de notificación con acciones (iOS `DarwinNotificationCategory`, Android `AndroidNotificationAction`) y un background entrypoint que enruta la acción a `PendingActionQueue.enqueue(...)`. Generaliza más allá del agua (cerrar ayuno, registrar comida, registrar sueño).

**RF-199-02 — Cola de acciones pendientes.** `PendingActionQueue` persiste acciones en SharedPreferences con `id` único. Al reanudar la app (lifecycle `resumed`) se vacía vía `CoachingActionRouter`, que invoca el notifier correcto (p. ej. `hydrationProvider.notifier.addWater(0.25)`). Idempotente: no re-procesa un `id` ya aplicado.

**RF-199-03 — Hidratación de bucle cerrado.** La notificación de hidratación (IDs 400–419) usa la categoría accionable: *"¿Ya tomaste tu vaso?"* → **[Sí, lo registro]** encola un vaso; **[Aún no]** reprograma un recordatorio en +15 min y, al abrir, muestra CTA directo. Tono cálido, sin culpa (memoria de tono).

**RF-199-04 — Tarjeta interactiva in-app.** En el slot de `NextBestActionCard`, reemplazar el texto fijo del coach por una **tarjeta-pregunta con botones** (mismo `ActionablePrompt`, misma acción). Resuelve además la queja de la `CycleCoachingFeedbackCard` de texto muerto.

**RF-199-05 — Capa predictiva (contexto, no hora fija).** `PredictiveTriggerEngine` decide emitir un prompt de hidratación según: tiempo desde el último vaso registrado, progreso vs meta, fase circadiana; y **suprime** si ya cumplió la meta o está en ventana de sueño. El motor de coaching emite prompts tipados en vez de strings.

### Fase B — Superficies ambientales (post-lanzamiento)

**RF-199-06 — Live Activity del ayuno (iOS) + Live Update (Android).** El ayuno activo se muestra en Isla Dinámica / lockscreen con tiempo + próximo hito y botón "Cerrar ayuno". Spike nativo primero para de-riesgar el bridge.

**RF-199-07 — Widget interactivo de hidratación.** Widget iOS (WidgetKit, home/lockscreen) + Glance (Android) con anillo de progreso y "+1 vaso" de un toque vía App Intent / Glance callback → cola → flush. Reusa el mismo `PendingActionQueue` (App Group container en iOS).

---

## 7. Telemetría (SPEC-193)

- `coaching_prompt_shown` { surface: notification|card|liveactivity|widget, type }
- `coaching_prompt_answered` { type, option, surface }
- `pending_action_flushed` { type, latency_ms } (tiempo entre encolar y aplicar)

---

## 8. Testing

- `PendingActionQueue`: enqueue/flush, idempotencia por `id`, dedupe doble-tap. Puro.
- `CoachingActionRouter`: ActionType → notifier correcto. Puro con fakes.
- `PredictiveTriggerEngine`: emite/suprime según contexto (meta cumplida, sueño, tiempo desde último vaso). Puro.
- Widget test: `InteractiveCoachingCard` renderiza opciones y dispara la acción.
- Manual (device): notificación accionable en iOS (expandir → Sí → vaso registrado al abrir) y Android (inline).

---

## 9. Riesgos

- **iOS background action frágil** → mitigado por el patrón cola+flush (no dependemos del background write).
- **Costo nativo de Fase B** (targets Xcode/Gradle, App Intents, provisioning) → aislado post-lanzamiento, arranca con spike.
- **Tope de duración de Live Activities** (~8–12h) vs ayuno 16h → actualizar por hitos + manejar expiración.
- **Fricción Apple Developer/DUNS pendiente** → Fase B no se bloquea por billing, pero comparte la dependencia de cuenta de desarrollador.

---

## 10. Decisiones abiertas (para Carlos)

- ¿Fase A entra a v1 de lanzamiento o se difiere para no arriesgar el ~10-ago?
- ¿El spike nativo de la Isla Dinámica del ayuno se adelanta como gancho de marketing, o se respeta el orden A → B?
- Cantidad de agua por "vaso" (0.25 L por defecto) y tope de prompts/día.
