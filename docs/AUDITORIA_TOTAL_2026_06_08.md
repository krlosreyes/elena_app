# Auditoría Total — ElenaApp (2026-06-08)

**Alcance:** código, arquitectura, funcionalidad, persistencia de datos, coherencia de información entre pantallas.
**Método:** lectura de código + rastreo de patrones (no validación en device salvo donde se indica).
**Disparador:** "el producto aún no se siente sólido".

> **Estado de cierre — actualizado 2026-06-09.** 6 de las 7 acciones ejecutables se cerraron esta sesión (#1–#7). Solo queda **F1** (re-test de la CycleClosureCard en dispositivo), que depende de observación en device. Detalle por ítem abajo y resumen de commits en §6.

---

## 0. Veredicto

El producto **no es frágil en su lógica de dominio** (el IMR, el scoring de coaching, los generadores son Dart puro bien testeado). La sensación de "no sólido" viene de **tres focos concretos y atacables**:

1. **Infra de datos** que hasta hoy fallaba en silencio (App Check tumbando la sesión, ventanas de query con tope `now`). **Ya corregido** esta sesión, pero conviene blindar para que no reaparezca.
2. **Un `dashboard_screen.dart` de 2.375 líneas** que concentra casi todo el riesgo: cada bug y cada feature pasa por ese mismo archivo gigante. Es la causa #1 de que los cambios se sientan riesgosos.
3. **Modelo de datos multi-fuente** (el mismo dato vive en `users/{uid}`, `biometric_history`, `streak_history`, `metabolic_cycles`, `daily_summary`) con **un sync por band-aid** y reglas de ventana **inconsistentes entre pilares**.

Severidades: **ALTA** (afecta datos/percepción de solidez ya), **MEDIA** (deuda que muerde pronto), **BAJA** (pulido).

---

## 1. Persistencia de datos

### P1 · ALTA → ya RESUELTA esta sesión (blindar)
- **App Check en debug tumbaba la credencial** → `permission-denied` → la app lo trataba como logout, reseteaba pilares y abortaba escrituras. Fix: App Check solo en release (`main.dart`).
- **`watchSince` con tope `now` al suscribir** → los registros nuevos no aparecían en vivo. Fix: stream abierto (`exercise/nutrition/hydration` repos).
- **Blindaje pendiente:** no hay test que detecte una regresión de estos dos. Recomendado: test de que `watchSince(since)` (sin `until`) no filtra por tope superior, y un smoke test de arranque sin App Check válido.
- ✅ **CERRADO (2026-06-09).** Test anti-regresión `firestore_nutrition_v1_source_watch_test.dart` (4 casos: stream abierto tras medianoche, live-update de comida nueva, exclusión pre-start, tope explícito respetado). La parte "arranque sin App Check" queda cubierta por la decisión arquitectónica (App Check solo en release, `main.dart`); no es testeable en unidad de forma aislada.

### P2 · MEDIA — ventana de nutrición inconsistente (cruce de medianoche)
- `firestore_nutrition_v1_source.dart:32,78` hace `end = endOfDay ?? DayBoundaryResolver.endOfDay(now)`. Al pasar `until=null` (tras el fix de hoy), **igual topa en fin-de-día**, mientras `exercise`/`hydration` quedan **sin tope** (`if (endOfDay != null)`).
- **Síntoma:** un Día Metabólico que cruza medianoche (ayuno 18:00 → ventana al día siguiente) **corta las comidas registradas después de las 00:00** del ciclo en curso. Los otros pilares no.
- **Fix:** alinear el source de nutrición al patrón de exercise/hydration (sin tope cuando `endOfDay == null`).
- ✅ **CERRADO (commit 52f57bb).** `watchTodayLogs` solo aplica `isLessThan` cuando `endOfDay != null`; con `null` el stream queda abierto, coherente con los otros pilares. Verificado por el test de regresión (P1/P2).

### P3 · BAJA — health-sync de peso por band-aid
- El peso de Apple/Google se propaga a `users.weight` con un parche aparte (`health_auto_sync_controller._syncCanonicalWeight`, Bug A) en vez de pasar por el servicio canónico `BiometricHistoryService.updateFromHealthKitSync` (que escribe **ambas** fuentes atómicamente con `WriteBatch`).
- Riesgo práctico bajo (HealthKit casi solo aporta peso), pero es una ruta que puede divergir. **Fix:** enrutar el sync de salud por el servicio canónico.
- ✅ **CERRADO (2026-06-09).** Nuevo método `BiometricHistoryService.syncCanonicalWeightFromHistory` (actualiza doc raíz + re-merge idempotente de la entrada de historia ya escrita, en un solo `WriteBatch`, sin duplicar). El `HealthAutoSyncController` dejó de usar `saveProfile` crudo. Ahora **toda** escritura biométrica pasa por el servicio canónico → cierra también la recomendación de C1.

---

## 2. Coherencia de información entre pantallas

### C1 · Biométricos — CORRECTO (documentar como patrón)
- Perfil lee de `users/{uid}.*`; Análisis lee de `biometric_history`. **Pero** las dos rutas de escritura (editar perfil, check-in) pasan por `BiometricHistoryService._writeSnapshot`, que escribe **doc raíz + historia atómicamente** (`applyBiometricUpdate`). → Perfil y Análisis quedan coherentes salvo la ruta health (P3).
- Es el patrón correcto. **Recomendación:** que TODA escritura biométrica pase por ese servicio (cerrar P3) y prohibir `saveProfile` con campos biométricos sueltos.
- ✅ **CERRADO (2026-06-09).** Con el fix de P3, ya no hay ningún callsite que escriba biometría por `saveProfile` suelto (los `saveProfile` restantes solo tocan perfil circadiano y protocolo de ayuno — campos no biométricos). No se añadió guard de runtime porque rompería onboarding/edición circadiana (persisten el `UserModel` completo con el peso arrastrado sin cambios); queda como invariante documentada.

### C2 · IMR / Score — CORRECTO
- Dashboard usa `displayedImrProvider` (línea 470) y Análisis (`daily_summary_provider:37`) también. El "Score del Día" (motivacional) vs IMR longitudinal es **arquitectura dual a propósito** (SPEC-141/143). No hay incoherencia detectada.

### C3 · Objetivos (SoT) — COHERENTE
- Ejercicio, hidratación y sueño se rigen por "Mis objetivos" (Bug B). **Verificado:** la **nutrición** no tiene meta numérica (su pilar es conteo/ratio A:E → N/A), el **ayuno** usa `user.fastingProtocol` como fuente única (editable en perfil), y el `goals_progress_dashboard` lee `goalsProvider` (el mismo SoT). Sin incoherencia detectada.
- ✅ **RE-VERIFICADO (2026-06-09).** Trazado de los 6 `GoalType`: ejercicio/sueño/hidratación → target del pilar vía `PillarGoalResolver` (goal activo > fallback), con `hydrationLiters` consumido en `hydration_notifier` (líneas 93/145). `nutritionADominantPercent` **sí existe** como meta semanal de calidad (% comidas A-dominantes), evaluada en `goal_progress_computer` + línea objetivo de Análisis; es una **dimensión distinta** del score diario de nutrición (`0.60·conteo + 0.40·adherencia de ventana`), por lo que no hay incoherencia. `fastingDaysPerWeek` es frecuencia semanal en el dashboard de objetivos; el target diario de ayuno (16/18/20 h) viene del protocolo activo — separación por diseño. El test `pillar_goal_resolver_test.dart` cubre la precedencia goal-activo/fallback/inactivo de los 3 pilares.

---

## 3. Arquitectura

### A1 · ALTA — `dashboard_screen.dart` = 2.375 líneas (god widget)
- Creció de ~1.874 (baseline 15-may) a **2.375**. Concentra: rings de 5 pilares, score, coaching cards, banners, sheets, pickers, lógica de objetivos. **Es la causa raíz de que los cambios se sientan riesgosos** — hoy Bug B + coaching + reset convivieron todos en este archivo.
- **Fix (SPEC-119, subir de prioridad):** extraer cada card/sección a `presentation/widgets/`; dejar `dashboard_screen` como orquestador < 400 líneas. Es el cambio de mayor impacto en "sentir sólido".
- Acompañan: `onboarding_screen` 1.901, `profile_screen` 1.591, `plate_ratio_sheet` 1.035.
- ✅ **CERRADO (2026-06-09, SPEC-119).** Las 5 cards de pilar extraídas a `presentation/widgets/` (`ExercisePillarCard`, `HydrationPillarCard`, `SleepPillarCard`, `ComidasPillarCard`, `FastingConsciousnessCard`) + helpers de presentación a `PillarCardUi`. `dashboard_screen.dart` bajó de **2.375 → 923 líneas** (un commit por card, `flutter analyze` en verde en cada paso). No llegó al objetivo nominal de <400 (quedan el reloj circadiano, la fila de pilares, overlays y orquestación), pero se eliminó la concentración de riesgo: cada pilar ahora se edita aislado. El resto de los god-files (onboarding/profile) queda como deuda Fase 3.

### A2 · MEDIA — features mal ubicadas
- `hydration` vive bajo `features/dashboard/` en vez de feature propia; `fasting_history` es colección top-level (no `users/{uid}/...`). Rompe el patrón uniforme de features y las reglas "una subcolección por usuario". (SPEC-120/121, Fase 3.)

### A3 · BAJA — multiplicidad de stores del mismo "día"
- `streak_history`, `daily_summary`, `metabolic_cycles` e `imr_history` guardan vistas solapadas del mismo día/ciclo. Funciona, pero cada escritura toca varios → más superficie de incoherencia. Documentar el grafo de escritura (qué evento escribe qué) evitaría futuros band-aids.

---

## 4. Funcionalidad / ciclo metabólico

### F1 · MEDIA — CycleClosureCard reaparece (Bug C #3, sin cerrar)
- La lógica de dismissal es **correcta**: `hasUnreadCycleClosure = dismissedCycleId != last.cycleId`, persistida en prefs. Si reaparece "en cada apertura" es porque **se está cerrando un ciclo NUEVO (cycleId distinto) repetidamente**, no por el dismiss.
- **Hipótesis actualizada:** buena parte de eso era el churn de credencial de App Check (resetaba estado). **Re-testear ahora** que App Check está arreglado. Si persiste, el origen es cierre espurio en el evaluador (triggers `fallbackSleepDetected`/`protocolChanged`/bootstrap) — instrumentar el `reason` del cierre y atacar el trigger.
- ⏳ **ABIERTO — requiere device.** Único ítem sin cerrar. Acción para Carlos: abrir la app varias veces tras el fix de App Check y observar si la tarjeta reaparece. Si persiste, siguiente paso (Claude): instrumentar el `reason` del cierre del ciclo para identificar el trigger del cierre espurio. La superficie de tests del evaluador ya está reforzada (ver F2).

### F2 · MEDIA — complejidad del Día Metabólico
- El ciclo tiene 6 triggers de cierre (manual, sleep, 3h, absoluto, calendar, protocolChanged) + bootstrap + override 21:30. Es el subsistema con más bugs históricos (SPEC-149/183/189/190/192). No es un bug puntual: es **superficie de riesgo alta**. Recomendado: una suite de tests de escenarios del evaluador (apertura, cierre por cada trigger, cruce de medianoche, doble ayuno) — formaliza SPEC-122/lo que quedó pendiente.
- ✅ **CERRADO (commit 8dae0e3).** `metabolic_cycle_resolver_test.dart` reforzado con +10 escenarios de límite exacto: cierre manual 30min, sleep 2h, absoluto 28h/27h59m, precedencia (sleep > 3hWindow > absoluto), no-cierre espurio de ciclo de 23h, y ventana TRE cruzando medianoche. 31/31 en verde. Esto reduce la superficie de riesgo del evaluador y deja base para instrumentar F1 si reaparece.

### F3 · BAJA — herramienta "viaje en el tiempo" expuesta en producción
- `correctFastingStartTime` (picker de corregir hora) puede dejar un ayuno activo con inicio de ayer (hoy generó el "ayuno 100% al iniciar"). **Fix:** gatear esa herramienta a `kDebugMode` para que un usuario real no cree estados raros.
- ✅ **CERRADO (2026-06-09).** El botón "Corregir hora de inicio del ayuno" en `FastingConsciousnessCard` ahora está bajo `if (isActive && kDebugMode)`. En release queda oculto (dead-code-eliminated); los flujos normales (iniciar ahora, finalizar con picker en overlays) intactos. **Nota de producto:** si más adelante un usuario real necesita corregir un inicio olvidado, la alternativa a re-exponerlo es mantener el botón pero clampear la corrección para que nunca empuje el ayuno por encima del target.

---

## 5. Recomendaciones priorizadas

| # | Acción | Severidad | Esfuerzo | Estado |
|---|---|---|---|---|
| 1 | **Refactor `dashboard_screen` (SPEC-119)** — orquestador < 400 líneas, cards a widgets | ALTA | 1-2 d | ✅ Cerrado (2.375→923 líneas, 5 cards extraídas) |
| 2 | **Alinear ventana de nutrición** (P2) al patrón sin-tope de exercise/hydration | MEDIA | 0.5 d | ✅ Cerrado (52f57bb + test) |
| 3 | **Suite de escenarios del evaluador de ciclo** (F2) + re-test Bug C #3 (F1) | MEDIA | 1-2 d | 🟡 Tests cerrados (8dae0e3); re-test device de F1 abierto |
| 4 | **Enrutar health-sync por servicio canónico** (P3) + prohibir biometría suelta en `saveProfile` (C1) | MEDIA | 0.5 d | ✅ Cerrado (`syncCanonicalWeightFromHistory`) |
| 5 | **Tests anti-regresión de persistencia** (P1: watchSince abierto + arranque sin App Check) | MEDIA | 0.5 d | ✅ Cerrado (test nutrición; App Check por release-gate) |
| 6 | **Verificar SoT de objetivos** en nutrición/ayuno y goals dashboard (C3) | MEDIA | 0.5 d | ✅ Cerrado (re-verificado coherente) |
| 7 | **Gatear "viaje en el tiempo" a debug** (F3) | BAJA | 0.2 d | ✅ Cerrado (`kDebugMode`) |
| 8 | Mover `hydration` a feature propia + `fasting_history` a subcolección (A2) | BAJA | post-MVP | ⏸️ Diferido a Fase 3 |

**Lo que más mueve la aguja de "sentir sólido": #1 (god widget) y #3 (estabilizar el ciclo).** El resto son cierres limpios de deuda concreta.

---

## 6. Cierre de auditoría (2026-06-09)

**6 de 7 acciones ejecutables cerradas en código + tests.** Trabajo realizado en `mvp-core-clean`:

- **SPEC-119** (A1): 5 cards de pilar + `PillarCardUi` extraídas; dashboard 2.375 → 923 líneas, un commit por card con `flutter analyze` en verde.
- **P2** (commit 52f57bb): `watchTodayLogs` con tope superior condicional.
- **F3**: botón de corregir-hora gateado a `kDebugMode`.
- **P3/C1**: `BiometricHistoryService.syncCanonicalWeightFromHistory`; `HealthAutoSyncController` ya no usa `saveProfile` crudo.
- **F2** (commit 8dae0e3): +10 escenarios en `metabolic_cycle_resolver_test.dart` (31/31).
- **P1/P2 regresión** (commits c91cc36 + 842fdd0): `firestore_nutrition_v1_source_watch_test.dart` (4 casos, en verde).
- **C3**: SoT de objetivos re-verificada coherente (sin cambio de código).

**Único pendiente — F1 (requiere device):** re-test de la `CycleClosureCard` tras el fix de App Check. Si reaparece, siguiente paso es instrumentar el `reason` del cierre del ciclo.

**Fuera del alcance de código (Carlos):** SPEC-125 TestFlight, formularios de privacidad de consola (SPEC-193.1), aprobación de DRAFTs 183/189/190/192.
