# SPEC-171 — Score del Día anclado al ciclo metabólico

**Estado:** CLOSED 2026-06-04
**Versión:** 1.0
**Tipo:** Refactor — cierre de deuda técnica SPEC-149 §13.7
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2.5 §3.1 (doc `docs/PLAN_DELIVERY_2026_06_04.md`)
**Estimación:** ~0.5 día (1 computer + 1 provider + 1 callsite + tests)
**Marco normativo:** `IMR_BIBLIOGRAPHY.md` §13 (Día Metabólico), `CONSTITUTION.md`
**Depende de:** SPEC-140 (Score del Día rebalanceado), SPEC-149 (Día Metabólico), SPEC-149.2 (cycle-aware streams).
**Bloquea:** SPEC-170 (UI dual de scores) — Necesita que el "HOY" del header ya sea cíclico antes de mostrarlo lado a lado con el IMR.

---

## 1. Contexto

SPEC-149 §13.7 documentó esta deuda al cierre del Día Metabólico:

> *"Modificación del `dailyScoreProvider` para anclar al ciclo en lugar del día calendárico — el provider sigue mostrando Score del Día CALENDÁRICO en el header de PILARES HOY. El refactor profundo del provider va en Ola 2."*

Hoy en `lib/src/features/streak/application/daily_score_provider.dart`:

```dart
final dailyScoreProvider = Provider<int>((ref) {
  final streak = ref.watch(streakProvider);
  return computeDailyScore(streak.todayEntry);
});
```

`StreakEntry.todayEntry` se persiste con `date = dayKeyIso(now)` (calendárico, SPEC-138). Las magnitudes que combina (`fastingMagnitude`, etc.) sí provienen de providers cíclicos post SPEC-149.2 — pero el **rótulo** del entry es calendárico y el snapshot se guarda en `daily_summary/{YYYYMMDD}`. Esto produce dos ambigüedades:

1. En el **cruce de medianoche con ciclo abierto**, el `StreakEntry` resetea al cambiar `date` pero el ciclo sigue vivo — el header muestra un score caído sin que el usuario haya cerrado nada.
2. En el **cierre del ciclo a media tarde** (caso típico OMAD), el `daily_summary` sigue rotulado al día calendárico, no al ciclo cerrado — el sitio web Metamorfosis Real lee ese summary y muestra un día parcial.

### 1.1 — Por qué importa para el pivot

El pivot "active coaching" (memoria `strategic-pivot-passive-to-active-coaching`) requiere que la métrica de "cómo viví este día" se ancle a la unidad biológicamente significativa, no al reloj. El usuario que cumple sus 5 pilares dentro del ciclo no debe ver el score caer al cruzar medianoche.

### 1.2 — Por qué NO romper `daily_summary` ni el provider legacy

`daily_summary/{YYYYMMDD}` es consumido por el **sitio Astro Metamorfosis Real** vía mirror canónico (SPEC-82). Cambiarlo a ciclo metabólico rompería contratos externos que no controlamos. Decisión SPEC-149 §13.5 vigente: `DayBoundaryResolver` sigue dueño del calendárico (web, racha legacy), `MetabolicCycleResolver` dueño del coaching del usuario en la app.

Además, `dailyScoreProvider` lo lee el `metabolic_cycle_evaluator_provider` (línea 88) para construir el snapshot del ciclo al cerrar. Si se vuelve cíclico, se crea dependencia circular: ciclo → score → ciclo.

## 2. Decisión de producto

### 2.1 — Provider nuevo `displayDailyScoreProvider`, NO refactor del legacy

Crear un provider nuevo que decide qué mostrar al usuario:

- Si hay ciclo abierto con protocolo conocido (no 'Ninguno' / no null): score cíclico EN VIVO computado desde magnitudes de los providers cyclicos (`fastingProvider`, `sleepProvider`, etc.) aplicando la misma fórmula de `StreakEntry.dailyQualityScore`.
- Sino: fallback a `dailyScoreProvider` legacy (calendárico).

