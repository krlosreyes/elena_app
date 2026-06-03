# SPEC-132.next — HealthKit observers + background delivery (iOS)

**Estado:** BLOCKED — esperando habilitación de capability "HealthKit Background Delivery" en Apple Developer Portal (ver §6 Rollout)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Extensión nativa de SPEC-132 (Bloque F)
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 1 — Cierre (la pesada)
**Estimación:** 3-4 sesiones (Swift nativo + Dart + Info.plist + entitlements)
**Marco normativo:** `CONSTITUTION.md`. Extiende SPEC-132 sin romper su API.

---

## 1. Contexto

SPEC-132 (cerrada hace meses) implementó la capa de sync PULL contra HealthKit/Health Connect:
- `HealthSyncService` (plugin `health` v13.3.1) lee weight + sleep + steps.
- `HealthAutoSyncController` debouncing 15min, sync ventana 7 días.
- `HealthImportService` con reglas "Manual wins over auto".

**Gap actual confirmado en validación visual 2026-06-02:** Carlos se pesa con báscula Mi → Zepp Life escribe a Apple Health → Elena no se entera hasta que Carlos abre la app + pasaron 15 min desde el último sync.

**SPEC-132.next agrega PUSH:** HKObserverQuery + enableBackgroundDelivery → iOS despierta la app cuando HealthKit recibe data nueva → Elena dispara sync → al abrir Elena el peso ya está actualizado.

## 2. Decisión arquitectónica

### 2.1 — `enableBackgroundDelivery`, no `BGTaskScheduler`

`BGTaskScheduler` (iOS 13+) es para tareas programadas tipo "ejecutar cada 1h cuando el sistema lo permita". Requiere scheduling explícito + `BGTaskSchedulerPermittedIdentifiers`. **Esto NO es lo que queremos.**

`HKHealthStore.enableBackgroundDelivery(for:frequency:)` es el camino canónico para HealthKit: iOS notifica a la app cuando hay data nueva sin scheduling explícito. El sistema decide la latencia según batería / uso. Frecuencia `.immediate` es el ideal para peso (event-driven, no se generan miles de samples).

### 2.2 — `HKObserverQuery` por tipo

Una observer query por cada `HKObjectType` que queremos vigilar:
- `HKQuantityType.bodyMass` (peso)
- `HKQuantityType.stepCount` (pasos)
- `HKCategoryType.sleepAnalysis` (sueño)

Cada observer dispara su `updateHandler` cuando HealthKit recibe data del tipo correspondiente. El handler:
1. Notifica al MethodChannel Dart con un mensaje liviano `{ type: "weight" }`.
2. Llama el `completionHandler` del observer (obligatorio — sin esto iOS deja de despachar eventos).

**No leemos data en el handler.** El sync completo (con dedup, idempotencia, "manual wins over auto") sigue siendo responsabilidad del `HealthAutoSyncController` en Dart. El handler nativo solo es un trigger.

### 2.3 — Anchor persistido vs sync de ventana

Considerado: `HKAnchoredObjectQuery` con anchor en `UserDefaults` para leer solo lo nuevo desde el último sync. **Rechazado para esta SPEC** porque:
- El `HealthAutoSyncController` actual ya hace dedup en Dart via `_plugin.removeDuplicates(points)` + `HealthImportService._dateKey` + "manual wins over auto".
- Agregar anchor en Swift duplica responsabilidades y complica testing.
- El sync de ventana 7 días + dedup en Dart cubre el caso real (Carlos no se pesa 10 veces al día).

Si en producción aparece un problema de performance (sync repetido leyendo muchos samples), se introduce anchored en una SPEC-132.next.1.

### 2.4 — Persistencia de `lastRunAt`

Hoy el `HealthAutoSyncController.lastRunAt` vive en memoria. Si iOS despierta la app en background → el `HealthAutoSyncController` se reconstruye desde cero → `lastRunAt = null` → no debouncing real.

Fix: persistir `lastRunAt` en `SharedPreferences` con key `health.lastRunAt`. Hidratar en el constructor del controller.

### 2.5 — Comunicación nativa → Dart

`MethodChannel` con nombre `com.metamorfosis.elena/healthkit_observer`. Mensajes:
- Nativo → Dart: `invokeMethod("healthDataChanged", { "type": "weight" })`.
- Dart → Nativo: `invokeMethod("startObserving")` para arrancar los observers (llamado desde Dart después de tener permisos).

## 3. Cambios técnicos

### 3.1 — `ios/Runner/Runner.entitlements`

Agregar:
```xml
<key>com.apple.developer.healthkit.background-delivery</key>
<true/>
```

Requiere que el provisioning profile incluya esta capability. Carlos debe habilitarla en App Store Connect / Apple Developer Portal → Identifiers → ElenaApp → HealthKit → "Background Delivery" tick. Detalles en §6 (Rollout).

### 3.2 — `ios/Runner/Info.plist`

Sin cambios. Los `UIBackgroundModes` actuales (`fetch`, `remote-notification`) son suficientes — HealthKit background delivery NO requiere un mode adicional. El sistema despierta la app vía el delivery mechanism interno de HealthKit.

### 3.3 — `ios/Runner/HealthKitObserver.swift` (nuevo)

Clase Swift que encapsula:
- `HKHealthStore` instance singleton.
- Setup de los 3 observers (peso, sueño, pasos).
- `enableBackgroundDelivery(for:frequency:)` para cada uno (`.immediate` para peso, `.hourly` para sueño y pasos).
- Re-publica eventos al MethodChannel.
- Idempotencia: `startObserving()` es no-op si ya hay observers activos.

