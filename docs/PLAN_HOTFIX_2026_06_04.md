# Plan de Hotfix — Solidez de datos, ciclo y notificaciones

**Fecha:** 2026-06-04
**Líder:** Carlos
**Implementación:** Claude
**Disparador:** Carlos instaló la app en iPhone (release build) y reportó 4 problemas críticos. Diagnóstico técnico exhaustivo confirmó **7 bugs reales** y 2 deudas estructurales.
**Estimación total:** ~2 días de trabajo si se ejecuta en orden de fases. Cada fase es ejecutable y validable de forma independiente.

---

## 1. Los 4 problemas con causa raíz confirmada

### P1 — Health Sync trae peso pero NO sleep ni exercise

**Causa raíz #1:** `health_sync_service.dart:311` llama `getHealthDataFromTypes` con los 5 tipos de sleep iOS (IN_BED + ASLEEP + DEEP + LIGHT + REM) en **una sola call**. Si UNO solo de los 5 tipos falla autorización, la call entera lanza y todo el sleep cae a cero. Weight es una call separada → se salva.

**Causa raíz #2:** Threshold de pasos `_minStepsForExerciseLog = 2000` (`health_import_service.dart:61`). Si Carlos tiene <2000 pasos en los últimos 7 días, no se importa NINGÚN día de ejercicio.

**Causa raíz #3:** `Runner.entitlements:7-8` declara `healthkit.background-delivery = true` pero la capability **NO está aprobada en Apple Developer Portal** (BLOCKED externo SPEC-132.next). En release firmado iOS aplica entitlements estrictos: declarar lo no autorizado puede causar denegación silenciosa de tipos clínicos.

**Causa raíz #4:** `app.dart:39-46` dispara sync SOLO al primer login del proceso. No hay `WidgetsBindingObserver` con `AppLifecycleState.resumed` → traer la app desde background no re-sincroniza.

### P2 — Cierre día metabólico no completa el flujo

**Estado actual confirmado:**
- ✅ `metabolicCycleEvaluatorProvider` está montado en `dashboard_screen.dart:146`.
- ✅ `dailyResetProvider.triggerDailyReset(flushClosingDay: false)` SÍ se invoca al cierre.

**Causa raíz #1:** `metabolic_cycle_evaluator_provider.dart:104` pasa `lastMealTime: null` hardcoded ("Reservado para Bloque E"). El trigger `fallbackSleepDetected` exige ese valor → **JAMÁS dispara**. En la práctica solo `manualNextFasting` y `protocolChanged` cierran ciclos.

**Causa raíz #2:** `metabolicPulseProvider` (`Stream.periodic` cada 10s) no emite valor inicial. El evaluator espera 10s tras montar para hacer el primer tick. Si el usuario sale antes, NO evalúa.

**Causa raíz #3:** El evaluator está montado SOLO mientras `DashboardScreen` está vivo. Si Carlos navega a Análisis/Perfil, el `Provider<void>` puede desmontarse y los listeners se cancelan.

**Causa raíz #4:** `SleepNotifier` NO escucha `currentMetabolicCycleProvider`. El filtrado vive INLINE en `dashboard_screen.dart:370-386` (`sleepBelongsToCurrentCycle`). El sleep no reacciona en cascada al cierre — el bugfix3 de hoy parchó UI pero no el notifier.

**Causa raíz #5:** `analysis_series_providers.dart` NO observa `currentMetabolicCycleProvider` ni `lastClosedMetabolicCycleProvider`. Las gráficas Apple-Fitness style NO se invalidan al cerrar el ciclo. El `CyclesHistoryCard` sí actualiza (tiene su propio provider), pero el resto del Análisis no.

### P3 — Notificaciones (agua + circadianas + ayuno) NO llegan

**Estado verificado:**
- ✅ `NotificationService.init()` en `main.dart:98`.
- ✅ `notificationSchedulerProvider` montado en `app.dart:22`.
- ✅ Listener del perfil con `fireImmediately: true` en `notification_provider.dart`.
- ✅ Timezone configurado.

**Causa raíz ÚNICA (alta confianza):** **`NotificationService.requestPermissions()` está definido pero NUNCA se invoca en el proyecto.** Grep exhaustivo confirma cero llamadas desde main, app, onboarding, providers o widgets. En `flutter_local_notifications ≥ 13` el flag `requestAlertPermission: true` en `DarwinInitializationSettings` **no dispara el modal por sí solo en iOS reciente**. Resultado: iOS marca la app como "permisos denegados por default" y `zonedSchedule` se ejecuta sin error visible pero el sistema descarta TODAS las entregas.

**Causa secundaria:** `AppDelegate.swift` no setea `UNUserNotificationCenter.delegate`. Sin esto, las notifs que SÍ se schedulearan no se mostrarían en foreground (silenciadas mientras la app está abierta).

### P4 — Persistencia: datos no se guardan o no se reflejan

