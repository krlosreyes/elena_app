# SPEC-183 — Bootstrap del FastingNotifier NO debe crear ciclo metabólico

**Estado:** DRAFT v1.0 — pendiente aprobación
**Severidad:** P0 (rompe el día metabólico del usuario)
**Origen:** Bug reportado por Carlos 2026-06-05. Ciclo `2026-06-05T21:32:28.980Z` creado sin acción del usuario.
**Relacionado con:** SPEC-149 (Día Metabólico), SPEC-174 (Evaluator), SPEC-176 (FastingProvider cycle-aware)

---

## 1. Síntoma observado

Carlos abrió la app el 2026-06-05 a las 16:32:28 sin haber iniciado ayuno manualmente. Resultado:

- Se creó automáticamente el ciclo `metabolic_cycles/2026-06-05T21:32:28.980Z` con `startedAt: 16:32:28`.
- Logs registrados ANTES de las 16:32 (exercise_log a las 12:32:57, biometric a las 12:07:08) quedaron FUERA del ciclo.
- Todos los providers cycle-aware (`watchSince(cycle.startedAt)`) filtraron los logs anteriores.
- El dashboard mostró todos los pilares en 0 a pesar de tener datos reales en Firestore.

## 2. Mecanismo del bug

### 2.1 Cadena de llamadas que dispara el bug

1. **App boot.** El `FastingNotifier` se construye con `state = FastingState.initial()` (`isActive: false`).
2. **Restauración desde Firestore.** El listener al `lastFastingIntervalProvider` (líneas 53-92 de `fasting_notifier.dart`) recibe un interval persistido con `isFasting: true`:
   ```dart
   state = state.copyWith(
     startTime: interval.startTime,
     isActive: interval.isFasting,  // ← transición false → true
     ...
   );
   ```
3. **Detector del evaluator.** El `metabolicCycleEvaluatorProvider` (líneas 50-62) escucha:
   ```dart
   ref.listen<FastingState>(fastingProvider, (previous, next) {
     if (previous != null && !previous.isActive && next.isActive) {
       _evaluate(ref, DateTime.now(),
         newFastingTriggered: true,
         newFastingAt: next.startTime);
     }
   });
   ```
   Como `previous.isActive: false` y `next.isActive: true`, dispara `newFastingTriggered=true`.
4. **Creación del ciclo.** El `MetabolicCycleService.evaluateAndApply` recibe `newFastingStartedExplicitly: true`. Como no hay ciclo abierto previo (`fetchOpenCycle == null`), crea ciclo nuevo con `startedAt = newFastingAt`.

### 2.2 Causa raíz

**El evaluator NO distingue entre dos tipos de transición `isActive: false → true`:**

| Origen | Significado | Debería crear ciclo |
|--------|-------------|---------------------|
| **Bootstrap** — listener restaura desde Firestore | Continuación de un ayuno previo, no inicio | ❌ NO |
| **User tap** — `startFastingManual()` desde UI | Inicio explícito del usuario | ✅ SÍ |

El bug es que el evaluator trata ambos casos como "inicio explícito".

## 3. Diseño del fix

### 3.1 Principio

Añadir al `FastingState` un enum `FastingActivationSource` que indique de dónde proviene la activación. El evaluator usa este campo para decidir si dispara la creación de ciclo.

### 3.2 Modelo de datos

```dart
// fasting_state.dart — extender el state
enum FastingActivationSource {
  /// Estado inicial — `isActive: false`. Sin transición aún.
  none,

  /// El listener restauró el state desde Firestore al boot.
  /// NO debe disparar creación de ciclo metabólico.
  bootstrap,

  /// El usuario presionó "iniciar ayuno" en la UI.
  /// SÍ debe disparar creación de ciclo metabólico.
  userInitiated,
}

class FastingState {
  // ... campos existentes
  final FastingActivationSource activationSource;

  const FastingState({
    ...
    this.activationSource = FastingActivationSource.none,
  });
}
```

### 3.3 Cambio en `FastingNotifier`

