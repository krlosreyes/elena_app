# SPEC-236: Apple Watch Companion App

**Status**: APPROVED-DESIGN  
**Prioridad**: MEDIUM — diferenciador de retención post-lanzamiento  
**Fecha**: 2026-06-18  
**Origen**: Auditoría de coaching: "no hay notificaciones en los smart watch" (Carlos). No existe target watchOS, no hay WatchConnectivity, no hay complicaciones. Las notificaciones llegan al reloj solo por reflejo del OS.  
**Dependencias**: SPEC-235 (Live Activity — comparte infra de datos compartidos), SPEC-232 (check-ins), SPEC-233 (prompts accionables)  
**Esfuerzo estimado**: 10-15 días  
**Requisitos**: Apple Developer Program, Xcode con watchOS SDK, dispositivo Apple Watch para testing

---

## 1. Problema

ElenaApp no tiene presencia en la muñeca del usuario. Las notificaciones llegan al Apple Watch por reflejo del sistema operativo, pero:

- No se puede registrar agua desde el reloj (hay que sacar el iPhone)
- No se ve el timer de ayuno (hay que abrir la app)
- No hay complicación en el watch face (el dato más consultado — "¿cuánto llevo?" — requiere desbloquear iPhone)
- Los check-ins emocionales (SPEC-232) no llegan al reloj de forma interactiva
- No hay feedback háptico contextual (el reloj podría vibrar suavemente en hitos de ayuno)

En el ecosistema de apps de salud, **la presencia en el reloj es señal de seriedad**. Zero, Fastic y LIFE no tienen app de Watch — este es un diferenciador real.

---

## 2. Propuesta

### 2.1 Experiencias en el Watch

Cuatro superficies en watchOS:

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  COMPLICACIÓN    │  │  APP PRINCIPAL   │  │  NOTIFICACIÓN    │  │  HAPTICS        │
│  (watch face)    │  │  (SwiftUI)       │  │  INTERACTIVA     │  │  CONTEXTUALES   │
│                  │  │                  │  │                  │  │                  │
│  Timer ayuno     │  │  Estado ayuno    │  │  Check-in        │  │  Hito alcanzado │
│  Score del día   │  │  Registro agua   │  │  "¿Cómo vas?"    │  │  Fase cambió    │
│  Vasos de agua   │  │  Check-in        │  │  Acción 1 toque  │  │  Meta cumplida  │
│                  │  │  Score resumen   │  │                  │  │                  │
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
```

### 2.2 Complicaciones (Watch Face)

Tres complicaciones para diferentes familias de watch face:

#### Complicación Circular (Graphic Corner / Circular)
```
    ╭───────╮
   │ 🔥 14h │
   │  /16h  │
    ╰───────╯
    ━━━━━░░
