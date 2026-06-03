# SPEC-151 — Card "Meta alcanzada": opción de continuar ayunando

**Estado:** IN_PROGRESS
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Bug UX descubierto en validación de uso (Ola 1)
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 1 — Estabilización
**Estimación:** 1-2 horas
**Marco normativo:** `CONSTITUTION.md`.

---

## 1. Contexto

Durante uso real de la app post-SPEC-149.1, Carlos detectó que cuando el ayuno alcanza `targetHours` (16h en protocolo 16:8, etc.), el overlay "¡META ALCANZADA!" aparece con un único CTA "CONFIRMAR HITO REAL" que abre time picker → cierra el ayuno → abre ventana de alimentación.

**No hay forma de continuar ayunando** desde ese overlay. Si el usuario quiere extender más allá del target (práctica común en ayunos prolongados, autofagia profunda, OMAD/ADF ocasional), el overlay queda bloqueando la pantalla sin opción que respete su intención.

Esta SPEC añade un segundo CTA legítimo al overlay: **"CONTINUAR AYUNANDO"**.

## 2. Decisión de diseño

### 2.1 — Dos botones, ambos legítimos

| Botón | Visual | Acción |
|---|---|---|
| `TERMINAR AYUNO` | ElevatedButton (verde sólido) | Comportamiento previo: abre time picker → `confirmManualFastingEnd(manualTime)` → cierra ayuno → abre ventana. |
| `CONTINUAR AYUNANDO` | OutlinedButton (borde verde) | Llama `continueFastingPastTarget()` → silencia overlay → mantiene `isActive = true`. |

### 2.2 — Comportamiento de "Continuar ayunando"

`FastingNotifier.continueFastingPastTarget()` ejecuta:

1. Setea `_fastingEndConfirmedToday = true` para que `_tick()` no vuelva a activar `isWaitingForFastingEnd` en este ciclo.
2. Setea `state.isWaitingForFastingEnd = false` para ocultar overlay inmediatamente.
3. Mantiene `state.isActive = true` — el ayuno sigue corriendo.
4. Setea `state.completedToday = true` porque el target SÍ se alcanzó — el día cuenta para racha y pilar.

**Efectos visuales esperados:**
- El satélite/ring del ayuno queda en 100% (clampado por `progressPercentage`).
- El contador de horas sigue creciendo más allá del target → muestra "overtime" naturalmente.
- Al reabrir la app, el overlay no reaparece (mientras `_fastingEndConfirmedToday` siga true en memoria de sesión).

### 2.3 — Camino de salida cuando el usuario decide cerrar

El usuario cierra desde el flujo normal del dashboard (`_buildFastingConsciousnessCard` → `EarlyFastingEndDialog` → `confirmManualFastingEnd`). El mismo camino que ya existe para cierres tempranos. No se introduce UI duplicada.

### 2.4 — Restart de app durante overtime

Si Carlos reinicia la app durante overtime (ej: hot reload, kill+open):
- `_fastingEndConfirmedToday = false` en memoria fresca.
- `state.completedToday` se rehidrata como `true` desde `lastCompletedFastingProvider` si hay un intervalo completado HOY. Pero aquí el intervalo NO está completado (sigue abierto), así que esta vía no aplica.
- `_tick()` evalúa: `state.isActive && progressPercentage >= 1.0 && !_fastingEndConfirmedToday` → reactiva overlay.

**Decisión consciente:** después de un restart, el overlay puede reaparecer. Es comportamiento aceptable porque el usuario puede volver a tocar "Continuar". Persistir el "modo overtime" entre sesiones es complejidad innecesaria para esta SPEC. Si se vuelve un problema, abrir SPEC-151.1 con persistencia del flag.

## 3. Cambios técnicos

### 3.1 — `fasting_notifier.dart`

Nuevo método público `continueFastingPastTarget()`. Idempotente — segunda llamada con `isWaitingForFastingEnd == false` es no-op silencioso.

### 3.2 — `dashboard_screen.dart`

**`_buildBaseOverlay`** extendido con dos parámetros opcionales:
- `String? secondaryButtonLabel`
- `VoidCallback? onSecondary`

Si ambos provistos, renderiza un `OutlinedButton` debajo del primario.

**`_buildFastingEndOverlay`** pasa:
- `buttonLabel: "TERMINAR AYUNO"` (cambió de "CONFIRMAR HITO REAL" para claridad de intención)
- `secondaryButtonLabel: "CONTINUAR AYUNANDO"` con callback al notifier

**`_buildFeedingEndOverlay` y `_buildWakeUpOverlay`** quedan inalterados (no se les pasa secondary).

## 4. Criterios de aceptación

1. Cuando el ayuno alcanza target, el overlay muestra DOS botones: "TERMINAR AYUNO" (verde sólido) y "CONTINUAR AYUNANDO" (outlined).
2. Tap en "TERMINAR AYUNO" abre time picker y ejecuta el flujo previo de cierre.
3. Tap en "CONTINUAR AYUNANDO" oculta el overlay inmediatamente, el ayuno sigue activo, el contador sigue creciendo.
4. Después de "Continuar", el overlay no reaparece en `_tick` posteriores durante esta sesión.
5. El usuario puede cerrar el ayuno desde el dashboard normal en cualquier momento de overtime.

### 4.1 — Sobre tests

El cambio total son ~3 líneas de mutación de state en `FastingNotifier`. Testear este método unitariamente requiere mockear el árbol completo de providers que `FastingNotifier(Ref)` necesita en construcción (auth, user, ticker, repository) — el costo de setup excede el valor de cobertura para este delta.

**Validación de SPEC-151 es 100% visual en device**, con el siguiente protocolo:

1. Carlos inicia ayuno con `startFastingManual` apuntando ~17h hacia atrás (para activar el overlay rápido en protocolo 16:8).
2. Verifica que el overlay aparece con dos botones según §2.1.
3. Tap en "CONTINUAR AYUNANDO" → overlay desaparece, ring queda en 100%, contador sigue creciendo.
4. Espera ~30s y confirma que el overlay no reaparece.
5. Tap en el botón normal de cerrar (desde la card de Ayuno) → debería cerrar normal.

Si en el futuro se hace refactor del `FastingNotifier` a pure functions, agregar tests del `computeContinueState`.

## 5. Out of scope (explícito)

- **Persistencia del flag overtime entre sesiones:** no se aborda. Tras restart, overlay puede reaparecer. Caso edge, no bloqueante.
- **Notificación de "overtime"** al pasar X horas adicionales: future SPEC si UX lo demanda.
- **Subir el target dinámicamente** (16:8 → 18:6): rechazado en discusión previa por confundir al usuario.

## 6. Rollout

Sin breaking changes. Sin migración. Push a `mvp-core-clean` + validación visual cuando Carlos tenga iPhone.

## 7. Changelog

### v1.0 — 2026-06-02

UX fix descubierto en uso real. Respeta la intención del usuario cuando decide extender su ayuno más allá del protocolo declarado.
