# SPEC-206 — Offline-first (registrar sin conexión, sincronizar al reconectar)

**Estado:** IN-PROGRESS (2026-06-11) — inc0 persistencia explícita + inc1 piloto Hidratación implementados. Pendiente: validación en device → replicar patrón al resto de pilares.
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

## 4. Rollout pendiente (tras validar piloto)
Replicar el patrón a: Ayuno (`fasting_notifier`/`transitionTo`), Ejercicio, Sueño, Nutrición, Racha (`streak_notifier`), Ciclo metabólico. Cada uno: write no-bloqueante + listener como fuente de verdad + efectos locales inmediatos.

## 5. Notas
- Auth: Firebase Auth persiste la sesión en disco → offline el usuario sigue logueado.
- App Check (release/AppAttest): las lecturas de caché y la cola de escritura no dependen de él; el token se adjunta al sincronizar.
- No se introdujo `connectivity_plus`: no hace falta detectar red manualmente; el SDK maneja la transición.