Esto:
- **Cierra la deuda** sin tocar el provider legacy ni `daily_summary`.
- **Evita la dependencia circular** con el evaluador del ciclo.
- **Es testeable** porque el cómputo del cíclico es función pura.

### 2.2 — Misma fórmula, misma bibliografía

El cíclico usa los mismos pesos (Sleep 25%, Fasting 22%, Exercise 20%, Nutrition 18%, Hydration 15%) y la misma regla de renormalización ante magnitudes null. Esto preserva la promesa de SPEC-140 ("el 100 es alcanzable") y la bibliografía existente (`IMR_BIBLIOGRAPHY.md` §6).

### 2.3 — Delta vs ayer del cíclico

`displayDailyScoreDeltaProvider` calcula la diferencia entre el score del **ciclo actual** (en vivo) y el score del **último ciclo cerrado** (persistido en `metabolic_cycles`). Si no hay ciclo cerrado previo, retorna null (mismo contrato que el delta legacy).

### 2.4 — El header pasa al nuevo provider

`dashboard_screen.dart` líneas 342-343 cambian de `dailyScoreProvider` / `dailyScoreDeltaProvider` a las versiones `display*`. **Cero cambios visuales** — solo cambia la fuente.

### 2.5 — Provider legacy `dailyScoreProvider` queda intacto

Sigue siendo consumido por `metabolic_cycle_evaluator_provider` para construir el snapshot al cierre. Esto es deliberado: el snapshot persistido en `metabolic_cycles/{cycleId}.dailyScore` debe coincidir con lo que el StreakEntry rotula como "hoy" para no romper las estadísticas históricas de SPEC-141 (IMR longitudinal Ola 3).

## 3. Lo que NO se hace (límites duros)

- **NO se modifica `daily_summary/{YYYYMMDD}`.** Sigue calendárico (contrato sitio web SPEC-82).
- **NO se modifica `StreakEntry`** ni su persistencia.
- **NO se modifica el evaluador del ciclo.** Sigue consumiendo `dailyScoreProvider` legacy.
- **NO se reescribe la fórmula de cómputo.** Misma de SPEC-140.
- **NO se toca SPEC-141** (IMR longitudinal queda en Ola 3 con disclaimer).

## 4. Requisitos funcionales

### RF-171-01 — `CycleScoreComputer.compute(magnitudes)` (función pura)

Nuevo archivo `lib/src/features/metabolic_cycle/application/cycle_score_computer.dart`:

```dart
class CycleScoreComputer {
  CycleScoreComputer._();

  /// SPEC-171 §RF-171-01: aplica la misma fórmula que
  /// StreakEntry.dailyQualityScore pero sobre magnitudes en vivo.
  /// Retorna 0-100.
  static int compute({
    double? fastingMagnitude,
    double? sleepQualityScore,
    double? hydrationMagnitude,
    double? exerciseMagnitude,
    double? nutritionMagnitude,
  }) {
    const wSleep = 0.25;
    const wFasting = 0.22;
    const wExercise = 0.20;
    const wNutrition = 0.18;
    const wHydration = 0.15;

    double weightedSum = 0.0;
    double totalWeight = 0.0;
    void add(double? mag, double w) {
      if (mag == null) return;
      weightedSum += w * mag.clamp(0.0, 1.0);
      totalWeight += w;
    }

    add(fastingMagnitude, wFasting);
    add(sleepQualityScore, wSleep);
    add(hydrationMagnitude, wHydration);
    add(exerciseMagnitude, wExercise);
    add(nutritionMagnitude, wNutrition);

    if (totalWeight == 0.0) return 0;
    final raw = (weightedSum / totalWeight).clamp(0.0, 1.0);
    return (raw * 100).round();
  }
}
```

### RF-171-02 — `displayDailyScoreProvider`

Reemplaza al legacy SOLO en el header. Vive en `lib/src/features/streak/application/daily_score_provider.dart` (al lado del legacy, para que callsites del header lo encuentren sin nuevos imports).

