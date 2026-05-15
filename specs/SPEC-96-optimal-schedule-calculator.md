# SPEC-96 — Horarios óptimos coherentes con ciclo circadiano

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Lógica de negocio + coherencia circadiana
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` §3, §4, §6 (regla 1).

---

# 1. Contexto

La bibliografía científica (`docs/CIRCADIAN_BIBLIOGRAPHY.md` §4) prescribe ventanas óptimas concretas para cada protocolo de ayuno, ancladas al cierre obligatorio a las 20:30 (antes del bloqueo intestinal a las 22:00 documentado en Biological Dial §13):

| Protocolo | Apertura ventana | Cierre ventana | Inicio ayuno | Fin ayuno |
|---|---|---|---|---|
| Ninguno | 06:30 | 20:30 | 20:30 | 06:30 |
| 16:8 | 12:30 | 20:30 | 20:30 | 12:30 |
| 18:6 | 14:30 | 20:30 | 20:30 | 14:30 |
| 20:4 | 16:30 | 20:30 | 20:30 | 16:30 |

Hoy la app permite al usuario configurar `firstMealGoal` y `lastMealGoal` arbitrariamente y `EatingWindowState.compute` (SPEC-95) cae al `firstMealGoal` raw del perfil cuando no hay un intervalo de ayuno reciente. Esto produce dos defectos:

1. **Configuraciones incoherentes con la biología** pueden persistir sin advertencia (ej. cerrar ventana a las 23:00 viola el bloqueo intestinal).
2. **El usuario nuevo no recibe guía** — el onboarding pregunta hora de primera y última comida con pickers vacíos en lugar de proponer los óptimos derivados del protocolo elegido.

Carlos lo resumió: *"Debemos garantizar que el usuario inicie el ayuno y la ventana de alimentación en las horas que más le beneficia teniendo en cuenta el ciclo circadiano. El inicio y fin tanto del ayuno como de la ventana de alimentación deben ser completamente coherentes entre sí."*

# 2. Problema

**2.1 No existe una autoridad única que calcule los horarios óptimos.**
Cada componente (onboarding, profile, eating_window_state) deriva sus tiempos de forma diferente. No hay garantía de coherencia ayuno↔ventana.

**2.2 El onboarding deja al usuario adivinar.**
`onboarding_screen.dart` Step 2 (Cronograma) muestra pickers sin defaults clínicamente justificados. El usuario nuevo pone "08:00 / 20:00" por inercia y termina con ventana de 12h cuando seleccionó protocolo 16:8.

**2.3 El profile permite configuraciones biológicamente incompatibles.**
Editar `lastMealGoal` a las 22:30 no dispara ningún warning. La app acepta lo que el usuario pone, contradiciendo la regla canónica.

**2.4 `EatingWindowState.compute` cae al raw `firstMealGoal` aunque sea incoherente.**
Si el perfil tiene `firstMealGoal: 09:00` pero el protocolo es 18:6, la ventana pintada arranca a las 09:00 (con cierre a las 15:00) — exactamente al revés de lo prescrito.

# 3. Solución propuesta

**3.1 Nuevo value object puro `OptimalSchedule`** en `lib/src/features/dashboard/domain/optimal_schedule.dart`:

```dart
class OptimalSchedule {
  final TimeOfDay windowStart;    // apertura de ventana de comida
  final TimeOfDay windowEnd;      // cierre de ventana
  final TimeOfDay fastingStart;   // == windowEnd
  final TimeOfDay fastingEnd;     // == windowStart (día siguiente)
  final int windowHours;
  final int fastingHours;
  final String fastingProtocol;   // canónico
}

class OptimalScheduleCalculator {
  /// Ancla: 20:30 como cierre de ventana de comida (antes del
  /// bloqueo intestinal a las 22:00).
  static const TimeOfDay kWindowEndAnchor = TimeOfDay(hour: 20, minute: 30);

  /// 21:00 es el límite absoluto. Cerrar después viola el bloqueo
  /// intestinal y arruina la calidad del sueño.
  static const TimeOfDay kHardLimitWindowEnd = TimeOfDay(hour: 21, minute: 0);

