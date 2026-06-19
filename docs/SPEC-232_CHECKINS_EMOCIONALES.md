# SPEC-232: Check-ins Emocionales Durante el Ayuno

**Status**: APPROVED-DESIGN  
**Prioridad**: HIGH — diferenciador competitivo principal  
**Fecha**: 2026-06-18  
**Origen**: Carlos: "no hay un cómo te sientes durante el ayuno, no hay acompañamiento al usuario"  
**Dependencias**: SPEC-199 (infra notificaciones accionables), SPEC-224 (PredictiveTriggerEngine)  
**Esfuerzo estimado**: 3-4 días

---

## 1. Problema

El ayuno intermitente es un acto **emocional y físico**. El usuario experimenta hambre, irritabilidad, fatiga, claridad mental — estados que cambian hora a hora. ElenaApp hoy celebra hitos de ayuno ("¡12 horas!") pero nunca **pregunta cómo se siente el usuario**. El coaching es unidireccional: la app habla, el usuario solo puede tocar "OK".

Ninguna app de ayuno del mercado (Zero, Fastic, Simple, LIFE) implementa check-ins emocionales contextuales. Este es el diferenciador más accesible.

---

## 2. Propuesta

### 2.1 Modelo de Datos: `FastingCheckIn`

```dart
/// Sentimientos predefinidos — orden por valencia (positivo → negativo).
enum FastingFeeling {
  energized,    // "Con energía"
  focused,      // "Concentrado"
  good,         // "Bien"
  hungry,       // "Con hambre"
  tired,        // "Cansado"
  irritable,    // "Irritable"
}

class FastingCheckIn {
  final String id;             // 'checkin_{userId}_{isoDate}_{fastingHour}'
  final DateTime timestamp;
  final int fastingHour;       // hora de ayuno al momento del check-in (4, 8, 12, 16...)
  final FastingFeeling feeling;
  final String? cycleId;       // metabolic cycle al que pertenece
}
```

**Persistencia**: Firestore `users/{uid}/fasting_checkins/{id}`. Patrón offline-first (SPEC-206): write unawaited + stream como fuente de verdad.

### 2.2 Puntos de Contacto (triggers)

Los check-ins se disparan en **momentos donde el cuerpo cambia de fase**:

| Hora de ayuno | Fase fisiológica | Pregunta contextualizada |
|---------------|------------------|--------------------------|
| 4h | Digestión terminando | "¿Cómo empiezas el ayuno?" |
| 8h | Glucógeno agotándose | "Llevas 8 horas. ¿Cómo te sientes?" |
| 12h | Cetosis temprana | "Tu cuerpo cambió de marcha. ¿Cómo vas?" |
| 16h | Autofagia iniciando | "Entraste en limpieza profunda. ¿Cómo estás?" |

**Regla de supresión**: no disparar si el usuario ya respondió un check-in en las últimas 3 horas (evitar fatiga). Respetar ventana de vigilia (no despertar al usuario).

### 2.3 Superficies

#### A. Notificación accionable (superficie primaria)

```
┌──────────────────────────────────────────┐
│ 🫀 Llevas 12 horas. ¿Cómo vas?           │
│ Tu cuerpo cambió de marcha.              │
│                                          │
│ [Con energía] [Bien] [Con hambre] [Cansado]│
└──────────────────────────────────────────┘
```

**Implementación iOS**: `UNNotificationCategory` con 4 `UNNotificationAction`. Máximo 4 acciones en iOS expandido. Las 2 opciones menos comunes (Concentrado, Irritable) van en la tarjeta in-app.

**Implementación Android**: `AndroidNotificationAction` × 4 (Android soporta más acciones que iOS en notificaciones).

**Respuesta sin abrir app**: el handler de notificación (ya implementado en SPEC-199) encola el check-in en `PendingActionQueue` y lo persiste al hacer flush en `CoachingActionRouter`.

#### B. Tarjeta in-app (superficie secundaria)

Si el usuario abre la app durante un hito activo y no ha respondido, mostrar una tarjeta tipo `InteractiveCoachingCard` con las 6 opciones completas (incluye Concentrado e Irritable que no caben en la notificación).

#### C. Post-respuesta: coaching adaptativo

Según la respuesta, el `CoachingScorer` ajusta la siguiente acción:

