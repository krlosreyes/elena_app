# Constitución del Día Metabólico

**Estado:** v1.0 — 2026-06-05
**Mantenedor:** Carlos (PM) + Claude
**Marco normativo:** este documento es la fuente única de verdad sobre el comportamiento del ciclo metabólico. Cualquier PR que toque `lib/src/features/metabolic_cycle/` debe citar la sección aplicable y validar contra el §5 (invariantes).

---

## §1 — Principio fundacional

**El día metabólico es un ciclo definido por EVENTOS CONSCIENTES DEL USUARIO, no por el reloj calendárico.**

El ciclo refleja el ritmo biológico real del usuario (ayuno → ventana de comida → cierre), no la rotación de la Tierra. Un usuario que cena a las 21:00 y rompe ayuno al día siguiente a las 13:00 tiene UN ciclo metabólico que **cruza** la medianoche calendárica. El reloj no parte el ciclo.

Documentos hermanos: `CIRCADIAN_BIBLIOGRAPHY.md` (cronograma circadiano), `IMR_BIBLIOGRAPHY.md` (pesos del score), `specs/SPEC-149-*.md` (implementación), `specs/SPEC-183-*.md` (fix bootstrap).

---

## §2 — Eventos que CREAN ciclo

| Evento | Condición | `startedAt` del ciclo |
|--------|-----------|------------------------|
| **Usuario inicia ayuno** | Tap consciente en UI ("Iniciar ayuno") → `startFastingManual()` con `activationSource = userInitiated` | `DateTime.now()` al momento del tap |

**ESE ES EL ÚNICO EVENTO QUE CREA CICLO.** No hay otros.

### §2.1 — Eventos que NO crean ciclo

Lista expansiva — todos estos son anti-patrones documentados:

- ❌ **Bootstrap de la app**: restaurar `FastingState` desde Firestore al abrir la app NO crea ciclo. Se marca `activationSource = bootstrap` (SPEC-183).
- ❌ **Hot reload / Hot restart**: el reset del state Dart no debe crear ciclo nuevo.
- ❌ **Crossing medianoche**: pasar de 23:59 a 00:00 NO crea ciclo. El ciclo abierto sigue siendo el mismo.
- ❌ **Logout/login**: re-autenticar no crea ciclo. Sólo restaura el state existente.
- ❌ **Cambio de protocolo de ayuno**: cambiar de 16:8 a 18:6 no debe disparar nuevo ciclo si el actual está abierto. El cambio se aplica al próximo ciclo legítimo.
- ❌ **Registrar comida** (`logMeal`): NO crea ciclo. Solo registra dato dentro del ciclo abierto o el fallback `startOfDay`.
- ❌ **Cualquier API automática del backend**: sin acción consciente del usuario, no se crea ciclo.

---

## §3 — Eventos que CIERRAN ciclo

El ciclo se cierra por **uno** de estos triggers (orden de precedencia):

1. **Cierre manual de ventana** — usuario tap "Cerrar ventana de comida" en UI.
2. **Inicio explícito de nuevo ayuno** — `newFastingStartedExplicitly = true` Y el ciclo actual tiene duración ≥ duración mínima del protocolo.
3. **`fallback3hAfterWindow`** — pasaron 3h desde la última comida sin nuevo evento.
4. **`fallbackSleepDetected`** — se detectó sueño tras la última comida.
5. **`fallbackAbsolute`** — el ciclo lleva más de `kAbsoluteCycleLimit` (~28h) abierto.
6. **`fallbackCalendar`** — solo para protocolos con `useCalendarFallback`, si pasaron a día calendárico nuevo.

Cada cierre genera un `CycleFeedback` con magnitudes consolidadas (SPEC-149 §RF-149-08).

### §3.1 — Lo que NO debe pasar al cerrar

- ❌ Cerrar sin generar feedback.
- ❌ Cerrar mientras `isClosed == true` (doble cierre — el resolver bloquea esto, ver `metabolic_cycle_resolver.dart:113`).
- ❌ Cerrar sin escribir a Firestore.
- ❌ Cerrar y NO abrir el siguiente si el usuario lo solicita inmediatamente.

---

## §4 — Quién consume el ciclo

Todos los providers cycle-aware leen `cycle.startedAt` como `since` para `watchSince(...)`. Si no hay ciclo abierto, **el fallback es `DayBoundaryResolver.startOfDay(now)`** (calendárico).