  static OptimalSchedule forProtocol(String protocol);
  static bool isCoherent(TimeOfDay windowStart, TimeOfDay windowEnd, String protocol);
  static String? lintReason(TimeOfDay windowStart, TimeOfDay windowEnd, String protocol);
}
```

**3.2 Refactor `EatingWindowState.compute`** para que cuando NO haya `lastInterval` reciente, use `OptimalScheduleCalculator.forProtocol(user.fastingProtocol)` como fuente — NO el `firstMealGoal` raw. El `firstMealGoal` se respeta solo si está dentro de la tolerancia (±60 min del óptimo).

**3.3 Auto-fill en onboarding** (`onboarding_screen.dart`):
- Step "Cronograma" muestra los horarios óptimos del protocolo elegido como **defaults precargados**.
- Cada picker tiene un label "Recomendado por Elena: HH:mm" debajo.
- El usuario puede sobreescribir pero el cambio fuera de ±60 min del óptimo dispara un tooltip con la justificación bibliográfica.

**3.4 Validación en profile** (`profile_screen.dart`):
- Al editar `firstMealGoal` o `lastMealGoal`:
  - Si dentro de tolerancia: guardado normal.
  - Si fuera de tolerancia: snackbar warning con el principio canónico (ej. "El bloqueo intestinal empieza a las 22:00 — cerrar tu ventana antes mejora tu sueño").
  - Si > 21:00 (hard limit): **bloquear** guardado, mostrar diálogo "Esta hora rompe el bloqueo intestinal documentado en la bibliografía circadiana. Cambia tu protocolo si necesitas comer más tarde."

**3.5 Helper `OptimalScheduleCalculator.lintReason`** devuelve un mensaje human-readable explicando por qué una configuración no es óptima (o `null` si lo es). Reutilizable desde onboarding y profile.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `OptimalSchedule` + calculator | `lib/src/features/dashboard/domain/optimal_schedule.dart` |
| 2 | Tests puros del calculator | `test/features/dashboard/domain/optimal_schedule_test.dart` |
| 3 | Refactor `EatingWindowState.compute` para usar óptimo cuando proceda | `lib/src/features/dashboard/domain/eating_window_state.dart` |
| 4 | Tests actualizados del eating_window_state | `test/features/dashboard/domain/eating_window_state_test.dart` |
| 5 | Auto-fill horarios al cambiar protocolo en onboarding | `lib/src/features/onboarding/presentation/onboarding_screen.dart` |
| 6 | Validación + warning en profile al editar horarios | `lib/src/features/auth/presentation/profile_screen.dart` |

# 5. Criterios de aceptación

1. `OptimalScheduleCalculator.forProtocol('16:8').windowStart` → `TimeOfDay(12, 30)`.
2. `OptimalScheduleCalculator.forProtocol('18:6').windowStart` → `TimeOfDay(14, 30)`.
3. `OptimalScheduleCalculator.forProtocol('20:4').windowStart` → `TimeOfDay(16, 30)`.
4. `OptimalScheduleCalculator.forProtocol('Ninguno').windowStart` → `TimeOfDay(6, 30)`.
5. Todos los protocolos cierran a `TimeOfDay(20, 30)`.
6. `isCoherent` retorna `true` para óptimo exacto, `true` para ±60 min, `false` para >60 min de desviación.
7. `lintReason` retorna `null` para configuración óptima, string específico para incoherente.
8. `EatingWindowState.compute` sin `lastInterval` usa óptimo (no raw `firstMealGoal`).
9. Onboarding precarga horarios al elegir protocolo. Cambiar protocolo recalcula.
10. Profile bloquea guardar `lastMealGoal > 21:00` con diálogo educativo.
11. Profile muestra warning (no bloqueante) para desviaciones >60 min.
12. `flutter analyze` sin issues nuevos. `flutter test` mantiene 504+ verdes con +M nuevos.

# 6. Pruebas

`optimal_schedule_test.dart`:
- Cada protocolo retorna horarios exactos esperados.
- `windowHours + fastingHours == 24` siempre.
- `fastingStart == windowEnd` y `fastingEnd == windowStart` siempre.
- `isCoherent` con desviación de 0/30/60/61/90 min: pasa en ≤60, falla en >60.
- `lintReason` retorna mensaje no-vacío para configs >60 min off; cita "bloqueo intestinal" cuando `windowEnd > 21:00`.

`eating_window_state_test.dart` (actualizados):
- Sin `lastInterval`, protocolo 18:6, sin `firstMealGoal` → `windowStart` = 14:30 (no 08:00 fallback viejo).
- Sin `lastInterval`, protocolo 18:6, con `firstMealGoal: 09:00` (incoherente) → `windowStart` = 14:30 (óptimo gana sobre raw incoherente).
- Sin `lastInterval`, protocolo 18:6, con `firstMealGoal: 14:00` (dentro de tolerancia ±60 min) → `windowStart` = 14:00 (respeta preferencia del usuario).
- Con `lastInterval` reciente (≤24h) → respeta `lastInterval.startTime` como antes (el SPEC no toca esa rama).

# 7. Riesgos

**7.1 Usuarios existentes con horarios ya configurados fuera del óptimo.**
Mitigación: el cambio es retrocompatible. La validación de profile sólo se dispara al editar; los valores persistidos se respetan hasta que el usuario los toque. El display del dashboard sí usa el óptimo (con tolerancia), así que el reloj se ve coherente.

**7.2 Tolerancia ±60 min es arbitraria.**
La bibliografía no fija una tolerancia exacta. 60 min es un compromiso razonable: respeta variabilidad individual (horarios de trabajo, costumbres familiares) sin tolerar desviaciones que rompen el principio circadiano. Si el equipo médico revisa, se ajusta en un punto.

**7.3 Hard limit a 21:00 puede frustrar a usuarios sociales.**
Mitigación: el bloqueo es por edición. El usuario que ya tenía `lastMealGoal: 22:00` no se ve afectado hasta que toque el valor. La app empuja, no obliga retroactivamente.

**7.4 `OptimalSchedule.forProtocol('OMAD')` o un protocolo desconocido.**
El calculator tira un default seguro (16:8) y AppLogger.warning. Cualquier protocolo nuevo debe agregarse explícitamente.

# 8. Out of scope

- Migración batch de usuarios existentes a horarios óptimos (decisión de UX no técnica, separada).
- Recomendar protocolo según ritmo del usuario (lo opuesto: SPEC futura podría sugerir 18:6 a alguien que ya cierra a las 19:00 naturalmente).
- Notificaciones push de recordatorio circadiano (SPEC-97 candidato).
- Diferenciar fines de semana (la bibliografía no distingue; sería SPEC futura tipo "modo flexible").
- Zonas horarias / viajes — la app asume hora local del device.

# 9. Resultado

(Se completa al cerrar el SPEC.)
