# SPEC-220 — Celebración al cruzar umbral 3/5 pilares

**Estado:** IMPLEMENTED (2026-06-17)
**Versión:** 0.1
**Líder:** Carlos · **Implementación:** Claude
**Depende de:** SPEC-65 (streak entry), SPEC-194 (coaching pipeline).
**Prioridad:** Alta — pre-launch (retención/engagement).
**Estimación:** 3 SP

---

## 1. Problema

Cuando el usuario completa su 3er pilar del día y cruza el umbral de `qualifiesForStreak`, no recibe ningún feedback positivo. El `streak_notifier.dart` ya detecta el cambio (línea 262: `newEntry.qualifiesForStreak != prevQualified`) pero no emite ningún evento. Este es el momento de mayor refuerzo positivo del día — "hoy ya cuentas para tu racha" — y está completamente desperdiciado.

Para una app de salud metabólica donde la adherencia a largo plazo es el objetivo, la ausencia de celebración en el momento más significativo del día es un gap de producto grave.

## 2. Solución

### 2.1 Evento de celebración

**`streak_notifier.dart`** — En el bloque donde `newEntry.qualifiesForStreak != prevQualified`:

```dart
if (newEntry.qualifiesForStreak && !prevQualified) {
  // Emitir evento de celebración
  _ref.read(celebrationEventProvider.notifier).state = CelebrationEvent(
    type: CelebrationType.streakThreshold,
    pillarsCompleted: newEntry.pillarsCompleted,
    currentStreak: state.currentStreak + 1, // incluye hoy
    timestamp: DateTime.now(),
  );
}
```

### 2.2 Modelo del evento

**Nuevo archivo:** `core/domain/celebration_event.dart`

```dart
enum CelebrationType {
  streakThreshold,  // 3/5 pilares → cuenta para racha
  // Futuro: streakMilestone (7 días, 30 días), personalBest, etc.
}

class CelebrationEvent {
  final CelebrationType type;
  final int pillarsCompleted;
  final int currentStreak;
  final DateTime timestamp;
  // ...
}
```

**Provider:** `StateProvider<CelebrationEvent?>((_) => null)` — se consume y se limpia.

### 2.3 Presentación

**Dashboard** — Un widget `CelebrationOverlay` que observa `celebrationEventProvider`:

- **Visual:** Micro-animación — banner deslizante desde arriba (NO modal, NO interrumpe).
- **Copy:** Varía según contexto:
  - Primera vez hoy: "🎯 3/5 — ¡Hoy cuentas para tu racha!"
  - Con racha activa: "🔥 3/5 — Día {N} consecutivo. Vas muy bien."
  - 4to pilar: "💪 4/5 — Un pilar más que ayer" (si aplica).
  - 5/5: "⭐ 5/5 — Día perfecto. Tu cuerpo lo nota."
- **Duración:** 3 segundos, auto-dismiss. Tap descarta inmediato.
- **Tono:** Cálido, sin culpa, sin exceso. Consistente con SPEC-169 (tono notificaciones).

### 2.4 Notificación local (app en background)

Si la racha se evalúa vía `CoachingActionRouter.flush()` al volver a foreground y el usuario no está viendo el dashboard, considerar una notificación local inmediata — sujeto a validación de UX. Por ahora, solo el banner in-app.

## 3. Archivos a tocar

| Archivo | Cambio |
|---------|--------|
| `core/domain/celebration_event.dart` | NUEVO — modelo + enum |
| `core/providers/celebration_providers.dart` | NUEVO — StateProvider |
| `features/streak/application/streak_notifier.dart` | Emitir evento en el bloque de detección |
| `features/dashboard/presentation/widgets/celebration_overlay.dart` | NUEVO — widget banner |
| `features/dashboard/presentation/dashboard_screen.dart` | Agregar CelebrationOverlay al Stack |

## 4. Tests

- Unit: `streak_notifier` — simular transición de 2→3 pilares, verificar que `celebrationEventProvider` emite.
- Unit: no emitir si ya estaba en `qualifiesForStreak` (pilar 4→5 no re-dispara threshold).
- Widget: `CelebrationOverlay` renderiza y auto-descarta a los 3s.

## 5. Notas

- El evento es one-shot — se limpia al consumir. No persiste en Firestore.
- Consistente con el modelo de coaching (SPEC-194): es feedback positivo, no una acción.
- Futuras extensiones: milestones de racha (7, 14, 30 días) usan el mismo mecanismo.
