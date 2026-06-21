# SPEC-237 — Correcciones de Auditoría de Código

**Estado:** IMPLEMENTED 2026-06-21  
**Rama:** mvp-core-clean  
**Origen:** Auditoría estática archivo-por-archivo de los 440 archivos Dart (2026-06-21)

---

## Resumen

Auditoría completa del codebase identificó 5 bugs. 2 de alta prioridad afectan el cálculo del IMR en producción. Los otros 3 son de prioridad media/baja (silenciamiento de errores, antipatrón Riverpod, API deprecada).

---

## BUG-A — `circadianScore` bonus cancelado por clamp (Alta)

**Archivo:** `lib/src/core/engine/score_engine.dart`  
**Líneas:** 201, 232

### Causa raíz

El bloque Conducta asigna `circadianScore = 1.1` cuando el usuario come **antes** de su meta eTRF (bonus por disciplina circadiana). Sin embargo, en la línea siguiente se aplica `.clamp(0.0, 1.0)` antes de usar el valor, anulando completamente el bonus:

```dart
// ANTES (buggy):
final double behaviorBlock = (0.38 * circadianScore.clamp(0.0, 1.0)) + ...
//                                               ^^^^^^^^^^^^^^^^ cancela 1.1 → 1.0
```

**Impacto cuantificado:**
- Bonus esperado: `0.38 × 1.1 = 0.418` en bloque circadiano
- Bonus real: `0.38 × 1.0 = 0.380`
- Pérdida en IMR final: `0.038 × 0.25 × 100 = 0.95 puntos` (nunca aplicados)
- La penalización de 0.5 sí funciona (0.5 < 1.0, no afectada por el clamp)

### Fix

Aplicar el clamp solo al acumular en `raw`, donde ya hay clamp global a 100. Dentro del bloque Conducta, permitir que `circadianScore` exceda 1.0 para que el bonus tenga efecto:

```dart
// DESPUÉS (correcto):
final double behaviorBlock = (0.38 * circadianScore) + // sin clamp aquí
    (0.20 * sSleep) +
    (0.20 * sExercise) +
    (0.12 * nutritionScore.clamp(0.0, 1.0)) +
    (0.10 * sHydration);
```

El `raw` final ya tiene `.clamp(0, 100)` que acota el score total.  
`circadianAlignment` en el resultado se sigue clampando a 1.0 (es un indicador 0-1, no un score).

---

## BUG-B — Campo `whtr` duplica fórmula de `ica` (Alta)

**Archivo:** `lib/src/core/engine/score_engine.dart`  
**Líneas:** 248–249, 277, 322–323, 351

### Causa raíz

`ica` (Índice Cintura-Altura) y `whtr` (Waist-to-Height Ratio) son conceptualmente distintos en el dominio:
- `ica` = `waistCircumference / height` → forma correcta de cálculo
- `whtr` en `IMRv2Result` debería recibir el mismo valor (son equivalentes matemáticamente)

Sin embargo, el campo `whtr` se asignaba con la variable `ica` de forma redundante. Aunque el resultado numérico es correcto, el código es confuso: `whtr: ica` sugiere que se usó la variable incorrecta. La variable local `whtr` calculada en el bloque interno (`s1`) se descarta sin asignar al resultado.

### Fix

Asignar `whtr` explícitamente desde el valor calculado (no reusar `ica` como alias):

```dart
// DESPUÉS:
whtr: (user.waistCircumference ?? 0) > 0
    ? user.waistCircumference! / user.height
    : 0.0,
```

Esto hace el código auto-documentado y elimina la confusión entre la variable local `whtr` del bloque `s1` y el campo del resultado.

---

## BUG-C — `catch (_) {}` silencia errores de parsing de Goals (Media)

**Archivo:** `lib/src/features/goals/data/goal_repository.dart`  
**Línea:** 74

### Causa raíz

Si un documento de objetivo en Firestore falla al deserializarse (campo inesperado, cambio de schema, migración incompleta), el error se silencia completamente. El usuario ve sus metas vacías sin ninguna traza de diagnóstico:

```dart
// ANTES:
} catch (_) {}
```

### Fix

Agregar log de warning con contexto:

```dart
// DESPUÉS:
} catch (e) {
  AppLogger.warning('[GoalRepository] goal inválido key=${entry.key}: $e');
}
```

---

## BUG-D — `ref.read()` en `build()` sin reactividad (Media)

**Archivo:** `lib/src/features/health_sync/presentation/health_sync_card.dart`  
**Línea:** 74

### Causa raíz

`ref.read()` dentro de `Widget build()` no es reactivo. Si el provider cambia de implementación (mock↔real en testing, cambio de plataforma), el widget no se reconstruye. Es un antipatrón Riverpod documentado.

```dart
// ANTES (antipatrón):
final service = ref.read(healthSyncServiceProvider);
```

### Fix

```dart
// DESPUÉS:
final service = ref.watch(healthSyncServiceProvider);
```

---

## BUG-E — `.withOpacity()` deprecado en Flutter 3.x (Baja)

**Archivo:** `lib/src/features/dashboard/presentation/widgets/celebration_overlay.dart`  
**Líneas:** 120, 151

### Causa raíz

Flutter 3.x deprecó `Color.withOpacity()` en favor de `Color.withValues(alpha: ...)`.

### Fix

```dart
// ANTES:
color: _backgroundColor.withOpacity(0.3)
color: Colors.white.withOpacity(0.85)

// DESPUÉS:
color: _backgroundColor.withValues(alpha: 0.3)
color: Colors.white.withValues(alpha: 0.85)
```

---

## Criterios de Aceptación

- [ ] `circadianScore = 1.1` produce IMR ~0.95 pts mayor que `circadianScore = 1.0`
- [ ] `IMRv2Result.whtr` tiene valor independiente de `ica` (misma fórmula, variable limpia)
- [ ] Error de parsing de goal genera log `WARNING` en consola
- [ ] `health_sync_card` se reconstruye si `healthSyncServiceProvider` cambia
- [ ] Compilación sin warnings de `.withOpacity()`

## Archivos modificados

```
lib/src/core/engine/score_engine.dart
lib/src/features/goals/data/goal_repository.dart
lib/src/features/health_sync/presentation/health_sync_card.dart
lib/src/features/dashboard/presentation/widgets/celebration_overlay.dart
```
