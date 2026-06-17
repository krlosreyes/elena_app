# SPEC-221 — Unificar escalas de fases de ayuno

**Estado:** IMPLEMENTED (2026-06-17) — displayName/description/orchestratorBand en fasting_status.dart. Rename biological_phases.FastingPhase → OrchestratorFastingBand completado en todos los archivos (engine, state, freezed, validators, tests). Typedef deprecado eliminado.
**Versión:** 0.1
**Líder:** Carlos · **Implementación:** Claude
**Depende de:** SPEC-149 (día metabólico), OrchestratorEngine.
**Prioridad:** Media — sprint siguiente.
**Estimación:** 5 SP

---

## 1. Problema

Existen dos `FastingPhase` incompatibles en el codebase:

### A. `biological_phases.dart` (OrchestratorEngine)
```dart
enum FastingPhase { alerta, gluconeogenesis, cetosis, autofagia }
// Umbrales: <4h, 4-8h, 8-12h, ≥12h
```

### B. `fasting_status.dart` (Dashboard UI)
```dart
enum FastingPhase { none, postAbsorption, transition, fatBurning, autophagy, survival }
// Umbrales: 0, <12h, 12-18h, 18-24h, 24-48h, 48h+
```

**Conflicto concreto:** Un ayuno de 10 horas es "cetosis" para el orchestrator pero "postAbsorption" para el UI. Un ayuno de 14 horas es "autofagia" para el orchestrator pero apenas "transition" para el UI. El coaching puede decir una cosa y el dashboard mostrar otra.

## 2. Diagnóstico

La escala B (`fasting_status.dart`) es más granular y científicamente precisa:
- `postAbsorption` (0-12h): fase real de absorción/post-absorción donde baja la insulina.
- `transition` (12-18h): gluconeogénesis + inicio de oxidación de ácidos grasos.
- `fatBurning` (18-24h): cetosis nutricional establecida.
- `autophagy` (24-48h): autofagia significativa (Alirezaei 2010, Yoshinori Ohsumi).
- `survival` (48h+): conservación profunda, no recomendada sin supervisión.

La escala A (`biological_phases.dart`) tiene umbrales incorrectos: "cetosis" a las 8h es prematuro (la cetosis nutricional significativa empieza ~16-18h según Cahill & Owen), y "autofagia" a las 12h es engañoso (los estudios en humanos muestran autofagia significativa a partir de 24-36h).

## 3. Solución

### 3.1 Enum canónico único

Mantener el enum de `fasting_status.dart` como fuente de verdad. Agregar metadata para UI y para lógica interna del orchestrator:

```dart
enum FastingPhase {
  none,           // No ayunando / alimentación
  postAbsorption, // 0-12h: bajando insulina, usando glucógeno
  transition,     // 12-18h: gluconeogénesis, inicio oxidación grasa
  fatBurning,     // 18-24h: cetosis nutricional establecida
  autophagy,      // 24-48h: reciclaje celular profundo
  survival;       // 48h+: conservación (supervisión médica)

  /// Nombre para UI del dashboard.
  String get displayName => switch (this) {
    none => 'Alimentación',
    postAbsorption => 'Post-absorción',
    transition => 'Transición',
    fatBurning => 'Quema de grasa',
    autophagy => 'Autofagia',
    survival => 'Conservación',
  };

  /// Banda simplificada para el OrchestratorEngine (4 estados).
  /// Permite que la lógica de decisión del orchestrator siga
  /// operando con su granularidad original.
  OrchestratorFastingBand get orchestratorBand => switch (this) {
    none || postAbsorption => OrchestratorFastingBand.early,
    transition => OrchestratorFastingBand.gluconeogenesis,
    fatBurning => OrchestratorFastingBand.ketosis,
    autophagy || survival => OrchestratorFastingBand.deepFasting,
  };
}

/// Bandas internas del OrchestratorEngine — NO expuestas al usuario.
enum OrchestratorFastingBand { early, gluconeogenesis, ketosis, deepFasting }
```

### 3.2 Eliminar `biological_phases.dart:FastingPhase`

El OrchestratorEngine importará `FastingPhase` de `fasting_status.dart` y usará `.orchestratorBand` para su lógica interna. El enum duplicado de `biological_phases.dart` se elimina.

**Nota:** `biological_phases.dart` también contiene `CircadianPhase` — ese enum no tiene duplicado y se mantiene intacto. Solo el `FastingPhase` se mueve.

### 3.3 Archivos a tocar

| Archivo | Cambio |
|---------|--------|
| `features/dashboard/domain/fasting_status.dart` | Agregar `displayName`, `orchestratorBand` |
| `core/orchestrator/biological_phases.dart` | Eliminar `FastingPhase` enum. Mantener `CircadianPhase`. |
| `core/orchestrator/orchestrator_engine.dart` | Importar `FastingPhase` de fasting_status, usar `.orchestratorBand` |
| Cualquier import de `biological_phases.dart` que use `FastingPhase` | Redirigir import |

### 3.4 Mapping de umbrales del orchestrator

El OrchestratorEngine actualmente usa `_fastingPhaseForHours(double h)` con umbrales de 4/8/12h. Estos se eliminan — la fase viene directamente del `FastingState.phase` (ya calculada por `FastingStatus.currentPhase` con los umbrales correctos).

## 4. Tests

- Unit: `FastingPhase.orchestratorBand` — cada fase mapea a la banda correcta.
- Unit: `OrchestratorEngine.calculate()` — resultado idéntico al pasar bandas equivalentes.
- Grep: cero imports de `biological_phases.FastingPhase` residuales.

## 5. Riesgos

- El OrchestratorEngine perderá la granularidad "alerta" (<4h). Ahora esa banda se unifica con `postAbsorption` bajo `OrchestratorFastingBand.early`. Si el orchestrator tenía lógica específica para <4h, hay que verificar que no se pierda comportamiento. Actual: solo hay un bloque genérico para "alerta" que dice "post-ingesta" — compatible con `early`.

## 6. Notas

- La escala B ya está en producción visible al usuario en el dashboard. No hay migración de datos.
- `survival` (48h+) no se promueve en la app — Elena App es para ayuno intermitente, no extendido. El coaching debería disuadir ayunos >48h sin supervisión.
