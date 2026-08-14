# SPEC-296 — Pilar Ejercicio: datos reales de la actividad + fix duplicación

**Estado:** 296.1/.2/.3/.4 IMPLEMENTED. Falta verificación en simulador (Carlos).
**Fecha:** 2026-08-14
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Pedido de Carlos

Mostrar en el pilar la info de la actividad (como las imágenes: tipo, fuente, calorías, inicio, duración, distancia — la provee Apple Health), arreglar el bug que **duplica sesiones**, y explicar **cómo la actividad beneficia** al usuario.

## 2. Diagnóstico

- **Duplicación:** una misma sesión registrada por varias fuentes (Apple Watch + app de gym + iPhone) llega como workouts distintos (uuids distintos). `removeDuplicates` del plugin no los colapsa (fuente distinta) → varios `ExerciseLog` (`hk_workout_{uuid}`).
- **Datos faltantes:** el `WorkoutHealthValue` del plugin trae `totalEnergyBurned` y `totalDistance`, pero `_toSample` no los lee; y ni `HealthSample` ni `ExerciseLog` tienen campos para calorías/distancia.
- **UI faltante:** las tarjetas de "Actividades" de las imágenes NO existen en la app.

## 3. Partes

### 296.1 — Fix duplicación (IMPLEMENTED)
`health_import_service.dart`: `dedupWorkoutSamples` colapsa workouts que se solapan en tiempo y son del mismo tipo, conservando el más largo. Se aplica en `_importWorkouts`. Test: `test/features/health_sync/dedup_workouts_test.dart`.

### 296.2 — Capturar calorías + distancia (pendiente, necesita build_runner)
- `HealthSample`: nuevos `caloriesKcal`, `distanceMeters`.
- `health_sync_service._toSample`: leer `v.totalEnergyBurned` / `v.totalDistance` del `WorkoutHealthValue`.
- `ExerciseLog` (Freezed → `dart run build_runner build`): nuevos `caloriesKcal`, `distanceKm`, `sourceName`. Capturar en `_importWorkouts`.

### 296.3 — UI "Actividades" + beneficios (IMPLEMENTED)
Lista de tarjetas por sesión: ícono por tipo, badge "Importado desde Apple Health", Calorías, Inicio, Duración, Distancia; y un bloque de **beneficios** por tipo de actividad. Widget compartido `ImportedActivitiesSection` (`exercise/presentation/widgets/`), lee `exerciseProvider.history`, filtra a HOY, se autooculta si no hay actividad.

### 296.4 — Ubicación en el Dashboard (IMPLEMENTED)
Decisión de Carlos (2026-08-14): las tarjetas van en la **card del pilar Ejercicio del Dashboard** (`exercise_pillar_card.dart`), al final, después de los botones. Se pinta solo si `hasActivityToday` (evita separación colgante). También sigue disponible en Perfil → Hábitos de ejercicio.

## 4. Verificación 296.1 (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/health_sync test/features/health_sync
flutter test test/features/health_sync/dedup_workouts_test.dart
```
