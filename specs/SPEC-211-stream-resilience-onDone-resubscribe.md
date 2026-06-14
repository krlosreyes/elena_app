# SPEC-211 — Resiliencia de streams: onDone + onError en todos los notifiers

**Estado:** APPROVED-DESIGN (2026-06-14)
**Versión:** 1.0
**Tipo:** Bug P1 — Streams se cierran silenciosamente tras token refresh / reconexión Firestore.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~45 min
**Depende de:** notifiers de Sueño, Ejercicio, Biometría, Ayuno
**Nota:** NutritionNotifier ya tiene el patrón completo desde SPEC-206 (2026-06-14). Este SPEC replica el mismo patrón a los restantes.

---

## 1. Problema

Firestore puede cerrar un stream de `.snapshots()` por:
- Token refresh de Firebase Auth (cada ~1h).
- Reconexión después de pérdida de red.
- Límite de conexiones simultáneas (raro, pero posible en dispositivos con muchas apps).

Cuando el stream se cierra, el `.listen()` dispara `onDone`. Si no hay handler para `onDone`,
la subscripción queda como "finalizada" — el notifier no recibe nuevos snapshots pero tampoco
sabe que el stream terminó. La UI no muestra error; simplemente deja de actualizarse.

Notifiers afectados (sin `onDone`):

| Notifier | Archivo |
|----------|---------|
| `SleepNotifier._initSleepSubscription` | `sleep_notifier.dart` |
| `ExerciseNotifier._subscribeFor` | `exercise_notifier.dart` |
| `ProgressNotifier._subscribeToBiometric` | `progress_notifier.dart` |
| `FastingNotifier._initFastingStream` | `fasting_notifier.dart` |

---

## 2. Solución — patrón uniforme

El mismo patrón que `NutritionNotifier` (implementado en SPEC-206):

```dart
// Plantilla para TODOS los notifiers
_sub = repo.watchSince(userId, since).listen(
  (data) {
    if (!mounted) return;
    state = _recalculate(data);
  },
  onError: (Object e) {
    AppLogger.warning('[NombreNotifier] stream error (transitorio): $e');
    // No cambiar state: el dato anterior sigue siendo válido hasta reconexión.
  },
  onDone: () {
    // Firestore cerró el stream (token refresh, reconexión).
    // Re-suscribir para no quedarse sin actualizaciones.
    if (mounted) _subscribeFor(_currentSince);
  },
);
```

### inc1 — SleepNotifier

En `_initSleepSubscription()`:
```dart
_sleepSub = _repo.watchRecent(userId).listen(
  (logs) { if (mounted) state = _buildState(logs); },
  onError: (e) => AppLogger.warning('[SleepNotifier] stream error: $e'),
  onDone: () { if (mounted) _initSleepSubscription(userId); },
);
```

### inc2 — ExerciseNotifier

En `_subscribeFor(DateTime since)`:
```dart
_sub = _repo.watchSince(userId, since).listen(
  (logs) { if (mounted) state = _buildState(logs); },
  onError: (e) => AppLogger.warning('[ExerciseNotifier] stream error: $e'),
  onDone: () { if (mounted) _subscribeFor(since); },
);
```

### inc3 — ProgressNotifier (`_subscribeToBiometric`)

```dart
_bioSub = _ref.read(biometricRepositoryProvider)
    .watchHistory(userId)
    .listen(
  (list) { if (mounted) state = state.copyWith(biometricHistory: list.reversed.toList()); },
  onError: (e) => AppLogger.warning('[ProgressNotifier] biometric stream error: $e'),
  onDone: () { if (mounted) _subscribeToBiometric(userId); },
);
```

### inc4 — FastingNotifier (verificar)

Verificar si `_initFastingStream` tiene `onDone`. Si no:
```dart
onDone: () { if (mounted) _initFastingStream(userId); },
```

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/dashboard/application/sleep_notifier.dart` | `onDone` en `_initSleepSubscription` |
| `lib/src/features/exercise/application/exercise_notifier.dart` | `onDone` en `_subscribeFor` |
| `lib/src/features/progress/application/progress_notifier.dart` | `onError` + `onDone` en `_subscribeToBiometric` |
| `lib/src/features/dashboard/application/fasting_notifier.dart` | Verificar y añadir `onDone` si falta |

---

## 4. Criterios de aceptación

- [ ] En modo avión: registrar agua/comida/ejercicio/sueño. Al reconectar, los datos aparecen
  actualizados sin reiniciar la app.
- [ ] Simular cierre de stream (forzar desconexión WiFi por 2 min y reconectar):
  el notifier re-suscribe automáticamente y los datos se actualizan.
- [ ] `flutter analyze` sin warnings en los archivos modificados.
- [ ] Logs de AppLogger muestran warnings de `onError` cuando hay error de red, no excepciones
  no manejadas.
