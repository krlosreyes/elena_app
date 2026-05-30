# SPEC-138 — Límite del día: fuente única, atribución correcta y anti-contaminación

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-29
**Tipo:** Infra de datos / Core
**Autor:** Liderazgo de proyecto (análisis)
**Decisión de producto:** Mantener **medianoche local (00:00)** como límite nominal del día. NO se adopta rollover circadiano ni anclaje a hora de despertar. El alcance es **corregir bugs** y **unificar la fuente del día**.
**Marco normativo:** SPEC-58 (reset diario de 5 pilares), SPEC-101 (un ayuno por día), SPEC-108 (id canónico de sueño), SPEC-111 (persistencia de DailySummary), SPEC-51 (CircadianEngine). IMR_BIBLIOGRAPHY.md §4.6, CIRCADIAN_BIBLIOGRAPHY.md §3.

---

# 1. Contexto

ElenaApp calcula todos sus indicadores (IMR, los 5 pilares, racha, DailySummary) sobre la noción de "el día de hoy". Esa noción está implementada **de forma independiente en al menos siete lugares distintos**, todos derivando la fecha desde `DateTime.now()` local del dispositivo. No existe una fuente única de verdad sobre cuándo empieza y termina el día.

La preocupación es legítima y ya está documentada por el propio equipo. SPEC-111 §2 lo dice textualmente:

> "El cierre del día NO está marcado en ningún lado: si el usuario abre el app después de medianoche, el cómputo del día anterior puede contaminar el nuevo día."

Esta SPEC consolida el diagnóstico, define el límite del día de forma explícita y única, y corrige los bugs de atribución y contaminación, **sin cambiar el límite a una hora distinta de medianoche**.

---

# 2. Diagnóstico — dónde se define hoy "el día"

Cada módulo recalcula el límite por su cuenta. La expresión `DateTime(now.year, now.month, now.day)` aparece **23 veces** en `lib/`.

| # | Módulo | Archivo | Cómo define el día |
|---|--------|---------|--------------------|
| 1 | Reset diario | `core/services/daily_reset_service.dart` | Clave `yyyy-MM-dd`; timer hasta `DateTime(y,m,d+1)` = próxima medianoche |
| 2 | Hidratación | `features/dashboard/data/hydration_repository_impl.dart` | `startOfDay = DateTime(y,m,d)`, query `timestamp >= startOfDay` (sin tope superior) |
| 3 | Ejercicio | `features/exercise/data/exercise_repository_impl.dart` | Igual que hidratación |
| 4 | Nutrición | `features/nutrition/data/sources/firestore_nutrition_v1_source.dart` | Calcula `startOfDay` **dentro del data source**, no en el repo |
| 5 | Sueño | `features/dashboard/application/sleep_notifier.dart` | `_dayDocId(wokeUp)` → clave por día calendario del **despertar** |
| 6 | Ayuno | `features/dashboard/application/fasting_history_provider.dart` | `hasCompletedFastingTodayProvider` compara `endTime` con `now` por día calendario |
| 7 | Racha | `features/streak/domain/streak_engine.dart` | `_dateKey()` propio; cutoff `DateTime(y,m,d) - 6 días` |
| 8 | DailySummary | `features/analysis/data/mappers/daily_summary_mapper.dart` | `docIdFor(now)` → `YYYYMMDD` |

Todos coinciden hoy en "medianoche local" por convención, pero **nada lo garantiza**: cualquier cambio futuro en uno solo de estos puntos rompe la coherencia, y los bugs descritos abajo nacen precisamente de que cada quien resuelve el día a su manera.

---

# 3. Errores y riesgos encontrados

## 3.1 No hay fuente única (riesgo estructural)
Ocho implementaciones paralelas de la misma regla. Cualquier ajuste (zona horaria, hora de corte, manejo de DST) hay que replicarlo ocho veces sin red de seguridad. Es la causa raíz de los demás defectos.