### 3.4 — `ios/Runner/AppDelegate.swift`

Agregar:
- Instancia de `HealthKitObserver`.
- Setup del MethodChannel `com.metamorfosis.elena/healthkit_observer` con handler que rutea `"startObserving"` al observer.
- En `didFinishLaunchingWithOptions`: si la app fue despertada por HealthKit (`launchOptions` con key `healthkit` ó nuestro propio mecanismo), arrancar el observer inmediatamente.

### 3.5 — `lib/src/features/health_sync/application/health_observer_service.dart` (nuevo)

Cliente Dart del MethodChannel. Expone:
- `Future<void> start()` que llama `startObserving` en nativo.
- `Stream<HealthObserverEvent>` que emite cuando llega `healthDataChanged`.

### 3.6 — `lib/src/features/health_sync/application/health_observer_provider.dart` (nuevo)

Provider side-effect que escucha el stream del observer service y dispara `healthAutoSyncControllerProvider.runNow(userId)` cuando llega evento. Debouncing local de 30 segundos para no martillar si llegan múltiples eventos seguidos (peso + pasos + sueño del mismo workout, por ejemplo).

### 3.7 — `health_auto_sync_controller.dart` (modificar)

- En el constructor, hidratar `lastRunAt` desde SharedPreferences.
- En `_runNow`, después de setear `lastRunAt = DateTime.now()`, persistir.
- `_kMinSyncInterval` se mantiene en 15 min para foreground; el observer trigger ignora el debounce (usa `runNow`, no `runIfDue`).

### 3.8 — Wire en root widget

En `lib/src/main.dart` o equivalente, `ref.watch(healthObserverSideEffectProvider)` después del bootstrap de auth para que el observer arranque cuando hay sesión.

## 4. Criterios de aceptación

1. Carlos se pesa con báscula → Zepp Life escribe a Apple Health → iOS dispara observer → Elena ejecuta sync en background → al abrir Elena, el peso ya está actualizado (sin esperar 15 min de debouncing).
2. La app despertada por HealthKit en background completa el sync sin crashes ni leaks.
3. Si los permisos están denegados, el observer no arranca y no spamea logs.
4. Múltiples eventos del observer en <30s solo disparan UN sync (debounce local).
5. `lastRunAt` se persiste en SharedPreferences — restart de la app respeta el debounce de 15 min.
6. `HealthAutoSyncController.runIfDue()` (foreground) sigue funcionando como antes — no se rompe el path existente.

### 4.1 — Sobre tests

- Tests de código Swift: fuera de scope. iOS no se testea en este codebase Flutter.
- Tests Dart del `HealthObserverService` con `MethodChannel.setMockMethodCallHandler`: sí, cubren el path de mensajes nativo → Dart.
- Tests del side-effect provider con `ProviderContainer`: sí, cubren que el evento dispara `runNow`.
- Validación end-to-end del observer real: 100% visual en device (instalar release build, pesarse, esperar, abrir app).

## 5. Out of scope (explícito)

- **`HKAnchoredObjectQuery` con anchor en UserDefaults:** rechazado en §2.3.
- **Background sync en Android (Health Connect):** equivalente en Android usa `WorkManager` + `HealthConnectClient.getChanges` — diferente código, diferente SPEC. Si Carlos saca versión Android, abrir SPEC-132.next.android.
- **HealthKit writes:** la app sigue read-only respecto a HealthKit (decisión SPEC-132).
- **Más tipos de datos:** se agregan en futuras SPECs (no hidratación, no ejercicio detallado, no glucosa).

## 6. Rollout

**Pre-requisito de Carlos:**
1. Apple Developer Portal → Identifiers → ElenaApp → Capabilities → marcar HealthKit "Background Delivery".
2. Regenerar provisioning profile y descargar.
3. Actualizar en Xcode (Signing & Capabilities → HealthKit → tick "Background Delivery").

Sin esto, el build compila pero el observer arranca con error de permisos al llamar `enableBackgroundDelivery`. **Bloqueante para validación visual.**

**Validación visual:**
1. Build release + install en iPhone.
2. Otorgar permisos HealthKit a Elena.
3. Pesarse con báscula Mi (que escribe a Apple Health vía Zepp).
4. Esperar 1-5 min (la latencia real depende del sistema).
5. Abrir Elena → el peso aparece sin haber refrescado manualmente.

**Sin breaking changes** en el path foreground existente. Si el observer falla por cualquier razón (entitlement no habilitado, plugin error, etc.), el path de `HealthAutoSyncController.runIfDue()` sigue funcionando como antes.

## 7. Changelog

### v1.0 — 2026-06-02

SPEC redactada. Plan en 5 bloques (entitlements, Swift, MethodChannel Dart, side-effect provider, wire). Implementación arranca después de aprobación.

### v1.0.1 — 2026-06-02 (mismo día, tarde)

Implementación arrancada y revertida. Carlos detectó que no tiene aún habilitada la capability "Background Delivery" en Apple Developer Portal y revirtió los cambios para evitar build roto. Estado movido a BLOCKED. Cuando Carlos habilite la capability + regenere provisioning profile (§6 Rollout), retomamos la implementación en el mismo orden de bloques.

Archivos huérfanos (`HealthKitObserver.swift` y `health_observer_service.dart`) eliminados del disco para no dejar código inerte. El plan documentado en §3 sigue válido — se reconstruyen tal cual cuando se reactive.
