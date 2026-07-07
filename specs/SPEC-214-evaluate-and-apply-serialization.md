# SPEC-214 — Serializar evaluateAndApply: eliminar race condition del ciclo metabólico

**Estado:** IMPLEMENTED (2026-06-14) — evaluateAndApply serializado con flag _evaluating + try/finally. commit f4a73b8.
**Versión:** 1.0
**Tipo:** Bug P1 — Race condition entre trigger de 10s y tap de usuario en evaluateAndApply.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~45 min
**Depende de:** `metabolic_cycle_service.dart`, `metabolic_cycle_evaluator_provider.dart`

---

## 1. Problema

`MetabolicCycleService.evaluateAndApply()` se puede llamar desde **dos fuentes simultáneas**:

1. `metabolicPulseProvider` — timer que dispara cada 10 segundos.
2. Listener de `fastingProvider` — dispara en cada transición de estado (false→true, active→closed).

Si el usuario presiona "Iniciar ayuno" exactamente en el momento del tick del pulse:
1. Ambos callers hacen `await repository.fetchOpenCycle(userId)` simultáneamente.
2. Ambos encuentran `null` (no hay ciclo abierto todavía).
3. Ambos llaman `_persistCycle(userId, fresh)` con el mismo `cycleId`.
4. Firestore recibe dos writes del mismo documento casi simultáneamente.

Con `SetOptions(merge: true)` los writes convergen sin corrupción, pero:
- Se generan dos documentos en el log de revisión de Firestore.
- Los logs de AppLogger emiten el warning `[cycle.open.suspicious]` innecesariamente.
- En edge cases muy raros (network partition), los writes pueden diferir en `startedAt`.

---

## 2. Solución

### inc1 — Flag `_evaluating` para serializar llamadas concurrentes

En `MetabolicCycleService`, añadir un flag que bloquea la entrada concurrente:

```dart
// metabolic_cycle_service.dart
class MetabolicCycleService {
  bool _evaluating = false;

  Future<MetabolicCycleCheckResult> evaluateAndApply({
    required String userId,
    required MetabolicCycleEvaluationInput input,
  }) async {
    // Si ya hay una evaluación en curso, esperar o saltar.
    if (_evaluating) {
      AppLogger.info('[cycle.eval] evaluación concurrente ignorada (ya en curso)');
      return MetabolicCycleCheckResult.noop();
    }
    _evaluating = true;
    try {
      return await _evaluateInternal(userId: userId, input: input);
    } finally {
      _evaluating = false;
    }
  }

  // Renombrar la lógica actual a _evaluateInternal
  Future<MetabolicCycleCheckResult> _evaluateInternal({
    required String userId,
    required MetabolicCycleEvaluationInput input,
  }) async {
    // ... lógica actual sin cambios ...
  }
}
```

### inc2 — Alternativa: debounce en el evaluator provider

Si el flag resulta demasiado agresivo (puede silenciar evaluaciones legítimas rápidas),
una alternativa más suave es agregar un debounce de 500ms en `metabolicCycleEvaluatorProvider`:

```dart
// metabolic_cycle_evaluator_provider.dart
Timer? _debounce;

void _scheduleEvaluation() {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    _evaluate();
  });
}
```

**Recomendación:** Usar inc1 (flag) por ser determinístico. El debounce puede silenciar
la primera evaluación legítima en 500ms.

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/metabolic_cycle/application/metabolic_cycle_service.dart` | Flag `_evaluating` + `_evaluateInternal` |

---

## 4. Criterios de aceptación

- [ ] Logs de AppLogger no muestran `[cycle.open.suspicious]` en el flujo normal de
  "iniciar ayuno".
- [ ] En test: dos llamadas concurrentes a `evaluateAndApply` → solo una persiste el ciclo
  (la segunda retorna `noop`).
- [ ] El timer de 10s y el listener de fasting no crean ciclos duplicados.
- [ ] `flutter analyze` sin warnings.
