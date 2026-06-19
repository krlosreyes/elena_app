# SPEC-233: Prompts Interactivos para los 5 Pilares

**Status**: APPROVED-DESIGN  
**Prioridad**: HIGH — multiplica la superficie de coaching 5× con código existente  
**Fecha**: 2026-06-18  
**Origen**: Auditoría de coaching: `PredictiveTriggerEngine` tiene `fastingPrompt()`, `exercisePrompt()`, `nutritionPrompt()` implementados pero sin provider ni tarjeta in-app que los consuma. Solo hidratación tiene tarjeta interactiva.  
**Dependencias**: SPEC-199 Fase A (InteractiveCoachingCard), SPEC-224 (PredictiveTriggerEngine), SPEC-232 (check-ins)  
**Esfuerzo estimado**: 2-3 días

---

## 1. Problema

El `PredictiveTriggerEngine` ya tiene funciones puras para los 4 pilares accionables (hidratación, ayuno, ejercicio, nutrición), pero la `InteractiveCoachingCard` **solo consume hidratación**. Los otros 3 pilares son código muerto internamente — solo llegan al usuario vía notificación push, no como tarjetas in-app.

El 5° pilar (sueño) no tiene ningún prompt — ni en notificación ni en tarjeta. SPEC-234 lo cubre en profundidad, pero esta spec le da su slot en el carrusel.

Resultado: el usuario que abre la app solo ve "¿Ya tomaste tu vaso?" repetidamente. La percepción es de coaching unidimensional.

---

## 2. Propuesta

### 2.1 Arquitectura: Carrusel de Prompts

Reemplazar la tarjeta única `InteractiveCoachingCard` por un **carrusel rotativo** que muestra el prompt más relevante del momento. El `PredictiveTriggerEngine` ya decide cuál suprimir — solo falta exponerlo.

```
PredictiveTriggerEngine (ya existe, funciones puras)
    ↓
InteractivePromptOrchestrator (NUEVO — evalúa los 5 pilares)
    ↓
interactivePromptProvider (refactorizado — emite el prompt ganador)
    ↓
InteractiveCoachingCard (refactorizada — renderiza cualquier pilar)
```

### 2.2 InteractivePromptOrchestrator

Clase pura (sin I/O) que recibe el estado actual de los 5 pilares y devuelve el prompt más urgente:

```dart
class InteractivePromptOrchestrator {
  /// Evalúa los 5 pilares y devuelve el prompt más relevante, o null.
  /// Prioridad: check-in emocional (SPEC-232) > ayuno > hidratación > nutrición > ejercicio > sueño.
  static ActionablePrompt? evaluate({
    // Hidratación
    required bool hydrationGoalReached,
    required Duration? sinceLastGlass,
    // Ayuno
    required bool fastingActive,
    required bool protocolReached,
    // Ejercicio
    required bool exerciseGoalReached,
    // Nutrición
    required bool windowOpen,
    required Duration? sinceLastMeal,
    // Sueño (SPEC-234)
    required bool sleepRoutineTime,  // ¿estamos a 90min de sleepTime?
    required bool sleepLogged,       // ¿ya hay log de sueño hoy?
    // Contexto
    required DateTime now,
    required int wakeHour,
    required int sleepHour,
    // Anti-fatiga
    required Set<String> dismissedToday,
  }) { ... }
}
```

**Prioridad dinámica**: no es una lista fija. El orchestrator pondera:
1. **Urgencia temporal**: cerrar ayuno cuando el protocolo se alcanzó tiene ventana corta
2. **Pilar más débil**: si el `CoachingSnapshot.weakPillar` es ejercicio, el prompt de ejercicio sube de prioridad
3. **Anti-fatiga**: si el usuario descartó hidratación 2× hoy, rotar a otro pilar

### 2.3 Prompts por Pilar

#### Hidratación (ya existe — sin cambios funcionales)
```
┌──────────────────────────────────────┐
│ 💧 Momento de hidratarte             │
│ Un vaso ahora mantiene tu energía.   │
│                                      │
│ [Sí, lo registro]    [Ahora no]      │
└──────────────────────────────────────┘
```

#### Ayuno — Cierre de protocolo
```
┌──────────────────────────────────────┐
│ 🎉 ¡Protocolo completado!            │
│ Alcanzaste tu meta de ayuno.         │
│ ¿Lo cerramos?                        │
│                                      │
│ [Cerrar ayuno]    [Seguir un poco más]│
└──────────────────────────────────────┘
```
**Acción "Cerrar ayuno"**: llama `ref.read(fastingProvider.notifier).openEatingWindow()` vía `CoachingActionRouter`.

#### Ejercicio — Recordatorio contextual
```
┌──────────────────────────────────────┐
│ 💪 Momento de moverte                │
│ 30 min de actividad hoy marcan      │
│ la diferencia. ¿Ya lo hiciste?       │
│                                      │
│ [Sí, lo registro]    [Luego lo hago] │
└──────────────────────────────────────┘
```
**Acción "Sí, lo registro"**: abre `ExerciseInputSheet` (registro rápido) o registra ejercicio genérico (30 min caminata) si se prefiere 1-toque.