```dart
// fasting_notifier.dart — el listener marca bootstrap
_ref.listen(lastFastingIntervalProvider, (previous, next) {
  next.when(
    data: (interval) {
      if (interval == null) {
        state = state.copyWith(
          isActive: false,
          activationSource: FastingActivationSource.none,
          ...
        );
      } else {
        state = state.copyWith(
          startTime: interval.startTime,
          isActive: interval.isFasting,
          // SPEC-183: la restauración desde Firestore NO es inicio
          // explícito del usuario. El evaluator del ciclo NO debe
          // tratarla como tal.
          activationSource: interval.isFasting
              ? FastingActivationSource.bootstrap
              : FastingActivationSource.none,
          ...
        );
      }
    },
    ...
  );
}, fireImmediately: true);

// startFastingManual marca userInitiated
Future<void> startFastingManual(DateTime startTime) async {
  ...
  state = state.copyWith(
    isActive: true,
    activationSource: FastingActivationSource.userInitiated,  // ← clave
    ...
  );
  ...
}
```

### 3.4 Cambio en el evaluator

```dart
// metabolic_cycle_evaluator_provider.dart
ref.listen<FastingState>(
  fastingProvider,
  (previous, next) {
    final transitioned = previous != null && !previous.isActive && next.isActive;
    final isUserInitiated =
        next.activationSource == FastingActivationSource.userInitiated;

    // SPEC-183: solo disparar creación de ciclo si el ayuno fue
    // iniciado EXPLÍCITAMENTE por el usuario en esta sesión. Las
    // transiciones por bootstrap (restauración desde Firestore al
    // arrancar la app) NO deben crear ciclo nuevo.
    if (transitioned && isUserInitiated) {
      _evaluate(ref, DateTime.now(),
        newFastingTriggered: true,
        newFastingAt: next.startTime);
    }
  },
);
```

## 4. Migración / Limpieza

### 4.1 Ciclos huérfanos ya creados

Los usuarios que ya sufrieron este bug tienen ciclos huérfanos en `metabolic_cycles/*` con `startedAt` igual a la hora del bootstrap. **No los borramos automáticamente** porque puede haber actividad legítima posterior al bootstrap dentro de ese ciclo.

Mitigación para Carlos: borrar manualmente el doc afectado en Firebase Console.

### 4.2 Estado en Firestore

El enum `FastingActivationSource` vive en memoria. NO se persiste en Firestore. Cada bootstrap arranca con `none`, restaura a `bootstrap` si hay interval activo. El usuario reinicia el ciclo legítimo presionando "iniciar ayuno" cuando corresponda.

## 5. Tests

- `fasting_notifier_test.dart` (nuevo o extender):
  - boot con interval `isFasting=true` → state.activationSource = bootstrap
  - boot con interval null → state.activationSource = none
  - `startFastingManual()` → state.activationSource = userInitiated
- `metabolic_cycle_evaluator_test.dart` (nuevo o extender):
  - transición false→true con `activationSource = bootstrap` → NO llama `evaluateAndApply` con `newFastingTriggered`
  - transición false→true con `activationSource = userInitiated` → SÍ llama con `newFastingTriggered: true`
  - transición true→false (cierre) → no afectada

## 6. Riesgos

| Riesgo | Mitigación |
|--------|------------|
| Usuario cuyo ayuno legítimo NO genere ciclo si reinicia la app | El ciclo del ayuno legítimo ya está creado de antes; el bootstrap solo restaura state, no necesita recrear ciclo. Si por algún motivo el ciclo se perdió pero el ayuno persiste, el usuario lo nota y "reinicia ayuno" desde UI (acción consciente). |
| Race entre listener de Firestore y `startFastingManual()` | Improbable: `startFastingManual` escribe a Firestore y luego setea state local. El listener no debería sobrescribir con bootstrap. Test E2E lo cubre. |
| Datos huérfanos pre-fix | Documentado en §4.1. Borrado manual del ciclo afectado. |

## 7. Plan de entrega

- **Bloque A** (~15 min): añadir enum `FastingActivationSource` + campo en `FastingState` + tests del state.
- **Bloque B** (~20 min): modificar listener del notifier + `startFastingManual` + tests del notifier.
- **Bloque C** (~15 min): modificar evaluator + tests del evaluator.
- **Bloque D** (~10 min): borrado manual del ciclo huérfano + verificación E2E + commit/push.

Total estimado: **~1h**.

## 8. Decisión

Para implementar, requiero `ok recomendación` o ajustes específicos.

---

## Referencias internas

- `lib/src/features/dashboard/application/fasting_notifier.dart`
- `lib/src/features/metabolic_cycle/application/metabolic_cycle_evaluator_provider.dart`
- `lib/src/features/metabolic_cycle/application/metabolic_cycle_service.dart`
- Memoria: [[metabolic-day-anchors-to-user]]