**Bug A:** `SleepNotifier` solo escucha `currentUserStreamProvider`. `watchLatest(userId)` retorna el ÚLTIMO SleepLog histórico sin filtrar por ventana de ciclo → el sueño de "ayer" persiste tras cerrar el ciclo.

**Bug B:** `exerciseProvider` (`exercise_notifier.dart:13-24`) hace `ref.watch(currentUserStreamProvider)` DENTRO de la factory → cada emisión del stream destruye el notifier entero, pierde state. El patrón correcto vive en Hydration y Nutrition (factory simple + `ref.listen` interno).

**Bug C:** `HydrationNotifier.addWater` tiene `try { repo.add(...) } catch { /* log */ }` con catch vacío. Firestore offline persistence (default true en Flutter) hace que el write resuelva localmente, el stream emite, el usuario ve el +250ml — pero al matar la app antes de sync el log se PIERDE sin error visible. Usuario reporta "la app no guarda mis datos". Mismo patrón replicable en Exercise y Nutrition.

**Bug D (estructural):** Los 3 repos cycle-aware (Hydration, Exercise, Nutrition) tienen cap **`since + 28h`** en `watchSince`. Si el ciclo lleva >28h abierto (usuario "Ninguno", dispositivo apagado, etc.) el query corta logs FUTUROS dentro del propio ciclo → datos invisibles.

**Bug E (estructural):** `fastingProvider` NO escucha el ciclo metabólico. Solo usa `watchLatest` → al cerrar un ciclo el "último ayuno" sigue siendo el del ciclo anterior, contamina el estado.

---

## 2. Plan en 3 fases ordenadas por dependencia

Cada fase tiene SPECs ejecutables independientes. **Validación en iPhone tras cada fase** para confirmar antes de avanzar.

### FASE 1 — Hotfix crítico (~4-6 horas, 3 SPECs)

**Objetivo:** que las notificaciones lleguen, que Sleep+Exercise entren desde HealthKit, que el ciclo evalúe inmediatamente.

#### SPEC-172 — Permisos + foreground notificaciones (1h)
- Llamar `NotificationService.requestPermissions()` en momento educativo (post-onboarding o tras primer login, NO cold start ciego).
- Setear `UNUserNotificationCenter.delegate` en `AppDelegate.swift` para foreground.
- Loggear éxito/fallo de cada request en consola.
- **Criterio:** modal de permisos iOS aparece, Carlos acepta, dentro de 2 minutos llega notif de prueba.

#### SPEC-173 — Health Sync resilient (2h)
- `_fetchMetric` itera 5 tipos de sleep en LOOP, cada uno con try/catch propio + merge final.
- Threshold pasos: bajar a 500 (capturar incluso usuarios sedentarios) o eliminarlo.
- Agregar `AppLogger.info('HealthSync: ${metric.label} → ${samples.length} samples')` por métrica.
- Agregar `WidgetsBindingObserver` en `app.dart` que llame `runIfDue` en `AppLifecycleState.resumed`.
- **Decisión Carlos:** ¿remover `healthkit.background-delivery` del entitlements hasta que Apple lo apruebe? Riesgo bajo, deshace SPEC-132.next BLOCKED pero no toca el sync manual.
- **Criterio:** consola muestra "Sleep: N samples", "Steps: N samples" tras abrir app y los rings de sueño/ejercicio se llenan.

#### SPEC-174 — Evaluator del ciclo robusto + nivel root (1h)
- `_evaluate` one-shot inmediato al montar con `Future.microtask`.
- Mover `ref.watch(metabolicCycleEvaluatorProvider)` de `dashboard_screen.dart` a `app.dart` (nivel root) — evalúa siempre, no solo en Hoy.
- Leer `lastMealTime` real del `nutritionProvider.todayLogs.last.timestamp` en el input — activa `fallbackSleepDetected`.
- **Criterio:** abrir app con ciclo abierto > 24h → ciclo cierra en segundos (no espera 10s ni navegar a Hoy).

### FASE 2 — Cierre ciclo end-to-end (~5-7 horas, 4 SPECs)

**Objetivo:** que al cerrar el día metabólico TODO lo visible se refresque sin gestos manuales.

#### SPEC-175 — SleepNotifier cycle-aware (1.5h)
- Replicar patrón de Exercise/Hydration/Nutrition: `ref.listen(currentMetabolicCycleProvider)` dentro del notifier.
- Mover lógica `sleepBelongsToCurrentCycle` del Dashboard al notifier — el widget pasa a leer un estado limpio.
- Eliminar el bugfix3 inline (queda redundante con notifier correcto).
- **Criterio:** ring de sueño en 0 cuando corresponde, sin lógica especial en el widget.

#### SPEC-176 — FastingProvider cycle-aware (1h)
- `fastingProvider` ahora escucha el ciclo abierto y filtra el último ayuno por `startedAt`.
- Si no hay ciclo abierto, fallback al `watchLatest` actual.
- **Criterio:** "último ayuno" del Dashboard refleja el ciclo en curso, no contaminado con el ciclo anterior.

