# SPEC-149.2 — Streams de pilares por ventana cíclica

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Extensión de SPEC-149 / resolución Bug 2 SPEC-149.1
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 1 — Estabilización (cierre del Día Metabólico)
**Estimación:** 1-2 sesiones
**Marco normativo:** `CONSTITUTION.md`. Extiende SPEC-149 sin romper SPEC-138.

---

## 1. Contexto

SPEC-149.1 cerró 3 bugs de la `CycleClosureCard` pero dejó Bug 2 explícitamente deferido: **el conteo de ejercicio mostraba 66 min en Elena cuando Apple Activity mostraba 21 min real**.

Causa raíz: los 3 pilares acumulativos (`exercise`, `hydration`, `nutrition`) leen el stream `watchToday(userId)` que filtra por día calendárico `[startOfDay, endOfDay)`. Aunque SPEC-149.1 hace `resetDaily()` al cerrar el ciclo metabólico, el stream re-emite inmediatamente todos los logs del día calendárico — el contador no llega a 0.

Esta SPEC migra los 3 streams a **ventana cíclica** `[cycle.startedAt, +28h]` para que el contador del nuevo ciclo arranque y se mantenga en lo realmente acumulado dentro del ciclo en curso.

## 2. Decisión arquitectónica

### 2.1 — Nuevo método en cada repositorio

```dart
abstract class ExerciseRepository {
  /// SPEC-149.2: stream filtrado por ventana [since, since + 28h].
  /// 28h coincide con kAbsoluteCycleLimit del MetabolicCycleResolver,
  /// el límite duro de duración de un ciclo metabólico.
  Stream<List<ExerciseLog>> watchSince(String userId, DateTime since);

  /// SPEC-50.2: stream de los logs del día calendárico actual.
  /// Mantenido por compatibilidad — usado donde la semántica calendárica
  /// es deseada (ej: análisis histórico, sitio Metamorfosis Real).
  Stream<List<ExerciseLog>> watchToday(String userId);

  Future<void> save(String userId, ExerciseLog log);
}
```

Equivalente para `HydrationRepository.watchSince` y `NutritionRepository.watchSinceLogs`.

### 2.2 — Notifiers cycle-aware

Los 3 notifiers escuchan `currentMetabolicCycleProvider`. Cuando `cycle.startedAt` cambia (nueva apertura tras cierre), cancelan la suscripción anterior y crean una nueva con `watchSince(cycle.startedAt)`.

**Fallback cuando no hay ciclo abierto:** muy raro en producción (el bootstrap garantiza un ciclo), pero por defensa usamos `DayBoundaryResolver.startOfDay(now)` — equivalente al comportamiento previo.

### 2.3 — ExerciseNotifier: refactor estructural

A diferencia de Hydration y Nutrition, `ExerciseNotifier` no tiene `Ref`. Se cambia el constructor a `ExerciseNotifier({Ref ref, ...})` para escuchar el ciclo. Las dependencias `userId` y `repository` se siguen pasando explícitas para preservar testabilidad.

### 2.4 — Por qué `+28h` y no `endOfDay`

Un ciclo metabólico puede cruzar la medianoche calendárica (ej: ayuno arranca 21:00 hoy → ventana 13:00-21:00 mañana). Si `watchSince` filtra hasta `endOfDay(now)`, perdemos los logs de mañana mientras el ciclo siga abierto.

`since + 28h` cubre el ciclo máximo legal (`kAbsoluteCycleLimit`) + margen. Cuando el ciclo cierra (cualquier trigger), el notifier re-suscribe con el nuevo `since`. Sin riesgo de over-fetch porque los logs se filtran por timestamp.

## 3. Cambios técnicos

### 3.1 — `ExerciseRepository`

- `exercise_repository.dart`: agregar firma `watchSince(userId, since)`.
- `exercise_repository_impl.dart`: implementar `watchSince` con `endOfWindow = since + kCycleWindowDuration`. La constante `kCycleWindowDuration = Duration(hours: 28)` se expone públicamente para tests.

### 3.2 — `HydrationRepository` (idem)

### 3.3 — `NutritionRepository`

Similar, pero el método se llama `watchSinceLogs(userId, since)` para mantener consistencia con `watchTodayLogs`.

### 3.4 — Notifiers

**`ExerciseNotifier`** (lib/src/features/exercise/application/exercise_notifier.dart):
- Constructor agrega `Ref ref`
- `_initSubscription` recibe `DateTime since` y llama `watchSince`
- En el `_init`, listen a `currentMetabolicCycleProvider` con `fireImmediately: true`
- `resetDaily()` re-suscribe con el `since` actual del ciclo
- Provider `exerciseProvider` pasa `ref` al constructor

**`HydrationNotifier`** (lib/src/features/dashboard/application/hydration_notifier.dart):
- `_initHydrationSubscription` recibe `DateTime since`
- listen del ciclo en `_init`
- `resetDaily()` re-suscribe con el `since` actual

**`NutritionNotifier`** (lib/src/features/nutrition/application/nutrition_notifier.dart):
- `_subscribeToLogs` recibe `DateTime since`
- listen del ciclo en `_init`
- `resetDaily()` re-suscribe con el `since` actual

## 4. Criterios de aceptación

1. Al cerrar un ciclo metabólico, los contadores de los 3 pilares quedan en 0 (no en el acumulado calendárico).
2. Al cruzar medianoche con ciclo abierto, los contadores siguen acumulando del ciclo — no se resetean por medianoche calendárica.
3. Al iniciar un nuevo ciclo, el contador arranca en 0 y suma solo los logs dentro de la ventana.
4. Si no hay ciclo abierto (estado raro), fallback a `startOfDay` — comportamiento previo a SPEC-149.2.
5. `watchToday` sigue funcionando para callers existentes (análisis histórico, etc.).

### 4.1 — Sobre tests

Igual que SPEC-151: los 3 notifiers requieren mockear todo el árbol de providers (auth, user, ticker, repository, metabolic cycle) para instanciarse. Cero tests externos existentes los instancian. El costo de mockeo no justifica testear el delta de re-suscripción.

**Validación 100% visual en device**, con el siguiente protocolo:

1. Carlos inicia ayuno (cualquier hora válida del protocolo).
2. Registra ejercicio/hidratación/comida en el ciclo actual.
3. Verifica que los contadores reflejan solo lo del ciclo, no acumulados calendáricos previos.
4. Al cerrar manualmente el ayuno e iniciar el siguiente, los contadores arrancan en 0.
5. Si tiene un ayuno que cruza medianoche, verifica que los contadores no se resetean a las 00:00.

Si en el futuro se hace refactor de los notifiers a Container-pattern (separar pure functions del Riverpod-glue), agregar unit tests del cálculo de `since` y de la re-suscripción.

## 5. Out of scope (explícito)

- **`daily_summary` (SPEC-138):** sigue siendo por día calendárico. Esta SPEC NO toca daily_summary ni IMR longitudinal.
- **Sleep/Fasting pilares:** no se acumulan minuto a minuto — su lógica de día es distinta y queda sin cambios.
- **Streak por ciclo:** decisión pendiente para Ola 3 (SPEC-148).

## 6. Rollout

Sin breaking changes (`watchToday` se mantiene). Sin migración de datos. Push directo a `mvp-core-clean` + validación visual cuando Carlos tenga iPhone disponible.

## 7. Changelog

### v1.0 — 2026-06-02

Resolución del Bug 2 deferido por SPEC-149.1. Cierra el Día Metabólico como unidad coherente del producto.
