# SPEC-156 — CyclesHistoryCard: histórico de ciclos cerrados en Análisis

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Cuarta pieza de Ola 2 — cierra la narrativa del Día Metabólico
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 1-2 horas
**Marco normativo:** `CONSTITUTION.md`. Consume `metabolicCyclesHistoryProvider` (SPEC-149).

---

## 1. Contexto

Auditoría 2026-06-02: la pantalla Análisis no expone los **ciclos metabólicos cerrados** (`metabolic_cycles` subcolección). SPEC-149 persiste cada ciclo con score, magnitudes, feedback (achievements + gaps + insight + cita) y razón de cierre, pero solo se ve la card del último cierre en el Dashboard.

**Gap crítico:** sin histórico, el coaching pierde acumulación narrativa. El usuario no puede ver su **progreso ciclo a ciclo**, que es la unidad fundamental del producto post-pivot del 2026-06-01.

Esta SPEC añade `CyclesHistoryCard` debajo del `GoalsProgressDashboard`.

## 2. Decisión de diseño

### 2.1 — Layout compacto, una fila por ciclo

```
┌──────────────────────────────────────────┐
│ TUS CICLOS RECIENTES         últimos 7   │
│                                            │
│  ▓▓▓▓▓▓▓▓░░  85    2 jun   24h          ▸│
│  ▓▓▓▓▓▓▓░░░  72    1 jun   26h          ▸│
│  ▓▓▓▓▓▓▓▓▓░  88   31 may   23h ✨       ▸│
│  ▓▓▓▓░░░░░░  45   30 may   18h ⚠        ▸│
│  ▓▓▓▓▓▓▓▓▓░  90   29 may   24h          ▸│
│                                            │
│  💡 Tu mejor ciclo: 29 may (90).         │
│  "Autofagia + sueño en sync."             │
│   — Mattson 2017 + Walker 2017            │
└──────────────────────────────────────────┘
```

Cada fila:
- Barra de score discreta (10 niveles)
- Score numérico
- Fecha del cierre (corta)
- Duración total del ciclo en horas
- Flags opcionales: ✨ mejor de la semana, ⚠ peor de la semana
- Chevron derecho → tap abre `CycleDetailSheet`

### 2.2 — Bloque "Tu mejor ciclo"

Al pie de la tarjeta, identifica el ciclo de mayor score de los visibles y muestra:
- Fecha + score
- Insight del feedback (`feedback.insight`)
- Cita (`feedback.citation`)

Refuerza el coaching positivo y recupera la línea científica que se mostraba al momento del cierre.

### 2.3 — `CycleDetailSheet` (al tap en fila)

`DraggableScrollableSheet` que muestra el feedback completo del ciclo:
- Header con fecha + score
- Achievements (verdes con check)
- Gaps (ámbar con triángulo)
- Insight + cita en bloque destacado
- Razón de cierre (al pie, info)

Mismo patrón visual del `CycleClosureCardView` (SPEC-149) — reutilizamos el lenguaje visual del producto.

### 2.4 — Cantidad de ciclos mostrados

- Default: **7** últimos (1 semana metabólica típica).
- Si hay menos de 7, mostramos los que haya.
- Si hay 0 → empty state simple.

7 es razonable para una vista resumen. Si emerge demanda de ver más, futura SPEC-156.1 agrega "ver todos" → pantalla dedicada.

### 2.5 — Empty state

```
┌──────────────────────────────────────────┐
│ TUS CICLOS RECIENTES                      │
│                                            │
│  ⏳ Tu historia metabólica arranca acá.  │
│                                            │
│  Cerrá tu primer Día Metabólico iniciando│
│  tu siguiente ayuno. Ahí vas a ver los   │
│  scores, logros y enseñanzas del ciclo.  │
└──────────────────────────────────────────┘
```

Sin CTA — no podemos forzar el cierre, solo educar.

## 3. Cambios técnicos

### 3.1 — Nuevo dominio: `CyclesHistorySummary`

`lib/src/features/metabolic_cycle/domain/cycles_history_summary.dart`:

Pure Dart. Computa:
- Lista de los últimos N ciclos visibles (ya viene ordenada del provider).
- Mejor ciclo (mayor `dailyScore`) → usado para el bloque "Tu mejor ciclo".
- Peor ciclo → para flag visual ⚠ en la fila.

### 3.2 — `CyclesHistoryComputer`

`lib/src/features/metabolic_cycle/application/cycles_history_computer.dart`:

```dart
static CyclesHistorySummary compute({
  required List<MetabolicCycle> closedCycles,
  int maxToShow = 7,
});
```

### 3.3 — Widget `CyclesHistoryCard`

`lib/src/features/metabolic_cycle/presentation/widgets/cycles_history_card.dart`:
- `ConsumerWidget` que watchea `metabolicCyclesHistoryProvider`.
- Loading / error / data states.
- Empty state según §2.5.
- Filas con barra discreta de 10 niveles + score + fecha + duración + flags.
- Bloque "Tu mejor ciclo" al pie.
- Tap en fila abre `CycleDetailSheet`.

### 3.4 — Widget `CycleDetailSheet`

`lib/src/features/metabolic_cycle/presentation/widgets/cycle_detail_sheet.dart`:
- Stateless. Recibe `MetabolicCycle` por constructor.
- DraggableScrollableSheet con `initialChildSize: 0.7`.
- Patrón visual idéntico al `CycleClosureCardView`.

### 3.5 — Integración en `analysis_screen.dart`

Debajo del `GoalsProgressDashboard`, antes del `BodyCompositionTrendChart`:

```dart
const GoalsProgressDashboard(),
const SizedBox(height: 14),
const CyclesHistoryCard(), // SPEC-156
const SizedBox(height: 14),
const BodyCompositionTrendChart(),
```

## 4. Criterios de aceptación

1. Análisis muestra `CyclesHistoryCard` debajo de `GoalsProgressDashboard`.
2. Cada fila refleja un ciclo cerrado con: barra de score, número, fecha corta, duración en horas, chevron.
3. El ciclo de mayor score lleva flag ✨; el de menor score lleva ⚠ (solo si hay ≥3 ciclos visibles).
4. Bloque "Tu mejor ciclo" muestra insight + cita del ciclo de mayor score.
5. Tap en una fila abre `CycleDetailSheet` con feedback completo.
6. Empty state si no hay ciclos cerrados — texto educativo, sin CTA.
7. Tests cubren: `pickBestCycle`, `pickWorstCycle`, summary cuando hay 0/1/3+ ciclos.

### 4.1 — Sobre tests

`CyclesHistoryComputer` es pure Dart → unit tests directos. `CycleDetailSheet` y `CyclesHistoryCard` requieren mocks de Riverpod — validación visual.

## 5. Out of scope (explícito)

- **Pantalla dedicada "Todos mis ciclos":** futura SPEC-156.1 si emerge demanda.
- **Comparativa entre ciclos** (delta entre 2 fechas seleccionadas): SPEC futura.
- **Edición de ciclos cerrados:** out of scope total — los ciclos cerrados son inmutables (SPEC-149).
- **Filtros por razón de cierre** (manualNextFasting vs fallback): nice-to-have, no MVP.

## 6. Rollout

Sin breaking changes. Sin migración. Push directo a `mvp-core-clean` + validación visual cuando Carlos tenga iPhone.

## 7. Changelog

### v1.0 — 2026-06-02

Cierra el gap crítico identificado en la auditoría: sin histórico de ciclos, el coaching no acumula narrativa. Aprovecha 100% datos ya persistidos por SPEC-149.