#### Nutrición — Ventana abierta
```
┌──────────────────────────────────────┐
│ 🍽 Tu ventana está abierta           │
│ Es buen momento para tu próxima      │
│ comida. ¿Ya comiste?                 │
│                                      │
│ [Registrar comida]    [Aún no]       │
└──────────────────────────────────────┘
```
**Acción "Registrar comida"**: abre `NutritionInputSheet` (registro rápido de calidad).

#### Sueño — Rutina nocturna (slot de SPEC-234)
```
┌──────────────────────────────────────┐
│ 🌙 Tu cuerpo se prepara              │
│ En 90 min es tu hora de dormir.      │
│ ¿Iniciamos tu rutina?                │
│                                      │
│ [Iniciar rutina]    [Hoy no]         │
└──────────────────────────────────────┘
```
**Acción "Iniciar rutina"**: navega a `SleepRoutineScreen` (SPEC-234).

### 2.4 Refactorización de InteractiveCoachingCard

La tarjeta actual está hardcodeada para hidratación. Refactorizar para que sea **agnóstica del pilar**:

```dart
class InteractiveCoachingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(interactivePromptProvider);  // ya no es solo hydration
    if (prompt == null) return const SizedBox.shrink();

    return _buildCard(
      prompt: prompt,
      pillarColor: _colorForPillar(prompt),  // azul agua, naranja ayuno, verde ejercicio...
      onPrimary: () => _handleAction(ref, prompt.primaryAction),
      onSecondary: () => _handleAction(ref, prompt.secondaryAction),
    );
  }
}
```

### 2.5 CoachingActionRouter — nuevas acciones

Extender el router para manejar las acciones de los 3 pilares nuevos:

| PromptActionType | Handler |
|------------------|---------|
| `logWater` | Ya existe — `addWater()` |
| `closeFasting` | `fastingNotifier.openEatingWindow()` |
| `logExercise` | Navegar a `ExerciseInputSheet` o registrar default |
| `logMeal` | Navegar a `NutritionInputSheet` o registrar default |
| `startSleepRoutine` | Navegar a `SleepRoutineScreen` (SPEC-234) |
| `snooze` | Ya existe — ocultar por 15 min |

**Decisión UX para ejercicio y nutrición**: a diferencia de hidratación (1 vaso = acción atómica), ejercicio y nutrición requieren datos del usuario (tipo, duración, calidad). La acción primaria **abre el sheet de registro** en lugar de registrar automáticamente. Esto mantiene la calidad del dato.

---

## 3. Archivos Nuevos

| Archivo | Propósito |
|---------|-----------|
| `coaching/application/interactive_prompt_orchestrator.dart` | Evalúa los 5 pilares y elige prompt |

## 4. Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `interactive_prompt_provider.dart` | Consumir orchestrator en vez de solo hydration |
| `interactive_coaching_card.dart` | Renderizar cualquier pilar (color, icono, acciones) |
| `coaching_action_router.dart` | Handlers para `closeFasting`, `logExercise`, `logMeal`, `startSleepRoutine` |
| `actionable_prompt.dart` | Nuevo `PromptActionType.startSleepRoutine` |
| `pending_action_queue.dart` | Serializar/deserializar las nuevas acciones |

---

## 5. Supresión Contextual (resumen de reglas existentes + nuevas)

| Pilar | Suprimir si... |
|-------|----------------|
| Hidratación | meta cumplida, fuera de vigilia, vaso < 60 min, hora ≥ 21 |
| Ayuno | no activo, protocolo no alcanzado |
| Ejercicio | meta cumplida, hora < 6 o ≥ 20 |
| Nutrición | ventana cerrada, comió hace < 2h |
| Sueño | ya registró sueño hoy, hora < (sleepTime - 2h) |

---

## 6. Criterios de Aceptación

- [ ] AC-01: al abrir la app, la tarjeta interactiva muestra el prompt del pilar más relevante (no siempre hidratación)
- [ ] AC-02: el prompt de ayuno aparece cuando el protocolo se alcanza y permite cerrar con 1 toque
- [ ] AC-03: el prompt de ejercicio abre el sheet de registro al tocar "Sí, lo registro"
- [ ] AC-04: el prompt de nutrición abre el sheet de registro al tocar "Registrar comida"
- [ ] AC-05: el prompt de sueño aparece ~90 min antes de sleepTime y navega a rutina nocturna
- [ ] AC-06: si el usuario descarta un pilar 2× en el día, el orchestrator rota a otro
- [ ] AC-07: el pilar débil del `CoachingSnapshot` tiene prioridad en la rotación
- [ ] AC-08: los prompts de ayuno/ejercicio/nutrición funcionan vía notificación push + PendingActionQueue (sin abrir app)
