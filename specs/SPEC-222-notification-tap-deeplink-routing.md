# SPEC-222 — Deeplink routing al tocar notificaciones

**Estado:** IMPLEMENTED (2026-06-17)
**Versión:** 0.1
**Líder:** Carlos · **Implementación:** Claude
**Depende de:** SPEC-169 (smart notifications), SPEC-224 (notificaciones accionables), GoRouter.
**Prioridad:** Media — sprint siguiente.
**Estimación:** 5-8 SP

---

## 1. Problema

Cuando el usuario toca el **cuerpo** de una notificación (no un botón de acción), la app se abre en el último estado visible — cualquier pestaña. El `default` case de `PendingActionQueue.handleNotificationAction()` no encola nada y no navega.

**Ejemplo concreto:** El usuario recibe "🍽️ Tu ventana abrió", toca la notificación esperando ver su pilar de nutrición, pero aterriza en la pestaña de Análisis donde estaba ayer. Fricción que degrada la confianza en las notificaciones.

## 2. Solución

### 2.1 Payload en cada notificación

Agregar `payload` JSON a cada `scheduleAt` call en `NotificationScheduler`:

```dart
await NotificationService.scheduleAt(
  id: NotificationIds.firstMeal,
  title: '🍽️ Tu ventana abrió',
  body: '...',
  scheduledTime: ...,
  payload: '{"route": "/", "tab": 0, "pillar": "nutrition"}',
);
```

Categorías de routing por rango de ID:

| Rango ID | Categoría | Route | Tab/Pillar |
|----------|-----------|-------|------------|
| 100 (wakeUp) | Circadiano | `/` | Dashboard (tab 0) |
| 101-102 (firstMeal, lastMealWarning) | Nutrición | `/` | Dashboard, scroll a nutrición |
| 103-107 (locks, sleep, eTRF) | Circadiano | `/` | Dashboard (tab 0) |
| 200-203 (fasting milestones) | Ayuno | `/` | Dashboard, pilar ayuno |
| 301 (nextMealReady) | Nutrición | `/` | Dashboard, pilar nutrición |
| 400-450 (hydration) | Hidratación | `/` | Dashboard, pilar hidratación |
| 500-501 (paywall) | Billing | `/paywall` | Pantalla de paywall |

### 2.2 Handler de foreground

**`notification_service_mobile.dart`** — `_notificationForegroundResponseHandler`:

```dart
void _notificationForegroundResponseHandler(NotificationResponse response) {
  // 1. Acciones con botón → PendingActionQueue (ya existente)
  if (response.actionId != null) {
    unawaited(PendingActionQueue.handleNotificationAction(
      response.actionId, response.id));
    return;
  }
  // 2. Tap en cuerpo → deeplink routing
  if (response.payload != null) {
    NotificationRouter.handlePayload(response.payload!);
  }
}
```

### 2.3 NotificationRouter (nuevo)

**Nuevo archivo:** `core/services/notification_router.dart`

```dart
class NotificationRouter {
  static GlobalKey<NavigatorState>? navigatorKey;

  static void handlePayload(String payload) {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final route = data['route'] as String? ?? '/';
    // GoRouter.of(context).go(route) — acceso via navigatorKey
    // o vía un provider global de GoRouter.
  }
}
```

### 2.4 Handler de background (cold start)

Cuando la app se abre desde una notificación estando cerrada, el payload se captura en `getNotificationAppLaunchDetails()`. Actualmente no se usa. Agregar en `app.dart` (init):

```dart
final details = await NotificationService.getLaunchDetails();
if (details?.didNotificationLaunchApp == true) {
  NotificationRouter.handlePayload(details!.payload);
}
```

### 2.5 Agregar `payload` a `NotificationService`

**`notification_service_mobile.dart`** — `scheduleAt`:
- Agregar parámetro `String? payload` y pasarlo al `NotificationDetails`.

**`notification_service_web.dart`** — stub: agregar parámetro, ignorar.

## 3. Archivos a tocar

| Archivo | Cambio |
|---------|--------|
| `core/services/notification_service_mobile.dart` | `payload` param en `scheduleAt` + `showImmediate`, handler split |
| `core/services/notification_service_web.dart` | `payload` param (no-op) |
| `core/services/notification_scheduler.dart` | Agregar `payload` JSON a cada llamada |
| `core/services/notification_router.dart` | NUEVO — routing por payload |
| `app.dart` | Cold-start launch details handling |
| `core/services/pending_action_queue.dart` | Sin cambio (botones de acción siguen igual) |

## 4. Tests

- Unit: `NotificationRouter.handlePayload` — cada payload mapea al route correcto.
- Integration: simular tap en notificación con payload, verificar que GoRouter navega.
- Edge case: payload malformado → fallback a dashboard sin crash.

## 5. Riesgos

- `GoRouter` requiere un `BuildContext` o `navigatorKey` global para navegar programáticamente. Si el widget tree no está montado (cold start), la navegación debe ser lazy — guardar el route y aplicarlo cuando el primer frame se renderiza.
- Notificaciones ya programadas (sin payload) seguirán abriendo el default. No hay migración — se resuelve orgánicamente cuando las notificaciones se reprograman (diariamente).

## 6. Notas

- El `payload` NO debe contener datos sensibles — es almacenado en texto plano por el OS.
- Compatible con la arquitectura de `PendingActionQueue` — los botones de acción siguen usando `actionId`, el tap en cuerpo usa `payload`.
