# SPEC-203 — Entrenamientos reales desde HealthKit (workouts)

**Estado:** IMPLEMENTED (2026-06-10) — workouts tipados al sync + observer `.immediate` + regla pasos-vs-workout + tests. Decisión §2 adoptada (workouts ganan; pasos solo en días sin workout). Pendiente: validación en device (registrar un workout en Apple Health → ver el log tipado).
**Versión:** 0.1 (draft)
**Tipo:** Health sync — el pilar de Ejercicio pasa de "pasos" a entrenamientos reales (caminata, trote, fuerza, HIIT, movilidad).
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Continuación de Health sync (post SPEC-132.next).
**Estimación:** ~2 días (nativo Swift + Dart sync + import + mapping + tests).
**Depende de:** SPEC-132 (pull sync), SPEC-132.next (observers + background delivery), SPEC-68 (`ExerciseType` ya existe).
**Bloquea:** que el pilar de Ejercicio refleje sesiones reales del usuario (gym/cardio), no solo pasos.

---

## 1. Contexto

Hoy el pilar de **Ejercicio** se alimenta de **pasos** (`HealthMetric.steps` → `ExerciseLog`, "actividad equivalente"). Carlos: necesita que cuenten los **entrenamientos reales** — caminata, trote, fuerza, HIIT, todo lo que el usuario registra en Apple Health como sesión.

La buena noticia: el modelo ya está listo. `ExerciseLog` (SPEC-68) tiene `durationMinutes`, `type` (`ExerciseType`: liss / hiit / strength / mobility), `activityType`, `heartRateAvg`. Solo falta **leer los `HKWorkout` y mapearlos**.

---

## 2. Decisión de producto — pasos vs. workouts (el fork)

Si sumamos pasos **y** workouts, un trote se cuenta **dos veces** (genera pasos + un workout). Regla adoptada:

> **Los workouts son la fuente de verdad del minutaje de ejercicio.** Los **pasos quedan como piso/fallback solo en días SIN workout.**

- Día con ≥1 workout → minutos de ejercicio = suma de duraciones de los workouts de ese día. Los pasos de ese día NO suman a ejercicio (evita inflar).
- Día sin workout → se conserva el comportamiento actual (pasos → "actividad equivalente").
- Esto mantiene el Score del Día / IMR honesto: una caminata informal (muchos pasos, sin sesión) sigue dando crédito; un gym/trote registrado no se duplica.

`activityType` libre de cada `ExerciseLog` guarda el nombre real del workout (para la UI: "Trote", "Fuerza", etc.).

---

## 3. Tabla de mapeo HKWorkoutActivityType → ExerciseType

| HKWorkoutActivityType (ejemplos) | ExerciseType |
|---|---|
| walking, running (suave), cycling, hiking, elliptical, rowing | **liss** |
| highIntensityIntervalTraining, crossTraining, jumpRope, stairClimbing | **hiit** |
| traditionalStrengthTraining, functionalStrengthTraining, coreTraining | **strength** |
| yoga, flexibility, mindAndBody, pilates, cooldown | **mobility** |
| (cualquier otro / desconocido) | **liss** (default neutral) |

La distinción running suave vs. sprint no la da el tipo de actividad de Apple; si hay `heartRateAvg` alto o intervalos, se podría refinar a `hiit` en una iteración (out of scope acá).

---

## 4. Cambios técnicos

**RF-203-01 — Nativo (`ios/Runner/HealthKitObserver.swift`).** Agregar un 4º observer sobre `HKObjectType.workoutType()` con frecuencia **`.immediate`** (los workouts SÍ son eventos discretos que Apple entrega al instante, a diferencia de pasos/sueño que van `.hourly`). Notifica `{type:"workout"}` al MethodChannel. El usuario debe tener permiso de lectura de workouts (agregar a los tipos solicitados en `requestAuthorization`).

**RF-203-02 — Dominio (`health_metric.dart`).** Agregar `HealthMetric.workout` (unidad `minutes`, label "Entrenamiento"). El `HealthSample` del workout lleva duración (minutos) + el `activityType` nativo para el mapeo.

**RF-203-03 — Sync (`HealthSyncService`).** Leer `HealthDataType.WORKOUT` del paquete `health` en la ventana de 7 días. Cada `HealthDataPoint` de workout expone `workoutActivityType`, `totalEnergyBurned`, `totalDistance`, y duración (`dateFrom`/`dateTo`). Normalizar a `HealthSample` (minutos + activityType + opcional FC).

**RF-203-04 — Import (`HealthImportService`).** Por cada workout → `ExerciseLog(durationMinutes, type=mapeo, activityType=nombre, timestamp=inicio, heartRateAvg?)`. Idempotente: dedup por id derivado del workout (`uuid` o `start+type+duration`). "Manual wins over auto" preservado (un log manual del mismo día/tipo no se pisa). Aplicar la regla §2 (workouts desplazan a los pasos de ese día).

**RF-203-05 — Observer trigger.** El evento `{type:"workout"}` dispara `runNow` igual que los otros (reusa el side-effect de SPEC-132.next, sin cambios).

---

## 5. Lo que NO se hace aquí

- **NO** se escribe a HealthKit (la app sigue read-only).
- **NO** se infieren intervalos/HIIT desde la FC (refinamiento futuro).
- **NO** se importan métricas nuevas fuera de workouts (no glucosa, no VO2max).
- **NO** se toca Android (Health Connect usa `ExerciseSessionRecord` — SPEC-203.android si sale versión Android).

---

## 6. Criterios de aceptación

1. El usuario registra un entrenamiento de fuerza en Apple Health → al sincronizar, aparece un `ExerciseLog` con `type=strength` y los minutos reales, y suma al pilar de Ejercicio del día.
2. Una caminata registrada como workout cuenta como `liss` con su duración real.
3. En un día con workout, los pasos NO doble-cuentan al ejercicio.
4. En un día sin workout, los pasos siguen dando "actividad equivalente" como hoy.
5. Re-sincronizar no duplica logs (idempotencia por id de workout).
6. Un log manual de ejercicio no se pisa por el auto-import (manual wins).

---

## 7. Testing

- Mapeo `HKWorkoutActivityType → ExerciseType`: tabla pura, todos los casos + default.
- `HealthImportService` con workouts sintéticos: dedup, manual-wins, regla pasos-vs-workout. Puro/con fakes.
- Swift: fuera de scope (validación en device).
- E2E: registrar un workout en Apple Health → sync → ver el log tipado en Elena (device).

---

## 8. Decisiones abiertas (para Carlos)

- ¿La regla §2 (workouts desplazan pasos del día) te cuadra, o prefieres un tope combinado (p. ej. max(steps_eq, workouts) en vez de "workouts ganan")?
- La tabla §3: ¿el default `liss` está bien para tipos desconocidos, o prefieres no contar lo desconocido?
- ¿Importamos también la **energía/distancia** del workout para mostrarla (calorías, km), o por ahora solo minutos + tipo?
