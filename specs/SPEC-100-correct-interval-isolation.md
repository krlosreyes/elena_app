# SPEC-100 — Aislar la corrección de hora al intervalo correcto + tolerar data fantasma

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Bug fix de aislamiento + tolerancia a data legacy
**Marco normativo:** SPEC-97, SPEC-99.

---

# 1. Contexto

Después de SPEC-99, Carlos reporta que el bug persiste: al corregir la hora de inicio del ayuno, la app vuelve a mostrar ventana de alimentación.

Hipótesis confirmada por análisis: la cuenta de Firestore tiene un **doc fantasma** con `endTime: null` e `isFasting: false` (una ventana de comida que nunca se cerró formalmente — probablemente residuo del bug pre-SPEC-97 cuando "Corregir hora de inicio" abría ventanas por error).

# 2. Problema

**2.1 `updateOpenIntervalStartTime` muta todos los docs abiertos.**
La query es `where userId=X and endTime isNull`. Si hay 2 abiertos (un ayuno y una ventana fantasma), ambos cambian su `startTime` al valor pickeado.

**2.2 `streamLatest` no desambigua entre 2 abiertos con misma `startTime`.**
Después de SPEC-99 prefiere "el primero abierto que encuentre". Si ambos tienen la misma startTime (porque el paso 2.1 los igualó), el orden es indefinido. Si Firestore devuelve la ventana fantasma primero, `isFasting: false` se propaga al state.

# 3. Solución

**3.1 `updateOpenIntervalStartTime` acepta filtro opcional `isFastingFilter`.**

Cuando el caller corrige una hora de inicio de **ayuno**, pasa `isFastingFilter: true`. Solo se mutan docs con `isFasting=true`. Si hay una ventana fantasma con `isFasting=false`, no se toca.

**3.2 `streamLatest` con prioridad explícita.**

Entre docs abiertos, prefiere `isFasting=true` (el ayuno) sobre `isFasting=false` (ventana). Razón: en el flujo de producto, "estado actual de ayuno" siempre gana sobre "ventana abierta colateral".

Implementación: dentro del `map` del snapshot, primer pass busca abiertos con `isFasting=true`; segundo pass busca cualquier abierto; tercer fallback es el más reciente cerrado.

**3.3 Limpieza automática (opt-in para SPEC futuras).**
La detección de "2+ docs abiertos del mismo usuario" es señal de data corrupta. Podríamos auto-cerrar el ventana fantasma al detectarla. Por ahora out of scope — el fix anterior es suficiente para que la UI funcione correctamente sin migración.

# 4. Plan

| # | Acción | Archivo |
|---|---|---|
| 1 | Agregar `isFastingFilter` a contrato y impl del data source | `fasting_interval_data_source.dart`, `firestore_fasting_interval_v1_source.dart` |
| 2 | Propagar en repo (param opcional) | `fasting_interval_repository.dart` + impl |
| 3 | Notifier pasa `isFastingFilter: true` al corregir ayuno | `fasting_notifier.dart` |
| 4 | `streamLatest` prefiere `isFasting=true` entre abiertos | `firestore_fasting_interval_v1_source.dart` |
| 5 | Tests del nuevo comportamiento | `firestore_fasting_interval_v1_source_test.dart` |

# 5. Criterios de aceptación

1. Con doc ayuno abierto (isFasting=true) + doc ventana fantasma (isFasting=false, endTime=null), `updateOpenIntervalStartTime(isFastingFilter: true)` solo muta el ayuno.
2. `streamLatest` con dos abiertos emite el de `isFasting=true`.
3. `flutter test` pasa con +3 tests nuevos del SPEC-100.
4. `flutter analyze` sin issues nuevos.

# 6. Riesgos

**6.1 Ruptura de contrato del data source.**
`updateOpenIntervalStartTime` ahora acepta un parámetro opcional. Backwards-compatible: callers existentes (ninguno hoy salvo el repo) siguen funcionando si lo omiten — pero entonces vuelven al comportamiento anterior. Aceptable.

**6.2 Doc fantasma sigue en Firestore.**
Esta SPEC NO lo limpia. La UI funcionará bien por la priorización en `streamLatest`. Si el equipo decide limpiar (SPEC futura), agregar un script de migración que cierre cualquier doc abierto con `isFasting=false` que no sea el último creado.

# 7. Out of scope

- Migración batch de docs huérfanos.
- Cambio del schema (agregar `createdAt`).
- Tests E2E del flujo de corrección.

# 8. Resultado

(Se completa al cerrar el SPEC.)
