# SPEC-108 — Unificación de IDs de sueño + diálogo de registro existente

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Bug fix de persistencia + mejora UX
**Marco normativo:** SPEC-106 (persistencia y edición del pilar Sueño).

---

# 1. Contexto

Carlos reportó: "al cerrar sesión y volver a ingresar los datos de sueño cambiaron, no son persistentes".

Auditoría: el bug es real y tiene causa exacta. `confirmManualWakeUp` (al despertar) y `saveManualSleep` (al editar) generan **IDs distintos para el mismo día calendario**:

- `confirmManualWakeUp`: `id: 'sync_YYYYMMDD'`
- `saveManualSleep`: `id: 'manual_YYYYMMDD'`

Resultado: dos documentos coexistiendo en `users/{uid}/sleep_history/` para el mismo día. El stream `streamLatest` ordena por `wokeUp desc limit 1` y devuelve cualquiera dependiendo del orden temporal. Cuando el usuario abre, edita y guarda, el sync queda zombie; cuando despierta y la app llama a `confirmManualWakeUp`, sobrescribe el `sync_*` con defaults del perfil y la edición manual previa "desaparece" del stream porque el sync tiene `wokeUp` más reciente.

Carlos también pidió una mejora UX: cuando ya hay un registro del día actual y el usuario toca "Actualizar Registro", mostrar primero un diálogo con el contenido del registro existente y dos rutas: editarlo o eliminar y crear uno nuevo.

# 2. Problema

**2.1 IDs duplicados.** Dos docs por día porque dos paths usan prefijos distintos.

**2.2 `confirmManualWakeUp` sobrescribe el manual.** Cuando se dispara automáticamente, escribe sobre `sync_*` con datos calculados del perfil — si el usuario había editado manualmente con metadata (calidad 1-5), no se conserva.

**2.3 UX "Actualizar Registro" no comunica que ya hay registro.** El sheet abre con campos precargados (gracias a SPEC-106) pero el usuario que YA registró manualmente no sabe si está sobreescribiendo o creando.

# 3. Solución propuesta

**3.1 Unificar IDs a `'sleep_YYYYMMDD'`.**

Ambos paths (`saveManualSleep` y `confirmManualWakeUp`) usan un helper privado `_dayDocId(DateTime)` que devuelve `'sleep_YYYYMMDD'`. Cualquier `repo.save()` del mismo día UPSERTS el mismo documento → un solo registro por día, persistencia idempotente.

**3.2 `confirmManualWakeUp` respeta lo ya registrado.**

Cambio defensivo: si `state.lastLog` existe Y es del día actual (mismo `wokeUp.day`), `confirmManualWakeUp` NO sobreescribe — el usuario ya registró. Si NO hay log o es de un día anterior, sí registra el auto-wake-up.

**3.3 Diálogo `SleepExistingLogDialog`.**

Modal Material 3 con:
- Título: "Ya tienes un registro de sueño hoy".
- Contenido: bedtime, waketime, duración, calidad (si está presente).
- Tres acciones: "Editar este registro" / "Eliminar y registrar nuevo" / "Cancelar".

**3.4 Dashboard intercepta el tap.**

Botón "Actualizar Registro":
- Si `state.lastLog == null` O el log NO es de hoy → abre sheet limpio (sin diálogo).
- Si hay log de hoy → muestra `SleepExistingLogDialog`. Según la opción elegida:
  - Editar → abre sheet con `initial: state.lastLog`.
  - Eliminar y crear nuevo → ejecuta el flujo del botón "Eliminar" (SPEC-106).
  - Cancelar → no-op.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Helper `_dayDocId` en notifier + uso en ambos paths | `sleep_notifier.dart` |
| 2 | Guard en `confirmManualWakeUp`: no sobreescribir si ya hay log de hoy | `sleep_notifier.dart` |
| 3 | Crear diálogo `SleepExistingLogDialog` | `lib/src/features/dashboard/presentation/widgets/sleep_existing_log_dialog.dart` |
| 4 | Dashboard: handler `_onTapUpdateSleep` con la lógica condicional | `dashboard_screen.dart` |

# 5. Criterios de aceptación

1. Después de un `confirmManualWakeUp`, el doc se guarda con id `sleep_20260514`.
2. Después de un `saveManualSleep`, el mismo doc (mismo id `sleep_20260514`) se sobrescribe — NO se crea otro.
3. Si el usuario edita manualmente y se duerme/despierta, `confirmManualWakeUp` NO sobreescribe el registro manual existente del día.
4. Tap "Actualizar Registro" con log de hoy → aparece diálogo con bedtime/waketime/duración/calidad.
5. Tap "Editar este registro" → abre sheet con campos precargados.
6. Tap "Eliminar y registrar nuevo" → diálogo de confirmación de eliminación + sheet limpio.
7. Tap "Cancelar" → no-op.
8. Tap "Actualizar Registro" sin log o con log de día anterior → abre sheet limpio directo.
9. Tras cerrar sesión y volver a entrar, el sheet precarga los campos ya registrados (no se pierden).
10. `flutter analyze` y `flutter test` sin regresiones.

# 6. Riesgos

**6.1 Docs legacy con id `sync_*` o `manual_*` siguen vivos en Firestore.**
Tras el cambio, los nuevos saves usan `sleep_*`. Los viejos quedan huérfanos. El stream lee el más reciente por `wokeUp` así que pueden seguir interfiriendo durante 1 día (hasta que el usuario registre con nuevo ID que probablemente tendrá `wokeUp` más reciente). Aceptable; no requiere migración batch.

**6.2 Si los docs legacy tienen wokeUp más reciente que el nuevo `sleep_*`, el stream emite el viejo.**
Sumamente edge case (requiere `confirmManualWakeUp` con `now` mayor que cualquier edición manual). Si se reporta, una SPEC futura limpia los legacy.

**6.3 Cambiar el comportamiento de `confirmManualWakeUp` (no sobreescribir si ya hay registro hoy).**
El comportamiento previo era "siempre escribir al despertar". El nuevo es "respetar lo que ya está". Esto se alinea con la intención del usuario que YA registró manualmente — más correcto, menos sobreescribe-silencioso.

# 7. Out of scope

- Migración batch de docs legacy con id `sync_*` y `manual_*`.
- Permitir más de un registro de sueño por día calendario (siesta + sueño nocturno como docs separados).
- Auditoría de cambios.

# 8. Resultado

(Se completa al cerrar el SPEC.)
