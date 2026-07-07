# SPEC-206 — Offline-first (registrar sin conexión, sincronizar al reconectar)

**Estado:** IMPLEMENTED (2026-06-11) — inc0 persistencia + inc1 Hidratación + inc2 MetabolicCycleService offline-first + inc3 los 5 pilares no bloqueantes. commits 893076d b9bfc91 8cc7ff2.
**Versión:** 0.1
**Líder:** Carlos · **Implementación:** Claude
**Depende de:** cloud_firestore (persistencia offline nativa).

---

## 1. Problema

La app "solo funciona con internet". Para una app de salud, el registro debe poder hacerse sin conexión y sincronizar al reconectar.

## 2. Diagnóstico (causa raíz)

No es la base de datos: Firestore en móvil ya trae **persistencia offline ON por defecto** (lee de caché, encola escrituras, sincroniza al reconectar). El problema es **cómo escribimos**: todas las escrituras hacen `await` del write de Firestore, y está documentado que **offline ese Future no resuelve hasta reconectar** (flutter#20871, #25415, docs Firestore "Access data offline"). El dato sí se guarda en caché local al instante, pero el `await` queda colgado → `isSaving` nunca se apaga → el pilar parece trabado.

## 3. Solución

### inc0 — Persistencia explícita (`main.dart`)
`FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, cacheSizeBytes: CACHE_SIZE_UNLIMITED)` antes de cualquier uso de Firestore (móvil; web omitido por single-tab). Caché ilimitada: una app de salud no debe desalojar historial.

### inc1+ — Escritura optimista, no bloqueante (patrón por pilar)
- NO `await` el write para el flujo de UI.
- El listener `.snapshots()`/`watchSince` ya refleja la caché local al instante (incluso offline, con `hasPendingWrites`) → es la fuente de verdad del número en pantalla.
- Efectos **locales** (notificaciones flutter_local_notifications) corren de inmediato.
- Efectos **online** (analytics, coaching) van en `.then()` (ack del servidor).
- `.catchError()` captura solo errores REALES (permisos/validación), no el offline (que queda pendiente sin emitir) → ahí avisamos a la UI; Firestore revierte la mutación fallida y el listener corrige.

Piloto implementado en **Hidratación** (`hydration_notifier.addWater`). Validar en device (avión → registrar → ver al instante → reconectar → confirmar sync en Firestore).

### inc1.fix — Login no se cuelga (`firebase_auth_repository._buildAccount`)
Bug hallado en device: tras offline→reconexión→logout→login, **no se podía entrar a la app** (quedaba en /splash). Causa: `authStateChanges` hace `asyncMap` sobre `_buildAccount`, que hacía `await .get()` del doc de usuario; el try/catch atrapaba errores pero **no un cuelgue** → el stream nunca emitía → `authState` en loading eterno → router atrapado en /splash. Fix: `timeout(6s)` sobre la lectura + fallback a `GetOptions(source: cache)` (un usuario existente tiene su doc en caché y se clasifica bien sin servidor).

### inc2 — Transición de ciclo offline-first (`metabolic_cycle_service`) ★ FIX CRÍTICO
Bug en device: el agua mezclaba dos días metabólicos. Causa raíz: la transición de ciclo (al iniciar ayuno) hacía `await _repository.save(closed)` y luego `await _repository.save(opened)` **secuenciales**. Offline el `await` del cierre se colgaba → la **apertura del ciclo nuevo nunca corría** → no había ciclo abierto → los 4 pilares caían al fallback de reloj (`startOfDay(now)` = medianoche) y mezclaban el día que cerró con el que abrió. Fix: helper `_persistCycle` no-bloqueante (`unawaited` + `catchError`) reemplaza los 5 `await save`. Ahora cierre y apertura escriben en caché al instante → `watchOpenCycle` emite el ciclo nuevo → los pilares se re-anclan en tiempo real, ONLINE U OFFLINE.

### Estado de los pilares (auditoría)
Los 4 pilares de datos (Hidratación, Sueño, Ejercicio, Nutrición) YA escuchan `currentMetabolicCycleProvider` y se re-suscriben con `_subscribeFor(newSince)` al cambiar el ciclo → real-time cycle-aware. No requieren cambio: el bug era exclusivamente que el ciclo no abría offline (inc2). El fallback `startOfDay(now)` queda SOLO para el caso legítimo "nunca hubo ciclo" (primer uso), donde no hay día previo con qué mezclar.

### inc3 — Escrituras de todos los pilares no bloqueantes (2026-06-11)
Aplicado el patrón a las escrituras de cada notifier (antes todas `await` → colgaban offline e isSaving quedaba trabado):
- **Ayuno** (`fasting_notifier`): `startFastingManual`, `correctFastingStartTime`, `confirmManualFastingEnd`, `confirmFeedingEnd` → estado optimista + write `unawaited` + efectos locales (hitos/notifs) inmediatos + analytics/coaching en `.then`/inmediato; rollback solo en error REAL (catchError).
- **Ejercicio** (`exercise_notifier.logExercise`): optimista, listener `watchSince` como fuente de verdad.
- **Sueño** (`sleep_notifier`): `confirmManualWakeUp`, `saveManualSleep`, `deleteLastLog` → setean `state.lastLog` optimista + writes `unawaited`.
- **Nutrición** (`nutrition_notifier`): `addMeal`, `removeLastMeal` → optimista, listener como verdad.
- **Racha** (`streak_notifier`): `_persistToday`, `_persistAdherence` → `unawaited` con catch logout-aware (SPEC-87) preservado.

Regla aplicada uniformemente: efectos LOCALES (flutter_local_notifications) corren ya; efectos ONLINE (analytics/coaching) en el ack o se auto-encolan; `.catchError` capta solo errores reales (el offline queda pendiente sin emitir).

## 5b. Pendiente para mañana (handoff)
- Tests: (a) `metabolic_cycle_service` — al cerrar+abrir, ambos ciclos se persisten aunque el `save` no resuelva (fake repo cuyo `save` devuelve un Future que nunca completa → verificar que igual se llamó open y que el método retorna `closed+opened`); (b) hidratación offline ya cubierta por validación device.
- Correr suite `test/features/metabolic_cycle/` + `test/features/dashboard/` y `flutter analyze`.
- Commit + push.

## 5. Notas
- Auth: Firebase Auth persiste la sesión en disco → offline el usuario sigue logueado.
- App Check (release/AppAttest): las lecturas de caché y la cola de escritura no dependen de él; el token se adjunta al sincronizar.
- No se introdujo `connectivity_plus`: no hace falta detectar red manualmente; el SDK maneja la transición.