#### SPEC-177 — Análisis re-invalida al cerrar ciclo (2h)
- Crear `cycleClosureBumpProvider` (`Provider<int>` que incrementa al cerrar) que los `analysis_series_providers` consumen como dependencia.
- Alternativa: `ref.watch(lastClosedMetabolicCycleProvider)` directo en cada series builder.
- **Criterio:** Carlos inicia nuevo ayuno → cierra ciclo → navega a Análisis → ve el día recién cerrado en las gráficas.

#### SPEC-178 — Quitar cap 28h en `watchSince` (1h)
- Reemplazar `until = since + 28h` por `until = now` (o sin cap) en los 3 repos (Hydration, Exercise, Nutrition).
- **Criterio:** ciclo de 36h abierto (protocolo "Ninguno" durante 2 días) muestra todos los logs sin truncar.

### FASE 3 — Solidez de datos / write integrity (~3-4 horas, 3 SPECs)

**Objetivo:** que los writes nunca se pierdan en silencio, que el patrón de providers sea consistente.

#### SPEC-179 — Write integrity con error visible (2h)
- Eliminar `try { } catch (e) { /* log */ }` vacíos en Notifiers (hydration, exercise, nutrition).
- En vez de tragar: re-throw y manejar arriba con SnackBar/estado de error.
- **Decisión Carlos:** ¿desactivar Firestore offline persistence (más estricto, error inmediato si no hay red) o mantener pero notificar al usuario que está offline?
- **Criterio:** desconectar wifi, agregar agua → usuario ve "Sin conexión, intentaré más tarde" o "Error al guardar" — no silencio.

#### SPEC-180 — exerciseProvider patrón consistente (1h)
- Mover `ref.watch(currentUserStreamProvider)` fuera de la factory.
- Usar `ref.listen` interno como Hydration y Nutrition.
- **Criterio:** hot reload o emisión del stream de usuario no destruye el state del notifier.

#### SPEC-181 — Tests E2E del flujo cierre (1h)
- Test integración con FakeFirebaseFirestore que abre ciclo, simula pilares, dispara cierre, valida reset de notifiers + emisión de gráficas + scheduleNotifications llamado.
- **Criterio:** suite verde sin device físico.

---

## 3. Decisiones a tomar antes de empezar

Carlos define antes de arrancar Fase 1:

1. **Threshold pasos para ExerciseLog:** ¿500, 1000, o sin threshold?
2. **Foreground notifs:** ¿mostrar banner cuando app está abierta (Apple no lo hace por default) o silenciar?
3. **Capability HealthKit background-delivery:** ¿remover del entitlements ahora (deshace SPEC-132.next pero limpia el release) o esperar aprobación Apple?
4. **Firestore offline:** ¿persistencia desactivada (errores inmediatos) o activa con UI de error?
5. **Orden de ejecución:** ¿Fase 1 toda en una sesión o un SPEC por vez con validación intermedia?

---

## 4. Criterios de cierre del plan

**Al cerrar Fase 1:**
- 🔔 Notif de hidratación llega en horario programado.
- ❤️ Sleep + Exercise se ven en Dashboard tras abrir HealthKit.
- ⏰ Ciclo cierra automáticamente cuando corresponde, sin necesidad de iniciar ayuno manual.

**Al cerrar Fase 2:**
- 🔄 Cerrar ciclo → CycleClosureCard aparece + los 5 pilares resetean a 0 + gráficas Análisis muestran el día cerrado.
- 🛌 Ring sueño en 0 cuando corresponde (bugfix3 redundante).
- ⏱️ Ayuno mostrado en Dashboard refleja el ciclo en curso.

**Al cerrar Fase 3:**
- 💾 Logs se guardan SIEMPRE o el usuario VE el error.
- ⚙️ Patrón de notifiers consistente en los 5 pilares.
- ✅ Suite de tests E2E verde.

**Criterio global:** Carlos usa la app un día completo (24h+) y los 4 problemas reportados hoy NO reaparecen.

---

## 5. Próximo paso operativo

Carlos responde las 5 decisiones de §3 + aprueba el plan. Si aprueba:

**Arranco SPEC-172 (permisos notifs)** — mayor impacto, menor esfuerzo. Valida en 1h, deja base para el resto.

Si Carlos prefiere ataque en orden distinto (ej. P4 primero porque es el más grave), lo ajustamos.

---

## 6. Bibliografía interna usada

- Memoria `project_metabolic_day.md` — arquitectura SPEC-149/149.1/149.2.
- Memoria `project_spec_132_next.md` — BLOCKED Apple capability.
- Memoria `feedback_notification_tone.md` — tono humano-cercano para copies (SPEC-172 ExplainerSheet de permisos).
- Memoria `strategic-pivot-passive-to-active-coaching` — el plan respeta el pivot, no agrega tracking pasivo nuevo.
- `docs/PLAN_DELIVERY_2026_06_04.md` — Ola 2.5 cerrada hace horas; este hotfix es deuda emergente, no rompe el plan de Olas (entre Ola 2.5 y Ola 3).
