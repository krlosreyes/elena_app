# SPEC-216 — Garantizar reset de isSaving con try/finally en notifiers

**Estado:** APPROVED-DESIGN (2026-06-14)
**Versión:** 1.0
**Tipo:** Bug P1 — Spinner de guardado puede quedar activo indefinidamente.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~20 min
**Depende de:** `sleep_notifier.dart`

---

## 1. Problema

`SleepNotifier.saveManualSleep()` sigue el patrón:

```dart
state = state.copyWith(isSaving: true);
try {
  // ... lógica ...
  state = state.copyWith(isSaving: false);  // ← solo en el path feliz
} catch (e) {
  state = state.copyWith(isSaving: false);  // ← solo en el catch
}
```

Si ocurre una excepción entre el `isSaving: true` inicial y el primer reset dentro del
`try` (ej. construcción de `SleepLog` lanza `ArgumentError`, o una llamada asíncrona
se cancela por dispose), **el catch puede no ejecutarse** (si el error no es del tipo
correcto) o hay un path donde `isSaving` queda `true` hasta el siguiente rebuild.

El mismo patrón puede estar en otros notifiers que manejan operaciones guardables.

---

## 2. Solución

### inc1 — Patrón `try/finally` en `saveManualSleep`

```dart
// sleep_notifier.dart
Future<void> saveManualSleep({...}) async {
  if (!mounted) return;
  state = state.copyWith(isSaving: true);
  try {
    final log = SleepLog(
      id: const Uuid().v4(),
      fellAsleep: fellAsleep,
      wokeUp: wokeUp,
    );
    // Optimistic update
    state = state.copyWith(lastLog: log, isSaving: false);
    // Write no-bloqueante (SPEC-206)
    unawaited(
      _repo.saveSleep(_userId!, log).catchError((Object e) {
        AppLogger.warning('[SleepNotifier] saveSleep falló: $e');
      }),
    );
  } catch (e) {
    AppLogger.warning('[SleepNotifier] saveManualSleep error: $e');
    // fall-through al finally
  } finally {
    // Garantiza reset de isSaving sin importar qué ocurrió arriba.
    if (mounted) state = state.copyWith(isSaving: false);
  }
}
```

### inc2 — Auditar otros métodos con `isSaving`

Buscar en el codebase todos los patrones `isSaving: true` / `isSaving: false` y verificar
que todos tienen `try/finally` o que el `isSaving: false` está garantizado:

```bash
grep -rn "isSaving: true" lib/
```

Por cada resultado: confirmar que hay un `finally` que resetea, o que el path de error
está cubierto de forma exhaustiva.

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/dashboard/application/sleep_notifier.dart` | `try/finally` en `saveManualSleep` |
| Otros notifiers con `isSaving` | Verificar y añadir `finally` si falta |

---

## 4. Criterios de aceptación

- [ ] Simular error de construcción de `SleepLog` (pasar `wokeUp` anterior a `fellAsleep`) →
  la UI no muestra spinner indefinido, vuelve al estado normal.
- [ ] `flutter analyze` sin warnings.
- [ ] `grep -rn "isSaving: true" lib/` → todos los resultados tienen `finally` correspondiente.
