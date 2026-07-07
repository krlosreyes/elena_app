# SPEC-210 — removeLastMeal cycle-aware (corrección ventana calendárica)

**Estado:** IMPLEMENTED (2026-06-14) — removeLastMeal cycle-aware. commit 53e6484.
**Versión:** 1.0
**Tipo:** Bug P0 — "Deshacer última comida" puede borrar comida del ciclo anterior.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~30 min
**Depende de:** `nutrition_repository_impl.dart`, `nutrition_notifier.dart`

---

## 1. Problema

`NutritionRepositoryImpl.removeLastMeal()` busca la última comida usando ventana calendárica:

```dart
// nutrition_repository_impl.dart (bug actual)
Future<void> removeLastMeal(String userId) async {
  final now = DateTime.now();
  final latest = await _source.latestTodayLog(
    userId,
    startOfDay: DayBoundaryResolver.startOfDay(now),  // medianoche
    endOfDay: DayBoundaryResolver.endOfDay(now),
  );
```

El ciclo metabólico NO es calendárico — puede empezar a las 18:00 del día anterior.
Si un usuario que abre su ciclo a las 18:00 del martes registra comida a las 19:00
y luego quiere deshacerla el miércoles a las 01:00, `latestTodayLog` busca desde
medianoche del miércoles → no encuentra nada → silently no-op.

Peor: si hay comidas del ciclo anterior (lunes noche), `latestTodayLog` puede
devolver una comida de ese ciclo y borrarla, corrompiendo el historial histórico.

---

## 2. Solución

### inc1 — Añadir `since` a la interfaz del repositorio

```dart
// nutrition_repository.dart
abstract class NutritionRepository {
  // ...
  Future<void> removeLastMeal(String userId, {required DateTime since});
}
```

### inc2 — Implementación cycle-aware en `NutritionRepositoryImpl`

```dart
// nutrition_repository_impl.dart
@override
Future<void> removeLastMeal(String userId, {required DateTime since}) async {
  // Sin tope superior: busca desde el inicio del ciclo actual hasta ahora.
  final latest = await _source.latestTodayLog(
    userId,
    startOfDay: since,
    endOfDay: null,   // sin tope → busca hasta el momento actual
  );
  if (latest == null) return;
  await _source.deleteLog(userId, latest.docId);
}
```

### inc3 — Caller en `NutritionNotifier`

`NutritionNotifier` ya tiene `_currentCycleStartedAt`. Pasarlo al repo:

```dart
// nutrition_notifier.dart
Future<void> removeLastMeal() async {
  final userId = _userId;
  if (userId == null) return;
  final since = _currentCycleStartedAt ?? DayBoundaryResolver.startOfDay(DateTime.now());
  // Optimistic: quitar último log del state local
  if (state.todayLogs.isNotEmpty) {
    final updated = List<NutritionLog>.from(state.todayLogs)..removeLast();
    state = _recalculate(updated, state.targetMeals);
  }
  unawaited(
    _repo.removeLastMeal(userId, since: since).catchError((Object e) {
      AppLogger.warning('removeLastMeal falló: $e');
    }),
  );
}
```

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/nutrition/domain/nutrition_repository.dart` | Añadir `since` a `removeLastMeal` |
| `lib/src/features/nutrition/data/nutrition_repository_impl.dart` | Implementar con `since` |
| `lib/src/features/nutrition/application/nutrition_notifier.dart` | Pasar `_currentCycleStartedAt` como `since` |

---

## 4. Criterios de aceptación

- [ ] Ciclo iniciado a las 18:00 del martes. Comida registrada a las 19:00. Deshacer a
  las 01:00 del miércoles → la comida de las 19:00 se borra, no ninguna otra.
- [ ] Sin comidas en el ciclo actual → `removeLastMeal` no borra nada (no-op silencioso).
- [ ] Ciclo con 3 comidas → deshacer → quedan 2, el stream emite la lista correcta.
- [ ] Test unitario con `FakeNutritionRepository` verifica que `since` se pasa correctamente.