```
Timer de ayuno con barra de progreso circular. Color cambia por fase (gris → azul → verde → dorado).

#### Complicación Rectangular (Graphic Rectangular)
```
┌────────────────────┐
│ 🔥 14h 32min       │
│ ━━━━━━━━━━░░ 16h   │
│ Cetosis · 💧4/8    │
└────────────────────┘
```
Timer + barra + vasos de agua del día. El dato más rico en el watch face.

#### Complicación Inline (Modular / Utility)
```
🔥 14:32 de 16h
```
Solo texto — compatible con todos los watch faces.

**Actualización**: las complicaciones se actualizan vía `CLKComplicationServer.sharedInstance().reloadTimeline()` cada 15 minutos (budget de watchOS). Para el timer, se usa `CLKRelativeDateTextProvider` que cuenta automáticamente sin consumir budget.

### 2.3 App Principal (SwiftUI)

Vista minimalista optimizada para muñeca. Tres pantallas accesibles por scroll vertical:

#### Pantalla 1: Estado del Ayuno
```
┌──────────────────────┐
│                      │
│      🔥 14:32        │
│    ━━━━━━━━━░░       │
│    Cetosis activa    │
│                      │
│  Meta: 16h           │
│  Siguiente: Autofagia│
│  en 1h 28min         │
│                      │
│  [Cerrar ayuno]      │
└──────────────────────┘
```

#### Pantalla 2: Registro Rápido
```
┌──────────────────────┐
│                      │
│  💧 Hidratación      │
│     4 de 8 vasos     │
│                      │
│  ╭─────╮             │
│  │ +1  │  ← Crown    │
│  │ vaso│    tap       │
│  ╰─────╯             │
│                      │
│  Último: hace 45 min │
└──────────────────────┘
```

Registro de agua con **un solo toque** en el botón grande, o girando la Digital Crown para ajustar cantidad. Feedback háptico `.success` al registrar.

#### Pantalla 3: Score del Día
```
┌──────────────────────┐
│                      │
│  Score: 72           │
│  ━━━━━━━━━━━░░       │
│                      │
│  🔥 Ayuno    ✓       │
│  💧 Agua     4/8     │
│  🏃 Ejercicio ✗      │
│  🍽 Nutrición ✓      │
│  😴 Sueño    ✓       │
│                      │
└──────────────────────┘
```

Resumen compacto de los 5 pilares. Toque en un pilar → detalle mínimo.

### 2.4 Notificaciones Interactivas en Watch

Las notificaciones de Elena ya llegan al Watch por reflejo. Con la app companion, se enriquecen:

- **Check-in emocional (SPEC-232)**: la notificación en el Watch muestra los 4 emojis como botones. El usuario responde desde la muñeca sin sacar el iPhone.
- **Hidratación accionable**: botón "Registrar vaso" directamente en la notificación.
- **Cierre de ayuno**: botón "Cerrar" cuando el protocolo se alcanza.

Implementación: `UNNotificationCategory` con acciones — la misma infra de SPEC-199 Fase A. watchOS las renderiza automáticamente si la app companion está instalada.

### 2.5 Haptics Contextuales

Vibraciones suaves en momentos clave (sin sonido, solo tacto):

| Evento | Patrón háptico | Momento |
|--------|----------------|---------|
| Cambio de fase | `.notification` (suave) | Al pasar de digestión → quema, quema → cetosis, etc. |
| Protocolo alcanzado | `.success` (doble tap) | Al alcanzar las horas target |
| Vaso registrado | `.click` (click) | Confirmación inmediata |
| Check-in pendiente | `.directionUp` (suave) | En hitos 4h/8h/12h/16h |

**Frecuencia controlada**: máximo 4 haptics por sesión de ayuno para no molestar. El usuario puede desactivar haptics en settings del Watch.

### 2.6 Comunicación iPhone ↔ Watch

```
┌──────────┐                          ┌──────────┐
│  iPhone   │◄── WatchConnectivity ──►│  Watch    │
│  (Flutter)│                          │  (Swift)  │
│           │  transferUserInfo()      │           │
│           │  ──────────────────►     │           │
│           │  {fastingStart, score,   │           │
│           │   glasses, protocol}     │           │
│           │                          │           │
│           │  sendMessage()           │           │
│           │  ◄──────────────────     │           │
│           │  {action: "logWater"}    │           │
│           │                          │           │
│           │  UserDefaults (shared)   │           │
│           │  ◄────────────────►      │           │
│           │  App Group container     │           │
└──────────┘                          └──────────┘
```

**Flujo de datos**:
1. **iPhone → Watch** (`transferUserInfo`): estado actual del ayuno, score, vasos, protocolo. Se envía en cada cambio de estado significativo. `transferUserInfo` es fire-and-forget y sobrevive a la app cerrada.
2. **Watch → iPhone** (`sendMessage`): acciones del usuario (registrar vaso, cerrar ayuno, check-in). Si el iPhone está alcanzable, `sendMessage` es instantáneo. Si no, `transferUserInfo` encola.
3. **Datos compartidos** (`UserDefaults` via App Group): el estado del ayuno se escribe en el container compartido para que las complicaciones lo lean sin depender de la sesión de WatchConnectivity.

**Flutter bridge**: `MethodChannel('elena/watch_connectivity')` conecta Flutter con `WCSession` nativo. El canal es bidireccional:
- Flutter escucha acciones del Watch → las aplica vía los notifiers existentes
- Flutter envía actualizaciones al Watch cuando el estado cambia

### 2.7 Gating SPEC-197

- **Free**: complicación con timer + app principal con estado de ayuno (solo lectura)
- **Premium**: registro de agua, check-ins, cierre de ayuno, haptics, score completo

---

## 3. Estructura de Archivos Nuevos

### watchOS (Swift — Xcode target separado)
```
watchOS/
  ElenaWatch/
    ElenaWatchApp.swift              ← Entry point
    ContentView.swift                ← Tab container
    Views/
      FastingView.swift              ← Estado del ayuno
      HydrationView.swift            ← Registro de agua
      ScoreView.swift                ← Score del día
    Complications/
      ComplicationController.swift   ← Timeline provider
      ComplicationViews.swift        ← SwiftUI para complicaciones
    Services/
      WatchSessionManager.swift      ← WCSession delegate
      HapticsManager.swift           ← Feedback háptico
    Models/
      WatchFastingState.swift        ← Modelo compartido
      WatchPillarSummary.swift
    Assets.xcassets/
    Info.plist
