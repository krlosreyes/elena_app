# SPEC-229: Coherencia del Score del Día — Análisis y Corrección

**Status**: APPROVED-DESIGN  
**Prioridad**: CRITICAL — afecta la métrica principal del usuario  
**Fecha**: 2026-06-18  
**Origen**: Discrepancia reportada por Carlos: "los últimos días mi score estuvo por encima de 70pts" pero `MetabolicCycle.dailyScore` registra 34-49.

---

## 1. Hallazgo Principal

El score que el usuario VE en el Dashboard diverge del score que se GRABA al cerrar el ciclo metabólico. La causa raíz no es un solo bug sino **5 fallas interconectadas** en el pipeline de datos.

### Evidencia de Firestore (charlie2@gmail, semana 10-17 jun 2026)

| closedAt (local)    | dailyScore | liveScore | closureReason          | fasting | exercise | nutrition | hydration | sleep |
|---------------------|-----------|-----------|------------------------|---------|----------|-----------|-----------|-------|
| Jun 12, 11:30pm     | 35        | —         | fallback3hAfterWindow  | 0.41    | 0        | 0         | 0.09      | 1.0   |
| Jun 14, 8:11am      | 16        | —         | fallback3hAfterWindow  | 0        | 0        | 0         | 0.18      | 0.55  |
| Jun 14, 1:31pm      | 40        | —         | fallbackSleepDetected  | 0        | 0        | 0.6       | 0.27      | 1.0   |
| Jun 14, 11:30pm     | 49        | —         | fallback3hAfterWindow  | 0.32    | 0.63     | 0         | 0.27      | 1.0   |
| Jun 15, 11:30pm     | 47        | 47        | fallback3hAfterWindow  | 0.35    | 0.67     | 0         | 0.09      | 1.0   |
| Jun 16, 12:25pm     | **76**    | **76**    | fallbackSleepDetected  | 0.84    | 1.77     | 0.6       | 0.45      | 0.81  |
| Jun 16, 11:31pm     | 34        | 34        | fallback3hAfterWindow  | 0.37    | 0        | 0         | 0.36      | 0.81  |
| Jun 17, 11:30pm     | 39        | 39        | fallback3hAfterWindow  | 0.41    | 0        | 0         | 0.64      | 0.81  |

**Contraste**: ciclos de inicio de junio (manualNextFasting) → scores 70-95.

---

## 2. Los 5 Bugs Identificados

### BUG-229-A: liveScore se sobreescribe antes del cierre (CRÍTICO)

**Archivo**: `metabolic_cycle_evaluator_provider.dart`, líneas 194-208  
**Severidad**: CRÍTICA — destruye el score del usuario

**Mecanismo**: En cada tick del evaluador (10s), se ejecuta esta secuencia:

```
1. dailyScore = ref.read(displayDailyScoreProvider)  → valor ACTUAL (puede ser bajo)
2. updateLiveScore(cycleId, dailyScore)               → SOBREESCRIBE el buen valor en Firestore
3. evaluateAndApply(input)                             → lee el ciclo con liveScore ya sobreescrito
4. scoreAtClose = openCycle.liveScore ?? input.score   → usa el valor bajo
5. Ciclo cierra con dailyScore = valor bajo
```

**Evidencia**: En TODOS los ciclos recientes `liveScore == dailyScore`. Si liveScore fuera un high water mark, debería ser ≥ dailyScore.

**Ejemplo concreto**: Jun 17
- 3pm: usuario activo, liveScore se stampa como ~50-60 (magnitudes parciales buenas)
- 5pm: nuevo ciclo abre, liveScore del nuevo = 30 (fasting recién arranca)
- 11:30pm: evaluador stampa liveScore=39 (magnitudes actuales), cierra ciclo con 39.
- El pico real del ciclo (quizá 50-60) se perdió.

**Fix**: liveScore HIGH WATER MARK.

```dart
// ANTES (bug):
if (openCycleSnap.liveScore != dailyScore) {
  updateLiveScore(userId, cycleId, dailyScore);
}

// DESPUÉS (fix):
final existingLive = openCycleSnap.liveScore ?? 0;
final newLiveScore = dailyScore > existingLive ? dailyScore : existingLive;
if (openCycleSnap.liveScore != newLiveScore) {
  updateLiveScore(userId, cycleId, newLiveScore);
}
```

---

### BUG-229-B: Fallback trigger usa `expectedWindowCloseTime` stale (CRÍTICO)

**Archivo**: `metabolic_cycle_evaluator_provider.dart` → `eating_window_provider.dart`  
**Severidad**: CRÍTICA — causa cierres prematuros y ciclos de 6h

**Mecanismo**: Cuando hay un ayuno activo (`isFasting=true`), el `EatingWindowProvider` computa `windowEnd` usando el **schedule óptimo del día actual**, no la ventana real del ciclo:

```dart
// eating_window_state.dart (caso isFasting=true):
final DateTime fallbackStart = _fallbackWindowStart(user, now);
return EatingWindowState(
  windowEnd: fallbackStart.add(Duration(hours: hours)), // ← HOY, no mañana
  status: EatingWindowStatus.unknown,
);
```

Para un 16:8 con óptimo 10am:
- `windowEnd = hoy 10am + 8h = hoy 6pm`
- Si el usuario inicia ayuno a las 5pm, el evaluador ve `now(9pm) - 6pm = 3h` → ¡FALLBACK FIRES!
- Pero la ventana real de ESTE ciclo no abre hasta mañana 9am.

**Evidencia**: Los ciclos de Jun 14-17 duran **5-6.5 horas** con un protocolo de 16:8 (deberían durar ~24h). Todos cierran a las 11:30pm por `fallback3hAfterWindow`.

**Fix**: El evaluador debe ignorar `expectedWindowCloseTime` cuando el ciclo lleva menos de `targetFastingHours` activo (la ventana de este ciclo aún no abrió).

```dart
// En _evaluate(), antes de pasar al service:
DateTime? effectiveWindowClose = eatingWindow?.windowEnd;
if (openCycle != null && effectiveWindowClose != null) {
  final targetFastingHours = fastingHoursForProtocol(openCycle.fastingProtocol);
  final cycleAge = now.difference(openCycle.startedAt);
  if (targetFastingHours != null && 
      cycleAge < Duration(hours: targetFastingHours)) {
    // El ayuno de este ciclo no ha terminado → la ventana de hoy no aplica.
    effectiveWindowClose = null;
  }
}
```

---

### BUG-229-C: `displayDailyScore` cambia de fuente silenciosamente

**Archivo**: `daily_score_provider.dart`, líneas 79-97  
**Severidad**: MEDIA — UX confusa, no pérdida de datos

**Mecanismo**: `displayDailyScoreProvider` tiene dos modos:
1. **Con ciclo abierto**: `CycleScoreComputer.compute(streakEntry.magnitudes)` — score cycle-aware
2. **Sin ciclo abierto**: `dailyScoreProvider` → `streakEntry.dailyQualityScore * 100` — score calendario

Ambos leen las mismas magnitudes del streakEntry, pero la **fórmula es idéntica** (mismos pesos SPEC-140). La diferencia real surge cuando:
- Sin ciclo → el streak acumula todo el día (sleep + exercise + nutrition de hoy)
- Con ciclo → el streak también acumula todo el día, PERO la magnitud de ayuno cambia drásticamente al iniciar un nuevo fasting (0h/16h = 0.0)

**Resultado**: El usuario ve 70+ cuando no hay ciclo (fasting del día ya está persistido como completado por `closedProgressToday`). Al abrir un nuevo ciclo e iniciar un nuevo ayuno, fastingMagnitude cae de ~1.0 a 0.0 → score cae ~22 puntos instantáneamente.

**Fix integrado con BUG-229-A**: Si el liveScore es high water mark, captura el 70+ antes de que caiga. No requiere cambio adicional.

---

### BUG-229-D: Magnitudes del streak no se persisten en cada cambio

**Archivo**: `streak_notifier.dart`, líneas 306-311  
**Severidad**: BAJA — solo afecta si la app se mata y reinicia mid-day

**Mecanismo**: La persistencia del StreakEntry a Firestore solo ocurre cuando cambia `pillarsCompleted`:

```dart
if (newEntry.qualifiesForStreak != prevQualified ||
    newEntry.pillarsCompleted != prevPillars) {
  _persistToday(newEntry);
}
```

Mejoras de magnitud que no cruzan un umbral (e.g., hydration 0.5→0.8 sin llegar al 75%) NO se persisten. Si la app se mata, el StreakEntry en Firestore tiene magnitudes viejas.

**Impacto en el score**: El evaluador lee magnitudes del `streakProvider` (in-memory), no de Firestore. Dentro de la misma sesión los valores son correctos. Solo hay riesgo si la app reinicia justo antes de un cierre.

**Fix**: Agregar condición de persistencia por cambio significativo de magnitudes:

```dart
final magChanged = prev != null && (
  (newEntry.fastingMagnitude ?? 0) - (prev.fastingMagnitude ?? 0) > 0.1 ||
  (newEntry.hydrationMagnitude ?? 0) - (prev.hydrationMagnitude ?? 0) > 0.1 ||
  // ... etc.
);
if (newEntry.qualifiesForStreak != prevQualified ||
    newEntry.pillarsCompleted != prevPillars ||
    magChanged) {
  _persistToday(newEntry);
}
```

---

### BUG-229-E: Timezone en bucketing de la gráfica

**Archivo**: `temporal_aggregator.dart`, líneas 63-66  
**Severidad**: BAJA — cosmético, desplaza barras 1 día

**Mecanismo**: `closedAt` llega como UTC desde Firestore. El bucketing usa:

```dart
DateTime(date.year, date.month, date.day) // date = UTC DateTime
```

