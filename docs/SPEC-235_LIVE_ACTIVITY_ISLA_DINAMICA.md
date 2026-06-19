# SPEC-235: Live Activity + Isla Dinámica para el Ayuno

**Status**: APPROVED-DESIGN  
**Prioridad**: MEDIUM-HIGH — presencia ambient del coach sin abrir la app  
**Fecha**: 2026-06-18  
**Origen**: SPEC-199 Fase B (diseñada, nunca implementada) + auditoría coaching: "el usuario no siente presencia del coach fuera de la app"  
**Dependencias**: SPEC-199 Fase A (notificaciones accionables — IMPLEMENTED), SPEC-232 (check-ins)  
**Esfuerzo estimado**: 5-7 días  
**Requisitos nativos**: Widget Extension (Swift), ActivityKit (iOS 16.1+), Android 16 Live Updates

---

## 1. Problema

El ayuno intermitente es una **actividad continua** que dura 12-24 horas. Hoy, el usuario debe abrir la app para saber en qué fase está, cuánto le falta, o si ya alcanzó su protocolo. Esto rompe la experiencia de "coach que acompaña" porque el coach desaparece cuando cierras la app.

Las Live Activities de iOS y Live Updates de Android resuelven exactamente este caso: estado persistente en la pantalla de bloqueo y la Isla Dinámica sin abrir la app.

---

## 2. Propuesta

### 2.1 Anatomía de la Live Activity

```
┌─────────────────────────────────────────────────┐
│ ISLA DINÁMICA (compacta)                        │
│                                                 │
│  [🔥 14:32]              [━━━━━━━━━━━░░ 16h]    │
│   timer                    barra progreso       │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ ISLA DINÁMICA (expandida — long press)          │
│                                                 │
│  🔥 Ayuno activo              14h 32min         │
│                                                 │
│  ━━━━━━━━━━━━━━━━━━━━░░░░░                      │
│  Cetosis activa                Meta: 16h        │
│                                                 │
│  Siguiente hito: Autofagia en 1h 28min          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ LOCK SCREEN (banner persistente)                │
│                                                 │
│  🔥 Ayuno activo — 14h 32min de 16h             │
│  ━━━━━━━━━━━━━━━━━━━━░░░░░                      │
│  Cetosis activa · Autofagia en 1h 28min         │
│                                                 │
│  [Cerrar ayuno]                                 │
└─────────────────────────────────────────────────┘
```

### 2.2 Estados y Transiciones

La Live Activity tiene 4 estados visuales alineados con las fases de ayuno de Elena:

| Fase | Horas | Color | Icono | Mensaje |
|------|-------|-------|-------|---------|
| Digestión | 0-4h | Gris | 🕐 | "Tu cuerpo digiere" |
| Quema de grasa | 4-12h | Azul | 🔥 | "Quemando reservas" |
| Cetosis | 12-16h | Verde | ⚡ | "Cetosis activa" |
| Autofagia | 16h+ | Dorado | ✨ | "Limpieza profunda" |

**Transiciones**: cuando la fase cambia, la Live Activity se actualiza con animación y el usuario ve el cambio en la Isla Dinámica sin hacer nada. En lock screen, el color del banner cambia.

### 2.3 Ciclo de Vida

```
startFastingManual() / bootstrapFasting()
    ↓
ActivityKit.request(attributes, contentState)  ← inicia Live Activity
    ↓
Timer periódico (cada 60s) O push token update
    ↓
Activity.update(newContentState)  ← actualiza timer + fase
    ↓
openEatingWindow() / closeFasting()
    ↓
Activity.end(finalContent, dismissalPolicy: .default)  ← termina
```

**Límite de iOS**: Live Activities tienen un tope de ~8 horas de actualización local (después, solo push). Para ayunos de 16-24h, necesitamos:
- Primeras 8h: timer local (no requiere servidor)
- 8h+: `Activity.request` con `staleDate` para que iOS muestre "Ayuno activo — abre la app para ver tu progreso" si no hay push
- **Decisión pragmática v1**: usar solo timer local. Un ayuno de 16h con Live Activity que se "congela" a las 8h pero muestra el timer correcto al abrir la app es aceptable para v1. Push token updates requieren infraestructura de servidor (APNs) que no tenemos.

### 2.4 Implementación Técnica — iOS

**Paquete Flutter**: `live_activities` (pub.dev) — bridge entre Flutter y ActivityKit.

**Archivos nativos necesarios**:

```
ios/
  ElenaWidgetExtension/
    ElenaWidgetExtension.swift          ← Widget Extension target
    ElenaFastingAttributes.swift        ← ActivityAttributes
    ElenaFastingLiveActivity.swift      ← Vista SwiftUI de la Live Activity
    Assets.xcassets/                    ← Iconos para la Live Activity
  Runner.entitlements                   ← Push Notifications entitlement
```

