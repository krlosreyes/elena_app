# SPEC-141 — IMR de Perfil: refactor a métrica longitudinal compuesta

**Estado:** CLOSED-PENDING-CLINICAL 2026-06-05 (código entregado tras feature flag; validación clínica externa sigue pendiente para flippear)
**Versión:** 1.2

---

## 0. Estado actual (2026-06-05)

Bloques A-E entregados:

- **A** — `StreakEngine.computeMonthlyQualityScore` + `computeActiveDaysLast90` + `computeAdherenceTrend`. `ScoreEngine.calculateLongitudinalIMR` con fórmula 40/35/15/10 y renormalización si `history < 7` magnitudes. `IMRv2Result` extendido con `longitudinalScore`, `subscoreBehaviorTrend`, `subscoreAdherence`, `subscoreCoherence` (nullable, no rompe legacy).
- **B** — `longitudinalImrProvider` (live, sin red). `WeeklyImrSnapshotService` con triggers A (check-in) y C (staleness 7d) conectados. Gatillo B (HealthKit) deferred a SPEC-141.2. Helper `buildWeekISO`.
- **C** — `imrToCanonicalMap` detecta `longitudinalScore` y emite shape `schemaVersion=2` con `legacyDailyScore` + `subscores`. `UserProfileRepository.writeImrHistorySnapshot` escribe a `users/{uid}/imr_history/{weekISO}` idempotente. Firestore rules ya cubrían la colección (SPEC-143).
- **D** — `kEnableLongitudinalImr = false` por default en `lib/src/core/config/feature_flags.dart`. Cuando flag ON, `profile_screen.dart` lee `longitudinalImrProvider`, sustituye el score del badge y agrega banner ámbar "Validación clínica pendiente".
- **E** — bibliografía actualizada (§14 con Dansinger 2005 + Petersen-Shulman 2018), memoria persistida, este cierre formal.

**Para activar en producción:**
1. Especialista clínico firma validación de pesos macro (§11).
2. Sitio Astro Metamorfosis Real actualizado para leer `schemaVersion=2` (Carlos coordina).
3. Cambiar `kEnableLongitudinalImr` a `true` en `feature_flags.dart` (1 línea).
4. Telemetría in-app confirma estabilidad: scores 50-75 en perfiles activos, sin saltos >15 puntos por snapshot.

---

**Versión histórica:** 1.1
**Fecha:** 2026-06-01 (v1.0) · refinada 2026-06-01 (v1.1, cadencia semanal + dependencia explícita con SPEC-143) · diseño aprobado 2026-06-01
**Tipo:** Refactor de motor central — redefinición del IMR como métrica longitudinal con cadencia de cómputo semanal
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** 2 (post-SPEC-140 — el Score del Día debe existir primero para que el componente "behaviorTrend 30d" tenga su fuente canónica)
**Estimación:** 5–6 días Carlos+Claude + revisión clínica externa (paralelizable)
**Marco normativo:** `CONSTITUTION.md`, `IMR_BIBLIOGRAPHY.md` (a actualizar tras esta SPEC), `docs/ROADMAP_PRODUCCION_10_10.md`.
**Depende de:**
- SPEC-65 (`StreakEntry.dailyQualityScore` — fuente del componente longitudinal).
- SPEC-71 (`CoherenceEngine.calculate` — fuente del componente de coherencia).
- SPEC-82 (canonical mirror `imr.current` — debe versionarse a schemaVersion = 2).
- SPEC-70.5 (validación clínica externa previa — esta SPEC abre nueva revisión).
- SPEC-140 (Score del Día — si está implementado, su `dailyScore` reemplaza a `dailyQualityScore` como fuente del componente 35%; ver §RF-141-04).

**Bloquea:**
- SPEC-142 (refactor de UI Análisis + Profile que renderiza ambos scores explícitamente — depende de tener los dos campos persistidos).

**Dependencia dura (nueva en v1.1):**
- **SPEC-143** (Persistencia histórica del IMR + versionado automático biométrico). SPEC-141 no puede entrar a IN_PROGRESS sin SPEC-143 aprobada. Razón: la cadencia semanal requiere una colección `imr_history` que hoy no existe, y el gatillo "check-in biométrico" requiere que toda edición de peso/cintura/etc. versionen automáticamente — gap explícito detectado en auditoría 2026-06-01.

---

## 1. Contexto y motivación

### 1.1 — El problema observado en producción

Un usuario que completa los 5 pilares perfectamente en un día puede ver un IMR de **34/100** en su pantalla Análisis. La razón es matemática, no un bug: el `IMRv2Result.totalScore` actual combina tres bloques con la fórmula firmada en SPEC-70.5:

```
IMR_actual = 0.50 × Estructura + 0.25 × Metabolismo + 0.25 × Conducta
```

El bloque **Estructura** (WHtR + FFMI age-stratified) no se mueve día a día — depende de composición corporal, que cambia en semanas/meses. Para un adulto promedio sin biometría óptima, `structureBlock ≈ 0.3–0.5`. Aunque Metabolismo y Conducta lleguen a 1.0 (5 pilares perfectos), el techo matemático del IMR diario queda en `0.50 × 0.4 + 0.25 + 0.25 ≈ 0.70 = 70/100`. En perfiles sin `bodyFatPercentage` real (fallback poblacional SPEC-92), el techo es aún más bajo.

Esta característica fue intencional bajo el supuesto "IMR = estado metabólico real, no logro diario". Pero en práctica:

1. **El IMR se renderiza en la pantalla diaria** (`imr_ring_with_satellites.dart` línea 91 — central, 56pt, etiquetado "IMR HOY"). El usuario lo lee como score del día.
2. **No hay otra métrica que responda "¿cómo viví hoy?"** que llegue a 100. El esfuerzo perfecto del día queda sin recompensa visible.
3. **El IMR se mueve poco día a día** (por el peso 0.50 de Estructura), entonces tampoco cumple bien su rol original de feedback de adherencia.

Resultado: un número que confunde dos preguntas y responde mal a ambas.

### 1.2 — La separación propuesta

SPEC-140 introduce **Score del Día** — métrica 0-100 alcanzable con 5 pilares perfectos, que vive en el Dashboard y reemplaza al rol motivacional del IMR diario.

SPEC-141 (este documento) redefine el **IMR** como métrica longitudinal de **perfil metabólico**, que es lo que originalmente quería ser: un indicador de salud metabólica de fondo basado en composición corporal + adherencia sostenida en el tiempo + coherencia entre pilares. Pasa al badge identitario de Perfil y al sitio web Metamorfosis Real. Ya no se renderiza como "IMR HOY".

### 1.3 — Por qué el cambio es legítimo bibliográficamente

El `IMR_BIBLIOGRAPHY.md §1 nota meta-analítica` ya admite explícitamente:

> "El reparto 50/25/25 es una decisión del equipo basada en literatura agregada. **No** existe un estudio que valide este split exacto contra una cohorte. Es defendible pero la calibración exacta es **ENGINEERING JUDGMENT**."

Y el roadmap clínico §9.1 ya tenía pendiente:

> "Cuando ElenaApp tenga >1000 usuarios con ≥90 días de uso, correr regresión de outcomes percibidos vs componentes del IMR para validar empíricamente. Sigue siendo el siguiente paso natural cuando haya datos."

SPEC-141 no contradice la bibliografía; ejecuta su propio roadmap antes de tener los 1000 usuarios. La validación clínica externa de SPEC-70.5 firmó pesos *internos* a cada bloque (circadiano 38%, sueño 7h, hidratación 10%); esta SPEC re-pondera los *macro-bloques*, no los internos. Es un cambio de organización del agregado, no un cambio del modelo clínico.

## 2. Decisión de producto (resumen ejecutivo)

1. **Se introduce un nuevo método `ScoreEngine.calculateLongitudinalIMR(user, state, history)`** que produce el IMR longitudinal compuesto. La firma actual `calculateIMR(user, state)` se preserva sin cambios — el motor expone ambos durante la transición.
2. **La fórmula longitudinal es:**
   ```
   IMR_longitudinal =
       0.40 × Estructura
     + 0.35 × ScoreDiarioPromedio30d
     + 0.15 × AdherenceTrend
     + 0.10 × Coherencia
   ```
3. **Los cuatro componentes se calculan exclusivamente con datos que ya existen:** `structureBlock` (de `calculateIMR`), `StreakEntry.dailyQualityScore` (SPEC-65), `currentStreak` + `activeDaysLast90` (StreakEngine), `CoherenceEngine.calculate` (SPEC-71).
4. **Renormalización para usuarios sin historial completo:** si el historial es < 7 días, los pesos de componentes longitudinales se renormalizan sobre Estructura. Un usuario que recién terminó onboarding obtiene `score = structureBlock × 100` (mismo techo que `calculateBaseline` actual, no peor).
5. **El sitio web Metamorfosis Real recibe el cambio vía `meta.schemaVersion = 2`** en `imr.current`. El campo `totalScore` pasa a representar el nuevo IMR longitudinal. Se agregan subcampos en `imr.current.subscores` para que el frontend pueda renderizar el desglose. El campo `legacyDailyScore` se persiste en paralelo durante 30 días de transición para que el sitio tenga ventana de migración.
6. **El IMR que se muestra hoy en Análisis NO cambia de fuente en esta SPEC.** Eso queda explícitamente a SPEC-142 (refactor de UI). Esta SPEC solo introduce el nuevo método y persiste sus outputs. La pantalla Análisis sigue mostrando `calculateIMR` (diario) hasta que SPEC-142 la reemplace por el longitudinal o por el Score del Día.
7. **El badge IMR en Profile (`profile_screen.dart` línea 772) SÍ cambia de fuente en esta SPEC** — pasa a leer el longitudinal. Esto es deliberado: Profile es identidad metabólica, no acción diaria.
8. **🆕 v1.1 — El IMR longitudinal NO se recalcula a cada cambio de pilar.** Se computa con cadencia semanal (cada 7 días naturales) y solo se dispara por uno de estos tres gatillos: (a) check-in biométrico manual del usuario, (b) sync nuevo desde HealthKit/Health Connect que aporte mediciones biométricas, (c) fallback automático cuando al abrir la app han pasado > 7 días desde el último snapshot. Esta cadencia tiene tres razones: refleja la escala real de cambio metabólico (ver Petersen-Shulman 2018), reduce escrituras a Firestore en ~50× respecto al cálculo live, y alinea el IMR con su semántica de "perfil de fondo" — no se mueve por una taza de agua.
9. **🆕 v1.1 — Cada snapshot semanal persiste en `users/{uid}/imr_history/{weekISO}`** (colección que SPEC-143 crea). El campo `users/{uid}.imr.current` se convierte en *cache del último snapshot* (lectura rápida para Profile), apuntando al último weekISO escrito. Profile y el sitio web Metamorfosis Real leen `imr.current` sin tocar la subcollection. Análisis (cuando SPEC-142 lo refactorice) puede leer `imr_history` para mostrar tendencia.

## 3. Lo que NO se hace (límites duros de scope)

- **No se elimina ni se modifica `calculateIMR(user, state)`.** El método legacy sigue funcionando idénticamente para no romper consumidores ni tests existentes. SPEC-142 decidirá su retiro futuro.
- **No se modifican los pesos internos a Estructura, Metabolismo o Conducta.** SPEC-70.5 sigue firmando esos pesos. Solo se re-pondera el agregado macro.
- **No se cambia `ScoreEngine.calculateBaseline(user)`.** El usuario que termina onboarding sin historial sigue obteniendo el score basado en Estructura. La renormalización de §RF-141-05 produce el mismo número para ese caso.
- **No se cambia ningún campo de `MetabolicState` ni `IMRv2Result` ya existente.** Solo se agregan campos derivados nuevos en `IMRv2Result` (`longitudinalScore`, `subscoreStructure`, `subscoreBehaviorTrend`, `subscoreAdherence`, `subscoreCoherence`).
- **No se toca la UI del Dashboard ni de Análisis.** Esos cambios son SPEC-142.
- **No se introduce nuevo input del usuario.** Todo se computa con datos que ya se persisten.
- **No se cambia el cálculo de `metabolicCoherence` ni de `dailyQualityScore`.** Solo se consume.
- **No se prometen outcomes clínicos en copy.** El IMR longitudinal se etiqueta como "perfil metabólico" y se acompaña de su tooltip educativo, igual que el actual.
- **🆕 v1.1 — El IMR longitudinal NO se recalcula en tiempo real.** Si el usuario abre la app 10 veces en un día, el número que ve en Profile es el mismo en las 10 — corresponde al último snapshot semanal. Esto es deliberado y refuerza la semántica de "perfil de fondo". Solo se actualiza con los gatillos de §RF-141-12.
- **🆕 v1.1 — No se crea infraestructura de Cloud Functions ni cron-jobs externos** para forzar recálculo. El gatillo fallback de §RF-141-12.C es client-side al abrir la app. Esto evita complejidad operacional y costos GCP. Una SPEC futura puede agregar un Cloud Function si el patrón de uso revela que muchos usuarios no abren la app cada 7 días.

Cualquier PR que vulnere estos límites debe abrir SPEC nueva.

## 4. Requisitos funcionales

### RF-141-01 — Nuevo método en `ScoreEngine`

Agregar:

```dart
class ScoreEngine {
  // ... métodos existentes preservados ...

  /// SPEC-141: IMR longitudinal compuesto. Combina composición
  /// corporal (estructura) con adherencia sostenida (30 días de
  /// dailyQualityScore), consistencia (streak/active days) y
  /// coherencia metabólica (CoherenceEngine).
  ///
  /// Reemplaza el rol identitario del IMR diario en la pantalla
  /// Perfil. El IMR diario (`calculateIMR`) se preserva sin cambios.
  IMRv2Result calculateLongitudinalIMR(
    UserModel user,
    MetabolicState state,
    List<StreakEntry> history,
  );
}
```

### RF-141-02 — Composición numérica

La fórmula es:

```
structure       = structureBlock(user)                              // 0..1
behaviorTrend30 = monthlyQualityScore(history)                      // 0..1
adherenceTrend  = computeAdherenceTrend(history)                    // 0..1
coherence       = state.metabolicCoherence                          // 0..1

raw_full = 0.40*structure + 0.35*behaviorTrend30
         + 0.15*adherenceTrend + 0.10*coherence

longitudinalScore = (raw_renormalized * 100).round().clamp(0, 100)
```

Donde `raw_renormalized` aplica la regla de renormalización de §RF-141-05.

### RF-141-03 — Nuevo cómputo `computeMonthlyQualityScore`

Extender `StreakEngine` con el método equivalente al `computeWeeklyQualityScore` (SPEC-53) pero con ventana de 30 días:

```dart
/// SPEC-141: promedio del dailyQualityScore en ventana de 30 días.
///
/// Espejo de [computeWeeklyQualityScore] con ventana extendida. Es el
/// input primario del IMR longitudinal (peso 35%).
///
/// Casos:
/// - Historial vacío → 0.0.
/// - Menos de 30 entries en ventana → promedio sobre las disponibles
///   (NO se divide por 30; mismo patrón que el semanal).
/// - Entradas legacy sin magnitudes → fallback `pillarsCompleted/5`
///   ya documentado en StreakEntry.
static double computeMonthlyQualityScore(List<StreakEntry> history)
```

Implementación: idéntica a `computeWeeklyQualityScore` cambiando el `subtract(const Duration(days: 6))` por `subtract(const Duration(days: 29))` (30 días incluyendo hoy).

### RF-141-04 — Fuente del `behaviorTrend30` cuando SPEC-140 esté vigente

Si SPEC-140 (Score del Día) está implementada y persiste `dailyScore` por entrada, el componente `behaviorTrend30` pasa a ser:

```
behaviorTrend30 = average(history[last 30].dailyScore) / 100
```

Si SPEC-140 NO está aún implementada (estado al momento de aprobar esta SPEC), el componente usa el `dailyQualityScore` de StreakEntry directamente (que es semánticamente similar pero con pesos legacy 25/20/20/20/15).

La transición se hace en una SPEC posterior (`SPEC-141.bis`) cuando SPEC-140 esté en producción; entretanto, la fuente queda explícitamente documentada en código:

```dart
// SPEC-141: behaviorTrend30 usa dailyQualityScore (SPEC-65) hasta
// que SPEC-140 (Score del Día con pesos 25/22/20/18/15) esté en
// producción y persistiendo `dailyScore` por entrada. La migración
// se hace en SPEC-141.bis cuando esa condición se cumpla.
```

### RF-141-05 — Renormalización para usuarios sin historial

Cuando el usuario no tiene suficiente historial para calcular `behaviorTrend30`, `adherenceTrend` o `coherence`, los pesos correspondientes se redistribuyen proporcionalmente sobre los componentes con señal.

**Reglas de "no disponible":**
- `behaviorTrend30`: no disponible si `history.length < 7`. Un usuario debe tener al menos 7 días para que un "promedio mensual" tenga sentido.
- `adherenceTrend`: no disponible si `history.length < 3`. Necesitamos al menos 3 días para que streak/active sea significativa.
- `coherence`: no disponible si `state.lastMealTime == null` (mismo gate que `calculateIMR`).

**Algoritmo:**

```dart
final componentes = <(double weight, double signal, bool available)>[
  (0.40, structure,       true),                      // siempre
  (0.35, behaviorTrend30, history.length >= 7),
  (0.15, adherenceTrend,  history.length >= 3),
  (0.10, coherence,       state.lastMealTime != null),
];

final disponibles = componentes.where((c) => c.available).toList();
if (disponibles.isEmpty) {
  // sólo posible si Estructura es 0 (caso defensivo, no debería ocurrir)
  return IMRv2Result.empty();
}

final sumWeights = disponibles.fold(0.0, (acc, c) => acc + c.weight);
final weighted   = disponibles.fold(0.0,
  (acc, c) => acc + c.weight * c.signal);
final rawRenormalized = weighted / sumWeights;
final longitudinalScore = (rawRenormalized * 100).round().clamp(0, 100);
```

**Consecuencia:** un usuario que recién terminó onboarding (0 días de historial) obtiene `score = structureBlock × 100`, idéntico al actual `calculateBaseline`. La progresión a un usuario con 30+ días es continua y sin saltos.

### RF-141-06 — `computeAdherenceTrend` (nueva métrica derivada)

```dart
/// SPEC-141: tendencia de adherencia 0..1.
///
/// Combina dos señales binarias-suaves:
///   - currentStreak normalizada a 30 días (cap)
///   - % días con al menos un pilar logueado en últimos 90 días
///
/// Fórmula: 0.5 * (min(currentStreak, 30) / 30) + 0.5 * (activeDays90 / 90)
///
/// Diseño: el primer término premia consistencia reciente (racha viva),
/// el segundo premia presencia sostenida en la app (no perfección).
/// Un usuario con racha 30+ Y presencia 90/90 obtiene 1.0.
static double computeAdherenceTrend(List<StreakEntry> history)
```

Implementación delegada a `StreakEngine`. `activeDaysLast90` se define como el conteo de entradas en `history` con fecha dentro de los últimos 90 días que tienen al menos un pilar registrado (`pillarsCompleted >= 1`).

### RF-141-07 — Extensión de `IMRv2Result`

Agregar campos derivados nuevos al value object existente:

```dart
class IMRv2Result {
  // ... campos existentes preservados ...

  /// SPEC-141: score longitudinal compuesto (40/35/15/10).
  /// 0 si el método legacy `calculateIMR` lo produjo
  /// (preserva backward compat).
  final int longitudinalScore;

  /// SPEC-141: subscores expuestos para que el sitio web y la UI
  /// puedan renderizar el desglose. Todos en escala 0..1.
  final double subscoreStructure;     // peso 0.40
  final double subscoreBehaviorTrend; // peso 0.35
  final double subscoreAdherence;     // peso 0.15
  final double subscoreCoherence;     // peso 0.10

  /// SPEC-141: indica cuál de las dos fórmulas produjo este result.
  /// 'daily' = calculateIMR (legacy), 'longitudinal' = calculateLongitudinalIMR.
  final String scoreVariant;
}
```

Defaults para constructores existentes:
- `IMRv2Result.empty()` → `longitudinalScore: 0`, subscores `0`, `scoreVariant: 'empty'`.
- `calculateIMR(...)` retorna el result con `longitudinalScore: 0`, subscores `0`, `scoreVariant: 'daily'`.
- `calculateLongitudinalIMR(...)` retorna `totalScore: longitudinalScore` (alias), subscores correctos, `scoreVariant: 'longitudinal'`.

### RF-141-08 — Persistencia canónica `imr.current`

Extender `imr_persistence_provider.dart` para que el sink debounced persista TANTO el legacy diario COMO el longitudinal:

```
users/{uid}.imr.current:
  schemaVersion: 2                  // era 1 — bump por esta SPEC
  totalScore: <longitudinalScore>   // ahora el longitudinal (perfil)
  legacyDailyScore: <dailyScore>    // SPEC-141: ventana transición 30 días
  subscores:
    structure: 0..1
    behaviorTrend: 0..1
    adherence: 0..1
    coherence: 0..1
  zone: <zone del longitudinal>
  description: <descripción del longitudinal>
  imc, tmb, metabolicAge, ica, ffmi, whtr: ... (sin cambios)
  updatedAt: <serverTimestamp>
```

El campo `legacyDailyScore` se persiste durante 30 días post-deploy para que el sitio web Metamorfosis Real tenga ventana de migración. Pasados 30 días, se abre `SPEC-141.cleanup` para retirarlo.

### RF-141-09 — Profile screen lee snapshot semanal (no live)

`profile_screen.dart` línea ~706-797 (`_buildIdentityCard`) consume hoy `imrResult.score` desde un provider que computa live. **v1.1: pasa a leer el snapshot persistido en `users/{uid}.imr.current`** vía `weeklyImrSnapshotProvider` (stream sobre el doc raíz, sin invocar `ScoreEngine` en runtime).

El provider:
- Stream sobre `users/{uid}` filtrando solo el subcampo `imr.current`.
- Si `imr.current.scoreVariant == 'longitudinal'`, renderiza ese score.
- Si está vacío o legacy, dispara una recomputación inicial (one-shot, no live).

El badge de Profile, al recargarse, muestra el último snapshot. NO se mueve cuando el usuario registra una comida o agua — solo cuando se dispara un gatillo de §RF-141-12.

### RF-141-12 — Servicio `WeeklyImrSnapshotService` (cadencia semanal)

Nueva clase en `lib/src/core/engine/weekly_imr_snapshot_service.dart`:

```dart
class WeeklyImrSnapshotService {
  WeeklyImrSnapshotService(this._ref);
  final Ref _ref;

  /// Gatillo A — usuario hizo check-in biométrico manual.
  /// Se invoca desde BiometricCheckinNotifier al persistir nueva medición.
  /// Siempre recomputa (el usuario explícitamente actualizó su composición).
  Future<void> recomputeOnBiometricCheckIn(UserModel user);

  /// Gatillo B — HealthKit / Health Connect aportó nueva biometría.
  /// Se invoca desde el listener del puente SPEC-132 cuando llegan
  /// mediciones de peso/cintura/composición. Si la diferencia con la
  /// medición anterior es < 1%, NO recomputa (ruido del sensor).
  Future<void> recomputeOnHealthKitSync(UserModel user, BiometricDelta delta);

  /// Gatillo C — fallback: si al abrir la app han pasado > 7 días
  /// desde el último snapshot, recomputa con los datos actuales sin
  /// pedir intervención. Sirve para usuarios que no hacen check-in.
  /// Se invoca desde el splash/init de la app (o desde el provider
  /// al detectar `imr.current.weekISO` viejo).
  Future<void> recomputeIfStale(UserModel user);

  /// Lógica común: computa, persiste en imr_history/{weekISO} y
  /// actualiza imr.current como cache. Idempotente por weekISO.
  Future<void> _writeSnapshot(UserModel user, {required String reason});
}
```

Reglas operacionales:

- **weekISO** = ISO 8601 week number (`yyyy-Www`, ej. `2026-W23`). Una sola snapshot por semana ISO por usuario. Reescritura del mismo weekISO sobrescribe (idempotente).
- **Resolución del "último snapshot":** `imr.current.weekISO` apunta al doc activo en `imr_history`.
- **Cuando dos gatillos coinciden en la misma semana ISO:** el más reciente gana (sobrescribe el doc del weekISO). El campo `reason` registra el último gatillo: `'biometric_checkin' | 'healthkit_sync' | 'fallback_stale'`.
- **Onboarding:** al completar onboarding, se dispara `_writeSnapshot` con reason `'onboarding_baseline'`. Este es el primer snapshot del usuario y siempre usa `calculateBaseline` si `history.length < 7`.

### RF-141-13 — Detección de staleness al abrir la app

Lugar de invocación: el provider raíz que monta el árbol de Riverpod tras login exitoso (probablemente `userBootstrapProvider` o similar — confirmar en implementación).

Lógica:

```dart
final last = user.imr.current.computedAt;  // Timestamp
final now = DateTime.now();
if (last == null || now.difference(last).inDays >= 7) {
  await WeeklyImrSnapshotService(ref).recomputeIfStale(user);
}
```

Esta lógica corre **una sola vez por sesión de app** (no en cada rebuild). Si el usuario abre la app dos veces en el mismo día tras un snapshot fresco, no se dispara nada. Si abre la app después de 10 días, dispara una recomputación que toma datos del estado actual de los 5 pilares + history últimos 30 días + biometría actual.

### RF-141-10 — Analysis screen NO cambia en esta SPEC

`imr_ring_with_satellites.dart` y `daily_summary_provider.dart` siguen consumiendo `calculateIMR` (legacy diario) sin cambios. SPEC-142 decidirá si esa pantalla migra al Score del Día (SPEC-140) o al IMR longitudinal o muestra ambos como dos cards.

Esta separación es deliberada — SPEC-141 introduce el cálculo y la persistencia sin tocar UI más allá del badge Profile, que sí cambia de fuente.

### RF-141-11 — Tooltip / glossario actualizado (v1.1)

En el badge de Profile, al tap largo, mostrar tooltip:

> **IMR — Índice de Resiliencia Metabólica**
> Tu salud metabólica de fondo, basada en composición corporal (40%), adherencia sostenida los últimos 30 días (35%), consistencia y racha (15%) y coherencia entre pilares (10%). **Se actualiza cada 7 días o cuando registras nuevas medidas corporales.** Última actualización: *[hace X días]*.

El copy explícito de los pesos es deliberado: la promesa de marca es transparencia científica. El usuario que toca el badge entiende qué mide y cuándo cambia.

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Agregar `calculateLongitudinalIMR` + helper `_renormalize` | `lib/src/core/engine/score_engine.dart` |
| 2 | Agregar `computeMonthlyQualityScore` y `computeAdherenceTrend` | `lib/src/features/streak/domain/streak_engine.dart` |
| 3 | Extender `IMRv2Result` con campos derivados nuevos | `lib/src/core/engine/score_engine.dart` (mismo archivo) |
| 4 | Adaptar persistencia a `schemaVersion: 2` + `legacyDailyScore` + ruta `imr_history/{weekISO}` | `lib/src/core/engine/imr_persistence_provider.dart` |
| 5 | **🆕 v1.1 — Crear `WeeklyImrSnapshotService`** con 3 gatillos | `lib/src/core/engine/weekly_imr_snapshot_service.dart` (nuevo) |
| 6 | **🆕 v1.1 — Crear `weeklyImrSnapshotProvider`** (stream sobre `imr.current` cache) | `lib/src/core/engine/weekly_imr_snapshot_provider.dart` (nuevo) |
| 7 | **🆕 v1.1 — Conectar gatillo A** desde BiometricCheckinNotifier | `lib/src/features/progress/application/biometric_checkin_notifier.dart` |
| 8 | **🆕 v1.1 — Conectar gatillo C** (staleness check al login) | `lib/src/core/orchestrator/user_bootstrap_provider.dart` (o equivalente; confirmar en implementación) |
| 9 | Migrar badge Profile al provider del snapshot | `lib/src/features/auth/presentation/profile_screen.dart` |
| 10 | Actualizar bibliografía con nueva fórmula y citas | `IMR_BIBLIOGRAPHY.md` (nueva §1.1 + actualización §1) |
| 11 | Actualizar canonical mapper para schemaVersion 2 | `lib/src/shared/data/mappers/user_profile_mapper.dart` |

