# SPEC-234: Coaching de Sueño y Rutina Nocturna Guiada

**Status**: APPROVED-DESIGN  
**Prioridad**: HIGH — el pilar sueño pesa 25% del score pero tiene 0 coaching  
**Fecha**: 2026-06-18  
**Origen**: Auditoría de coaching: cero prompts accionables para sueño. Sin check-in post-despertar, sin rutina pre-sueño, sin higiene guiada.  
**Dependencias**: SPEC-233 (slot de sueño en el carrusel), SPEC-231 (prioridad datos sueño)  
**Esfuerzo estimado**: 3-4 días

---

## 1. Problema

Sueño es el pilar con **mayor peso** en el Score del Día (25%) y el **único sin coaching**:

| Pilar | Peso | Prompts accionables | Coaching in-app | Notificaciones |
|-------|------|---------------------|-----------------|----------------|
| Ayuno | 22% | ✅ cierre protocolo | ✅ tarjeta | ✅ hitos 12/16/18/24h |
| Hidratación | 15% | ✅ vaso de agua | ✅ tarjeta | ✅ cada 30 min |
| Ejercicio | 20% | ✅ registro | ⚠️ solo notif | ✅ ventana 6-20h |
| Nutrición | 18% | ✅ registro comida | ⚠️ solo notif | ✅ próxima comida |
| **Sueño** | **25%** | ❌ **ninguno** | ❌ **ninguno** | ⚠️ solo "hora de dormir" pasiva |

El usuario no recibe acompañamiento para mejorar su sueño. La notificación de `sleepTime` (ID 106) dice "hora de descansar" pero no guía al usuario sobre qué hacer.

---

## 2. Propuesta

Tres momentos de coaching de sueño en el día:

```
                  MAÑANA                    NOCHE                    NOCHE
              (post-despertar)          (90 min antes)           (a sleepTime)
                    │                       │                        │
            ┌───────┴───────┐       ┌───────┴───────┐       ┌───────┴───────┐
            │ "¿Cómo        │       │ Rutina        │       │ "Buenas       │
            │  dormiste?"   │       │ pre-sueño     │       │  noches"      │
            │  ★★★★☆        │       │ guiada        │       │  + resumen    │
            └───────────────┘       └───────────────┘       └───────────────┘
```

### 2.1 Momento A: Check-in Post-Despertar — "¿Cómo dormiste?"

**Trigger**: cuando `isWaitingForWakeUp == true` (overlay "¿Ya despertaste?"), ANTES de cerrar el overlay, presentar la pregunta.

**UI**: escala rápida de 1 toque integrada en el overlay existente de wake-up:

```
┌──────────────────────────────────────┐
│ ☀️ Buenos días                        │
│                                      │
│ ¿Cómo dormiste anoche?               │
│                                      │
│  😫    😐    🙂    😊    🤩           │
│  Mal  Regular Bien  Muy   Excelente  │
│                     bien             │
│                                      │
│ [Confirmar despertar]                │
└──────────────────────────────────────┘
```

**Implementación**: extender el overlay de `dashboard_screen.dart` (línea ~797) para incluir la escala ANTES del botón "Ya desperté". La respuesta se persiste como `SleepLog.subjectiveQuality` (campo que ya existe pero rara vez se llena — solo desde SleepInputSheet "Más detalle").

**Impacto en el score**: `SleepQualityCalculator` ya consume `subjectiveQuality` cuando existe. Al llenarlo sistemáticamente, la calidad del pilar sueño se enriquece automáticamente.

### 2.2 Momento B: Rutina Pre-Sueño Guiada

**Trigger**: notificación a `sleepTime - 90 minutos`. Si el usuario toca, abre `SleepRoutineScreen`.

**Notificación**:
```
┌──────────────────────────────────────┐
│ 🌙 Tu cuerpo se prepara              │
│ En 90 min es tu hora de dormir.      │
│ ¿Activamos tu rutina nocturna?       │
│                                      │
│ [Iniciar rutina]    [Hoy no]         │
└──────────────────────────────────────┘
```

**SleepRoutineScreen**: checklist interactivo de 4 pasos basados en higiene de sueño (Walker 2017, Huberman Lab):

```
┌──────────────────────────────────────┐
│ 🌙 RUTINA NOCTURNA                   │
│                                      │
│ Cada paso que completes mejora tu    │
│ sueño. No necesitas hacer todos.     │
│                                      │
│ ☐ Pantallas en modo oscuro/off       │
│   La luz azul retrasa la melatonina  │
│   30-60 min. Tu cerebro necesita     │
│   oscuridad para prepararse.         │
│                                      │
│ ☐ Última comida hace +2 horas        │
│   Digerir mientras duermes reduce la │
│   calidad del sueño profundo.        │
│                                      │
│ ☐ Temperatura fresca (18-20°C)       │
│   El cuerpo necesita bajar 1-2°C     │
│   para iniciar el sueño profundo.    │
│                                      │
│ ☐ Sin cafeína desde las 14:00        │
│   La vida media de la cafeína es     │
│   5-6 horas. A las 22h todavía      │
│   queda 25% en tu sistema.           │
│                                      │
│ [Completé mi rutina ✓]               │
└──────────────────────────────────────┘
```

