# SPEC-223 — Background processing (evaluación dinámica con app cerrada)

**Estado:** SCAFFOLDING-IMPLEMENTED (2026-06-17) — Fase 2 scaffolding: Info.plist BGTaskSchedulerPermittedIdentifiers, BackgroundTaskHandler.swift, background_notification_refresh.dart. Fase 1 sigue BLOCKED. Fase 3 pendiente.
**Versión:** 0.1
**Líder:** Carlos · **Implementación:** Claude
**Depende de:** SPEC-132.next (HealthKit background delivery), SPEC-169 (notificaciones), Apple Developer Portal (entitlement).
**Prioridad:** Post-launch.
**Estimación:** 13+ SP (3 fases)
**Bloqueante externo:** Background Delivery capability en Apple Developer Portal + provisioning profile regenerado.

---

## 1. Problema

La app solo puede evaluar condiciones y disparar coaching cuando está en **foreground**. Las notificaciones se programan estáticamente al inicio del día y no se adaptan al contexto real durante el día.

**Escenarios que no se resuelven sin background processing:**

1. **Hidratación completada → spam de reminders:** El usuario completa su meta de hidratación a las 14:00 pero sigue recibiendo reminders cada 30 minutos hasta las 21:00 porque nadie recalcula.
2. **Ayuno extendido → sin milestone dinámico:** Si el usuario pasa de 16:8 a ayuno extendido voluntario, los milestones one-shot de 12/16/18/24h ya se agotaron y no hay coaching.
3. **Sueño detectado por HealthKit → sin reacción:** HealthKit puede reportar que el usuario se durmió (via Apple Watch), pero sin background delivery la app no se entera hasta el próximo foreground.
4. **Día metabólico cerrado automáticamente → sin notificación:** El cierre automático del ciclo (SPEC-235) solo corre en foreground.

## 2. Solución — 3 fases

### Fase 1: HealthKit Background Delivery (SPEC-132.next)

**Prerequisito:** Obtener el entitlement de Background Delivery en Apple Developer Portal y regenerar provisioning profile.

**Ya implementado (BLOCKED):**
- `HealthKitObserver.swift` en `ios/Runner/` con `enableBackgroundDelivery` para pasos, sueño, workouts.
- `MethodChannel` entre Dart y Swift para start/stop observers.
- `AppDelegate.swift` instancia el observer.

**Pendiente al desbloquear:**
- Registrar `BGTaskScheduler` en `Info.plist` con identifier `com.metamorfosis.elena.healthkit-update`.
- En el handler de background: leer datos HealthKit acumulados, actualizar caché local (SharedPreferences), encolar acción en `PendingActionQueue` si hay milestone.
- Al volver a foreground: `CoachingActionRouter.flush()` ya procesa la cola.

### Fase 2: BGAppRefreshTask — Recálculo de notificaciones (2-3x/día)

iOS concede ~30 segundos de CPU para `BGAppRefreshTask`. Suficiente para:

1. Leer estado actual desde caché local (SharedPreferences + Firestore offline cache).
2. Evaluar si las notificaciones programadas siguen siendo relevantes:
   - ¿Hidratación ya completada? → Cancelar reminders restantes.
   - ¿Ayuno activo? → Verificar que no hay notificaciones de comida pendientes.
   - ¿Próximo milestone de ayuno? → Programar one-shot si no existe.
3. Reprogramar las que correspondan via `flutter_local_notifications`.

**Registro:**
```swift
// Info.plist
BGTaskSchedulerPermittedIdentifiers: [
  "com.metamorfosis.elena.notification-refresh"
]

// AppDelegate.swift
BGTaskScheduler.shared.register(
  forTaskWithIdentifier: "com.metamorfosis.elena.notification-refresh",
  using: nil
) { task in
  self.handleNotificationRefresh(task as! BGAppRefreshTask)
}
```

**Frecuencia:** `earliestBeginDate` = 4 horas. iOS decide cuándo ejecutar realmente (típicamente 2-3 veces/día en uso normal).

