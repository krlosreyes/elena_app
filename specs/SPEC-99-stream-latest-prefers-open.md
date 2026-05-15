# SPEC-99 — `streamLatest` debe preferir el intervalo abierto

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Bug fix de query layer
**Marco normativo:** SPEC-97 (corrección de hora de inicio).

---

# 1. Contexto

Reporte de Carlos (14-may-2026): después de aplicar SPEC-97, al corregir la hora de inicio del ayuno hacia atrás, el dashboard sigue mostrando que el ayuno se cerró y se abrió una ventana de alimentación. El bug visual reproduce el reportado pre-SPEC-97, pero el código del notifier y del data source `updateOpenIntervalStartTime` SÍ está bien — el problema vive en `streamLatest`.

# 2. Problema

`FirestoreFastingIntervalV1Source.streamLatest`:

```dart
return _collection
    .where('userId', isEqualTo: userId)
    .orderBy('startTime', descending: true)
    .limit(1)
    .snapshots();
```

Devuelve el doc con `startTime` mayor. Esa heurística es correcta en el flujo lineal "abrir interval → cerrar interval → abrir el siguiente" porque cada nuevo doc tiene `startTime` mayor que el anterior.

Pero NO es correcta cuando el usuario corrige el `startTime` de un ayuno **hacia atrás** (caso de uso central de SPEC-97):
- Doc histórico cerrado: `startTime: 21:00, endTime: 05:00 siguiente día, isFasting: false`.
- Ayuno actual abierto antes de corregir: `startTime: 08:00 hoy, endTime: null, isFasting: true`.
- Usuario corrige el ayuno a `startTime: 06:00` (2h antes).

`orderBy startTime desc limit 1` ahora devuelve el doc cerrado (`21:00 > 06:00`). El listener del notifier lee `isFasting=false` y `endTime!=null`, setea `state.isActive=false`, el painter cambia a ventana de comida fantasma.

# 3. Solución

`streamLatest` debe devolver:
- El intervalo **abierto** (`endTime == null`) si existe.
- Si ninguno está abierto, el más reciente por `startTime`.

Implementación: pedir los últimos 5 docs por `startTime descending` y elegir en cliente — si hay uno abierto en ese subset, gana; si no, devolver el primero.

Por qué 5: cubre con holgura el flujo normal "abrir → cerrar → abrir → cerrar". Más de 5 docs entre el abierto actual y el orden por startTime sería un anti-flujo (múltiples correcciones secuenciales hacia atrás), aceptablemente raro y manejable con un `limit` mayor en SPEC futura si pasa.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Cambiar query + filtro cliente en `streamLatest` | `firestore_fasting_interval_v1_source.dart` |
| 2 | Tests del nuevo comportamiento | `firestore_fasting_interval_v1_source_test.dart` |

# 5. Criterios de aceptación

1. Con un doc abierto (`endTime==null`) y un doc cerrado con `startTime` mayor → `streamLatest` emite el abierto.
2. Sin abiertos → emite el más reciente cerrado.
3. Sin historial → emite null.
4. Tras `correctOpenIntervalStartTime(newStart pasado)`, el snapshot emite el intervalo de ayuno actualizado, NO un doc cerrado histórico.
5. `flutter analyze` sin issues. `flutter test` con +3 nuevos tests.

# 6. Riesgos

**6.1 Latencia extra.** Pedir 5 docs en lugar de 1 es marginalmente más lento. Aceptable — son docs pequeños.

**6.2 Caso edge: más de 5 docs con startTime mayor al abierto.** No realista en flujo normal. Si pasa, fallback a "más reciente por startTime" (que es el comportamiento previo, así que no regresión). Si en producción se ve, se sube `limit` a 10 sin SPEC.

# 7. Out of scope

- Migrar a un campo `createdAt` o `isOpen` para ordenar (requeriría migración de docs existentes).
- Cambiar el ordering en `closeAllOpenAndCreate`.
- Auditoría de los `correctOpenIntervalStartTime` (separado).

# 8. Resultado

(Se completa al cerrar el SPEC.)
