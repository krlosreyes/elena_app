# SPEC-149.1 — Hotfix coaching post-cierre del Día Metabólico

**Estado:** IN_PROGRESS
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Hotfix de Ola 1 (extiende SPEC-149)
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 1 — Estabilización (cierre)
**Estimación:** 4-5 horas
**Marco normativo:** `CONSTITUTION.md`. Extiende SPEC-149 sin romper su contrato.

---

## 1. Contexto

Durante validación visual en iPhone (2026-06-02) Carlos detectó tres bugs en el flujo de cierre del Día Metabólico (SPEC-149) y uno relacionado en la sincronización de ejercicio. Los bugs no son de diseño — la SPEC-149 está conceptualmente correcta. Son bugs de integración descubiertos al usar la app en device real.

### 1.1 — Corrección conceptual también registrada

Carlos rectificó mi modelo mental del Día Metabólico: el ciclo **se ancla al inicio del ayuno del usuario, independiente de la hora del reloj**. La regla circadiana "cierre ventana ≤21:00" es **coaching**, no boundary técnico. Esta SPEC-149.1 respeta esa rectificación: el reset de pilares se dispara al cerrar el ciclo, sea la hora que sea. (Memoria: `feedback_metabolic_day_anchor.md`.)

## 2. Bugs cubiertos por esta SPEC

### Bug 1a — La X de la card no la cierra

**Síntoma:** el usuario toca la X del `CycleClosureCard`, la card no desaparece.

**Causa raíz:** `hasUnreadCycleClosureProvider` lee `prefs.getString(...)` directamente. Cuando `dismissLastCycleClosure(prefs, cycleId)` escribe el nuevo valor, no hay invalidation del provider en Riverpod. El provider conserva el valor cacheado y `hasUnread` sigue retornando `true`.

### Bug 1b — Los pilares no se reinician al cerrar el ciclo

**Síntoma:** al terminar la ventana de alimentación e iniciar el siguiente ayuno, los pilares (hidratación, ejercicio, comidas) siguen mostrando los acumulados del ciclo anterior.

**Causa raíz:** `MetabolicCycleService.evaluateAndApply` cierra y abre ciclos en Firestore pero nunca invoca `DailyResetNotifier.triggerDailyReset()`. El reset diario solo se dispara por timer a medianoche calendárica (SPEC-58). Al cerrar el ciclo metabólico a cualquier otra hora, los contadores in-memory de los notifiers no se limpian.

### Bug 1c — El botón "Empezar mi siguiente ayuno" sobra

**Síntoma:** la card aparece DESPUÉS de que el usuario tocó "iniciar ayuno" desde el dashboard (eso es lo que disparó el cierre, vía trigger `manualNextFasting`). El botón redundante invita a iniciar un ayuno que ya está activo.

**Causa raíz:** `dashboard_screen.dart` siempre pasa el callback `onStartNextFasting` sin condicionar a `fastingState.isActive`.

### Bug 2 — Conteo de ejercicio descoherente (21 min Apple Activity vs 66 min Elena)

**Diagnóstico parcial:** `exercise_notifier` se suscribe a `repository.watchToday(userId)` que filtra por día calendárico `[startOfDay, endOfDay)`. El reset cíclico (Bug 1b) limpia el state in-memory, pero el stream re-emite inmediatamente los datos calendáricos.

**Decisión:** **fuera de scope SPEC-149.1.** El fix completo requiere cambiar `watchToday` a `watchSince(start: cycle.startedAt)` en los repositorios de los 3 pilares afectados (ejercicio, hidratación, nutrición). Es invasivo y se trata en SPEC-149.2.

## 3. Cambios técnicos

### 3.1 — Fix Bug 1a: reactividad del dismiss

**Archivo:** `lib/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart`

Crear `CycleClosureDismissalNotifier` (StateNotifier) que mantiene el `dismissedCycleId` como estado reactivo, hidratado desde SharedPreferences en construcción. El método `dismiss(cycleId)` escribe a prefs Y actualiza `state`.

