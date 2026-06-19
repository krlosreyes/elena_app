# Coaching Evolution Roadmap — De "app que informa" a "coach que acompaña"

**Fecha**: 2026-06-18  
**Origen**: Auditoría integral del sistema de coaching por Carlos  
**Tesis**: Las apps de ayuno son timers glorificados. Elena puede ser **compañía**.

---

## Diagnóstico

El motor de coaching interno (SPEC-194) es sofisticado: 4 generadores de candidatos, scorer con priorización, anti-fatiga cross-device, telemetría de conducta, supresión contextual. Pero su **superficie visible** se reduce a una tarjeta minimalista en el dashboard con "Saber más" y notificaciones push.

**La app INFORMA pero no ACOMPAÑA.**

El usuario no siente coaching porque:
1. No hay diálogo — el coaching es unidireccional
2. No hay check-ins emocionales — nunca le preguntan "¿cómo te sientes?"
3. No hay presencia ambient — el coach desaparece al cerrar la app
4. Solo 1 de 5 pilares tiene prompt interactivo in-app (hidratación)
5. El pilar más pesado (sueño, 25%) tiene cero coaching

---

## Las 5 Capas

### Capa 1: SPEC-232 — Check-ins Emocionales Durante el Ayuno
**Esfuerzo**: 3-4 días · **Para lanzamiento**: ✅ Sí

El diferenciador más accesible. En hitos de ayuno (4h/8h/12h/16h), preguntar "¿Cómo te sientes?" con opciones de 1 toque: Con energía / Bien / Con hambre / Cansado / Irritable. La respuesta alimenta al motor de coaching para personalizar la siguiente acción. Si reporta "Irritable" 2× consecutivas → el coach sugiere cerrar el ayuno.

**Archivos nuevos**: 5 · **Archivos modificados**: 8  
**IDs de notificación**: 600-609

---

### Capa 2: SPEC-233 — Prompts Interactivos para los 5 Pilares
**Esfuerzo**: 2-3 días · **Para lanzamiento**: ✅ Sí

El `PredictiveTriggerEngine` ya tiene `fastingPrompt()`, `exercisePrompt()`, `nutritionPrompt()` como funciones puras, pero la `InteractiveCoachingCard` solo consume hidratación. Crear un `InteractivePromptOrchestrator` que evalúe los 5 pilares y emita el prompt más relevante. La tarjeta rota por pilares según urgencia, pilar débil, y anti-fatiga.

**Archivos nuevos**: 1 · **Archivos modificados**: 5

---

### Capa 3: SPEC-234 — Coaching de Sueño y Rutina Nocturna Guiada
**Esfuerzo**: 3-4 días · **Para lanzamiento**: ✅ Sí

Tres momentos: check-in post-despertar "¿Cómo dormiste?" (escala 5 emojis integrada en overlay), rutina pre-sueño guiada (checklist de 4 pasos de higiene, Walker 2017), y "Buenas noches" con resumen motivacional del día. El check-in llena `subjectiveQuality` del SleepLog (campo que ya existe pero rara vez se usa).

**Archivos nuevos**: 4 · **Archivos modificados**: 6  
**IDs de notificación**: 610-619

---

### Capa 4: SPEC-235 — Live Activity + Isla Dinámica para el Ayuno
**Esfuerzo**: 5-7 días · **Para lanzamiento**: ⚠️ Stretch

Presencia ambient del ayuno: timer + fase + barra de progreso en Isla Dinámica (iOS) y notificación ongoing con progreso (Android). 4 estados visuales por fase fisiológica. Botón "Cerrar ayuno" en lock screen al alcanzar protocolo. Absorbe SPEC-199 Fase B.

**Archivos nuevos**: 2 Flutter + 4 Swift · **Archivos modificados**: 6  
**IDs de notificación**: 700-709 (Android)

---