**Gatillo B (HealthKit sync) NO se conecta en esta SPEC** — depende de SPEC-132 (que aún no expone su API de eventos). Una vez SPEC-132 cierre, se abre `SPEC-141.2` con ese único cambio: invocar `recomputeOnHealthKitSync` desde el listener del puente.

Archivos NO modificados:
- `calculateIMR` y `calculateBaseline` quedan intactos.
- `MetabolicStateBuilder` no toca su firma.
- `CoherenceEngine` se consume sin cambios.
- `StreakEntry` no agrega campos (todos sus getters siguen vigentes).
- Pantalla Análisis (`analysis_screen.dart`, `imr_ring_with_satellites.dart`, `daily_summary_*`) sin cambios.
- Dashboard (`dashboard_screen.dart`) sin cambios.
- Tests existentes de `calculateIMR` siguen pasando idénticos.
- `imr_persistence_provider.dart` deja de tener debounce de 15s. Ya no escribe en cada cambio de pilar — solo cuando lo invoca `WeeklyImrSnapshotService._writeSnapshot`. Esto reduce escrituras Firestore ~50×.

## 6. Cambios en bibliografía

### 6.1 — `IMR_BIBLIOGRAPHY.md` se actualiza así

Nueva §0 al inicio del documento:

> **SPEC-141 (2026-06-XX):** desde esta versión, el `totalScore` que el sitio web Metamorfosis Real y el badge de Perfil consumen es el **IMR longitudinal** (40/35/15/10), no el IMR diario (50/25/25). El IMR diario sigue calculándose internamente para la pantalla Análisis hasta que SPEC-142 redefina su rol. Todas las secciones siguientes describen los pesos *internos* a cada bloque, que no cambian. Lo que cambia es la *organización del agregado*.

§1 se reescribe para distinguir explícitamente:

- §1.A — IMR diario (50/25/25): preservado en `calculateIMR`, fuente interna.
- §1.B — IMR longitudinal (40/35/15/10): nuevo agregado de perfil. Cita SPEC-141. Cada componente apunta a su propia sección:
  - Estructura 40% → §1.A.1 (Estructura ya documentada).
  - BehaviorTrend30 35% → §6 (Daily quality score) + ventana 30d.
  - AdherenceTrend 15% → nuevo §13.
  - Coherence 10% → §X (CoherenceEngine, SPEC-71, ya documentado en otro doc — agregar referencia cruzada).

Nuevo §13 — Pesos del IMR longitudinal:

```
§13.1 — Estructura 0.40 [HIGH] — composición corporal, mismo bloque que §2.
§13.2 — BehaviorTrend30 0.35 [MEDIUM] — promedio del dailyQualityScore
                                       en 30 días. Captura adherencia
                                       sostenida; ventana clínicamente
                                       relevante (~1 ciclo menstrual, ~1
                                       ciclo de adaptación metabólica).
§13.3 — AdherenceTrend 0.15 [ENGINEERING JUDGMENT] — combina racha actual
                                       y presencia 90d. Sin literatura
                                       directa pero refleja el principio
                                       de Dansinger 2005 JAMA: adherencia
                                       sostenida domina sobre intervención
                                       puntual.
§13.4 — Coherence 0.10 [MEDIUM] — CoherenceEngine SPEC-71. Penaliza
                                       desincronizaciones entre pilares
                                       (sueño bajo + ejercicio intenso,
                                       ayuno largo + deshidratación, etc.).
```

### 6.2 — Citas adicionales

Citas que deben agregarse al `IMR_BIBLIOGRAPHY.md` con esta SPEC:

- **Dansinger ML, Gleason JA, Griffith JL, Selker HP, Schaefer EJ.** "Comparison of the Atkins, Ornish, Weight Watchers, and Zone diets for weight loss and heart disease risk reduction: a randomized trial." *JAMA* 2005;293(1):43-53. *Justifica el peso del componente adherencia (§13.3): la adherencia sostenida supera la elección específica de dieta.*
- **Petersen MC, Shulman GI.** "Mechanisms of insulin action and insulin resistance." *Physiol Rev* 2018;98(4):2133-2223. *Justifica la ventana de 30 días: el turnover de marcadores metabólicos relevantes (HOMA-IR, triglicéridos, HbA1c parcial) se mueve en escala de 2-4 semanas.*

## 7. Modelo de datos persistente (v1.1)

**Dos lugares de persistencia** — uno para tendencia, otro como cache de lectura rápida.

### 7.1 — Cache de último snapshot (lectura rápida)

```
users/{uid}.imr.current  (subdoc del doc raíz, SPEC-82 existente)

  schemaVersion: 2                  // bump por SPEC-141
  weekISO: "2026-W23"               // 🆕 v1.1 — apunta al doc activo en imr_history
  totalScore: 0..100                // longitudinal del último snapshot
  legacyDailyScore: 0..100          // diario, ventana de transición 30d
  zone: "DETERIORADO" | ... | "OPTIMIZADO"
  description: String
  scoreVariant: "longitudinal"
  computedAt: Timestamp             // 🆕 v1.1 — usado por staleness check
  reason: String                    // 🆕 v1.1 — 'onboarding_baseline' |
                                     //          'biometric_checkin' |
                                     //          'healthkit_sync' |
                                     //          'fallback_stale'

  subscores:
    structure: 0..1
    behaviorTrend: 0..1
    adherence: 0..1
    coherence: 0..1

  // Campos derivados existentes (SPEC-82) — sin cambios
  imc, tmb, metabolicAge, ica, ffmi, whtr: number

  updatedAt: serverTimestamp
```

### 7.2 — 🆕 Historial semanal (tendencia)

```
users/{uid}/imr_history/{weekISO}  (subcollection, creada por SPEC-143)

  weekISO: "2026-W23"               // PK = doc id
  totalScore: 0..100
  computedAt: Timestamp
  reason: String

  subscores:
    structure: 0..1
    behaviorTrend: 0..1
    adherence: 0..1
    coherence: 0..1

  // Snapshot biométrico al momento del cómputo (para auditoría)
  biometricSnapshot:
    weight: number
    waistCircumference: number?
    neckCircumference: number?
    bodyFatPercentage: number?
    isMeasurementEstimated: bool
```

La subcollection `imr_history` es la creada por SPEC-143 (Persistencia histórica). SPEC-141 escribe en ella; SPEC-143 garantiza que existe, su shape, security rules y que también persiste el biometricSnapshot que la audita.

