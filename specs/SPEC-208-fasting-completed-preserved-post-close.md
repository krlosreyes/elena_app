# SPEC-208 — Preservar fastingCompleted después de cerrar el ayuno

**Estado:** IMPLEMENTED (2026-06-14) — fasting completed preserved post-close. commit cc25c6d.
**Versión:** 1.0
**Tipo:** Bug P0 — Score del Día incorrecto. Corrección de datos.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~45 min
**Depende de:** `streak_notifier.dart`, `fasting_notifier.dart`
**Bloquea:** integridad del Score del Día

---

## 1. Problema

En `StreakNotifier._evaluateToday()`, las horas de ayuno se calculan así:

```dart
// streak_notifier.dart
final double fastingHours =
    fasting.isActive ? fasting.duration.inSeconds / 3600.0 : 0.0;
```

Cuando el usuario cierra su ayuno, `isActive` pasa a `false` → `fastingHours = 0.0` →
`fastingMagnitude = 0.0` → `fastingCompleted = false`.

`_evaluateToday()` se dispara ante **cualquier cambio de cualquier pilar** (agua, comida,
ejercicio, sueño). En el momento en que el usuario registra agua después de cerrar el ayuno,
`_evaluateToday()` persiste `fastingCompleted: false` en Firestore, sobreescribiendo el
`true` que se había calculado mientras el ayuno estaba activo.

**Efecto en el usuario:** El Score del Día pierde el componente de ayuno a mitad del día.
El día puede terminar con `fastingCompleted: false` aunque el usuario haya completado sus 16h.

---

## 2. Diagnóstico

`FastingState` expone dos campos clave que `StreakNotifier` ignora cuando `!isActive`:

- `fastingState.completedToday` — true si el ayuno que acaba de cerrarse superó el target.
- `fastingState.closedProgressToday` — fracción 0.0–1.0 del progreso al cierre (para ayunos
  parciales que no llegan al 100% pero sí aportan al score).

El notifier los ignora y usa `0.0` por defecto cuando `!isActive`.

---

## 3. Solución

### inc1 — Preservar el progreso del ayuno cuando `!isActive`

En `streak_notifier.dart`, reemplazar el cálculo de `fastingHours`:

```dart
// ANTES (bug)
final double fastingHours =
    fasting.isActive ? fasting.duration.inSeconds / 3600.0 : 0.0;

// DESPUÉS (fix)
double fastingHours;
if (fasting.isActive) {
  // Ayuno en curso: usar duración real acumulada.
  fastingHours = fasting.duration.inSeconds / 3600.0;
} else if (fasting.completedToday == true) {
  // Ayuno cerrado y completado: usar el target completo para que
  // fastingMagnitude >= 1.0 y fastingCompleted = true persistan.
  fastingHours = _fastingTargetHours(currentProtocol);
} else {
  // Ayuno cerrado sin completar o sin ayuno hoy: usar el progreso parcial
  // guardado al cierre (0.0 si no hubo ayuno en absoluto).
  fastingHours = (fasting.closedProgressToday ?? 0.0)
      * _fastingTargetHours(currentProtocol);
}
```

### inc2 — Verificar que `FastingState` expone `completedToday` y `closedProgressToday`

Confirmar en `fasting_notifier.dart` / `FastingState` que ambos campos se persisten
correctamente en SharedPreferences al cerrar el ayuno. Si no existen, añadirlos:

```dart
// fasting_state.dart (o equivalente)
final bool completedToday;      // true si el ayuno cerrado superó el target del protocolo
final double? closedProgressToday; // fracción 0.0–1.0 al cierre (null = sin ayuno hoy)
```

### inc3 — Reset al inicio del siguiente ciclo

En `DailyResetService` o en `FastingNotifier._onNewCycle()`, resetear ambos campos a
`false` / `null` cuando se inicia un nuevo ciclo metabólico para que no contaminen el
siguiente día.

---

## 4. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/streak/application/streak_notifier.dart` | Cálculo `fastingHours` post-cierre |
| `lib/src/features/dashboard/application/fasting_notifier.dart` | Verificar/añadir `completedToday` y `closedProgressToday` en state |
| `lib/src/features/dashboard/domain/fasting_state.dart` | Añadir campos si no existen |

---

## 5. Criterios de aceptación

- [ ] Iniciar ayuno de 16h → completarlo → registrar agua → Score del Día mantiene `fastingCompleted: true`.
- [ ] `fastingMagnitude` en Firestore permanece ≥ 1.0 después de cerrar el ayuno.
- [ ] Al día siguiente (nuevo ciclo), `completedToday = false`, `closedProgressToday = null`.
- [ ] Ayuno cerrado antes de completar el target → `fastingMagnitude` refleja el progreso
  parcial, no `0.0`.

---

## 6. Impacto en datos históricos

Los ciclos ya cerrados en Firestore con `fastingCompleted: false` (por este bug) no se
recalculan automáticamente. Los `dailyScore` históricos quedarán subestimados para días
donde se registró agua/comida post-ayuno. Documentado como dato histórico imperfecto pre-SPEC-208.