**ActivityAttributes**:
```swift
struct ElenaFastingAttributes: ActivityAttributes {
    // Datos estáticos (no cambian durante la actividad)
    let protocol: String        // "16:8", "18:6", "20:4"
    let targetHours: Int
    let startedAt: Date

    struct ContentState: Codable, Hashable {
        let elapsedMinutes: Int
        let currentPhase: String    // "digestion", "fatBurning", "ketosis", "autophagy"
        let nextMilestoneMinutes: Int?
        let nextMilestoneName: String?
    }
}
```

**Flutter ↔ Native bridge**:
```dart
class LiveActivityService {
  static final _channel = MethodChannel('elena/live_activity');

  static Future<void> startFastingActivity({
    required DateTime startedAt,
    required String protocol,
    required int targetHours,
  }) async { ... }

  static Future<void> updateFastingActivity({
    required int elapsedMinutes,
    required String currentPhase,
    int? nextMilestoneMinutes,
    String? nextMilestoneName,
  }) async { ... }

  static Future<void> endFastingActivity() async { ... }
}
```

### 2.5 Implementación Técnica — Android

**Android 16 Live Updates** (API 36+): usa `ProgressStyle` de notificaciones.

Para Android < 16: notificación ongoing con `setProgress()` que se actualiza cada minuto. Visualmente similar pero sin la integración de lock screen de Android 16.

```dart
// Android fallback: notificación ongoing con progreso
await NotificationService.showOngoing(
  id: NotificationIds.fastingLiveProgress,
  title: '🔥 Ayuno activo — ${elapsed}h de ${target}h',
  body: '$phaseName · Siguiente hito: $nextMilestone',
  progress: elapsed / target,
  channelId: 'fasting_progress',
);
```

**ID reservado**: `NotificationIds.fastingLiveProgress = 700`.

### 2.6 Integración con el Motor de Coaching

La Live Activity se convierte en **superficie de check-in** (SPEC-232):

- En hitos 4h/8h/12h/16h, la actualización de la Live Activity incluye el texto "¿Cómo vas?" y al tocar abre la app en la tarjeta de check-in
- En protocolo alcanzado, el botón "Cerrar ayuno" aparece directamente en la Live Activity (lock screen)

### 2.7 Gating SPEC-197

- **Free**: Live Activity muestra timer + fase actual (información básica)
- **Premium**: Live Activity muestra hitos, check-ins, y botón de cierre directo

---

## 3. Archivos Nuevos

| Archivo | Propósito |
|---------|-----------|
| `core/services/live_activity_service.dart` | Bridge Flutter ↔ ActivityKit/Android |
| `ios/ElenaWidgetExtension/` (4 archivos Swift) | Widget Extension nativa |

## 4. Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `fasting_notifier.dart` | Llamar `LiveActivityService.start/end` al iniciar/cerrar ayuno |
| `metabolic_cycle_evaluator_provider.dart` | Llamar `LiveActivityService.update` en cada tick |
| `notification_service_mobile.dart` | IDs 700-709 para live progress Android |
| `ios/Runner.xcodeproj` | Agregar Widget Extension target |
| `ios/Podfile` | Target del Widget Extension |
| `pubspec.yaml` | Dependencia `live_activities` |

---

## 5. IDs de Notificación

| ID | Plataforma | Propósito |
|----|-----------|-----------|
| 700 | Android | Notificación ongoing de progreso de ayuno |
| 701-709 | Android | Reservados para estados especiales |

iOS usa ActivityKit (sin IDs de notificación — sistema separado).

---

## 6. Limitaciones Conocidas

1. **iOS < 16.1**: no hay Live Activities. Fallback a notificación ongoing similar a Android.
2. **8h local timer**: después de 8h sin push, iOS marca la actividad como stale. v1 acepta esto; v2 requiere servidor APNs.
3. **Widget Extension = Swift puro**: no corre Flutter. La UI de la Live Activity se escribe en SwiftUI. Los datos llegan vía `UserDefaults(suiteName: "group.elena")` compartido entre app y extension.
4. **Background updates**: el timer se actualiza vía `Timer.periodic` que iOS puede matar. Mitigación: `BGProcessingTask` para actualizar cada 15 min como backup.

---

## 7. Criterios de Aceptación

- [ ] AC-01: al iniciar ayuno, aparece Live Activity en Isla Dinámica (iOS) / notificación ongoing (Android)
- [ ] AC-02: el timer se actualiza cada minuto mostrando horas:minutos transcurridos
- [ ] AC-03: la barra de progreso refleja porcentaje completado del protocolo
- [ ] AC-04: al cambiar de fase (digestión→quema→cetosis→autofagia), el color y mensaje se actualizan
- [ ] AC-05: al alcanzar protocolo, aparece botón "Cerrar ayuno" en la lock screen
- [ ] AC-06: al cerrar ayuno (manual o automático), la Live Activity se cierra con resumen final
- [ ] AC-07: Android < 16: notificación ongoing con progreso visual funcional
- [ ] AC-08: la Live Activity funciona correctamente después de reboot del dispositivo