### Capa 5: SPEC-236 — Apple Watch Companion App
**Esfuerzo**: 10-15 días · **Para lanzamiento**: ❌ Post-lanzamiento

Complicación de timer en watch face, registro de agua con 1 toque, check-ins interactivos, haptics contextuales. SwiftUI nativo (sin Flutter en watchOS). Comunicación via WatchConnectivity + App Group.

**Archivos nuevos**: ~15 (mayoría Swift) · **Archivos modificados**: 7  
**Fases internas**: 4 (MVP complicación → app completa → check-ins → polish)

---

## Mapa de Dependencias

```
SPEC-199 Fase A (IMPLEMENTED)
    │
    ├── SPEC-232 Check-ins ◄── SPEC-224 PredictiveTriggerEngine
    │       │
    │       ├── SPEC-233 Prompts 5 pilares
    │       │       │
    │       │       └── SPEC-234 Coaching sueño
    │       │
    │       └── SPEC-235 Live Activity (absorbe SPEC-199 Fase B)
    │               │
    │               └── SPEC-236 Apple Watch (comparte infra App Group)
    │
    └── SPEC-205 Feed artículos (independiente, complementario)
```

---

## Mapa de IDs de Notificación

| Rango | Spec | Propósito |
|-------|------|-----------|
| 100-107 | SPEC-169 | Circadianas (wake, meals, sleep, eTRF) |
| 200-209 | SPEC-169 | Hitos de ayuno (12h, 16h, 18h, 24h) |
| 300-301 | SPEC-137/235 | Auto-cierre ciclo + próxima comida |
| 400-450 | SPEC-150/199 | Hidratación slots + snooze |
| 500-501 | SPEC-198 | Paywall nudges |
| **600-609** | **SPEC-232** | **Check-ins emocionales** |
| **610-619** | **SPEC-234** | **Coaching de sueño** |
| **700-709** | **SPEC-235** | **Live progress Android** |

---

## Nuevos PromptActionType (extensión de actionable_prompt.dart)

| Tipo | Spec | Handler |
|------|------|---------|
| `logWater` | SPEC-199 | Ya existe |
| `closeFasting` | SPEC-224 | Ya existe |
| `logExercise` | SPEC-224 | Ya existe |
| `logMeal` | SPEC-224 | Ya existe |
| `snooze` | SPEC-199 | Ya existe |
| **`checkInFeeling`** | **SPEC-232** | Nuevo — persiste FastingCheckIn |
| **`startSleepRoutine`** | **SPEC-234** | Nuevo — navega a SleepRoutineScreen |
| **`rateSleep`** | **SPEC-234** | Nuevo — persiste subjectiveQuality |

---

## Timeline Sugerido

```
Semana 1 (jun 23-27):  SPEC-232 check-ins + SPEC-233 prompts 5 pilares
                        ────────────────────────────────────────────
                        ~5-6 días. Transforma la percepción de coaching.

Semana 2 (jun 30-jul 4): SPEC-234 coaching sueño
                          ──────────────────────
                          ~3-4 días. Completa el pilar más pesado.

Semana 3-4 (jul 7-18):   SPEC-235 Live Activity
                          ─────────────────────
                          ~5-7 días. Presencia ambient.

Post-lanzamiento:         SPEC-236 Apple Watch
                          ─────────────────────
                          ~10-15 días. Diferenciador de retención.
```

---

## Principios Inmovibles

1. **NUNCA Firestore en background** — siempre cola local + flush en foreground (SPEC-199 §3.2)
2. **El coach CUIDA, no castiga** — irritabilidad 2× → sugerir cerrar ayuno, no forzar
3. **Tono cálido, sin culpa** — alineado con SPEC-169 y la audiencia Elena
4. **Gating coherente** — Free recibe coaching básico, Premium recibe la experiencia completa
5. **Fundamento científico** — cada recomendación cita fuente verificable (Walker, Huberman, Levine, Sutton)