| Provider | Archivo | Comportamiento |
|----------|---------|----------------|
| `nutritionProvider` | `lib/src/features/nutrition/application/nutrition_notifier.dart:155` | watchSince(cycle ?? startOfDay) |
| `hydrationProvider` | `lib/src/features/dashboard/application/hydration_notifier.dart` | Idem |
| `exerciseProvider` | `lib/src/features/exercise/application/exercise_notifier.dart` | Idem |
| `sleepProvider` | `lib/src/features/dashboard/application/sleep_notifier.dart` | Idem |
| `dailyUpfShareProvider` | `lib/src/features/nutrition/application/upf_share_provider.dart` | Idem (SPEC-138) |
| `displayedDailyScoreProvider` | `lib/src/features/streak/application/daily_score_provider.dart` | Idem (SPEC-171) |

**Implicación crítica:** un ciclo con `startedAt` incorrecto rompe TODOS los pilares simultáneamente sin error visible. Ese fue el bug de SPEC-183.

---

## §5 — Invariantes del ciclo (asserts duros)

Cualquier código que abra/cierre ciclo debe respetar:

| Invariante | Defensa |
|-----------|---------|
| Solo se abre con `input.newFastingStartedExplicitly == true` | `MetabolicCycleService.evaluateAndApply:100-102` |
| Solo un ciclo abierto por usuario | `_repository.fetchOpenCycle` retorna 0 o 1 |
| `cycle.startedAt <= now` | Validar antes de escribir |
| `cycle.startedAt ≈ input.newFastingStartedAt` (delta < 5min) | NUEVO — añadir warning si difiere (defensa contra bootstrap mal etiquetado) |
| Ciclo cerrado no se reabre — uno nuevo es uno nuevo | Resolver:113 bloquea doble cierre; abrir es una operación separada |
| `closedAt > startedAt` siempre | Validar en `_determineCloseTime` |

---

## §6 — Auditoría y trazabilidad

Cada apertura/cierre de ciclo emite un log estructurado vía `AppLogger.info`:

```
[cycle.open] cycleId=<id> startedAt=<iso> protocol=<p> source=userInitiated
[cycle.close] cycleId=<id> closedAt=<iso> reason=<reason> duration=<h>
```

Estos logs:
- Se envían a Crashlytics en release (SPEC-80).
- Permiten reconstruir el historial de ciclos del usuario para diagnóstico sin necesitar el doc de Firestore.
- Son la primera fuente de evidencia cuando se reporta un bug del tipo "los pilares no leen".

### §6.1 — Cuándo abrir bug nuevo

Si los pilares no muestran datos del día y los logs crudos SÍ existen en Firestore:

1. Buscar en logs `[cycle.open]` del día — confirma motivo de apertura.
2. Si la apertura no tiene `source=userInitiated`, es bug del evaluator (SPEC-183 retornó).
3. Si `source=userInitiated` pero `startedAt` no coincide con cuándo el usuario tocó el botón, es bug del notifier.
4. Si todo es correcto pero los pilares no leen, es bug del provider cycle-aware (no del ciclo).

---

## §7 — Histórico de cambios al modelo

| Fecha | SPEC | Cambio |
|-------|------|--------|
| 2026-06-01 | SPEC-149 | Modelo inicial del Día Metabólico |
| 2026-06-01 | SPEC-149.1 | Hotfix: X cierra el card, reset pilares al cerrar ciclo |
| 2026-06-04 | SPEC-149.2 | Providers cycle-aware (watchSince) |
| 2026-06-04 | SPEC-174 | Evaluator a nivel root + first tick + lastMealTime real |
| 2026-06-05 | SPEC-183 | Bootstrap NO crea ciclo — enum FastingActivationSource |
| 2026-06-05 | SPEC-184 | Esta constitución + logger semántico |

---

## §8 — Cómo usar este documento

1. **Antes de aceptar PR que toque `metabolic_cycle_*`**: el autor debe linkar a la sección de este doc que respalda el cambio.
2. **Antes de implementar SPEC nuevo que afecte ciclo**: releer §2 y §3.
3. **Al diagnosticar bug "pilares no leen"**: empezar por §4 y §6.1.
4. **Al onboardear a un colaborador nuevo**: este doc + `CIRCADIAN_BIBLIOGRAPHY.md` + `IMR_BIBLIOGRAPHY.md` es el onboarding obligatorio del dominio.

Este documento es **vivo**. Cualquier ajuste al modelo del Día Metabólico → PR a este doc primero, código después.
