# SPEC-159 — SleepQualityCard: calidad subjetiva semanal en Análisis

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Pieza de Ola 2 — expone dimensiones SPEC-69 ya persistidas
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 45 min
**Marco normativo:** `CONSTITUTION.md`. Consume `SleepLog` (SPEC-69), extiende `SleepRepository` (SPEC-50).

---

## 1. Contexto

Auditoría 2026-06-02 identificó que SPEC-69 persiste tres dimensiones del sueño que no se visualizan:

- `subjectiveQuality` (1-5)
- `sleepLatencyMinutes` (minutos hasta dormirse)
- `nightAwakenings` (despertares conscientes)

El `WeeklyCoachingCard` (SPEC-153) tiene una fila de sueño pero solo refleja el progreso 0..1 derivado de duración 0..8h y calidad agregada. Las dimensiones cualitativas se pierden.

Esta SPEC añade `SleepQualityCard` debajo del `MealsRatioCard` en Análisis. Por la naturaleza nocturna del sueño (1 log por noche), trabajamos con las **últimas 7 noches** del historial.

## 2. Decisión de diseño

### 2.1 — Layout

```
┌─────────────────────────────────────────────┐
│ TU SUEÑO                       7 NOCHES     │
│                                              │
│         7.2h                                 │
│       promedio · ★ 3.4                       │
│                                              │
│  dom  ████████░░  6.8h  ★★★☆☆  ⏱32 ↺2     │
│  sáb  ██████████  7.9h  ★★★★☆  ⏱18         │
│  vie  ████████░░  6.5h  ★★★☆☆  ⏱45 ↺1     │
│  jue  ██████████  8.2h  ★★★★★              │
│  mié  ████░░░░░░  4.5h  ★★☆☆☆  ⏱60 ↺3     │
│  mar  ████████░░  7.1h  ★★★★☆              │
│  lun  ██████████  7.8h  ★★★★☆  ⏱20         │
│                                              │
│  💡 Tu calidad subjetiva (3.4) está bajo    │
│     el target. Latencia >30min en 3 noches  │
│     sugiere cortisol elevado al acostarte.  │
│     → Cerrá pantallas 1h antes de dormir.   │
│     — Walker 2017 + AASM                    │
└─────────────────────────────────────────────┘
```

### 2.2 — Métricas en el header

- **Duración promedio** en horas decimales (1 decimal).
- **Calidad subjetiva promedio** sobre las noches que la registraron (★ X.X / 5).

### 2.3 — Cada fila representa una noche

- **Día de la semana** corto (dom, lun, ...).
- **Barra discreta** 10 niveles de duración (target 8h = 10).
- **Horas decimales** de duración.
- **Estrellas** ★ de la calidad subjetiva (1-5, vacías ☆ si no registrada).
- **⏱X** si `sleepLatencyMinutes` presente.
- **↺X** si `nightAwakenings ≥ 1`.

### 2.4 — Algoritmo del insight

5 ramas en orden de prioridad:

1. **Privación crónica** — `durationAvg < 6h` → Headline: "Tu duración promedio compromete reparación metabólica." Acción: "Apuntá a 7+ horas como mínimo no negociable." Cita: Walker 2017 + AASM.
2. **Latencia elevada** — `latencyAvg > 30min` en ≥3 noches con latencia registrada → "Tu latencia >30min sugiere cortisol elevado al acostarte." → "Cerrá pantallas 1h antes." → Walker 2017.
3. **Fragmentación** — `nightAwakenings ≥ 3` en ≥2 noches → "Fragmentación nocturna recurrente." → "Reducí líquidos y luz 2h antes." → AASM.
4. **Calidad baja** — `qualityAvg < 3` con ≥3 ratings → "Tu calidad subjetiva está bajo el target." → "Probá temperatura ≤19°C y oscuridad total." → Walker 2017.
5. **Sostenido** — `durationAvg ≥ 7h && qualityAvg ≥ 4` → "Tu sueño está sólido esta semana." → "Mantené ritmo y horarios consistentes." → AASM.
6. **Neutral default** — caso intermedio → "Estás en rango pero hay margen." → "Probá una rutina pre-sueño de 30 min." → Walker 2017.

### 2.5 — Período: últimas 7 noches con datos