| Respuesta | Acción inmediata del coach |
|-----------|---------------------------|
| Con energía / Concentrado | Refuerzo positivo: "Tu cuerpo ya encontró su ritmo" |
| Bien | Neutro: "Vas bien, sigue así" |
| Con hambre | Coaching: "Un vaso de agua con limón puede ayudar. ¿Lo tomamos?" → prompt de hidratación |
| Cansado | Coaching: "Es normal en esta fase. Un té sin azúcar puede darte un empujón" |
| Irritable | Empatía + decisión: "Está bien parar si lo necesitas. ¿Quieres cerrar el ayuno?" → prompt de cierre |

**Regla clave**: si el usuario reporta "Irritable" 2 veces consecutivas en el mismo ciclo, el coach sugiere **activamente** cerrar el ayuno. El producto cuida al usuario, no lo fuerza.

### 2.4 Integración con el Motor de Coaching

```
FastingCheckIn (dato)
    ↓
CheckInHistoryProvider (stream Firestore)
    ↓
CoachingSnapshotBuilder.withCheckIn(lastFeeling)
    ↓
CoachingScorer prioriza respuesta empática
    ↓
NextBestActionCard muestra acción contextualizada
```

**Nuevo generador**: `CheckInResponseGenerator` se agrega a la lista de 4 generadores existentes del `CoachingScorer`. Tiene prioridad ALTA cuando hay un check-in reciente negativo (hambre/cansancio/irritabilidad).

### 2.5 Telemetría (SPEC-193)

- `fasting_checkin_shown` — check-in mostrado (por hora de ayuno)
- `fasting_checkin_answered` — respuesta recibida (feeling + hora)
- `fasting_checkin_ignored` — no respondió en 30 min
- `checkin_to_action` — correlación: respondió hambre → tomó agua en los siguientes 15 min

---

## 3. Archivos Nuevos

| Archivo | Propósito |
|---------|-----------|
| `coaching/domain/fasting_check_in.dart` | Modelo `FastingCheckIn` + enum `FastingFeeling` |
| `coaching/data/check_in_repository.dart` | CRUD Firestore `fasting_checkins` |
| `coaching/application/check_in_provider.dart` | Stream + lógica de trigger |
| `coaching/application/check_in_response_generator.dart` | Generador de coaching post-respuesta |
| `dashboard/presentation/widgets/check_in_card.dart` | Tarjeta in-app |

## 4. Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `notification_scheduler.dart` | Agendar check-ins en hitos 4h/8h/12h/16h |
| `notification_service_mobile.dart` | Categoría iOS `elena_checkin` + IDs 600-609 |
| `coaching_action_router.dart` | Handler para `PromptActionType.checkInFeeling` |
| `actionable_prompt.dart` | Nuevo `PromptActionType.checkInFeeling` |
| `coaching_snapshot_builder.dart` | Incluir `lastFeeling` en snapshot |
| `coaching_providers.dart` | Registrar `CheckInResponseGenerator` |
| `dashboard_screen.dart` | Insertar `CheckInCard` cuando hay hito activo |
| `predictive_trigger_engine.dart` | Nuevo `checkInPrompt()` con supresión contextual |

---

## 5. IDs de Notificación

Rango reservado: **600-609** (check-ins de ayuno, hasta 10 hitos por sesión).

---

## 6. Fundamentación Científica

- **Interoception y ayuno**: Craig (2002) — la consciencia de señales corporales mejora la regulación metabólica. Preguntar "¿cómo te sientes?" es un acto de interoceptive training.
- **Behavioral check-ins**: Michie et al. (2011) BCT Taxonomy — "self-monitoring of outcomes" (técnica #2.4) + "feedback on behaviour" (#2.2). Los check-ins emocionales cumplen ambas.
- **Safety**: reportar irritabilidad 2× consecutivas → sugerir cierre. Alineado con el principio de Elena: el producto cuida, no castiga.

---

## 7. Criterios de Aceptación

- [ ] AC-01: en hora 4/8/12/16 de ayuno, el usuario recibe notificación con 4 opciones de sentimiento
- [ ] AC-02: la respuesta se persiste en Firestore sin abrir la app (vía PendingActionQueue)
- [ ] AC-03: si el usuario abre la app durante un hito activo sin haber respondido, ve la tarjeta in-app con 6 opciones
- [ ] AC-04: respuesta "Con hambre" dispara prompt de hidratación como siguiente acción
- [ ] AC-05: respuesta "Irritable" 2× consecutivas en el mismo ciclo → coach sugiere cerrar ayuno
- [ ] AC-06: check-in respetada la ventana de vigilia (no dispara entre sleepTime y wakeUpTime)
- [ ] AC-07: anti-fatiga: máximo 1 check-in cada 3 horas
- [ ] AC-08: telemetría: los 4 eventos se registran correctamente en Analytics