### Fase 3: BGProcessingTask — Daily summary nocturno

Una tarea nocturna (~3am) con más tiempo de CPU (hasta minutos) para:

1. Calcular y persistir el daily summary del día anterior si no se hizo en foreground.
2. Pre-computar la agenda de notificaciones del día nuevo.
3. Limpiar datos temporales (PendingActionQueue expirada, etc.).

**Requiere:** `externalAccessory` background mode o `processing` — iOS concede esto solo si el dispositivo está cargando + conectado a WiFi.

## 3. Archivos nuevos

| Archivo | Fase | Descripción |
|---------|------|-------------|
| `ios/Runner/BackgroundTaskHandler.swift` | 2 | Handler nativo para BGAppRefreshTask |
| `core/services/background_notification_refresh.dart` | 2 | Lógica Dart de recálculo |
| `ios/Runner/NightlyProcessingHandler.swift` | 3 | Handler nativo para BGProcessingTask |
| `core/services/background_daily_summary.dart` | 3 | Flush nocturno del daily summary |

## 4. Arquitectura

```
┌─────────────────────────────────────────────────┐
│                    iOS                           │
│  BGTaskScheduler                                 │
│    ├─ healthkit-update (Fase 1)                  │
│    │    → HealthKitObserver.swift                 │
│    │    → PendingActionQueue (SharedPreferences)  │
│    ├─ notification-refresh (Fase 2)              │
│    │    → BackgroundTaskHandler.swift             │
│    │    → Dart: background_notification_refresh   │
│    │    → flutter_local_notifications            │
│    └─ nightly-processing (Fase 3)                │
│         → NightlyProcessingHandler.swift          │
│         → Dart: background_daily_summary          │
│         → Firestore offline write                 │
└─────────────────────────────────────────────────┘
         │
         ▼ (foreground resume)
   CoachingActionRouter.flush(ref)
         │
         ▼
   [Notifiers actualizan estado visible]
```

## 5. Restricciones de iOS

- **BGAppRefreshTask:** ~30s CPU. No garantizado — iOS decide frecuencia según uso del usuario.
- **BGProcessingTask:** Más CPU pero solo con carga + WiFi. No confiable para tareas críticas.
- **No hay timer periódico garantizado en iOS.** El approach es best-effort + reconciliación en foreground.
- **flutter_local_notifications puede programar desde background** SI el plugin registrant está configurado (ya hecho en AppDelegate, SPEC-224).
- **Firestore writes en background:** Funcionan via caché offline (SPEC-206). Se sincronizan al reconectar.

## 6. Tests

- Fase 1: Test manual en device — cerrar app → caminar 1000 pasos → abrir app → verificar que exercise se actualizó.
- Fase 2: Simular BGAppRefreshTask en Simulator (Debug → Simulate Background Fetch). Verificar que notificaciones se reprogramaron.
- Fase 3: Verificar daily summary generado sin foreground (test en device nocturno).

## 7. Riesgos

- **Apple rejection:** Background modes deben estar justificados en la review. HealthKit background delivery es standard para health apps. `BGAppRefreshTask` para "notification management" es aceptado. Documentar en App Review notes.
- **Battery drain:** Mantener las tareas de background ligeras (<30s). No hacer network requests innecesarios — usar caché local.
- **Flutter engine en background:** Hay limitaciones documentadas. El engine headless puede no tener acceso a todos los plugins. Testear cada plugin usado en background.

## 8. Notas

- Fase 1 está BLOCKED por Apple Developer Portal. No requiere código nuevo significativo — solo desbloquear el entitlement.
- Fase 2 es la de mayor valor: resuelve el 80% de los escenarios (notificaciones adaptativas).
- Fase 3 es nice-to-have — el daily summary ya se genera en foreground (SPEC-111) y el flush a medianoche (SPEC-138 §4.4) cubre el caso normal.
- Android equivalente usaría `workmanager` — diferido hasta que haya versión Android.
