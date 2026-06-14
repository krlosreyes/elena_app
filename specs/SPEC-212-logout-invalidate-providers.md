# SPEC-212 — Logout limpio: invalidar todos los providers en signOut()

**Estado:** APPROVED-DESIGN (2026-06-14)
**Versión:** 1.0
**Tipo:** Bug P1 — Datos del usuario anterior visibles por un frame en logout/login.
**Líder:** Carlos · **Implementación:** Claude
**Estimación:** ~20 min
**Depende de:** `auth_controller.dart`

---

## 1. Problema

`AuthController.signOut()` invalida algunos providers pero no todos los que tienen
estado de usuario. En la ventana entre `signOut()` y la emisión del `null` de
`authStateProvider`, los providers con subscripciones Firestore activas pueden:

1. Recibir un último snapshot con error `permission-denied` (generando logs de error).
2. Mantener en memoria el estado del usuario anterior hasta que Riverpod los rebuilddea.

Providers **no invalidados** en `signOut()` actual:

| Provider | Riesgo |
|----------|--------|
| `lastFastingIntervalProvider` | Frame con ayuno del usuario anterior |
| `lastCompletedFastingProvider` | Frame con ayuno completado del usuario anterior |
| `lastClosedMetabolicCycleProvider` | Muestra card de cierre del usuario anterior |
| `metabolicCyclesHistoryProvider` | Historia de ciclos del usuario anterior |
| `progressProvider` | Biometría del usuario anterior |
| `globalSleepProvider` (si no se elimina en SPEC-209) | IMR con sueño del usuario anterior |

---

## 2. Solución

### inc1 — Consolidar invalidaciones en `signOut()`

```dart
// auth_controller.dart
Future<void> signOut() async {
  // Providers que reciben userId directamente
  _ref.invalidate(fastingProvider);
  _ref.invalidate(sleepProvider);
  _ref.invalidate(nutritionProvider);
  _ref.invalidate(exerciseProvider);
  _ref.invalidate(hydrationProvider);

  // Providers de ayuno
  _ref.invalidate(lastFastingIntervalProvider);
  _ref.invalidate(lastCompletedFastingProvider);

  // Providers de ciclo metabólico
  _ref.invalidate(currentMetabolicCycleProvider);
  _ref.invalidate(lastClosedMetabolicCycleProvider);
  _ref.invalidate(metabolicCyclesHistoryProvider);
  _ref.invalidate(last7ClosedCyclesProvider);
  _ref.invalidate(last14ClosedCyclesProvider);

  // Progreso / biometría
  _ref.invalidate(progressProvider);

  // Streak
  _ref.invalidate(streakProvider);

  // Auth (último — dispara la navegación al router)
  await _authRepository.signOut();
}
```

### inc2 — Verificar que los providers con guards de `account == null` retornan estado vacío

Todos los `StreamProvider` que leen datos de usuario deben tener:
```dart
final account = ref.watch(authStateProvider).value;
if (account == null) return Stream.value(/* estado vacío */);
```

Confirmar que los providers listados arriba tienen este guard. Si alguno no lo tiene,
añadirlo.

---

## 3. Archivos afectados

| Archivo | Cambio |
|---------|--------|
| `lib/src/features/auth/application/auth_controller.dart` | Lista completa de `_ref.invalidate()` en `signOut()` |

---

## 4. Criterios de aceptación

- [ ] Logout → login como usuario diferente → ningún dato del primer usuario visible en
  ningún frame (verificar Dashboard, Análisis, Progreso).
- [ ] No hay logs `permission-denied` de Firestore durante el logout.
- [ ] `flutter analyze` sin imports muertos o providers referenciados que no existen.

---

## 5. Nota de orden

Ejecutar SPEC-209 (unificar SleepProvider) antes de este SPEC. Una vez eliminado
`globalSleepProvider`, no hay que invalidarlo aquí.
