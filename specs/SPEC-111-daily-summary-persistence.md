# SPEC-111 — Persistencia diaria del DailySummary (histórico para Análisis)

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-15
**Tipo:** Infra de datos
**Marco normativo:** SPEC-110 (vista Análisis "Hoy"). Habilita SPEC-112 (calendario) y SPEC-113 (rediseño Análisis con tendencia / heatmap / insights).

---

# 1. Contexto

La pantalla Análisis tras SPEC-110 muestra solo el día actual. El strip semanal aparece como placeholder vacío para los días pasados porque la app NO persiste el resumen diario del usuario. Sin histórico, la pantalla Análisis no puede:

- Mostrar tendencia del IMR en el tiempo.
- Comparar período vs período.
- Hacer heatmap de pilares × días.
- Generar insights ("tu pilar más constante", "tu mejor día").
- Mostrar el calendario mensual estilo Apple Activity.

Esta SPEC entrega la infraestructura de persistencia que cualquier feature analítica futura va a necesitar.

# 2. Problema

Hoy los providers de cada pilar (`fastingProvider`, `sleepProvider`, etc.) tienen su propia persistencia individual (fasting_history, sleep_history, etc.). Pero:

- No hay **snapshot diario consolidado** (IMR + % de cada pilar al cierre del día).
- Reconstruir el snapshot del día N a partir de los logs individuales requeriría leer múltiples colecciones y recomputar — caro y frágil.
- El cierre del día NO está marcado en ningún lado: si el usuario abre el app después de medianoche, el cómputo "del día anterior" puede contaminar el nuevo día.

# 3. Solución propuesta

**3.1 Nueva colección Firestore.**

`users/{uid}/daily_summary/{YYYYMMDD}` — un documento por usuario y día calendario.

Schema:
```json
{
  "date": "2026-05-15",
  "imrScore": 72,
  "fastingProgress": 0.88,
  "sleepProgress": 0.94,
  "hydrationProgress": 0.84,
  "exerciseProgress": 0.58,
  "mealsProgress": 1.0,
  "updatedAt": Timestamp,
  "schemaVersion": 1
}
```

**3.2 Estrategia de escritura: debounced upsert.**

No usamos cron de backend (no tenemos). En cliente:

- `DailySummaryPersistenceService` escucha `dailySummaryProvider` (ya existente, SPEC-110).
- Cada cambio en el summary del día actual dispara un debounce de 30 segundos.
- Al expirar el debounce, persiste el snapshot del día actual con `set` (upsert por docId).
- Resultado: el doc del día se mantiene actualizado conforme el usuario interactúa, sin ráfagas de escrituras.

**3.3 Detección de cambio de día.**

Cuando el `dailySummaryProvider` emite y la fecha actual (`YYYYMMDD`) es distinta al último día persistido por la sesión, se persiste inmediatamente (sin debounce). Esto cierra el día anterior con su último estado antes de empezar el nuevo.

**3.4 Reglas Firestore.**

Agregar a `firestore.rules`:
```
match /users/{userId}/daily_summary/{dayId} {
  allow read, write: if isOwner(userId) && withinSizeLimit();
}
```

**3.5 Compatibilidad hacia atrás.**