```

### Flutter (bridge)
```
lib/src/core/services/watch_connectivity_service.dart    ← MethodChannel bridge
lib/src/core/services/watch_state_sync.dart              ← Sincroniza estado → Watch
```

### iOS (bridge nativo)
```
ios/Runner/WatchConnectivityPlugin.swift                 ← FlutterMethodChannel handler
ios/Runner/AppDelegate+WatchConnectivity.swift           ← WCSession setup
```

## 4. Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `fasting_notifier.dart` | Trigger `WatchStateSync.sendFastingUpdate()` al cambiar estado |
| `hydration_notifier.dart` | Trigger `WatchStateSync.sendHydrationUpdate()` al registrar vaso |
| `coaching_action_router.dart` | Handler para acciones que llegan del Watch |
| `app.dart` | Inicializar `WatchConnectivityService` en startup |
| `ios/Runner.xcodeproj` | Agregar Watch target + App Group |
| `ios/Runner.entitlements` | App Group capability |
| `pubspec.yaml` | Sin dependencia nueva — bridge es nativo puro |

---

## 5. Requisitos de Infraestructura

1. **Apple Developer Portal**: crear App Group (`group.com.elena.shared`)
2. **Xcode**: agregar Watch App target (watchOS 9.0+ para WidgetKit complications)
3. **Provisioning profiles**: regenerar con App Group + Watch App
4. **TestFlight**: el Watch app se distribuye automáticamente con el iPhone app
5. **NO requiere servidor**: toda la comunicación es local iPhone ↔ Watch

---

## 6. Limitaciones Conocidas

1. **Solo Apple Watch**: Android Wear OS no tiene equivalente a WatchConnectivity con Flutter. Wear OS requiere app separada en Kotlin/Compose. Se pospone a v2.
2. **watchOS 9+**: requerido para WidgetKit complications modernas. Watch Series 4+ (2018).
3. **Background refresh budget**: watchOS limita a ~4 updates/hora para complicaciones. El timer usa `CLKRelativeDateTextProvider` para contar sin consumir budget.
4. **Sin Flutter en Watch**: la app del Watch es SwiftUI nativa. No hay Flutter runtime en watchOS. Toda la UI se escribe en Swift.
5. **Testing**: requiere Apple Watch físico o Simulator con Xcode. No se puede testear con `flutter test`.

---

## 7. Fases de Entrega

| Fase | Entregable | Días |
|------|-----------|------|
| 1 | Complicación de timer de ayuno (solo lectura) + WatchConnectivity bridge | 4 |
| 2 | App principal: estado ayuno + registro de agua | 3 |
| 3 | Check-ins interactivos + haptics + score | 3 |
| 4 | Gating premium + polish | 2 |

La Fase 1 es el MVP: el usuario ve su timer de ayuno en el watch face. Eso solo ya es diferenciador.

---

## 8. Criterios de Aceptación

- [ ] AC-01: complicación circular muestra timer de ayuno con progreso visual en el watch face
- [ ] AC-02: complicación rectangular muestra timer + vasos de agua del día
- [ ] AC-03: al abrir la app en el Watch, se ve el estado actual del ayuno (fase, timer, meta)
- [ ] AC-04: el usuario puede registrar un vaso de agua con un toque desde el Watch
- [ ] AC-05: el vaso registrado en el Watch aparece en el iPhone en menos de 5 segundos
- [ ] AC-06: al alcanzar el protocolo de ayuno, el Watch vibra con patrón `.success`
- [ ] AC-07: las notificaciones de check-in (SPEC-232) muestran opciones interactivas en el Watch
- [ ] AC-08: al cerrar ayuno desde el Watch, el iPhone refleja el cambio inmediatamente
- [ ] AC-09: las complicaciones se actualizan cuando el estado del ayuno cambia
- [ ] AC-10: el timer de la complicación cuenta en tiempo real sin consumir budget de refresh
- [ ] AC-11: la app del Watch funciona sin conexión al iPhone (muestra último estado conocido)
- [ ] AC-12: gating: usuarios Free ven solo timer (lectura); Premium tienen registro + check-ins