`hasUnreadCycleClosureProvider` pasa de leer `prefs.getString` a `ref.watch(cycleClosureDismissalProvider)`.

La función helper `dismissLastCycleClosure(prefs, cycleId)` queda deprecada — el nuevo path es `ref.read(cycleClosureDismissalProvider.notifier).dismiss(cycleId)`. Por compatibilidad temporal la dejamos delegando al notifier (en caso de que algún test la use), marcada `@Deprecated`.

### 3.2 — Fix Bug 1b: reset al cerrar ciclo

**Archivo:** `lib/src/features/metabolic_cycle/application/metabolic_cycle_evaluator_provider.dart`

Después de `metabolicCycleServiceProvider.evaluateAndApply()`, si el resultado tiene `hasClosure && hasOpening`, disparamos `dailyResetProvider.notifier.triggerDailyReset(flushClosingDay: false)`.

**Por qué `flushClosingDay: false`:** el `daily_summary` (SPEC-138) es por día calendárico. Si lo flusheamos al cierre cíclico a las 21:00, sellamos un snapshot incompleto del día. El daily_summary sigue cerrando a medianoche; solo limpiamos los notifiers in-memory para que el contador del nuevo ciclo arranque visualmente en 0.

**Nota sobre coexistencia:** el `DailyResetService` calendárico se mantiene como red de seguridad. El reset cíclico es complementario, no reemplazo. Cuando ambos disparan en el mismo día (cierre de ciclo + medianoche), el segundo es idempotente (RF-58-03).

### 3.3 — Fix Bug 1c: condicionar CTA al estado del ayuno

**Archivo:** `lib/src/features/dashboard/presentation/dashboard_screen.dart`

Watch `fastingProvider` en el build del dashboard. Pasar `onStartNextFasting` solo si `!fastingState.isActive`. Si el ayuno ya está activo (caso típico cuando la card apareció por trigger `manualNextFasting`), el callback es `null` → la card no renderiza el botón.

## 4. Criterios de aceptación

1. Tap en la X del `CycleClosureCard` la oculta inmediatamente sin requerir hot reload o restart.
2. Al cerrar un ciclo metabólico (sea la hora que sea), los contadores in-memory de hidratación, ejercicio y nutrición se reinician.
3. Cuando la card aparece tras un trigger `manualNextFasting` (ayuno ya activo), el botón "Empezar mi siguiente ayuno" NO se renderiza.
4. Cuando la card aparece tras un fallback (sleep, 3h post-window, absoluto, calendar) y el ayuno NO está activo, el botón sí se renderiza.
5. El `daily_summary` calendárico no se flushea prematuramente por el reset cíclico.
6. Tests cubren: dismiss reactivo, reset disparado en `hasClosure && hasOpening`, condicional del CTA.

## 5. Out of scope (explícito)

- **Bug 2 (conteo de ejercicio descoherente):** requiere cambio de `watchToday` a `watchSince(cycleStart)` en 3 repositorios. Se aborda en SPEC-149.2.
- **Sincronización con Apple Health/HealthKit en tiempo real:** SPEC-132.next.
- **Persistencia de daily_summary por ciclo metabólico (vs día calendárico):** decisión arquitectónica pendiente, no se aborda aquí.

## 6. Rollout

Sin breaking changes. Sin migración de datos. Push directo a `mvp-core-clean` y validación visual en device.

Carlos confirma en device:
1. Cerrar ciclo manual (tocar "iniciar ayuno" estando en ventana).
2. Verificar que la card aparece sin botón CTA.
3. Verificar que hidratación/ejercicio/nutrición visualmente arrancan en 0 (aunque por Bug 2 el ejercicio puede re-emitir con datos legacy hasta SPEC-149.2).
4. Tocar X → card desaparece.

## 7. Changelog

### v1.0 — 2026-06-02

Hotfix de los 3 sub-bugs de la card descubiertos en validación visual. Bug 2 deferido a SPEC-149.2.