Para UTC-5, un ciclo cerrado a las 11:30pm local = 4:30am UTC del día siguiente → el bucket se asigna al día siguiente.

**Evidencia**: Un cierre del Jun 17 11:30pm local aparece en Jun 18 en la gráfica.

**Fix**: Convertir a local antes de bucketear:

```dart
case AggregationMode.daily:
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
```

---

## 3. Impacto Combinado

Los bugs se amplifican mutuamente:

```
BUG-B (fallback prematuro) → ciclos de 6h con magnitudes parciales
  → BUG-A (liveScore overwrite) → el pico del día se pierde
    → BUG-C (cambio de fuente) → el 70+ que vio el usuario nunca se captura
      → BUG-E (timezone) → las barras se desplazan +1 día
        → Resultado: gráfica muestra 35-49 cuando el usuario vivió 70+
```

Si solo BUG-B se resuelve: los ciclos duran ~24h, las magnitudes son completas, el score es alto.
Si solo BUG-A se resuelve: los ciclos cortos siguen, pero al menos el pico de cada ciclo corto se preserva.
Si AMBOS se resuelven: el score en la gráfica refleja fielmente la experiencia del usuario.

---

## 4. Plan de Implementación

### Incremento 1 — Fix crítico (BUG-229-A + BUG-229-B)

**Archivos a tocar**:
- `metabolic_cycle_evaluator_provider.dart` — liveScore HWM + guard de windowClose
- `metabolic_cycle_repository_impl.dart` — (sin cambios, `updateLiveScore` ya es merge)

**Cambios en el evaluador**:

1. **liveScore high water mark**: `max(existing, new)` en vez de overwrite
2. **Guard de fallback prematuro**: si el ciclo lleva menos tiempo que `targetFastingHours`, ignorar `expectedWindowCloseTime` → el trigger `fallback3hAfterWindow` no dispara hasta que la ventana de alimentación de ESTE ciclo efectivamente cierre.

**Migración SPEC-229**: Re-procesar ciclos cerrados entre Jun 10-18 que tengan `liveScore < peakScore estimado`. Criterio: si el ciclo cerró por fallback Y `liveScore == dailyScore` (señal de overwrite), recalcular usando las magnitudes del feedback. No aplica — las magnitudes del cierre ya son las degradadas. Los ciclos históricos afectados son irrecuperables sin los logs del streak. Marcar como deuda y que los nuevos ciclos sean correctos.

### Incremento 2 — Fix de calidad (BUG-229-D + BUG-229-E)

**Archivos a tocar**:
- `streak_notifier.dart` — persistencia por cambio de magnitud
- `temporal_aggregator.dart` — toLocal() antes de bucketear

### Incremento 3 — Migración datos históricos (opcional)

- Los ciclos del 10-17 jun con scores artificialmente bajos NO son recuperables (las magnitudes reales se perdieron).
- Opción: marcar estos ciclos como `migrated: false` y excluirlos de la gráfica, o dejar que el promedio se corrija naturalmente con ciclos nuevos correctos.

---

## 5. Validación

### Test manual post-incremento 1:
1. Abrir la app, esperar score > 50 en Dashboard
2. Verificar en Firestore que `liveScore` del ciclo abierto refleja el pico
3. Cerrar la app, esperar al fallback
4. Verificar que `dailyScore` del ciclo cerrado ≥ liveScore previo al cierre
5. Verificar que NO se crean ciclos de < 12h con protocolo 16:8

### Test automático:
- Unit test: `CycleScoreComputer.compute()` con magnitudes parciales → score esperado
- Unit test: liveScore HWM — `max(76, 39) == 76`
- Unit test: fallback guard — ciclo de 3h con 16:8 → `shouldClose()` returns null (no `fallback3hAfterWindow`)

---

## 6. Archivos Afectados (resumen)

| Archivo | Bug | Cambio |
|---------|-----|--------|
| `metabolic_cycle_evaluator_provider.dart` | A, B | HWM + guard windowClose |
| `streak_notifier.dart` | D | Persistencia por magnitud |
| `temporal_aggregator.dart` | E | toLocal() |
| `eating_window_provider.dart` | — | Sin cambios (el fix va en el evaluador) |
| `daily_score_provider.dart` | C | Sin cambios (resuelto transitivamente por A) |

---

## 7. Invariantes Post-Fix

1. **`liveScore` solo puede subir** dentro del mismo ciclo (high water mark)
2. **`dailyScore` al cierre ≥ liveScore** del último stamp antes del cierre
3. **`fallback3hAfterWindow` NUNCA dispara** antes de que transcurra `targetFastingHours` desde `startedAt`
4. **Barras de la gráfica** se ubican en el día LOCAL del cierre, no UTC
5. **Magnitudes del streak** se persisten cuando cambian > 0.1 en cualquier pilar

Estos invariantes deben ser verificables por tests unitarios y deben documentarse como reglas de regresión.
