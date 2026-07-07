# SPEC-215 — Limpieza de código deprecated y duplicados

**Estado:** IMPLEMENTED (2026-06-14) — fuente canónica fastingHoursForProtocol + deprecados eliminados. commit 5215720.
**Versión:** 1.0
**Tipo:** Deuda técnica P2 — Código muerto que confunde y genera warnings de compilación.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~30 min
**Depende de:** SPEC-209 (unificación SleepProvider — ejecutar primero)

---

## 1. Elementos a eliminar

### DUP-2 — `dismissLastCycleClosure` (deprecated, sin callers)

**Archivo:** `lib/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart`

Función marcada `@Deprecated` con cuerpo activo. Ningún caller en el codebase.

```dart
// ELIMINAR — líneas 166–172
@Deprecated('Use cycleClosureDismissalProvider.notifier.dismiss instead.')
Future<void> dismissLastCycleClosure({
  required SharedPreferences prefs,
  required String cycleId,
}) async {
  await prefs.setString(_kLastCycleClosureDismissedKey, cycleId);
}
```

---

### DUP-3 — `NutritionRepository.watchTodayLogs` (deprecated en interfaz e implementación)

**Archivos:**
- `lib/src/features/nutrition/domain/nutrition_repository.dart`
- `lib/src/features/nutrition/data/nutrition_repository_impl.dart`

Método marcado `@Deprecated` en la interfaz. La implementación sigue presente.
Ningún notifier activo lo llama (todos usan `watchSinceLogs`).

```dart
// ELIMINAR de nutrition_repository.dart
@Deprecated('Use watchSinceLogs instead')
Stream<List<NutritionLog>> watchTodayLogs(String userId);

// ELIMINAR de nutrition_repository_impl.dart
@override
Stream<List<NutritionLog>> watchTodayLogs(String userId) { ... }
```

---

### DUP-4 — Lógica `hoursFromProtocol` duplicada en dos clases

**Archivo 1:** `lib/src/features/streak/application/streak_notifier.dart`
Método: `_fastingTargetHours(String protocol)`

**Archivo 2:** `lib/src/features/metabolic_cycle/application/metabolic_cycle_service.dart`
Método: `_hoursFromProtocol(String protocol)`

Las implementaciones difieren en edge cases (`'OMAD'`, `'22:2'`). Extraer a una
función pura compartida.

---

## 2. Solución

### inc1 — Eliminar código deprecated

Borrar las declaraciones y implementaciones listadas en §1 (DUP-2, DUP-3).
Verificar con `grep -r "dismissLastCycleClosure\|watchTodayLogs"` que no quedan callers.

### inc2 — Extraer `hoursFromProtocol` a función compartida

Crear `lib/src/features/dashboard/domain/fasting_protocol_utils.dart`:

```dart
// fasting_protocol_utils.dart
/// Horas de ayuno del protocolo. Null si el protocolo no tiene ventana de ayuno.
/// Fuente de verdad única para todos los módulos que necesiten este dato.
double? fastingHoursForProtocol(String protocol) {
  switch (protocol) {
    case '12:12': return 12;
    case '14:10': return 14;
    case '16:8':  return 16;
    case '18:6':  return 18;
    case '20:4':  return 20;
    case '22:2':  return 22;
    case 'OMAD':  return 23;
    case 'Ninguno': return null;
    default: return null;
  }
}
```

Reemplazar en `streak_notifier.dart` y `metabolic_cycle_service.dart` los métodos
privados por llamadas a `fastingHoursForProtocol(protocol)`.

### inc3 — `flutter analyze` limpio

Después de las eliminaciones, correr `flutter analyze` y resolver cualquier warning
residual de imports muertos.

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart` | Eliminar `dismissLastCycleClosure` |
| `lib/src/features/nutrition/domain/nutrition_repository.dart` | Eliminar `watchTodayLogs` deprecated |
| `lib/src/features/nutrition/data/nutrition_repository_impl.dart` | Eliminar implementación deprecated |
| `lib/src/features/streak/application/streak_notifier.dart` | Reemplazar `_fastingTargetHours` con `fastingHoursForProtocol` |
| `lib/src/features/metabolic_cycle/application/metabolic_cycle_service.dart` | Reemplazar `_hoursFromProtocol` con `fastingHoursForProtocol` |
| `lib/src/features/dashboard/domain/fasting_protocol_utils.dart` (nuevo) | Función `fastingHoursForProtocol` |

---

## 4. Criterios de aceptación

- [ ] `grep -r "dismissLastCycleClosure"` → 0 resultados.
- [ ] `grep -r "watchTodayLogs"` → 0 resultados.
- [ ] `grep -r "_fastingTargetHours\|_hoursFromProtocol"` → 0 resultados (reemplazados).
- [ ] `flutter analyze` → 0 warnings en archivos modificados.
- [ ] Tests existentes pasan sin cambios (la lógica es idéntica, solo se consolidó).
