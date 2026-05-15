# SPEC-106 — Pilar Sueño: persistencia, edición sobre registro existente y eliminación

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Bug fix UX + completar feature
**Marco normativo:** `docs/CIRCADIAN_BIBLIOGRAPHY.md` (sección Sueño nueva), 3 artículos de la biblioteca de Metamorfosis Vital sobre sueño.

---

# 1. Contexto

Carlos reportó que la información del pilar Sueño "no es persistente". Auditoría reveló que:

- El modelo `SleepLog`, el repositorio (`SleepRepository.save`), el data source (`FirestoreSleepV1Source`) y el stream `watchLatest` SÍ persisten y emiten correctamente.
- El sheet `SleepInputSheet` captura bedtime, waketime, latencia, despertares y calidad subjetiva 1-5 (estrellas) y los persiste vía `saveManualSleep`.
- El score IMR ya consume `subjectiveQuality` via `SleepQualityCalculator`.

**Lo que rompe la UX y da la sensación de "no se guarda":**

1. El sheet **siempre arranca con valores hardcoded** (`bedtime 22:30 / wake 07:00`) — no precarga el último registro persistido. El usuario abre "Actualizar Registro", ve los defaults, y concluye que su registro previo se perdió.
2. El botón "Eliminar registro y volver a registrar" **es un placeholder** (`_showPendingFeatureSnack`). No hay método `delete` en el repo.
3. La **bibliografía Metamorfosis Vital sobre sueño no está mapeada** en `docs/CIRCADIAN_BIBLIOGRAPHY.md`. Sin esa anclaje, cualquier SPEC futura del pilar carece de fuente normativa verificable.

# 2. Problema

**2.1 Sheet no precarga.** Cada apertura del sheet ignora `state.lastLog`. El usuario no puede ajustar un campo concreto (ej. solo la calidad de su registro de anoche) sin tener que recapturar bedtime y wake. Pierde info implícitamente al guardar con defaults.

**2.2 Sin eliminación.** Si el usuario registra mal (ej. invirtió bedtime y wake), no puede borrar y rehacer. La UI dice "Eliminar registro y volver a registrar" pero no hace nada — pésima señal de credibilidad de producto.

**2.3 Bibliografía sin mapear.** El pilar Sueño es central al IMR (Reparación Profunda, GH, glinfático) pero la app no tiene referencias normativas internas que justifiquen las métricas captadas. Hace difícil ampliar el pilar con criterio.

# 3. Solución propuesta

**3.1 `SleepInputSheet` recibe `initial: SleepLog?`** (opcional).

- Si `initial != null`: precarga `bedtime`, `wakeTime`, `latencyMinutes`, `awakenings`, `subjectiveQuality` desde el log existente. El toggle "Más detalle" se abre automáticamente si algún campo opcional ya tenía valor (para que el usuario vea lo que ya registró).
- Si `initial == null`: comportamiento actual (defaults hardcoded).

**3.2 `SleepRepository.delete(userId, logId)`** — operación nueva en el contrato.

- `SleepDataSource.deleteDoc(userId, docId)` en el contrato.
- `FirestoreSleepV1Source.deleteDoc` borra el doc específico de `users/{uid}/sleep_logs/{docId}`.
- `SleepRepositoryImpl.delete` delega al source.

**3.3 `SleepNotifier.deleteLastLog()`** — método público.

- Si `state.lastLog != null`: llama a `repo.delete(uid, state.lastLog.id)`.
- Actualiza el state optimistically a `lastLog: null` mientras el stream re-emite.
- Maneja `isSaving` para evitar doble tap.
- AppLogger.debug del evento.

**3.4 Botón "Eliminar registro y volver a registrar" funcional.**

- Tap → `AlertDialog` de confirmación: "¿Eliminar el registro de sueño? Esta acción no se puede deshacer."
- Botones: "Cancelar" / "Sí, eliminar".
- Si confirma: llama a `deleteLastLog()`, espera el await, abre el sheet en modo limpio (`initial: null`).

**3.5 Sección "Sueño" en `docs/CIRCADIAN_BIBLIOGRAPHY.md`.**