A diferencia de comidas/ciclos que cubren "últimos 7 días calendáricos", para sueño preferimos **últimas 7 noches con log**. Razón: si el usuario tuvo gap (no registró el lunes y miércoles), las otras 5 noches igualmente nos dan una semana representativa. Coherente con `watchLatest` que ya existía — extensión natural.

### 2.6 — Empty state

Si no hay logs de sueño:

```
┌─────────────────────────────────────────────┐
│ TU SUEÑO                                     │
│                                              │
│  🌙 Tu reparación arranca acá.              │
│                                              │
│  Registrá tu próximo despertar para empezar │
│  a ver tu patrón de sueño y calidad.        │
└─────────────────────────────────────────────┘
```

## 3. Cambios técnicos

### 3.1 — Extender capa de datos

**`sleep_data_source.dart`** — agregar:
```dart
Stream<List<Map<String, dynamic>>> streamRecent({
  required String userId,
  required int limit,
});
```

**`firestore_sleep_v1_source.dart`** — implementar con `.orderBy('wokeUp', desc).limit(limit).snapshots()`. Single-field index automático (no requiere declarar en `firestore.indexes.json`).

**`sleep_repository.dart`** — agregar:
```dart
Stream<List<SleepLog>> watchRecent(String userId, {int limit = 7});
```

**`sleep_repository_impl.dart`** — delegar al source, mapear cada doc con el mapper, descartar los que fallen.

### 3.2 — Actualizar fakes legacy

`_FakeSleepRepository` (en `health_import_service_test.dart`) — agregar override de `watchRecent` retornando `Stream.empty()`. Patrón documentado en `feedback_interface_extension`.

### 3.3 — Nuevo dominio

`lib/src/features/dashboard/domain/sleep_weekly_insight.dart`:
- `SleepInsightTier` enum (empty, deprivation, latencyHigh, fragmented, lowQuality, sustained, neutral).
- `SleepWeeklyInsight` value object con duración promedio, calidad promedio, latencia promedio (nullable), noches con awakenings, tier.
- `SleepCoachingMessage` value object con headline + action + citation.

### 3.4 — Computer

`lib/src/features/dashboard/application/sleep_weekly_computer.dart`:
- `compute(logs) → SleepWeeklyInsight`.
- `pickTier(insight)` con prioridad §2.4.
- `messageForTier(tier) → SleepCoachingMessage`.

### 3.5 — Provider

`lib/src/features/dashboard/application/last_week_sleep_logs_provider.dart`:
- `StreamProvider.autoDispose<SleepWeeklyInsight>`.
- Consume `watchRecent(uid, limit: 7)`.

### 3.6 — Widget

`lib/src/features/dashboard/presentation/widgets/sleep_quality_card.dart`:
- ConsumerWidget con header + headline + 7 filas + insight block + empty state.

### 3.7 — Integración

En `analysis_screen.dart`, debajo de `MealsRatioCard`:

```dart
const MealsRatioCard(),
const SizedBox(height: 14),
const SleepQualityCard(),
const SizedBox(height: 14),
const BodyCompositionTrendChart(),
```

## 4. Criterios de aceptación

1. Análisis muestra `SleepQualityCard` debajo de `MealsRatioCard`.
2. Header muestra duración promedio + calidad promedio (★ X.X) correctos.
3. Cada fila: día abreviado + barra discreta + duración + estrellas (5 con ★/☆) + ⏱latencia opcional + ↺despertares opcional.
4. Insight cambia según tier (§2.4) con cita consistente.
5. Empty state si no hay logs.
6. Tests cubren: `compute` con casos representativos + `pickTier` (las 5 ramas + neutral default + empty).
7. `_FakeSleepRepository` legacy compila con el método nuevo.

### 4.1 — Sobre tests

Pure Dart. Sin widget test.

## 5. Out of scope

- **Trend chart de duración semanal** (curva) — el grid de 7 noches ya comunica.
- **Histograma de hora de dormirse / despertarse** — futura SPEC si emerge.
- **Compatibilidad con HealthKit sleep stages** (DEEP/REM/LIGHT) — depende de SPEC-132.next.

## 6. Rollout

Sin breaking changes. Sin migración. Push directo + validación visual.

## 7. Changelog

### v1.0 — 2026-06-02

Octava entrega de Ola 2. Conecta las dimensiones de calidad SPEC-69 con la UI por primera vez.