```dart
final displayDailyScoreProvider = Provider<int>((ref) {
  final cycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;
  final cycleHours = cycle == null
      ? null
      : NotificationScheduler.protocolFastingHours(cycle.fastingProtocol);

  // Sin ciclo o protocolo 'Ninguno' → fallback legacy.
  if (cycle == null || cycleHours == null) {
    return ref.watch(dailyScoreProvider);
  }

  // Cíclico: lee magnitudes en vivo del StreakEntry (que ya las computa
  // desde providers cyclicos post SPEC-149.2) y aplica el computer.
  final today = ref.watch(streakProvider).todayEntry;
  return CycleScoreComputer.compute(
    fastingMagnitude: today?.fastingMagnitude,
    sleepQualityScore: today?.sleepQualityScore,
    hydrationMagnitude: today?.hydrationMagnitude,
    exerciseMagnitude: today?.exerciseMagnitude,
    nutritionMagnitude: today?.nutritionMagnitude,
  );
});
```

**Nota**: el computer recibe las magnitudes del `todayEntry` pero esas magnitudes ya son cíclicas vía SPEC-149.2 (los providers de pilares observan `watchSince(cycle.startedAt)`). El refactor "verdadero" del StreakEntry para que se rotule cíclico va a SPEC-171.next si la telemetría lo justifica.

### RF-171-03 — `displayDailyScoreDeltaProvider`

```dart
final displayDailyScoreDeltaProvider = Provider<int?>((ref) {
  final cycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;
  final cycleHours = cycle == null
      ? null
      : NotificationScheduler.protocolFastingHours(cycle.fastingProtocol);

  if (cycle == null || cycleHours == null) {
    return ref.watch(dailyScoreDeltaProvider);
  }

  final lastClosed =
      ref.watch(lastClosedMetabolicCycleProvider).valueOrNull;
  if (lastClosed?.dailyScore == null) return null;

  final currentScore = ref.watch(displayDailyScoreProvider);
  return currentScore - lastClosed!.dailyScore!;
});
```

### RF-171-04 — Callsites del header

`lib/src/features/dashboard/presentation/dashboard_screen.dart` líneas 342-343:

```dart
final dailyScore = ref.watch(displayDailyScoreProvider);
final delta = ref.watch(displayDailyScoreDeltaProvider);
```

Sin más cambios. El widget existente (PillarRing con score numérico) se mantiene.

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `CycleScoreComputer` puro | `lib/src/features/metabolic_cycle/application/cycle_score_computer.dart` (nuevo) |
| 2 | Agregar `displayDailyScoreProvider` y delta | `lib/src/features/streak/application/daily_score_provider.dart` |
| 3 | Cambiar dos callsites del header | `lib/src/features/dashboard/presentation/dashboard_screen.dart` (líneas 342-343) |
| 4 | Tests del computer (≥6) | `test/features/metabolic_cycle/application/cycle_score_computer_test.dart` (nuevo) |
| 5 | Test del provider con/sin ciclo | `test/features/streak/application/display_daily_score_test.dart` (nuevo) |
| 6 | Actualizar SPEC-149 §13.7 marcando deuda RESUELTA | `specs/SPEC-149-dia-metabolico.md` |

## 6. Criterios de aceptación

1. Usuario sin ciclo abierto: `displayDailyScoreProvider` == `dailyScoreProvider` (idéntico al legacy).
2. Usuario con protocolo 'Ninguno' y ciclo abierto: idem (fallback legacy).
3. Usuario con ciclo 16:8 abierto y magnitudes parciales (ej. solo sleep + hydration): score = renormalización sobre esas dos magnitudes (mismo comportamiento de SPEC-140).
4. Score = 100 cuando las 5 magnitudes son 1.0.
5. Score = 0 cuando todas las magnitudes son null.
6. Delta cíclico = `current - lastClosed.dailyScore`; null si no hay ciclo cerrado previo.
7. El callsite del header consume el nuevo provider. El widget renderea idéntico.
8. `flutter analyze` sin issues nuevos.
9. `flutter test` mantiene baseline + ≥10 tests nuevos.

## 7. Plan de pruebas

### 7.1 — `cycle_score_computer_test.dart`