## 3.2 Tensión con el modelo circadiano (conceptual)
`CircadianEngine` (SPEC-51) modela el día biológico arrancando ~06:00 (fase ALERTA), con la fase SUEÑO cruzando medianoche (22:30 → 06:00). Es decir, el modelo de salud de la app trata el día como wake→wake, pero los indicadores cortan en 00:00. Conviven dos "días" incompatibles. Por decisión de producto mantenemos 00:00, pero los pilares que cruzan medianoche (sueño, ayuno) necesitan reglas de atribución explícitas para no romperse (3.3 y 3.4).

## 3.3 Atribución de sueño ambigua para quien despierta de madrugada
`_dayDocId` clava el registro de sueño al día calendario de `wokeUp`. Un usuario que se duerme 23:00 y despierta 00:30 genera un sueño atribuido al **nuevo** día calendario, dejando el día que efectivamente vivió (el anterior) sin sueño. El pilar Sueño de "ayer" queda en 0 aunque la persona sí durmió. Además, `confirmManualWakeUp` ajusta la hora de dormir restando un día solo cuando `now.hour < 12 && sleepTime.hour > 12` — heurística frágil para turnos nocturnos o siestas.

## 3.4 "Ya completaste tu ayuno de hoy" se dispara en el día equivocado
`hasCompletedFastingTodayProvider` marca el ayuno como "de hoy" comparando `endTime` con el día calendario actual. Un 16:8 que cierra a las 00:30 cuenta para el día nuevo, no para el día en que la persona hizo casi todo el ayuno. SPEC-101 §6 ya lo reconoce como caso aceptado pero confuso: el usuario ve el botón bloqueado un día y disponible el otro de forma contraintuitiva.

## 3.5 Contaminación post-medianoche (confirmado por SPEC-111)
El `DailyResetNotifier` dispara el reset exactamente a las 00:00 vía `Timer`, **solo si el proceso está vivo**. Dos escenarios problemáticos:
- App viva a medianoche (usuario registrando agua 23:58–00:05): el reset parte la sesión activa en dos días calendario de golpe.
- App cerrada a medianoche: el reset ocurre en el siguiente arranque vía `SharedPreferences`. Entre medianoche y la reapertura, los indicadores "en vivo" muestran el día anterior; el primer dato que el usuario registre puede caer en el bucket equivocado según el orden bootstrap vs. escritura.

## 3.6 Sin política de zona horaria / DST
Las claves de día se derivan del reloj local del dispositivo en cada sesión. Los timestamps se escriben con `Timestamp.fromDate(local)` (instante absoluto correcto), pero el **bucketing por día se recomputa desde el reloj local** cada vez. Consecuencias:
- Viaje entre husos: el mismo instante puede caer en dos días distintos según dónde esté el teléfono → un día se duplica o se salta en el histórico `YYYYMMDD`.
- DST: el día del cambio de hora tiene 23 o 25 h reales; el timer a "próxima medianoche" y las ventanas quedan descuadrados ese día.

## 3.7 Queries sin tope superior
Hidratación y ejercicio filtran solo `timestamp >= startOfDay`, sin `< endOfDay`. Hoy funciona porque no hay timestamps futuros, pero cualquier dato con reloj adelantado, import de Health con fecha futura, o edición manual filtra hacia "hoy" indebidamente.

---

# 4. Solución propuesta

Principio rector: **un solo lugar resuelve "qué día es" y "a qué día pertenece este instante". Todos los demás módulos consumen ese contrato.**

## 4.1 `DayBoundaryResolver` — fuente única (Dart puro, determinista)

Nuevo servicio en `core/` sin Flutter/Riverpod/Firestore, alineado con la regla SPEC-60 (nunca llama `DateTime.now()` internamente; recibe `now` desde afuera). Es la única autoridad sobre el día.

