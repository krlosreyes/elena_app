# Orchestrator — Notas de Implementación

## Estado actual: post-SPEC-46 (6-may-2026)

El paquete `core/orchestrator/` contiene la implementación única del Orquestador Central. Hasta SPEC-46 coexistían dos versiones (la v1 con strings y la v2 con enums tipados). SPEC-46 unificó todo en una sola.

### Archivos vigentes

| Archivo | Rol |
|---|---|
| `orchestrator_engine.dart` | Función pura `(MetabolicState, UserModel, StreakState) → OrchestratorState`. Sin efectos secundarios, sin Riverpod, sin Firestore. |
| `orchestrator_state.dart` | Modelo Freezed inmutable del estado del orquestador. Usa enums tipados (`FastingPhase`, `CircadianPhase`). |
| `orchestrator_state.freezed.dart` | Código generado por Freezed. **NO editar manualmente.** |
| `orchestrator_provider.dart` | `orchestratorProvider` y selectores derivados. Es la API pública del paquete. |
| `biological_phases.dart` | Enums `FastingPhase`, `CircadianPhase`, `Pillar`, `RecommendationPriority`. |
| `recommendation.dart` | Tipo `Recommendation` que produce el engine. |
| `phase_info_mapper.dart` | Mapeo de enums a metadatos UI (íconos, colores, etiquetas). |

### Archivos eliminados en SPEC-46

| Archivo | Motivo |
|---|---|
| `orchestrator_service.dart` | v1 con strings y multiplicadores hardcoded (`sleepRecoveryScore: 0.5`, `hydrationMlToday: 2000`). Sin consumidores externos. |
| `orchestrator_notifier.dart` | v1 — único consumidor del service v1. Sin consumidores externos. |
| `models/orchestrator_state.dart` | v1 con strings para fases. |
| `models/orchestrator_state.freezed.dart` | Generado de v1. |
| `models/orchestrator_state.g.dart` | Generado de v1. |
| `models/` (carpeta vacía) | Sin contenido tras los borrados. |

### Renombrados en SPEC-46

| Antes | Después |
|---|---|
| `orchestrator_state_v2.dart` | `orchestrator_state.dart` |
| `orchestrator_state_v2.freezed.dart` | `orchestrator_state.freezed.dart` |
| `class OrchestratorStateV2` | `class OrchestratorState` |

### Invariantes vigentes (CONSTITUTION.md §7)

- El paquete representa el sistema metabólico orquestado.
- No puede modificarse sin SPEC.
- Toda lógica debe ser explícita y determinista.
- `OrchestratorEngine.calculate` es función pura. Cualquier ramificación con `DateTime.now()`, `Random()` o efectos secundarios es violación de SPEC-00.

### Próximos cambios planificados

- **SPEC-51:** unificar la tabla circadiana de `_determineCircadianPhase` con `CircadianRules` en un único `CircadianEngine`.
- **SPEC-71:** mover el cálculo de coherencia a un `CoherenceEngine` dedicado para evitar la doble penalización con `MetabolicStateBuilder`.
- **SPEC-68:** sustituir el `String?` de `exerciseRecommendedType` por un enum tipado.
- **SPEC-70:** documentar la base bibliográfica de los multiplicadores y umbrales.

### Cómo extender

Cualquier modificación debe cumplir el ciclo SDD:

1. Spec firmada en `elena_app/specs/`.
2. Tests unitarios sobre `OrchestratorEngine` (SPEC-66 los habilita).
3. PR cita el ID de la SPEC en commit y descripción.
