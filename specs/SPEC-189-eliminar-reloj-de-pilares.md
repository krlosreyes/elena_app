# SPEC-189 — Eliminar referencias al reloj en pilares y servicio del ciclo

**Estado:** DRAFT v1.0 — pendiente aprobación
**Severidad:** P0 (corrige modelo fundacional §1)
**Origen:** Corrección estratégica de Carlos 2026-06-05.
**Relacionado con:** SPEC-149 (Día Metabólico), SPEC-184 (Constitución §1), SPEC-188 (sleep ventana pura).

---

## 1. Resumen ejecutivo

`METABOLIC_DAY_CONSTITUTION.md §1` establece que el día metabólico es 100% event-driven. **CERO referencia al reloj.** Esta SPEC elimina los fallbacks y triggers basados en reloj que viven en los providers y servicios del ciclo metabólico.

**Implicación de producto crítica:** si el usuario no ha iniciado su primer ayuno, **no ve datos del día**. Los pilares quedan en estado "esperando primer tap". El primer tap arranca el día.

---

## 2. Cambios concretos por archivo

### 2.1 — `lib/src/features/nutrition/application/nutrition_notifier.dart`

**Actual** (línea 155):
```dart
final since = cycleStartedAt ?? DayBoundaryResolver.startOfDay(DateTime.now());
```

**Después:**
```dart
if (cycleStartedAt == null) {
  // SPEC-189: sin ciclo abierto, no hay día metabólico → no suscribirse.
  // El state queda con la lista de hoy vacía. El primer tap "iniciar
  // ayuno" abrirá ciclo y disparará la suscripción.
  _logsSub?.cancel();
  if (mounted) state = state.copyWith(todayLogs: const []);
  return;
}
final since = cycleStartedAt;
```

### 2.2 — `lib/src/features/dashboard/application/hydration_notifier.dart`

Mismo patrón: si `cycle == null`, cancelar subscription y dejar state vacío.

### 2.3 — `lib/src/features/exercise/application/exercise_notifier.dart`

Mismo patrón.

### 2.4 — `lib/src/features/metabolic_cycle/domain/metabolic_cycle_resolver.dart`

**Eliminar el trigger `fallbackCalendar`** (cierre por cambio de día calendárico). Es la única regla del resolver que mira la rotación de la Tierra. Cierre del ciclo es exclusivo de:

- `manualNextFasting` (usuario tap iniciar nuevo ayuno)
- `manualWindowClose` (usuario tap cerrar ventana)
- `fallback3hAfterWindow` (3h post última comida)
- `fallbackAbsolute` (28h)
- `fallbackSleepDetected` (sueño tras última comida)

### 2.5 — `lib/src/features/metabolic_cycle/application/metabolic_cycle_service.dart` `bootstrapIfMissing`

**Actual** (líneas 244-249):
```dart
DateTime startedAt;
if (MetabolicCycleResolver.useCalendarFallback(protocol)) {
  startedAt = DateTime(now.year, now.month, now.day);
} else {
  startedAt = lastFastingStartTime!;
}
```

**Después:**
```dart
// SPEC-189: ya no hay fallback al inicio del día calendárico.
// Si llegamos aquí (post-guard SPEC-185), lastFastingStartTime != null.
startedAt = lastFastingStartTime!;
```

Y eliminar `useCalendarFallback` del resolver si ya no se usa en ningún lado.

### 2.6 — `lib/src/features/nutrition/application/upf_share_provider.dart`

Verificar — debería estar ya correcto post SPEC-138 (retorna empty si no hay ciclo). Confirmar.

### 2.7 — `lib/src/features/nutrition/data/nutrition_repository_impl.dart` `watchTodayLogs`

**Actual:** usa `DayBoundaryResolver.startOfDay/endOfDay` para definir "hoy".

**Después:** mantener el método solo para los pocos callsites que NO son cycle-aware (Analysis screen quizás). Si alguien quiere "los logs de hoy", debe usar `watchSinceLogs(uid, cycle.startedAt)`. El método legacy lo dejamos con `@deprecated` y un log warning.

### 2.8 — Análogos en `hydration_repository_impl.dart` y `exercise_repository_impl.dart`

Mismo patrón: deprecar `watchTodayLogs`, mantener `watchSince`.

---

## 3. Lo que NO cambia (decisiones de Carlos)

- `UserProfile.sleepTime` y `wakeUpTime` quedan en el esquema → SPEC-191.
- `fasting_notifier.updateSleepConsciousness` usa esos campos para el overlay "buenos días" → queda, es overlay informativo, NO define el día metabólico.
- Analítica semanal (last_week_*, weekly_coaching) → SPEC-190.

---

## 4. Riesgo de UX nuevo

**Usuario nuevo que no ha tapeado "iniciar ayuno" nunca** verá todos los pilares en 0 al primer login. Esto **es el comportamiento correcto según §1**, pero puede confundir.

**Mitigación:** mostrar un placeholder en el Dashboard que diga "Iniciá tu primer ayuno para arrancar tu día metabólico" cuando `currentMetabolicCycleProvider` retorna null. Esto se hace en SPEC-189.4 (sub-bloque UI).

---

## 5. Plan de entrega

- **Bloque A** (~30 min): cambiar 3 notifiers (nutrition/hydration/exercise) + tests adicionales.
- **Bloque B** (~20 min): resolver — eliminar `fallbackCalendar`. Tests del resolver.
- **Bloque C** (~10 min): service `bootstrapIfMissing` — eliminar branch calendárico.
- **Bloque D** (~10 min): UI placeholder "iniciá tu primer ayuno" si cycle == null.
- **Bloque E** (~10 min): deprecar `watchTodayLogs` en 3 repos con `@Deprecated`.

Total estimado: **~1h 20min**.

---

## 6. Tests críticos

- Provider de nutrición sin ciclo → emite `[]`.
- Provider con ciclo abierto + log dentro del ciclo → emite ese log.
- Provider con ciclo abierto + log ANTES del ciclo → emite `[]` (no captura logs previos).
- Resolver sin `fallbackCalendar` → no cierra el ciclo aunque pase la medianoche.

---

## 7. Decisión

Para implementar requiero `ok recomendación` o ajustes.

## 8. Referencias internas

- `docs/METABOLIC_DAY_CONSTITUTION.md §1`
- `specs/SPEC-149-*.md`
- Memoria [[metabolic-day-anchors-to-user]]
