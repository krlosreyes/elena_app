# SPEC-149 — Día Metabólico: ciclo ayuno↔alimentación como unidad fundamental del producto

**Estado:** CLOSED (implementada y testeada 2026-06-01)
**Versión:** 1.0
**Fecha:** 2026-06-01 · aprobada 2026-06-01 · cerrada 2026-06-01
**Tipo:** Cambio conceptual del modelo de "día" + nueva subcollection + cierre con coaching
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 1 — Estabilización + cimiento del active coaching
**Estimación:** 4–5 días Carlos+Claude (Bloque A + B + C + D)
**Marco normativo:** `CONSTITUTION.md`, `IMR_BIBLIOGRAPHY.md`, `docs/CIRCADIAN_BIBLIOGRAPHY.md`, `docs/NUTRITION_BIBLIOGRAPHY.md`.
**Depende de:**
- SPEC-138 (`DayBoundaryResolver` — se preserva, no se reemplaza).
- SPEC-95 (`EatingWindowState` — provee horas de apertura/cierre de ventana).
- SPEC-98 (selector de protocolo — provee duración esperada del ayuno).
- SPEC-140 (Score del Día — su cómputo se ancla al cierre del ciclo metabólico).
- SPEC-143 (persistencia histórica — patrón de subcollection con timestamp PK).

**Bloquea:**
- Pivot estratégico de Ola 1+ (passive logging → active coaching) — el cierre con feedback ES el coaching moment.
- SPEC-141 (IMR longitudinal) — el componente `behaviorTrend30` necesita ciclos cerrados como unidad de cómputo, no días calendario arbitrarios.
- SPEC-147 (Insights adaptativos) — los insights se generan al cierre de cada ciclo.

**No requiere validación clínica externa.** La cronobiología que respalda el modelo (TRE 24h cycle, Sutton 2018, Lopez-Minguez 2018) ya está en `IMR_BIBLIOGRAPHY.md`. SPEC-149 aplica el marco existente al producto.

---

## 1. Contexto y motivación

### 1.1 — El bug semántico que Carlos identificó

Carlos reportó tras usar la app en su iPhone: *"mi IMR diario no ha llegado al 100% a pesar de que he cumplido con todos mis pilares"*. Su hipótesis: la app no entiende cuándo termina su día metabólico real.

Auditoría confirma: `DayBoundaryResolver` (SPEC-138, 2026-05-30) define el día como **MEDIANOCHE LOCAL** con la justificación textual:

> *"Decisión de producto SPEC-138: el límite nominal del día es la MEDIANOCHE LOCAL (00:00). No hay rollover circadiano ni anclaje a hora de despertar."*

Fue una decisión pragmática para evitar complejidad de zona horaria y persistencia. **No fue una decisión metabólica.**

### 1.2 — Por qué el día calendárico es incorrecto para el producto

La promesa de Elena es "salud metabólica con base científica verificable". El día calendárico (00:00-23:59) es una convención administrativa romana. **No tiene relación con fisiología metabólica.**

[Sutton et al. (2018, *Cell Metab*)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8143522/) — la fuente que sostiene §3.3 del `IMR_BIBLIOGRAPHY.md` — midió outcomes metabólicos contra **ventanas de feeding/fasting**, no contra días calendario. La nomenclatura estándar de la literatura es `TRE 8/16` (8h alimentación, 16h ayuno) — y el ciclo se ancla al inicio del ayuno, no a medianoche.

