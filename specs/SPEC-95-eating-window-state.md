# SPEC-95 — `EatingWindowState` y painter alineado al protocolo del usuario

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Bug fix funcional MVP
**Marco normativo:** `CONSTITUTION.md`, `FastingProtocol` (16:8 / 18:6 / 20:4 / Ninguno).

---

# 1. Contexto

El `CircadianClock` del Dashboard pinta dos capas para visualizar el estado metabólico actual del usuario:

- **Capa "Ayuno":** arco que muestra cuánto lleva el ayuno actual, hitos de 12h / 18h / 24h. Pintado por `FastingRingPainter` cuando `fastingState.isActive == true`.
- **Capa "Ventana de comida":** arco que muestra cuándo abrió la ventana, cuándo cierra, dónde estamos dentro. Pintado por `EatingWindowPainter` cuando `fastingState.isActive == false`.

Reporte de Carlos (14-may-2026 con screenshots del usuario "PRUEBA" protocolo 18:6):
> "Cuando está en ventana de alimentación, el círculo interno no está mostrando el avance, tampoco se adapta a la hora de inicio o de fin del ayuno o de la ventana de alimentación."

# 2. Problema

Tres defectos encadenados:

**2.1 El painter recibe datos del ayuno, no de la ventana.**
`circadian_clock.dart:62-67` invoca `EatingWindowPainter(startTime: fastingState.startTime ?? now, duration: fastingState.duration, ...)`. Esos campos representan el ayuno, no la ventana. Cuando no hay ayuno activo:
- `fastingState.startTime` puede ser null → cae al `now` → arco arranca desde la hora actual (incorrecto).
- `fastingState.duration` es zero o el tiempo desde el último cierre → `sweepAngle = 0` → arco no se dibuja.

**2.2 `targetWindowHours` hard-coded en 8.**
`eating_window_painter.dart:16` asume protocolo 16:8 para todos. Un usuario con 18:6 debería ver ventana de 6h, con 20:4 de 4h. Hoy todos ven 8h.

**2.3 No existe el concepto de "fin de ventana".**
El painter dibuja el sweep a partir de un `duration` arbitrario, no calcula `windowEnd = windowStart + protocolHours`. Sin ese límite, ni se ve la ventana planeada ni se sabe cuándo debe reiniciar el ayuno.

**Causa raíz arquitectónica:** `FastingState` mezcla dos conceptos distintos — estado del ayuno y estado de la ventana de comida. Cuando `isActive==false`, el painter intenta inferir el segundo desde el primero y no funciona.

# 3. Solución propuesta

**3.1 Nuevo value object puro `EatingWindowState`** en `lib/src/features/dashboard/domain/eating_window_state.dart`:

```dart
class EatingWindowState {
  final DateTime windowStart;
  final DateTime windowEnd;
  final int windowDurationHours;        // 8 / 6 / 4 / 14 según protocolo
  final DateTime now;
  final EatingWindowStatus status;      // beforeWindow | withinWindow | afterWindow | unknown
  final double progressPercent;         // 0.0 .. 1.0
}

enum EatingWindowStatus { beforeWindow, withinWindow, afterWindow, unknown }
```

Con un constructor estático `EatingWindowState.compute(...)` que recibe `lastInterval`, `user`, `now` y produce el state.

**3.2 Helper puro `_windowHoursForProtocol(String protocol)`:**

| protocolo | windowHours |
|---|---|
| `"16:8"` | 8 |
| `"18:6"` | 6 |
| `"20:4"` | 4 |
| `"Ninguno"` o cualquier otro | 14 (default sensible: ventana de comida normal de un adulto sano sin TRF) |

**3.3 Lógica de `windowStart`:**

- Si `lastInterval != null && lastInterval.isFasting == false`: el usuario está en ventana de comida en curso. `windowStart = lastInterval.startTime` (es el momento en que cerró el ayuno).
- Si `lastInterval != null && lastInterval.isFasting == true`: hay ayuno activo. El componente que use este state debe verificar `fastingProvider.isActive` antes y NO pintar `EatingWindow`. Si por alguna razón se llama igual, devolver `status: unknown` y datos derivados del `firstMealGoal` para no fallar.
- Si `lastInterval == null` (usuario sin historial): caer a `user.profile.firstMealGoal` del día de hoy. Si también es null, caer a un default sensible (08:00 hora local).

**3.4 Nuevo provider `eatingWindowProvider`** en `lib/src/features/dashboard/application/eating_window_provider.dart` que computa `EatingWindowState` a partir de `lastFastingIntervalProvider` + `currentUserStreamProvider` + `metabolicPulseProvider` (para refrescar cada 10s).

**3.5 Refactor `EatingWindowPainter`** para recibir explícitamente:
- `windowStart: DateTime`
- `windowEnd: DateTime`
- `now: DateTime`
- `mealsCount: int` (sigue derivándose de `user.mealsPerDay` desde el caller)