Usuarios que ya tienen historial individual (fasting, sleep, etc.) pero no `daily_summary` empiezan a generar docs **desde el día que actualizan la app**. NO se hace migración batch retroactiva — los días anteriores quedan sin doc consolidado (la UI lo manejará como "sin datos" para esos días).

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `DailySummaryDoc` value object | `lib/src/features/analysis/data/daily_summary_doc.dart` |
| 2 | Crear mapper Doc ↔ DailySummary | `lib/src/features/analysis/data/mappers/daily_summary_mapper.dart` |
| 3 | Contrato del repository | `lib/src/features/analysis/domain/daily_summary_repository.dart` |
| 4 | DataSource contract + impl Firestore | `lib/src/features/analysis/data/sources/daily_summary_data_source.dart` + `firestore_daily_summary_v1_source.dart` |
| 5 | Impl del repository | `lib/src/features/analysis/data/daily_summary_repository_impl.dart` |
| 6 | Servicio de persistencia con debounce | `lib/src/features/analysis/application/daily_summary_persistence_service.dart` |
| 7 | Provider que arranca el servicio en app boot | `lib/src/features/analysis/application/daily_summary_persistence_service.dart` |
| 8 | Provider de histórico (rango de fechas) | `lib/src/features/analysis/application/historic_summaries_provider.dart` |
| 9 | Agregar regla Firestore | `firestore.rules` |
| 10 | Activar el servicio en main.dart | `lib/main.dart` |
| 11 | Tests del data source con fake_cloud_firestore | `test/features/analysis/data/firestore_daily_summary_v1_source_test.dart` |
| 12 | Tests del servicio de persistencia (debounce + change-of-day) | `test/features/analysis/application/daily_summary_persistence_service_test.dart` |

# 5. Criterios de aceptación

1. `DailySummary` que emite el provider se persiste en Firestore después de 30 segundos sin cambios.
2. Cambios rápidos consecutivos (ej. registrar 3 ml de agua + 5 ml de agua + 2 ml de agua) generan UNA escritura, no tres.
3. Al cambiar de día (cruce de medianoche), el día anterior se persiste sin debounce, inmediatamente.
4. El doc en Firestore tiene path `users/{uid}/daily_summary/{YYYYMMDD}` y los 6 campos correctos.
5. Tras cerrar y reabrir la app el mismo día, el doc se sigue actualizando (no se duplica, no se pierde).
6. Las reglas Firestore permiten al usuario leer/escribir solo su propia subcolección.
7. `historicSummariesProvider(from, to)` devuelve un stream con los docs en ese rango ordenados por fecha ascendente.
8. `flutter analyze` sin issues nuevos. `flutter test` con +N tests del data source y +M del servicio.

# 6. Riesgos

**6.1 Costo de Firestore.**
Una escritura cada ~30s mientras el usuario está activo. Con un usuario típico ~10 escrituras/día = 300/mes. Para 1000 usuarios activos diarios = 300K writes/mes — bajo el free tier (50K/día = 1.5M/mes). Aceptable.

**6.2 Cierre de día perdido si la app está cerrada al cruzar medianoche.**
Si el usuario no abre la app entre 23:59 y 00:00, el servicio no detecta el cambio de día. Mitigación: al próximo abrir, si el día actual es distinto al último persistido en preferencias locales, primero persistimos lo último del día previo (lo recordamos en SharedPreferences) y después empezamos el nuevo.

Edge case: el último snapshot guardado para "ayer" puede ser de las 18:00 (cuando el usuario cerró la app), no el snapshot completo del día. Aceptable para MVP — el usuario ve la info que tenía cuando interactuó por última vez.

**6.3 Conflicto con SPEC-86 (`imr.current` del sitio).**
SPEC-86 protege el campo `imr.current` que el sitio MR escribe. El `daily_summary` es subcolección APARTE — no toca `imr.current`. Sin conflicto.

**6.4 Schema v1 + versionamiento.**
Incluimos `schemaVersion: 1` en cada doc para futuras migraciones sin breaking.

**6.5 Persistencia mientras está logueando o sin auth.**
El servicio NO escribe si `authStateProvider.value?.uid == null`. Guard explícito.

# 7. Out of scope

- Rediseño de la pantalla Análisis con tendencia/heatmap/insights (SPEC-113).
- Vista calendario mensual (SPEC-112).
- Migración batch retroactiva para reconstruir días pasados desde logs individuales.
- Reglas de detección de "día completo vs día parcial" (todos los días se persisten con lo que se tenga).
- Sincronización con el sitio web Metamorfosis Real (canonical mirror del daily summary).

# 8. Resultado

(Se completa al cerrar el SPEC.)