```dart
class DayBoundaryResolver {
  /// Límite nominal del día: medianoche local (00:00). Constante por decisión
  /// de producto SPEC-138. Se expone como constante para que cualquier cambio
  /// futuro sea de un solo punto.
  static const int dayStartHour = 0;

  /// Clave canónica del día calendario al que pertenece `t`. Formato YYYYMMDD.
  static String dayKey(DateTime t);

  /// Inicio (inclusive) del día calendario de `t` → 00:00:00.000 local.
  static DateTime startOfDay(DateTime t);

  /// Fin (exclusivo) del día calendario de `t` → 00:00 del día siguiente.
  static DateTime endOfDay(DateTime t);

  /// Día calendario al que se ATRIBUYE un evento que cruza medianoche
  /// (sueño, ayuno). Ver 4.3 para la regla.
  static String attributionDayKey({required DateTime start, required DateTime end});
}
```

Los ocho puntos del §2 se refactorizan para delegar aquí. Se elimina toda ocurrencia local de `DateTime(now.year, now.month, now.day)` y todo `_dateKey`/`_dayDocId`/`docIdFor`/`_getTodayKey` duplicado, que pasan a llamar al resolver.

## 4.2 Queries acotadas por ambos extremos
Todos los data sources de pilar filtran `startOfDay <= timestamp < endOfDay`, no solo `>= startOfDay`. Cierra 3.7 y deja el contrato idéntico entre los cinco pilares.

## 4.3 Regla de atribución para eventos que cruzan medianoche
Sueño y ayuno son intervalos, no instantes. Regla única y explícita: **un evento se atribuye al día calendario en que ocurre la mayor parte de su duración** (punto medio del intervalo). Es determinista, simétrica y no depende de heurísticas de hora.
- Sueño 23:00 → 07:00: punto medio 03:00 → atribuido al día del despertar. Coherente con "el sueño que preparó tu hoy".
- Sueño 23:00 → 00:30: punto medio 23:45 → atribuido al día anterior. Corrige 3.3.
- Ayuno 16:8 que cierra 00:30 tras empezar el día previo: punto medio cae el día previo → "completaste tu ayuno" se asocia al día correcto. Corrige 3.4.

`sleep_notifier` y `fasting_history_provider` consumen `attributionDayKey` en lugar de comparar solo `wokeUp`/`endTime`. Se retira la heurística `now.hour < 12 && sleepTime.hour > 12`.

## 4.4 Ventana de gracia anti-contaminación
El reset no destruye el día anterior en cuanto el reloj marca 00:00; **finaliza (persiste) el día anterior y abre el nuevo de forma atómica**:
1. Antes de limpiar cualquier notifier, `triggerDailyReset` fuerza el `set` del `DailySummary` del día que cierra (escritura inmediata, sin esperar el debounce de 30 s de SPEC-111). Así el cierre queda sellado aunque la app se cierre enseguida.
2. Solo después se limpian los flags efímeros de los pilares.
3. El orden bootstrap-vs-escritura se vuelve irrelevante porque el día de un evento se determina por `dayKey(timestamp del evento)`, no por "qué notifier se inicializó primero".

Esto cierra 3.5 sin mover el límite de medianoche.

## 4.5 Política de zona horaria
- Cada `DailySummary` y cada log persiste, además del timestamp, el **offset de zona horaria con que se registró** (`tzOffsetMinutes`). Permite reconstruir el día local correcto aunque el dispositivo cambie de huso después.
- Política de bucketing: el día se ancla a la **zona horaria del dispositivo al momento del registro** (no se re-bucketiza retroactivamente al viajar). Documentado y explícito; evita que el histórico mute al cruzar husos (3.6).
- DST: el timer a "próxima medianoche" se recalcula con `DateTime(y, m, d+1)` (que ya respeta DST local) y se re-arma tras cada disparo (ya lo hace SPEC-58); se agrega un test del día de cambio de hora.

---

# 5. Alcance y NO-alcance

**Dentro:** crear `DayBoundaryResolver`; refactorizar los 8 puntos para delegar; acotar queries por ambos extremos; regla de atribución por punto medio en sueño y ayuno; cierre atómico del día anterior en el reset; persistir `tzOffsetMinutes`; tests.