Eliminar `duration` y `targetWindowHours` del constructor — todo se deriva de los DateTimes.

Lógica de dibujo nueva:
- Arco completo `[windowStart, windowEnd]` en color naranja tenue (alpha 0.20). Es la "ventana planeada".
- Si `now ∈ [windowStart, windowEnd]`: arco saturado desde `windowStart` hasta `now` (progreso real).
- Si `now > windowEnd`: arco completo saturado + indicador visual de "ventana cerrada" (ej. tono rojizo en los últimos grados).
- Si `now < windowStart`: solo el arco tenue (sin progreso).
- Hitos nutricionales se siguen distribuyendo entre `windowStart` y `windowEnd` (no fijos a 8h).

**3.6 Refactor `CircadianClock`** para:
- Recibir un `eatingWindow: EatingWindowState?` adicional.
- Pasar al painter los DateTimes correctos según `fastingState.isActive`.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear value object | `lib/src/features/dashboard/domain/eating_window_state.dart` |
| 2 | Tests puros del value object | `test/features/dashboard/domain/eating_window_state_test.dart` |
| 3 | Crear provider Riverpod | `lib/src/features/dashboard/application/eating_window_provider.dart` |
| 4 | Refactor del painter | `lib/src/features/dashboard/presentation/widgets/parts/eating_window_painter.dart` |
| 5 | Refactor del clock | `lib/src/features/dashboard/presentation/widgets/circadian_clock.dart` |
| 6 | Cablear el provider en el dashboard | `lib/src/features/dashboard/presentation/dashboard_screen.dart` |

# 5. Criterios de aceptación

1. Usuario protocolo `18:6` que terminó su ayuno a las 13:00 → ve arco de ventana entre 13:00 y 19:00, progreso hasta `now` si está dentro.
2. Usuario protocolo `20:4` → ve arco de 4h.
3. Usuario protocolo `"Ninguno"` → ve arco de 14h (default sensible).
4. Usuario nuevo sin historial de ayuno → ve arco a partir de `firstMealGoal` del perfil (o 08:00 si no hay).
5. Si `now > windowEnd` (ventana cerrada): visualmente se distingue de "ventana abierta sin progreso".
6. Cuando `fastingState.isActive == true`, NO se pinta `EatingWindowPainter`. Sigue `FastingRingPainter` como hoy.
7. `flutter analyze` sin issues nuevos.
8. `flutter test` mantiene 490+ verdes con +N nuevos del value object.

# 6. Pruebas

`eating_window_state_test.dart`:
- protocolo `18:6` con lastInterval cerrando ayuno a las 13:00, now=15:00 → status withinWindow, progress 33%, windowEnd 19:00.
- protocolo `20:4` con lastInterval a las 17:00, now=20:00 → status withinWindow, progress 75%, windowEnd 21:00.
- protocolo `"Ninguno"` con lastInterval null y firstMealGoal=08:00, now=12:00 → windowStart 08:00, windowEnd 22:00, progress 28.6%.
- lastInterval con `isFasting=true`, now cualquier hora → status `unknown` (el caller no debería invocar esta ruta, pero el state no falla).
- now < windowStart → status beforeWindow, progress 0.
- now > windowEnd → status afterWindow, progress clamp 1.0.
- Sin historial y sin firstMealGoal → fallback 08:00 + windowHours por protocolo.

# 7. Riesgos

**7.1 Cambio de firma del painter rompe call-sites no visibles.**
Mitigación: `flutter analyze` antes de commit. El único call-site real era `circadian_clock.dart` (verificado).

**7.2 Default 14h para protocolo "Ninguno" puede sentirse arbitrario.**
Documentado en código y en este SPEC. Si en el futuro el equipo médico recomienda otro número (ej. 12h por circadianos), se ajusta en un punto.

**7.3 Usuarios con `lastInterval` viejo (de hace 2 días) confunden al cálculo.**
Mitigación: si `lastInterval.startTime` está fuera del rango `[now - 24h, now]`, el state cae al fallback `firstMealGoal` de hoy. Eso evita pintar una ventana basada en data stale.

**7.4 El display de "ventana cerrada" (now > windowEnd) puede sentirse alarmista.**
Mitigación visual: cambio de tono sutil, no rojo agresivo. El equipo de UX puede ajustar el color en una micro-iteración futura.

# 8. Out of scope

- Notificaciones push cuando se acerca el fin de ventana (esto vive en `notification_scheduler.dart`, SPEC separada si se quiere mejorar).
- Animación del arco al cambiar de status.
- Ajustar `FastingRingPainter` (que funciona OK; este SPEC solo toca la ventana).
- Cambiar el copy de "BENEFICIOS AL INICIAR" del card de Ayuno (Carlos puede mencionarlo en una SPEC de copy si lo quiere).
- Lógica de "Iniciar Ayuno" / "Corregir hora de inicio" — eso sigue en `fastingProvider` sin cambios.

# 9. Resultado

(Se completa al cerrar el SPEC.)