- Con las 5 magnitudes en 1.0 → 100.
- Con las 5 magnitudes en 0.5 → 50.
- Con solo `sleepQualityScore = 1.0` y resto null → 100 (renormalizado).
- Con `fastingMagnitude = 1.5` (sobre-cumplido) → clamp a 1.0 → no afecta el score.
- Con todas null → 0.
- Con pesos parciales asimétricos (sleep 0.5 + hydration 1.0) → `(0.25*0.5 + 0.15*1.0) / (0.25 + 0.15) = 0.6875 → 69`.

### 7.2 — `display_daily_score_test.dart`

- ProviderContainer con `currentMetabolicCycleProvider = null` → retorna valor de `dailyScoreProvider`.
- ProviderContainer con ciclo `'Ninguno'` → retorna valor de `dailyScoreProvider`.
- ProviderContainer con ciclo `'16:8'` + `todayEntry` con magnitudes → retorna `CycleScoreComputer.compute(...)` aplicado.
- Delta sin `lastClosed` → null.
- Delta con `lastClosed.dailyScore = 60` y current = 75 → 15.

## 8. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | El usuario percibe inconsistencia entre header (cíclico) y sitio web Metamorfosis Real (calendárico) | Media | Documentado en SPEC-149 §13.5. El sitio sigue cumpliendo su contrato; la app es la fuente de coaching. Si se vuelve un problema, SPEC-141 unifica todo en Ola 3. |
| R-02 | Las magnitudes del `StreakEntry` siguen rotuladas calendárico → el cíclico es "casi cíclico" pero no 100% | Media | Aceptado para MVP: SPEC-149.2 ya dejó los providers subyacentes cíclicos, así que las magnitudes del entry reflejan el ciclo abierto en la mayoría de casos. El edge (entry calendárico recién creado por StreakNotifier al cruzar medianoche con ciclo abierto) queda como deuda explícita para SPEC-171.next. |
| R-03 | El delta cíclico depende de tener `lastClosed.dailyScore`, que podría ser null en ciclos viejos | Baja | El delta retorna null en ese caso (comportamiento idéntico al legacy con historial corto). |
| R-04 | Cambiar el callsite del header puede afectar tests visuales de SPEC-140 | Baja | El widget renderea idéntico — los tests deberían pasar sin tocar. Si fallan, revisar mocks de providers. |

## 9. Out of scope (explícito)

- Refactor del `StreakEntry` para rotularse cíclico → SPEC-171.next.
- Modificación de `daily_summary` (calendárico, contrato sitio web).
- Modificación de la fórmula de cómputo (pesos siguen siendo de SPEC-140).
- Actualización del `metabolic_cycle_evaluator_provider` (sigue consumiendo legacy).
- UI dual de scores HOY+IMR → SPEC-170 (siguiente Ola 2.5).

## 10. Cierre

Implementación completada en una sesión (~30 min, 3 bloques A-C):

- [x] **A** — `CycleScoreComputer` puro creado en `lib/src/features/metabolic_cycle/application/cycle_score_computer.dart` con los mismos pesos canónicos de SPEC-140.
- [x] **B** — `displayDailyScoreProvider` + `displayDailyScoreDeltaProvider` agregados al lado del legacy en `daily_score_provider.dart`. Decisión cíclico vs calendárico por presencia de `currentMetabolicCycleProvider` con protocolo conocido.
- [x] **B'** — Callsites del header (`dashboard_screen.dart:342-343`) cambiados a los `display*`. Cero cambio visual.
- [x] **C** — 11 tests del computer (`cycle_score_computer_test.dart`) cubriendo todas las combinaciones de magnitudes + 5 tests del provider (`display_daily_score_test.dart`) cubriendo fallback legacy.
- [x] **C'** — SPEC-149 §13.7 marcada "DEUDA RESUELTA 2026-06-04 — SPEC-171".
- [ ] Validación visual en iPhone (Carlos — pendiente próxima sesión cuando corra la app).

## 11. Changelog

### v1.0 — 2026-06-04

Documento inicial. Refactor mínimo invasivo: nuevo provider de display que decide cíclico vs calendárico sin tocar el legacy ni `daily_summary`. Cierra deuda SPEC-149 §13.7.
