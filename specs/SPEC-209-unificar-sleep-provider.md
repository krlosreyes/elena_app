# SPEC-209 — Unificar SleepNotifier: eliminar globalSleepProvider

**Estado:** IMPLEMENTED (2026-06-14) — globalSleepProvider eliminado, fuente única de sueño. commit 1522773.
**Versión:** 1.0
**Tipo:** Bug P0 — IMR calculado con datos de sueño del usuario anterior en logout/login.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~30 min
**Depende de:** `sleep_provider.dart`, `metabolic_state_provider.dart`
**Bloquea:** correcta lectura del IMR en sesiones multi-usuario (mismo dispositivo)

---

## 1. Problema

Existen **dos instancias independientes** de `SleepNotifier`:

| Provider | Archivo | Callers clave |
|----------|---------|---------------|
| `sleepProvider` | `dashboard/application/sleep_notifier.dart` | Dashboard, StreakNotifier, DailyResetService, análisis, `signOut()` |
| `globalSleepProvider` | `shared/providers/sleep_provider.dart` | `metabolicStateProvider` → `sleepDurationProvider`, `lastSleepLogProvider` |

Cada una tiene su propia subscripción Firestore y su propio state. **Nunca se sincronizan.**

Consecuencias:

1. **IMR incorrecto:** `metabolicStateProvider` calcula el IMR que ve el usuario
   leyendo sueño de `globalSleepProvider`. Si el usuario registra sueño, `sleepProvider`
   actualiza pero `globalSleepProvider` no necesariamente (depende del orden de evaluación).
2. **Fuga de datos tras logout:** `signOut()` invalida solo `sleepProvider`. `globalSleepProvider`
   sigue activo con datos del usuario anterior. El siguiente usuario ve el IMR calculado
   con el sueño del usuario previo hasta cold restart.
3. **Doble subscripción Firestore:** dos listeners Firestore activos para la misma colección
   `sleep_history`.

---

## 2. Solución

### inc1 — Eliminar `globalSleepProvider` y sus providers derivados huérfanos

En `lib/src/shared/providers/sleep_provider.dart`:
- Eliminar `globalSleepProvider` (la instancia redundante de `SleepNotifier`).
- Eliminar `sleepDurationProvider` si solo lo usa `metabolicStateProvider`.
- Eliminar `lastSleepLogProvider` si solo lo usa `metabolicStateProvider`.

### inc2 — Redirigir `metabolicStateProvider` a `sleepProvider`

En el provider que construye el estado metabólico para el IMR, reemplazar las referencias:

```dart
// ANTES
final sleepDuration = ref.watch(sleepDurationProvider);
final lastSleep = ref.watch(lastSleepLogProvider);

// DESPUÉS
final sleepState = ref.watch(sleepProvider);
final sleepDuration = sleepState.lastLog != null
    ? sleepState.lastLog!.wokeUp.difference(sleepState.lastLog!.fellAsleep)
    : Duration.zero;
final lastSleep = sleepState.lastLog;
```

### inc3 — Verificar `signOut()` invalida el único provider

Confirmar que `auth_controller.dart` invalida `sleepProvider` (ya lo hace). No hay nada
más que cambiar si se eliminó `globalSleepProvider`.

### inc4 — Verificar `DailyResetService` reset correcto

`DailyResetService` ya resetea `sleepProvider`. Con la unificación, el reset cubre
automáticamente la fuente del IMR.

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/shared/providers/sleep_provider.dart` | Eliminar `globalSleepProvider`, `sleepDurationProvider`, `lastSleepLogProvider` |
| `lib/src/features/dashboard/application/metabolic_state_provider.dart` (o equivalente) | Leer sueño de `sleepProvider` directamente |

---

## 4. Criterios de aceptación

- [ ] `flutter analyze` sin warnings sobre providers de sueño eliminados.
- [ ] En sesión del usuario A: registrar sueño → IMR se actualiza inmediatamente.
- [ ] Logout → login como usuario B → IMR no refleja datos de sueño del usuario A.
- [ ] Solo una subscripción activa a `sleep_history` en Firestore (verificable en logs de
  AppLogger o en la consola de Firebase Emulator).

---

## 5. Riesgo

Bajo. `globalSleepProvider` y sus derivados son internos a `metabolicStateProvider`.
No hay UI que los consuma directamente (todos pasan por el IMR o por `sleepProvider`).