Granularidad: una entrada por semana ISO. El usuario que abre la app cada día NO genera 7 entradas — genera 1 por semana. Esto reduce el costo de storage y consultas históricas a O(n) por semana, no O(n) por día.

## 8. Criterios de aceptación

1. `calculateLongitudinalIMR(user, MetabolicState.empty(), [])` retorna `IMRv2Result` con `longitudinalScore == structureBlock × 100` (renormalización a Estructura única). El score es idéntico a `calculateBaseline(user).totalScore`.

2. `calculateLongitudinalIMR(user, state, history)` con `history.length == 30` y `dailyQualityScore = 1.0` en todas las entradas + `structureBlock = 0.6` + `coherence = 1.0` + currentStreak 30 + activeDays 90 produce `longitudinalScore = round(0.40×0.6 + 0.35×1.0 + 0.15×1.0 + 0.10×1.0) × 100 = round(0.84 × 100) = 84`.

3. `computeMonthlyQualityScore([])` retorna `0.0`.

4. `computeMonthlyQualityScore(history)` con 5 entradas de calidad 1.0 (sub-7-day ventana) retorna `1.0` (NO 5/30 = 0.17; el divisor es entradas, no 30).

5. `computeAdherenceTrend(history)` con `currentStreak == 30` y `activeDays90 == 90` retorna `1.0`.

6. `computeAdherenceTrend(history)` con `currentStreak == 0` y `activeDays90 == 0` retorna `0.0`.

7. La persistencia en `imr.current` incluye `schemaVersion: 2`, `legacyDailyScore` y los 4 subscores con sus valores correctos.

8. El badge de `profile_screen.dart` muestra `longitudinalScore`, no `score` (verificado por widget test).

9. La pantalla Análisis (`imr_ring_with_satellites.dart`) muestra el mismo número que mostraba antes de SPEC-141 (no regresión).

10. `calculateIMR(user, state)` retorna exactamente el mismo `IMRv2Result.totalScore` que antes de SPEC-141 (no regresión — esto se verifica con los tests existentes que NO deben necesitar cambios).

11. Un usuario que termina onboarding (sin historial) NO ve un score peor que antes de SPEC-141. Caso específico: usuario con `structureBlock = 0.40` antes obtenía `calculateBaseline.totalScore = 20`; después de SPEC-141 obtiene `calculateLongitudinalIMR(history=[]).totalScore = round(0.40 × 100) = 40` por renormalización. **Esto es MEJOR que antes** — el baseline duplica su techo, sin inflación porque la mejora viene de eliminar peso muerto, no de pesar más.

12. `flutter analyze` sin issues nuevos.

13. `flutter test` mantiene baseline + ≥ 12 tests nuevos (ver §9).

14. La pantalla Análisis muestra advisory tooltip cuando el usuario tap el "IMR HOY": *"El número grande de aquí refleja tu día de hoy. El IMR longitudinal que define tu zona metabólica vive en Perfil."* (Este copy puede refinarse — el principio es que NO escondemos la dualidad, la explicamos.)

15. **🆕 v1.1 — Cadencia semanal verificable.** Tras completar onboarding, el usuario tiene un snapshot en `imr_history/{weekISO}` con `reason: 'onboarding_baseline'`. Abrir la app 5 veces en el mismo día NO genera nuevos snapshots ni nuevas escrituras a `imr.current`. El número de Profile permanece estable hasta el próximo gatillo.

16. **🆕 v1.1 — Gatillo biométrico funcional.** Al guardar un check-in biométrico desde `biometric_checkin_sheet`, se dispara `recomputeOnBiometricCheckIn`. Antes de 5 segundos, `imr.current.weekISO` apunta a la semana actual y el badge de Profile refleja el nuevo número.

17. **🆕 v1.1 — Staleness funcional.** Manipulando `computedAt` para que sea > 7 días atrás, al abrir la app se dispara `recomputeIfStale` una sola vez (verificable por test de integración con mock del provider de bootstrap).

18. **🆕 v1.1 — Idempotencia por weekISO.** Dos gatillos en la misma semana ISO sobrescriben el mismo doc en `imr_history`, no crean duplicados. El `reason` del doc refleja el último gatillo.

## 9. Plan de pruebas

### 9.1 — Tests puros (engine)

`test/core/engine/score_engine_longitudinal_test.dart`:

- Renormalización con `history.length < 3` → solo Estructura cuenta.
- Renormalización con `history.length` entre 3 y 6 → Estructura + Adherence + Coherence.
- Renormalización con `history.length >= 7` → los 4 componentes (full).
- `behaviorTrend30 = 1.0`, todos los demás en 1.0 → score 100.
- `structure = 0.5`, todo lo demás en 0.0 → score = `round((0.40 × 0.5 / 1.00) × 100)` = 20 con renormalización completa (porque los demás son 0, no "no disponibles"). **Importante:** "no disponible" ≠ "valor 0". Test específico que diferencia los dos casos.

### 9.2 — Tests StreakEngine

`test/features/streak/domain/streak_engine_monthly_test.dart`:

- `computeMonthlyQualityScore` con historial vacío → 0.0.
- `computeMonthlyQualityScore` con 30 entradas de calidad 1.0 → 1.0.
- `computeMonthlyQualityScore` con 5 entradas dentro de ventana → promedio de las 5.
- Entradas fuera de ventana (>30 días) se excluyen.
- `computeAdherenceTrend` con streak 30 + active 90 → 1.0.
- `computeAdherenceTrend` con streak 15 + active 45 → 0.5 × 0.5 + 0.5 × 0.5 = 0.5.
- `computeAdherenceTrend` con streak 60 (cap) → cap a 30/30 = 1.0 en el primer término.

### 9.3 — Tests persistencia

`test/core/engine/imr_persistence_provider_test.dart` (extensión):

- Persistencia escribe `schemaVersion: 2`, `legacyDailyScore`, `subscores.*`.
- Debounce 15s respetado (sin regresión SPEC-82).
- Round-trip Firestore → modelo → Firestore preserva todos los campos.

### 9.4 — Tests widget

`test/features/auth/presentation/profile_identity_card_test.dart`:

- Profile badge consume `imr.current.totalScore` (snapshot), no live `calculateLongitudinalIMR`.
- Cuando `scoreVariant == 'daily'` (degradado defensivo), badge muestra ese valor.
- Tooltip largo-tap muestra el copy de §RF-141-11.
- 🆕 v1.1 — el tooltip incluye la fecha del último cómputo formateada como "hace X días".

### 9.5 — Test E2E de no regresión

`test/integration/imr_no_regression_test.dart`:

- Construir un escenario completo (user + state + history) y verificar que `calculateIMR` antes y después de SPEC-141 retorna idéntico `totalScore`. Garantiza que el método legacy no se vea afectado.

### 9.6 — 🆕 v1.1 — Tests de `WeeklyImrSnapshotService`

`test/core/engine/weekly_imr_snapshot_service_test.dart`:

- Gatillo A (biometric checkin) siempre dispara `_writeSnapshot` aunque sea la misma semana ISO.
- Gatillo B (healthkit sync) con `BiometricDelta < 1%` NO dispara recompute (filtro de ruido).
- Gatillo C (staleness): `computedAt` hace 6 días → no dispara. Hace 7+ días → dispara.
- Idempotencia: dos llamadas a `_writeSnapshot` en la misma weekISO sobrescriben el mismo doc.
- `reason` se persiste correctamente para cada gatillo.
- `weekISO` cumple formato ISO 8601 (`yyyy-Www`).
- Onboarding completion dispara con `reason: 'onboarding_baseline'`.

### 9.7 — 🆕 v1.1 — Tests de staleness check al bootstrap

`test/core/orchestrator/user_bootstrap_provider_test.dart`:

- Usuario con `imr.current.computedAt` hace 8 días → al login, `recomputeIfStale` se invoca una vez.
- Usuario sin `imr.current` (legacy o nuevo) → dispara con reason `'onboarding_baseline'` o `'fallback_stale'` (decidir cuál).
- Llamadas múltiples al provider en la misma sesión NO disparan recálculo repetido (memoización).

## 10. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Sitio web Metamorfosis Real renderiza el nuevo `totalScore` sin estar listo, confundiendo al usuario MR | Alta | Persistir `legacyDailyScore` durante 30 días post-deploy. Notificar al equipo del sitio antes del despliegue. SPEC-141.cleanup retira el campo legacy una vez confirmada la migración. |
| R-02 | Validación clínica externa rechaza el split 40/35/15/10 | Alta | El especialista de SPEC-70.5 debe firmar esta SPEC antes de deploy. Si rechaza, ajustar pesos antes de implementar — sin código aún escrito, el costo es bajo. |
| R-03 | Usuario con datos parciales (5 días) ve score "bajo" porque renormalización solo considera Estructura + Adherence | Media | Mostrar copy contextual en Profile cuando `history.length < 30`: *"Tu IMR se está calibrando. En 30 días reflejará tu adherencia real."* No bloqueante. |
| R-04 | Confusión entre Score del Día (SPEC-140) y IMR longitudinal (SPEC-141) en copy | Media | El glossario (`SPEC-133` Centro de Ayuda) debe distinguir explícitamente. Coordinar con SPEC-142 (UI) para que la separación visual sea inequívoca. |
| R-05 | `computeMonthlyQualityScore` con historial pre-SPEC-65 (sin magnitudes) retorna ruido | Baja | El fallback `pillarsCompleted/5` de `dailyQualityScore` es honesto. Usuarios pre-SPEC-65 son históricamente pocos; aceptable. |
| R-06 | Cambio de fuente del badge Profile mientras un usuario lo está mirando produce salto visual del número | Baja | El despliegue gradual via Remote Config + animación de transición suave en `_buildIdentityCard`. Considerar feature flag inicial `flag.useLongitudinalIMR`. |
| R-07 | Tests legacy que asumen `IMRv2Result.totalScore` viene de `calculateIMR` se rompen al cambiar Profile | Media | Los tests existentes NO se rompen — `calculateIMR` no cambia. Profile usa nuevo provider. Los tests de Profile deben actualizarse en este PR. |
| R-08 | El especialista pide que `coherence` pese más que 0.10 | Baja | El 0.10 es ENGINEERING JUDGMENT documentado. Ajustable en revisión sin afectar arquitectura. |
| R-09 | Carga adicional del cómputo: `calculateLongitudinalIMR` requiere `history` completo, que puede ser largo | Baja | `history` ya se carga para la pantalla Análisis (último 30-90 días). Reutilizar el provider existente. No agregar nuevo round-trip Firestore. |
| R-10 | 🆕 v1.1 — Usuario que no abre la app en 30+ días ve un IMR completamente desactualizado | Media | Aceptable. El gatillo C (staleness) recomputa al volver. El nuevo número refleja el estado actual real (history vacío en esa ventana → renormaliza a Estructura). Una SPEC futura puede agregar Cloud Function de recompute si telemetría revela cohorte significativa de usuarios "ghost". |
| R-11 | 🆕 v1.1 — HealthKit sync dispara recompute en loop si el delta filter es muy permisivo | Media | El filter de "delta < 1%" se aplica a cada métrica biométrica individualmente. Si peso cambió 0.5% pero cintura cambió 2%, dispara. Documentar el threshold en `score_engine.dart` con comentario `// SPEC-141.RF-141-12.B`. |
| R-12 | 🆕 v1.1 — Onboarding completion intenta `_writeSnapshot` antes de que el sink de SPEC-82 esté listo | Baja | El callback de `completeOnboarding` ya espera la persistencia del user profile. `_writeSnapshot` queda en cola del mismo flujo. Test E2E de onboarding cubre la secuencia. |
| R-13 | 🆕 v1.1 — Dependencia con SPEC-143: si SPEC-143 no entrega `imr_history` a tiempo, SPEC-141 no puede pasar a IN_PROGRESS | Alta | Mitigación organizacional: SPEC-143 entra al sprint inmediatamente anterior a SPEC-141. El alcance de SPEC-143 es chico (subcollection nueva + rule + versionado biométrico automático). 2-3 días estimados. |

## 11. Validación clínica externa

Esta SPEC requiere **revisión y firma del especialista que validó SPEC-70.5** antes de pasar a IN_PROGRESS. Concretamente:

1. Compartir este documento + `IMR_BIBLIOGRAPHY.md` actualizada en draft.
2. Pedir dictamen sobre:
   - ¿La separación IMR diario / IMR longitudinal es defendible clínicamente?
   - ¿El split 40/35/15/10 refleja la proporcionalidad de los outcomes?
   - ¿La ventana de 30 días para `behaviorTrend` es la correcta o debería ser distinta (14/60/90)?
   - ¿La cita de Dansinger 2005 JAMA justifica el componente `adherenceTrend` con peso 15%?
   - ¿Petersen-Shulman 2018 justifica la ventana de 30 días como escala metabólica relevante?
3. Documentar la firma en §1 de `IMR_BIBLIOGRAPHY.md` (nombre, especialidad, institución, fecha) — igual que se hizo en SPEC-70.5.

Si el especialista propone ajustes a los pesos, esos ajustes entran a la SPEC ANTES de aprobarla. La SPEC pasa de DRAFT a IN_PROGRESS solo cuando ambos firman: Carlos y el especialista.

## 12. Plan de rollout (v1.1)

**Pre-condición:** SPEC-143 (Persistencia histórica + versionado biométrico) cerrada e implementada. SPEC-141 NO empieza sin esto.