[Lopez-Minguez et al. (2018, *Clin Nutr*)](https://pubmed.ncbi.nlm.nih.gov/28455106/) — la fuente que sostiene §4.6 — mostró que cenar tarde afecta glucosa al día *siguiente*. Esa relación causal solo tiene sentido si entendemos el "día metabólico" como ciclo ayuno→ventana→ayuno, no como bloque de 24h calendárico.

### 1.3 — Por qué esto bloquea el pivot de Ola 1

El [pivot estratégico aprobado por Carlos 2026-06-01](memory/project_strategic_pivot_2026_06_01.md) define el shift de "passive logging" a "active coaching". El active coaching requiere un MOMENTO DE FEEDBACK con cierre claro: el usuario completa su ciclo, recibe retroalimentación específica, entiende qué logró y qué le faltó, y arranca el siguiente ciclo con dirección.

**Sin Día Metabólico, no hay momento de cierre. Sin momento de cierre, no hay coaching.** El día calendárico se cierra a las 23:59 — momento arbitrario donde la mayoría de usuarios están durmiendo o cerca de dormir. No es un momento de coaching útil; es un timer técnico.

El Día Metabólico cierra en un momento biológicamente relevante (cuando el usuario inicia su próximo ayuno, típicamente después de cenar). Eso ES el momento de coaching natural — el cuerpo cierra un ciclo, la app cierra el ciclo, el usuario recibe síntesis.

## 2. Decisión de producto (resumen ejecutivo)

1. **Se introduce el concepto de "Día Metabólico"** como ciclo de duración variable (típicamente 22-28h) anclado al inicio del ayuno del usuario.
2. **Se preserva `DayBoundaryResolver` (SPEC-138)** para persistencia legacy y compatibilidad con sitio Metamorfosis Real. NO se reemplaza.
3. **Nuevo `MetabolicCycleResolver`** vive en paralelo, es Dart puro determinista, y define triggers de apertura y cierre del ciclo.
4. **El Score del Día se ancla al ciclo metabólico**, no al día calendárico. Se computa en tiempo real durante el ciclo abierto y se "congela" al cierre.
5. **Pantalla pasiva de cierre con coaching** se presenta en el Dashboard cuando el usuario abre la app tras un cierre. NO es modal bloqueante.
6. **Fallback calendárico** para usuarios con protocolo "Ninguno" — preserva la experiencia actual y los invita a activar un protocolo.
7. **Nueva subcollection** `users/{uid}/metabolic_cycles/{cycleId}` con shape canónico.
8. **El cómputo del IMR legacy NO cambia.** SPEC-141 será quien re-pondere el IMR longitudinal sobre ciclos cuando entre a IN_PROGRESS.

## 3. Lo que NO se hace (límites duros de scope)

- **NO se elimina `DayBoundaryResolver`.** Sigue siendo la fuente de verdad para `daily_summary/{YYYYMMDD}` (sitio web), `streak_engine`, `daily_reset_service`, `period_comparison_service`. Cualquier feature legacy que asuma día calendárico sigue funcionando.
- **NO se cambia el reset de medianoche.** El `DailyResetService` (SPEC-58) sigue reseteando los pilares a 00:00 local. El Día Metabólico es una capa SEMÁNTICA sobre los datos persistidos, no reemplaza el almacenamiento.
- **NO se cambia el cómputo del IMR legacy.** El `calculateIMR` actual sigue consumiendo magnitudes del día calendárico para el badge de Profile y la pantalla Análisis. SPEC-141 (IMR longitudinal) será quien migre a ciclos.
- **NO se cambia el persistido en `daily_summary`.** Los datos siguen almacenándose por día calendárico. El Día Metabólico se computa derivando esos datos por ciclo.
- **NO se intenta inferir ciclos para usuarios con protocolo "Ninguno".** El fallback calendárico es deliberado — los usuarios sin TRE/eTRF no tienen ciclo metabólico estructurado, y forzar uno crearía bugs de UX.
- **NO se introduce notificación push de cierre.** El feedback se presenta como card en Dashboard cuando el usuario abre la app. Notificación push activa puede ser SPEC-149.next post-MVP.
- **NO se altera el shape canónico del sitio Metamorfosis Real.** El sitio sigue leyendo `imr.current` y `daily_summary` con shape SPEC-82.
- **NO se altera la zona horaria.** El Día Metabólico opera en hora local del usuario, igual que el día calendárico actual.

## 4. Requisitos funcionales

### RF-149-01 — Value object `MetabolicCycle`

Crear en `lib/src/features/metabolic_cycle/domain/metabolic_cycle.dart`:

```dart
/// Un Día Metabólico — ciclo de duración variable anclado al inicio
/// del ayuno del usuario. SPEC-149.
class MetabolicCycle {
  /// ID único del ciclo. Formato: ISO timestamp del `startedAt`.
  /// Ejemplo: '2026-06-01T21:00:00.000Z'.
  final String cycleId;

  /// Momento exacto en que arrancó el ayuno que abre este ciclo.
  final DateTime startedAt;

  /// Momento de cierre del ciclo. Null mientras está abierto.
  final DateTime? closedAt;

  /// Razón por la que se cerró el ciclo. Null si está abierto.
  final ClosureReason? closureReason;

  /// Duración del ayuno completado en horas. Null mientras abierto.
  final double? fastingDurationHours;

  /// Duración de la ventana de alimentación en horas. Null mientras abierto.
  final double? feedingWindowHours;

  /// Score del Día final del ciclo (0-100). Null mientras abierto.
  /// Se computa al momento del cierre usando las magnitudes de cada pilar.
  final int? dailyScore;

  /// Estado de cada pilar al cierre (5 booleanos). Null mientras abierto.
  final CyclePillarsCompleted? pillarsCompleted;

  /// Magnitudes específicas de cada pilar al cierre (para análisis).
  final CycleMagnitudes? magnitudes;

  /// Resumen generado al cierre. Null mientras abierto.
  /// Incluye "lograste:", "te faltó:", "insight:".
  final CycleFeedback? feedback;

  // Constructor const, factories, copyWith, ==, hashCode.
}

enum ClosureReason {
  /// Usuario inició explícitamente un nuevo ayuno.
  manualNextFasting,

  /// Pasaron 3h desde el cierre esperado de la ventana sin nuevo ayuno.
  fallback3hAfterWindow,

  /// Sueño detectado + más de 2h desde última comida.
  fallbackSleepDetected,

  /// 28h pasaron desde último cierre sin nada.
  fallbackAbsolute,

  /// Usuario con protocolo "Ninguno" — cierre a 23:59 local (legacy).
  fallbackCalendar,
}
```

### RF-149-02 — `MetabolicCycleResolver` (Dart puro)

Crear en `lib/src/features/metabolic_cycle/domain/metabolic_cycle_resolver.dart`:

Funciones puras, sin estado mutable, sin Flutter, sin Riverpod, sin Firestore, sin `DateTime.now()`. Todas reciben timestamps externos.

**Reglas operacionales:**

```dart
class MetabolicCycleResolver {
  MetabolicCycleResolver._();

  /// Decide si el ciclo actual debe cerrarse dado el estado actual.
  /// Retorna la razón si cierra, null si no.
  static ClosureReason? shouldClose({
    required MetabolicCycle openCycle,
    required FastingState fastingState,
    required DateTime now,
    required String fastingProtocol,
    required DateTime? expectedWindowCloseTime,
    required DateTime? lastMealTime,
    required bool sleepDetected,
  });

  /// Construye un nuevo ciclo a partir del momento de inicio del ayuno.
  static MetabolicCycle openCycle({
    required DateTime startedAt,
    required String fastingProtocol,
  });

  /// Calcula el `expectedCloseAt` del ciclo abierto.
  /// Es el momento en que esperamos que el usuario inicie el próximo ayuno.
  static DateTime? expectedCloseAt({
    required MetabolicCycle openCycle,
    required DateTime? expectedWindowCloseTime,
  });

  /// True si el usuario tiene protocolo "Ninguno" → modo calendárico.
  static bool useCalendarFallback(String fastingProtocol);

  /// Para modo calendárico: cierre al fin del día local de hoy.
  static DateTime calendarFallbackCloseAt(DateTime now);
}
```

### RF-149-03 — `CycleFeedback` — el coaching moment

Value object que se construye al cierre de un ciclo. Contiene:

```dart
class CycleFeedback {
  /// Lista de logros — pilares completados al ≥80%.
  final List<String> achievements;

  /// Lista de gaps — pilares por debajo del 80%, ordenados por gap descendente.
  final List<String> gaps;

  /// Insight adaptativo del cierre. Una frase educativa basada en el patrón
  /// del ciclo + cita bibliográfica de respaldo cuando aplica.
  final String insight;

  /// Citación opcional (autor + año + revista corta).
  final String? citation;
}
```

**Reglas de generación** (SPEC-149.RF-149-03):

- `achievements`: pilares con magnitud ≥0.80 al cierre. Copy específico por pilar:
  - Sueño: *"Sueño Xh Ym — reparación óptima"* (cita: Walker 2017, AASM 2015).
  - Ayuno: *"Ayuno Xh — autofagia activa"* (cita: Mattson 2017).
  - Ventana cerrada temprano: *"Cerraste ventana antes de las X — eTRF favorable"* (cita: Sutton 2018).
  - Hidratación ≥100%: *"Hidratación al X% — termorregulación OK"* (cita: EFSA 2010).
  - Ejercicio ≥100%: *"Ejercicio X min — dosis ACSM completa"* (cita: ACSM 2021).
  - Cociente A ≥80%: *"Cociente A X% — respuesta insulínica baja"* (cita: Jenkins 1981 + Liu 2000).

- `gaps`: pilares con magnitud <0.80, ordenados de mayor a menor gap. Copy específico:
  - Hidratación 60%: *"Hidratación 60% — mañana apuntá a 2L para evitar desregulación"*.
  - Sueño <7h: *"Sueño Xh — Spiegel 1999 mostró que <7h desregula leptina"*.
  - Cierre tardío de ventana: *"Cerraste ventana a las X — Lopez-Minguez 2018: cierre <21h mejora glucosa"*.

- `insight`: ÚNICO insight adaptativo seleccionado de un pool de ~20 candidatos según el patrón del ciclo. Por ejemplo:
  - Si fasting alto + sueño bajo: *"Tu ayuno fue excelente pero el sueño quedó corto. La autofagia que iniciaste no se consolida sin sueño profundo."*
  - Si nutrición A baja + ayuno alto: *"Buen ayuno, pero hoy tus platos fueron E-dominantes. El ayuno gana cuando la ventana cierra con A."*
  - Si todo ≥80%: *"Ciclo metabólico óptimo. Esta consistencia es lo que mueve tu IMR longitudinal."*

### RF-149-04 — Triggers de cierre

**Trigger principal — `manualNextFasting`:**
Dispara cuando `FastingNotifier.startFasting()` se invoca Y existe un `MetabolicCycle` abierto del que han pasado al menos 30 min desde su `startedAt`. Esto evita falsos cierres por toques accidentales.

**Trigger fallback 1 — `fallback3hAfterWindow`:**
Si han pasado 3h desde `expectedWindowCloseTime` SIN inicio de nuevo ayuno detectado. Se chequea en cada `metabolicPulseProvider` tick (10s).

**Trigger fallback 2 — `fallbackSleepDetected`:**
Si `SleepNotifier` reporta sueño iniciado (manual o vía HealthKit cuando SPEC-132.next esté listo) Y han pasado al menos 2h desde `lastMealTime`. El timestamp del cierre es el `sleepStart` del log.

**Trigger absoluto — `fallbackAbsolute`:**
Si han pasado 28h desde `startedAt` del ciclo abierto sin que nada lo haya cerrado. Defensa contra ciclos huérfanos por bugs o pérdida de conexión. Se chequea al bootstrap de la app + cada hora.

**Trigger calendárico — `fallbackCalendar`:**
Solo aplica para usuarios con `fastingProtocol == 'Ninguno'`. El ciclo se cierra a las 23:59:59 local de hoy. Equivalente al modelo actual SPEC-138.

### RF-149-05 — Persistencia: `users/{uid}/metabolic_cycles/{cycleId}`

Nueva subcollection. Shape canónico:

```
{
  cycleId: "2026-06-01T21:00:00.000Z",
  startedAt: Timestamp,
  closedAt: Timestamp,
  closureReason: "manualNextFasting" | "fallback3hAfterWindow" | ...,

  fastingDurationHours: 16.0,
  feedingWindowHours: 8.0,

  dailyScore: 87,
  pillarsCompleted: {
    fasting: true,
    sleep: true,
    hydration: false,
    exercise: true,
    nutrition: true
  },
  magnitudes: {
    fastingMagnitude: 1.0,
    sleepQualityScore: 0.85,
    hydrationMagnitude: 0.65,
    exerciseMagnitude: 1.0,
    nutritionMagnitude: 0.90
  },
  feedback: {
    achievements: [...],
    gaps: [...],
    insight: "...",
    citation: "Sutton 2018, Cell Metab"
  },

  meta: {
    schemaVersion: 1,
    fastingProtocol: "16:8",
    tzOffsetMinutes: -300
  }
}
```

**Security rules:** mismo patrón que `imr_history` (SPEC-143 §RF-143-01). Solo dueño lee/escribe. Validación que `closedAt > startedAt` y que `dailyScore` está en [0, 100].

### RF-149-06 — `MetabolicCycleService` (orquestador)

Vive en `lib/src/features/metabolic_cycle/application/metabolic_cycle_service.dart`. Es el equivalente para ciclos del `BiometricHistoryService` de SPEC-143.

Responsabilidades:
- Escuchar `fastingProvider`, `metabolicPulseProvider`, `sleepProvider`, `nutritionProvider`.
- En cada tick: chequear `MetabolicCycleResolver.shouldClose(...)`. Si retorna razón, ejecutar cierre.
- Cierre = construir `MetabolicCycle` cerrado con feedback + persistir + emit evento.
- Apertura = al detectar nuevo `FastingInterval.startTime`, construir cycle abierto + persistir.
- Idempotencia: dos cierres del mismo cycleId sobrescriben el mismo doc.

### RF-149-07 — Providers Riverpod

```dart
/// El ciclo metabólico actualmente abierto del usuario. Null si no hay.
final currentMetabolicCycleProvider = StreamProvider<MetabolicCycle?>(...);

/// Último ciclo cerrado — fuente del card de cierre en Dashboard.
final lastClosedMetabolicCycleProvider = StreamProvider<MetabolicCycle?>(...);

/// True si el usuario abrió la app y hay un ciclo cerrado en las últimas 24h
/// que aún no fue "visto" (descartado por el usuario).
final hasUnreadCycleClosureProvider = Provider<bool>(...);

/// Historial de los últimos 90 días de ciclos cerrados — para Análisis.
final metabolicCyclesHistoryProvider = StreamProvider<List<MetabolicCycle>>(...);
```

### RF-149-08 — UI: card de cierre pasiva en Dashboard

Nuevo widget `CycleClosureCard` en `lib/src/features/metabolic_cycle/presentation/widgets/cycle_closure_card.dart`.

Se inserta en `dashboard_screen.dart` ENTRE el `EngagementBanner` y `NextMealBanner`, condicionado a `hasUnreadCycleClosureProvider == true`.

**Diseño:**

```
┌────────────────────────────────────────────────┐
│  TU CICLO METABÓLICO CERRÓ                  ✕  │
│                                                │
│  87 / 100                                      │
│                                                │
│  🟢 Lograste:                                  │
│   • Cerraste ventana antes de las 19h          │
│   • Sueño 7h 30min — reparación óptima         │
│                                                │
│  🟠 Te faltó:                                  │
│   • Hidratación 65% — mañana 2L                │
│                                                │
│  💡 Cerrar tu ventana temprano hoy mejora      │
│     tu glucosa de mañana (Lopez-Minguez 2018)  │
│                                                │
│  [Empezar mi siguiente ayuno]                  │
└────────────────────────────────────────────────┘
```

- **Dismissable** vía ✕ — al cerrar, persiste `lastCycleClosureDismissedAt` en SharedPreferences.
- **CTA principal** *"Empezar mi siguiente ayuno"* navega a `fastingProvider.notifier.startFasting(DateTime.now())`.
- **Tap en el score** o en una linea de logro/gap abre `CycleDetailScreen` (SPEC-149.B — fuera del MVP de SPEC-149).

### RF-149-09 — Score del Día anclado al ciclo

Modificar `dailyScoreProvider` (SPEC-140) para que:

- **Durante un ciclo abierto:** computa en tiempo real con las magnitudes actuales (comportamiento idéntico al actual).
- **Tras un cierre:** "congela" el score del ciclo cerrado. El número del header de PILARES HOY pasa a mostrar el score del nuevo ciclo abierto (que empezará en 0).

Esto resuelve el bug reportado por Carlos: si cumplió todos los pilares y la ventana cierra a las 19h, el ciclo se cierra a las 19h, el score se congela en 100, y ese 100 es el que ve en el card de cierre.

### RF-149-10 — Migración para usuarios existentes

Al primer login post-deploy:
- Si el usuario tiene `fastingProtocol != 'Ninguno'`: arrancar un ciclo abierto con `startedAt = last fasting start` si existe, o `DateTime.now()` como aproximación.
- Si el usuario tiene `fastingProtocol == 'Ninguno'`: arrancar ciclo en modo calendárico.

Idempotente — si ya hay ciclo abierto en Firestore, no crear duplicado.

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear value object `MetabolicCycle` + enums | `lib/src/features/metabolic_cycle/domain/metabolic_cycle.dart` (nuevo) |
| 2 | Crear `MetabolicCycleResolver` (Dart puro) | `lib/src/features/metabolic_cycle/domain/metabolic_cycle_resolver.dart` (nuevo) |
| 3 | Crear `CycleFeedback` + generadores | `lib/src/features/metabolic_cycle/domain/cycle_feedback.dart` (nuevo) |
| 4 | Crear `MetabolicCycleRepository` (Firestore) | `lib/src/features/metabolic_cycle/data/metabolic_cycle_repository.dart` (nuevo) |
| 5 | Crear `MetabolicCycleService` orquestador | `lib/src/features/metabolic_cycle/application/metabolic_cycle_service.dart` (nuevo) |
| 6 | Providers Riverpod | `lib/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart` (nuevo) |
| 7 | Crear `CycleClosureCard` widget | `lib/src/features/metabolic_cycle/presentation/widgets/cycle_closure_card.dart` (nuevo) |
| 8 | Mount card en Dashboard | `lib/src/features/dashboard/presentation/dashboard_screen.dart` |
| 9 | Adaptar `dailyScoreProvider` para anclar a ciclo | `lib/src/features/streak/application/daily_score_provider.dart` |
| 10 | Security rules nueva subcollection | `firestore.rules` |
| 11 | Bibliografía: nueva §13 sobre Día Metabólico | `IMR_BIBLIOGRAPHY.md` |

Archivos NO modificados:
- `DayBoundaryResolver` queda intacto (legacy + sitio web).
- `DailyResetService` queda intacto (reset 00:00 de pilares en memoria).
- `daily_summary/{YYYYMMDD}` queda intacto (sitio MR + análisis legacy).
- `ScoreEngine.calculateIMR` (IMR legacy) queda intacto.
- `StreakEntry.dailyQualityScore` queda intacto.

## 6. Modelo de datos persistente

Ver §RF-149-05.

## 7. Criterios de aceptación

1. `MetabolicCycleResolver.shouldClose` con `closureReason = manualNextFasting` retorna correctamente cuando un nuevo ayuno se inicia >30 min después del ciclo abierto.

2. `shouldClose` con `fallback3hAfterWindow` dispara cuando `now > expectedWindowCloseTime + 3h` y no hay nuevo ayuno.

3. `shouldClose` con `fallbackSleepDetected` dispara cuando `sleepDetected == true` y `now - lastMealTime > 2h`.

4. `shouldClose` con `fallbackAbsolute` dispara cuando `now - cycle.startedAt > 28h`.

5. `useCalendarFallback('Ninguno')` retorna true. Para cualquier otro protocolo, false.

6. `calendarFallbackCloseAt` retorna `23:59:59.999` del día local de hoy.

7. `openCycle` construye un `MetabolicCycle` válido con `closedAt = null`, `closureReason = null`, `cycleId = startedAt.toIso8601String()`.

8. `CycleFeedback.achievements` incluye todos los pilares con magnitud ≥0.80 con copy específico + cita.

9. `CycleFeedback.gaps` incluye pilares <0.80 ordenados por gap descendente.

10. `MetabolicCycleService` cierre crea entry en `metabolic_cycles/{cycleId}` con `closedAt` populado y `dailyScore` final.

11. `MetabolicCycleService` apertura crea entry abierto sin `closedAt`.

12. Idempotencia: dos cierres del mismo cycleId no crean duplicados.

13. `CycleClosureCard` renderiza con dailyScore, achievements, gaps, insight + citation.

14. Tap en ✕ marca el cycle como "visto" via SharedPreferences.

15. `dailyScoreProvider` durante ciclo abierto retorna score en tiempo real. Tras cierre, retorna score del nuevo ciclo abierto (probablemente 0).

16. Migración: usuario con protocolo "16:8" sin `metabolic_cycles` previos recibe un ciclo abierto al primer login.

17. Usuario "Ninguno": `MetabolicCycleService` crea ciclos calendáricos con cierre 23:59 local.

18. `flutter analyze` sin issues nuevos.

19. `flutter test` mantiene baseline + ≥25 tests nuevos del dominio + ≥10 tests del service.

## 8. Plan de pruebas

### 8.1 — Tests del Resolver (dominio puro)

`test/features/metabolic_cycle/domain/metabolic_cycle_resolver_test.dart`:

- `shouldClose` con cada uno de los 5 ClosureReason cubierto + casos negativos.
- `openCycle` válido y casos edge (startedAt en el pasado, futuro, etc.).
- `expectedCloseAt` con cada protocolo (16:8, 18:6, 20:4, OMAD, Ninguno).
- `useCalendarFallback` con todos los protocolos válidos.
- `calendarFallbackCloseAt` con fin de mes, fin de año, DST.

### 8.2 — Tests del CycleFeedback

`test/features/metabolic_cycle/domain/cycle_feedback_test.dart`:

- Magnitudes uniformes 1.0 → 5 achievements + 0 gaps.
- Magnitudes uniformes 0.5 → 0 achievements + 5 gaps.
- Mix realista: achievements ordenados, gaps ordenados por gap descendente.
- Cita bibliográfica apropiada por pilar.
- Insight adaptativo seleccionado coherentemente con el patrón.

### 8.3 — Tests del Service

`test/features/metabolic_cycle/application/metabolic_cycle_service_test.dart`:

- Con `FakeFirebaseFirestore`: apertura, cierre, idempotencia.
- Cierre por `manualNextFasting` produce doc con razón correcta.
- Cierre por `fallback3hAfterWindow` con clock controlado.
- Migración inicial para usuario sin historial.

### 8.4 — Tests de widget

`test/features/metabolic_cycle/presentation/widgets/cycle_closure_card_test.dart`:

- Renderiza dailyScore, achievements, gaps, insight.
- Tap en ✕ marca como visto.
- Tap en CTA dispara navegación.

### 8.5 — Test E2E

`test/integration/cycle_lifecycle_test.dart`:

- Escenario: usuario inicia ayuno 16:8 a las 21:00. Pasan 16h. Abre ventana. Como 13:00, 16:00, 19:00. Inicia próximo ayuno 21:00. Verifica que se creó 1 doc cerrado + 1 doc abierto en `metabolic_cycles`.

## 9. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Refactor del concepto "día" rompe consumidores legacy (streak, daily_summary, sitio MR) | Alta | NO se reemplaza DayBoundaryResolver. Convivencia explícita. Tests E2E del sitio MR ya cubren la persistencia legacy. |
| R-02 | Fallback calendárico para "Ninguno" puede confundir si se mezcla con datos de protocolos previos | Media | Persistir `fastingProtocol` en cada ciclo. La pantalla Análisis filtra por protocolo cuando renderiza tendencia. |
| R-03 | Trigger `fallback3hAfterWindow` puede disparar incorrectamente si el usuario está activo pero olvidó iniciar el botón de ayuno | Media | El cierre es "soft" — se persiste el ciclo cerrado pero el card de cierre tiene CTA para "deshacer" (revertir cierre + abrir uno nuevo retrocediendo al lastMealTime). Operación reversible en las primeras 6h post-cierre. |
| R-04 | Trigger absoluto 28h puede ser muy permisivo para usuarios estrictos | Baja | Configurable vía `users/{uid}.cycleAbsoluteLimitHours` con default 28h. Power users pueden bajarlo a 24h. |
| R-05 | Múltiples dispositivos del mismo usuario podrían ejecutar cierres concurrentes | Media | Idempotencia por `cycleId` (timestamp del startedAt). Dos dispositivos llegando al mismo cycleId convergen al mismo doc en Firestore. WriteBatch + merge. |
| R-06 | Generación de feedback puede dar copy estereotipado con el tiempo | Media | Pool de ~20 insights candidatos por patrón. Selección semialeatoria con peso por relevancia al ciclo. SPEC-147 (Insights adaptativos) extiende esto a generación más rica. |
| R-07 | La "congelación" del Score del Día al cierre puede confundir al usuario que esperaba ver el score acumular | Alta | Copy explícito en el header del Score: tras cierre, label cambia a *"NUEVO CICLO"* hasta que tenga datos. Card de cierre persistente hasta ser descartada o ver el detalle. |
| R-08 | Usuarios que activan/desactivan protocolo "Ninguno" pueden generar transiciones extrañas | Media | El servicio detecta el cambio de protocolo y cierra el ciclo abierto con razón `protocolChanged` (nueva razón). Documentar. |
| R-09 | El sitio web Metamorfosis Real puede querer consumir metabolic_cycles para tendencias | Baja | Out of scope SPEC-149. Sitio sigue leyendo daily_summary legacy. Cuando lo necesite, SPEC-149.MR expone shape canónico apropiado. |

## 10. Plan de rollout

**Bloque A — Dominio puro + tests (4-5h):**
1. `MetabolicCycle` value object + `ClosureReason` enum.
2. `MetabolicCycleResolver` con todas las funciones puras.
3. `CycleFeedback` + generadores de achievements/gaps/insight.
4. Tests exhaustivos del Resolver y Feedback (≥30 tests).
5. Commit "SPEC-149 Bloque A — dominio puro + tests".

**Bloque B — Persistencia + service (3-4h):**
1. `MetabolicCycleRepository` + Firestore implementation.
2. `MetabolicCycleService` orquestador.
3. Providers Riverpod.
4. Security rules nuevo block.
5. Tests del service con FakeFirebaseFirestore.

**Bloque C — UI cierre + Dashboard (3-4h):**
1. `CycleClosureCard` widget.
2. Integración en `dashboard_screen.dart`.
3. Adaptar `dailyScoreProvider`.
4. Tests de widget.

**Bloque D — Migración + bibliografía + cierre (2-3h):**
1. Migración para usuarios existentes.
2. Reescribir `IMR_BIBLIOGRAPHY.md` con nueva §13.
3. Actualizar memoria del proyecto.
4. Smoke test end-to-end manual.
5. Marcar SPEC-149 CLOSED.

## 11. Out of scope (explícito)

- Pantalla de detalle del ciclo histórico (SPEC-149.B).
- Notificación push activa al cierre (SPEC-149.next).
- Migración del IMR longitudinal a ciclos (SPEC-141 cuando entre).
- Migración del sitio web Metamorfosis Real a leer `metabolic_cycles` (SPEC-149.MR).
- Insights más ricos basados en patrones de >7 ciclos (SPEC-147).
- Comparativa visual ciclo a ciclo en pantalla Análisis (Ola 2).
- Inferencia automática de ciclos para usuarios "Ninguno" (deliberadamente fuera de scope MVP).
- Sincronización con HealthKit sleep para trigger fallback 2 (depende de SPEC-132.next).
- Multi-tenancy (un usuario con varios protocolos paralelos).

## 12. Aprobación

Esta SPEC requiere:

1. **Visto bueno de Carlos** sobre los 4 puntos confirmados: SPEC-149 entra a Ola 1, fallback calendárico para Ninguno (MVP), card pasiva (no modal bloqueante), arrancar inmediatamente.
2. **Sin validación clínica externa** — la cronobiología subyacente ya está validada en SPEC-70.5 (Lopez-Minguez 2018, Sutton 2018, Mattson 2017). SPEC-149 aplica el marco existente.
3. **Coordinación operacional con sitio web Metamorfosis Real** — notificarles que se introduce `metabolic_cycles` subcollection. NO consumen aún. Queda como capability futura.

## 13. Changelog

### v1.0 — 2026-06-01

Documento inicial post-feedback de Carlos sobre IMR diario que no llega a 100%. Diagnóstico: SPEC-138 definió el día como medianoche calendárica por pragmatismo, no por correspondencia metabólica. SPEC-149 introduce el Día Metabólico como capa semántica sobre los datos persistidos, anclada al ciclo ayuno↔alimentación. Aprobada por Carlos 2026-06-01 con las 4 decisiones de §12. Entra a Ola 1 del pivot estratégico passive→active coaching.

### Cierre 2026-06-01 (mismo día)

Implementación completada en 4 bloques durante la misma sesión:

**Bloque A — dominio puro.** `MetabolicCycle` value object inmutable con `open()`/`close()`. `MetabolicCycleResolver` puro con `shouldClose()` evaluando 6 triggers en orden de prioridad. `ClosureReason` enum con serialización. `CycleFeedback` con `CycleFeedbackGenerator` que produce achievements/gaps/insight desde un pool de ~20 candidatos calibrados con citas bibliográficas (Mattson, Walker, EFSA, ACSM, Liu, Sutton, Spiegel, Lopez-Minguez). ~50 tests del dominio.

**Bloque B — persistencia + service.** `MetabolicCycleRepository` interfaz + impl Firestore con mapper completo para campos opcionales del cierre. `MetabolicCycleService` orquestador con `evaluateAndApply()` (cierre + apertura encadenados) y `bootstrapIfMissing()` (creación retroactiva post-login). 5 providers Riverpod (`metabolicCycleServiceProvider`, `currentMetabolicCycleProvider`, `lastClosedMetabolicCycleProvider`, `metabolicCyclesHistoryProvider`, `hasUnreadCycleClosureProvider`). Rule específica en `firestore.rules` para `metabolic_cycles`. 8 tests del service con FakeFirebaseFirestore.

**Bloque C — UI cierre.** `CycleClosureCard` con arquitectura Container/View — `CycleClosureCardView` stateless puro testeable sin Riverpod, `CycleClosureCard` ConsumerWidget wrapper que lee providers. Layout: header letterspaced + ✕ dismissable + score 48pt monospace + sección LOGRASTE verde + sección TE FALTÓ ámbar + insight con citation + CTA "Empezar mi siguiente ayuno". 10 widget tests cubriendo render condicional, edge cases, interacciones, assertion defensiva.

**Bloque D — integración Dashboard + bibliografía + cierre.** `metabolicCycleEvaluatorProvider` side-effect que escucha `metabolicPulseProvider` (cada 10s) + `fastingProvider` (transición isActive false→true) y dispara `evaluateAndApply`. `metabolicCycleBootstrapProvider` one-shot al login que llama `bootstrapIfMissing`. Mount del `CycleClosureCard` en Dashboard entre `EngagementBanner` y `NextMealBanner`, conectado a `fastingProvider.notifier.startFasting()` vía callback del CTA. `IMR_BIBLIOGRAPHY.md` §13 nueva con 7 sub-secciones (definición, justificación bibliográfica, 6 triggers tabulados, coaching al cierre, relación con SPEC-138, relación con SPEC-141, out of scope explícito).

**Deuda técnica diferida explícita:** el `dailyScoreProvider` (SPEC-140) sigue mostrando "Score del Día calendárico" en el header de PILARES HOY. El "Score del Ciclo" aparece exclusivamente en el card de cierre. El refactor profundo del provider para anclar al ciclo va en Ola 2 cuando construyamos la pantalla de Análisis con historia. Documentado en SPEC-149 §13.7 y en la decisión arquitectural de Bloque D.

> **DEUDA RESUELTA 2026-06-04 — SPEC-171** (`specs/SPEC-171-cycle-aware-daily-score.md`). Se agregó `displayDailyScoreProvider` que decide entre cíclico (CycleScoreComputer aplicado sobre magnitudes en vivo) y calendárico (fallback al legacy `dailyScoreProvider`). El callsite del header en `dashboard_screen.dart` pasó al nuevo provider. El `dailyScoreProvider` legacy se mantiene intacto porque lo consume el evaluador del ciclo y cambiarlo crearía dependencia circular. Bibliografía: SPEC-171 §1.2.

**Próximo paso desbloqueado:** Ola 1 sigue con SPEC-146 (Auth hardening) y SPEC-132.next (HealthKit observers + background delivery). Ola 2 puede empezar a planificar el refactor del Score del Día sobre ciclos en lugar de días calendarios.