**Fuera (explícito):** cambiar el límite a una hora distinta de 00:00; rollover circadiano; anclaje a hora de despertar; re-bucketizado retroactivo por viaje; migración batch del histórico (consistente con SPEC-111 §76 — los días previos quedan como están).

---

# 6. Impacto en usabilidad

- El sueño se cuenta en el día que la persona realmente vivió, incluso si despierta de madrugada.
- El mensaje "ya completaste tu ayuno de hoy" deja de aparecer en el día equivocado.
- La actividad alrededor de medianoche ya no se parte ni se pierde: el día anterior queda sellado y el nuevo arranca limpio.
- Comportamiento estable al viajar y en el día de cambio de hora.
- Para el equipo: una sola regla del día, testeable y determinista, en vez de ocho.

---

# 7. Plan de trabajo (estimado)

| # | Tarea | Archivo principal |
|---|-------|-------------------|
| 1 | Crear `DayBoundaryResolver` (Dart puro) + tests unitarios | `lib/src/core/services/day_boundary_resolver.dart` |
| 2 | Reset: delegar clave + cierre atómico del día anterior | `core/services/daily_reset_service.dart` |
| 3 | Hidratación: delegar + query acotada `[start,end)` | `dashboard/data/hydration_repository_impl.dart`, `.../sources/firestore_hydration_v1_source.dart` |
| 4 | Ejercicio: delegar + query acotada | `exercise/data/exercise_repository_impl.dart`, `.../sources/firestore_exercise_v1_source.dart` |
| 5 | Nutrición: mover cálculo de día del source al repo + delegar | `nutrition/data/sources/firestore_nutrition_v1_source.dart` |
| 6 | Sueño: atribución por punto medio, retirar heurística | `dashboard/application/sleep_notifier.dart` |
| 7 | Ayuno: `hasCompletedFastingTodayProvider` usa atribución | `dashboard/application/fasting_history_provider.dart` |
| 8 | Racha: delegar `_dateKey`/cutoff | `streak/domain/streak_engine.dart` |
| 9 | DailySummary: `docIdFor` delega; persistir `tzOffsetMinutes` | `analysis/data/mappers/daily_summary_mapper.dart` |
| 10 | Tests: medianoche, cruce de sueño/ayuno, DST, viaje de huso | `test/core/services/day_boundary_resolver_test.dart` + tests por pilar |

---

# 8. Criterios de aceptación

1. No queda en `lib/` ninguna construcción local de día (`DateTime(now.year, now.month, now.day)`, `_dateKey`, `_dayDocId`, `_getTodayKey`) fuera de `DayBoundaryResolver`.
2. Un sueño 23:00→00:30 se atribuye al día anterior; uno 23:00→07:00 al día del despertar (tests verdes).
3. Un ayuno que cierra a las 00:30 no bloquea el botón del día nuevo de forma incorrecta.
4. Registrar un evento a las 00:02 con la app abierta lo coloca en el día calendario correcto y el día anterior queda persistido.
5. Las queries de los cinco pilares filtran por `[startOfDay, endOfDay)`.
6. Test del día de DST pasa sin días de 23/25 h mal contados.
7. Cero regresiones en la suite existente (`flutter test`).

---

# 9. Riesgos de la implementación

- **Cambio de id de sueño por atribución (3.3 → 4.3):** registros legacy keyed por `wokeUp` no se migran; conviven con la nueva regla solo desde la actualización (consistente con SPEC-111 §76). Documentar en notas de versión.
- **`tzOffsetMinutes` nuevo campo:** aditivo, `schemaVersion` +1; lectores antiguos lo ignoran.
- **Punto medio en ayunos muy largos (>24 h, multi-día):** definir que se atribuyen al día del punto medio; validar contra SPEC-118 (ayuno multidía) para no romper ese flujo.