1. **Día 0 (post-aprobación):** crear branch `spec/141-imr-longitudinal` desde `mvp-core-clean`.
2. **Día 1:** dominio puro — `computeMonthlyQualityScore`, `computeAdherenceTrend`, `calculateLongitudinalIMR`, `_renormalize`. Tests puros.
3. **Día 2:** extender `IMRv2Result`. Tests de campos derivados.
4. **Día 3 — 🆕 v1.1:** crear `WeeklyImrSnapshotService` con los 3 gatillos. Tests del servicio (§9.6). Sin integraciones aún.
5. **Día 4 — 🆕 v1.1:** crear `weeklyImrSnapshotProvider`. Conectar gatillo A (BiometricCheckinNotifier). Conectar gatillo C (bootstrap). Tests de integración (§9.7).
6. **Día 5:** migrar badge Profile al provider del snapshot. Tests de widget. Tooltip §RF-141-11.
7. **Día 6:** actualizar `IMR_BIBLIOGRAPHY.md` con §13 + cadencia semanal. Comentarios `// SPEC-141: ref §X.Y`. Coordinación con sitio web sobre `schemaVersion: 2`.
8. **Deploy:** detrás de feature flag `useLongitudinalIMR` por una semana. Si Remote Config no está disponible, deploy directo con plan de hotfix listo.
9. **+30 días post-deploy:** abrir `SPEC-141.cleanup` para retirar `legacyDailyScore`. Abrir `SPEC-141.2` para conectar Gatillo B (HealthKit sync) si SPEC-132 cerró.

## 13. Out of scope (explícito)

- UI del Dashboard y de la pantalla Análisis — SPEC-142.
- Refactor del Score del Día con pesos 25/22/20/18/15 — SPEC-140.
- Retiro del método `calculateIMR` legacy — SPEC futura (post-SPEC-142).
- Integración con HealthKit/Health Connect que pueda inyectar `dailyScore` desde wearables — SPEC-132.
- Cambio del peso de la coherencia (`CoherenceEngine`) — SPEC-71 sigue siendo dueña de ese motor.
- Cambio de los pesos internos a cualquier bloque (Estructura WHtR/FFMI, Metabolismo, Conducta) — SPEC-70.5 sigue firmando esos.
- Refactor del `score_engine.dart` para extraer un `IMRRules` puro (deuda técnica existente) — SPEC separada.
- Detección automática de "usuario está plateau" y sugerencias correctivas basadas en `behaviorTrend30` — telemetría post-MVP.
- **🆕 v1.1 — Persistencia histórica del IMR (`imr_history` subcollection)** y **versionado automático biométrico** — SPEC-143. SPEC-141 *consume* el shape que SPEC-143 garantiza; *no lo crea*.
- **🆕 v1.1 — Conexión del Gatillo B (HealthKit/Health Connect sync)** — SPEC-141.2 cuando SPEC-132 cierre. Mientras tanto, el método `recomputeOnHealthKitSync` existe pero no se invoca desde ningún listener.
- **🆕 v1.1 — Cloud Function de recompute para usuarios "ghost"** que no abren la app en 30+ días — SPEC futura, post-telemetría.
- **🆕 v1.1 — UI explícita de "última actualización del IMR"** beyond del tooltip — vive en SPEC-142.

## 14. Aprobación

Esta SPEC requiere:

1. **Visto bueno de Carlos** sobre el diseño general, los pesos 40/35/15/10 y el alcance.
2. **Firma del especialista clínico** que validó SPEC-70.5 sobre los puntos de §11.
3. **Coordinación documentada** con el equipo del sitio web Metamorfosis Real sobre el bump de schema y la ventana de transición de 30 días.

Hasta los tres confirmados, la SPEC permanece en estado DRAFT.

---

## 15. Changelog

### Aprobación de diseño v1.1 — 2026-06-01

Carlos aprobó el diseño de SPEC-141 v1.1 incluyendo:
- Fórmula longitudinal 40/35/15/10 (estructura/behaviorTrend30/adherence/coherence).
- Cadencia semanal con 3 gatillos (check-in biométrico, HealthKit sync futuro, fallback staleness).
- Dependencia dura con SPEC-143 (ya aprobada IN_PROGRESS).
- Profile lee cache `imr.current`, Análisis sin cambios.
- Persistencia dual: `imr.current` (cache) + `imr_history/{weekISO}` (tendencia, creada por SPEC-143).

**Próximo gate:** validación clínica externa por el especialista de SPEC-70.5 sobre los puntos de §11. Mientras no se confirme, SPEC permanece en APPROVED-DESIGN, no IN_PROGRESS. Coordinación de la revisión clínica queda como tarea operacional separada (no bloquea el resto del trabajo del equipo).

### v1.1 — 2026-06-01 (mismo día, post-feedback Carlos)

Refinamiento estructural tras feedback explícito: *"el IMR General debe calcularse cada semana cuando el Usuario ingrese sus medidas o en su defecto lo que importe de integración que hicimos, no a diario, debe tener una periodicidad de 7 días"*.

Cambios principales:

- **§2 punto 8 y 9 (nuevos):** introduce la cadencia semanal explícita. El IMR longitudinal no se recalcula en tiempo real ni con cada cambio de pilar. Tres gatillos: check-in biométrico, HealthKit/HC sync, fallback al abrir la app tras > 7 días.
- **§3 (extendido):** dos límites nuevos — no se recalcula en tiempo real, no se crea infraestructura de Cloud Functions en esta SPEC.
- **§RF-141-09 (reescrito):** Profile lee `imr.current` como cache, no invoca `ScoreEngine` en runtime.
- **§RF-141-12 (nuevo):** servicio `WeeklyImrSnapshotService` con los 3 gatillos.
- **§RF-141-13 (nuevo):** detección de staleness al bootstrap de la app.
- **§5 (extendido):** tabla de cambios de código sube de 8 a 11 entradas. Nuevos archivos: `weekly_imr_snapshot_service.dart`, `weekly_imr_snapshot_provider.dart`. Modificaciones a `biometric_checkin_notifier.dart` y `user_bootstrap_provider.dart`.
- **§7 (reescrito):** modelo de datos pasa de 1 lugar (`imr.current`) a 2 lugares (`imr.current` como cache + `imr_history/{weekISO}` como tendencia). Esta subcollection la crea SPEC-143, no SPEC-141.
- **§8 criterios 15-18 (nuevos):** cadencia verificable, gatillo biométrico, staleness, idempotencia por weekISO.
- **§9.6 y §9.7 (nuevos):** tests del servicio y del bootstrap.
- **§10 riesgos R-10 a R-13 (nuevos):** ghost users, delta filter HealthKit, race condition onboarding, dependencia dura SPEC-143.
- **§12 (reescrito):** plan de rollout con pre-condición SPEC-143 cerrada. Estimación sube de 6 a ~7 días.
- **§13 (extendido):** 4 nuevos puntos fuera de scope (persistencia histórica → SPEC-143, gatillo HealthKit → SPEC-141.2, Cloud Function ghost users, UI de timestamp → SPEC-142).
- **Header:** versión 1.0 → 1.1. Nueva dependencia dura SPEC-143.

Sin cambios a la fórmula 40/35/15/10, los componentes del cálculo, ni la renormalización para usuarios sin historial. La aritmética verificada en v1.0 se preserva idéntica.

### v1.0 — 2026-06-01

Documento inicial. Propuesta de refactor del IMR a métrica longitudinal compuesta. Pendiente aprobación Carlos + validación clínica externa.