Nueva subsección con:
- Resumen de los 3 artículos de Metamorfosis Vital (titulos + URLs + 3-5 bullets cada uno).
- Tabla "Métricas capturadas hoy vs. métricas futuras" (lo que el modelo tiene + roadmap).
- Reglas duras derivadas: ventana reparación 23:00-03:00, café cortado 14:00, pantallas off 60min antes, habitación 17-19°C.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Agregar `deleteDoc` al contrato del data source | `lib/src/features/dashboard/data/sources/sleep_data_source.dart` |
| 2 | Implementar en Firestore source | `lib/src/features/dashboard/data/sources/firestore_sleep_v1_source.dart` |
| 3 | Agregar `delete` al contrato del repo + implementación | `domain/sleep_repository.dart` + `data/sleep_repository_impl.dart` |
| 4 | Agregar `deleteLastLog` al notifier | `application/sleep_notifier.dart` |
| 5 | `SleepInputSheet` acepta `initial: SleepLog?` y precarga | `presentation/sleep_input_sheet.dart` |
| 6 | Card del sueño en Dashboard pasa `state.lastLog` al abrir sheet + implementa diálogo de eliminación | `presentation/dashboard_screen.dart` |
| 7 | Sección "Sueño" en bibliografía | `docs/CIRCADIAN_BIBLIOGRAPHY.md` |
| 8 | Tests del `delete` y precarga del sheet (no UI) | `test/features/dashboard/data/firestore_sleep_v1_source_test.dart` (crear) |

# 5. Criterios de aceptación

1. Tap en "Actualizar Registro" cuando ya hay un log de hoy → el sheet abre con los campos precargados desde `state.lastLog`.
2. Si el log previo tenía `subjectiveQuality = 4`, las 4 estrellas aparecen seleccionadas al abrir.
3. Tap en "Eliminar registro y volver a registrar" → diálogo "¿Eliminar el registro de sueño?".
4. Confirmar elimina el doc de Firestore y abre el sheet limpio (defaults hardcoded, sin valores previos).
5. Después de eliminar, `state.lastLog == null` y el card del Dashboard muestra el estado "sin registro".
6. `docs/CIRCADIAN_BIBLIOGRAPHY.md` tiene una sección "§10 Sueño — Bibliografía MR" con los 3 artículos y el mapping de métricas.
7. `flutter analyze` sin issues nuevos.
8. `flutter test` mantiene los anteriores + nuevos tests de delete.

# 6. Pruebas

`firestore_sleep_v1_source_test.dart` (nuevo, con fake_cloud_firestore):
- `deleteDoc` borra el doc esperado y no afecta otros docs del mismo usuario.
- `deleteDoc` de un docId inexistente no falla (idempotencia).
- `deleteDoc` no afecta logs de otros usuarios.

(No agregamos widget tests del sheet — la precarga se verifica en device.)

# 7. Riesgos

**7.1 Eliminar el último log es destructivo.**
Mitigación: diálogo de confirmación + texto claro. No hay undo. Si el usuario lo necesita, la SPEC futura puede agregar "papelera 7 días". Out of scope MVP.

**7.2 Precargar puede confundir si el usuario quiere registrar OTRO día.**
La app es "un log por día". El doc id es `manual_YYYYMMDD`, así que precargar el "último" es siempre del día actual o anterior. Si el usuario quiere registrar la noche pasada y ya hay un log del día actual, está editando ese mismo. Aceptable — el usuario que quiera registrar la noche dos días atrás tendría que usar una SPEC futura con "registro histórico" (out of scope).

**7.3 `subjectiveQuality` opcional en IMR.**
Si el usuario nunca lo registra, el score degrada graciosamente (`SleepQualityCalculator` lo maneja). Sin cambios necesarios.

**7.4 Tests requieren fake_cloud_firestore.**
Ya está en dev_deps (usado en otros tests).

# 8. Out of scope

- Métricas adicionales sugeridas por la bibliografía MR: temperatura del cuarto, exposición a pantallas, exposición a luz solar matutina, hora del último café, hora de cena, ejercicio del día. Útiles pero requieren más UI. SPEC futura.
- "Papelera 7 días" para deshacer eliminación.
- Registro histórico (más de un log al día / días pasados sin precargar).
- Edición de cada campo individualmente con tiles (estilo Profile biometría).
- Notificación push "registra tu sueño" al despertar.

# 9. Resultado

(Se completa al cerrar el SPEC.)