**Persistencia**: `SleepRoutineCheckIn` — modelo liviano con los ítems completados. No afecta el score directamente (no queremos castigar), pero alimenta al motor de coaching para personalizar tips futuros. Firestore: `users/{uid}/sleep_routines/{date}`.

**Gamificación suave**: al completar 3+ ítems, mostrar "Preparaste tu cuerpo para un sueño reparador. Descansa bien." Sin presión, sin penalización si no completa todo.

### 2.3 Momento C: "Buenas Noches" con Resumen del Día

**Trigger**: notificación a `sleepTime` exacto (reemplaza la notificación pasiva actual ID 106).

**Contenido enriquecido**: en vez de "Hora de descansar", incluir un mini-resumen motivacional:

```
┌──────────────────────────────────────┐
│ 🌙 Buenas noches                      │
│                                      │
│ Hoy completaste 4 de 5 pilares.     │
│ Tu ayuno de 16h fue impecable.       │
│ Descansa bien — mañana seguimos.     │
└──────────────────────────────────────┘
```

**Generación**: el `CoachingScorer` genera el resumen a partir de `CoachingSnapshot`:
- Pilares completados (count)
- Hito más notable del día (mayor magnitud relativa)
- Tono: siempre positivo, siempre hacia adelante. Alineado con SPEC-169 (tono cálido, sin culpa).

---

## 3. Modelo de Datos

### SleepRoutineCheckIn
```dart
class SleepRoutineCheckIn {
  final String id;           // 'routine_{date}'
  final DateTime date;
  final bool screensOff;
  final bool lastMealOk;
  final bool tempCool;
  final bool noCaffeine;
  final int completedCount;  // 0-4
}
```

### Extensión de SleepLog
No se crea campo nuevo — `subjectiveQuality` (1-5) ya existe. El check-in post-despertar simplemente lo llena de forma sistemática.

---

## 4. Archivos Nuevos

| Archivo | Propósito |
|---------|-----------|
| `dashboard/presentation/sleep_routine_screen.dart` | Checklist interactivo de rutina nocturna |
| `coaching/domain/sleep_routine_check_in.dart` | Modelo de la rutina completada |
| `coaching/data/sleep_routine_repository.dart` | CRUD Firestore `sleep_routines` |
| `coaching/application/sleep_coaching_provider.dart` | Lógica de triggers + resumen nocturno |

## 5. Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `dashboard_screen.dart` | Integrar escala "¿Cómo dormiste?" en overlay de wake-up |
| `sleep_notifier.dart` | `confirmManualWakeUp` acepta `subjectiveQuality` opcional |
| `notification_scheduler.dart` | Reemplazar notif sleep (ID 106) por versión enriquecida + agregar rutina (ID 610) |
| `notification_service_mobile.dart` | IDs 610-619 para coaching de sueño |
| `predictive_trigger_engine.dart` | Nuevo `sleepRoutinePrompt()` |
| `interactive_prompt_orchestrator.dart` (SPEC-233) | Evaluar slot de sueño |

---

## 6. IDs de Notificación

| ID | Propósito |
|----|-----------|
| 106 | "Buenas noches" enriquecido (reemplaza el actual) |
| 610 | Rutina pre-sueño (sleepTime - 90 min) |
| 611 | Check-in "¿Cómo dormiste?" post-despertar (fallback si no se usa overlay) |

---

## 7. Fundamentación Científica

- **Walker (2017)** "Why We Sleep": higiene de sueño (temperatura, luz, cafeína) como predictor de calidad. Cap. 12: "Twelve Tips for Healthy Sleep".
- **Huberman Lab (2021)**: protocolo de luz/oscuridad y temperatura para optimizar onset de melatonina.
- **Sutton et al. (2018)**: eTRF mejora calidad de sueño independientemente de la duración — el timing de la última comida importa más que las horas totales.
- **Principio Elena**: el coaching de sueño NO penaliza. Completar 0 de 4 ítems de la rutina no baja el score. La rutina es una herramienta, no una obligación.

---

## 8. Criterios de Aceptación

- [ ] AC-01: el overlay "¿Ya despertaste?" incluye escala "¿Cómo dormiste?" (5 opciones) antes del botón confirmar
- [ ] AC-02: la respuesta se persiste como `SleepLog.subjectiveQuality` sin crear un log duplicado
- [ ] AC-03: 90 min antes de sleepTime, el usuario recibe notificación de rutina pre-sueño
- [ ] AC-04: al tocar la notificación, se abre SleepRoutineScreen con 4 ítems de checklist
- [ ] AC-05: completar 3+ ítems muestra mensaje positivo de cierre
- [ ] AC-06: a sleepTime exacto, la notificación incluye resumen del día (pilares completados + hito)
- [ ] AC-07: la rutina completada se persiste en Firestore (no afecta score)
- [ ] AC-08: el coaching de sueño respeta el gating SPEC-197 (Free = acceso limitado a rutina)
