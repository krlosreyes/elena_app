// ─────────────────────────────────────────────────────────────────────────────
// SPEC-01: Recommendation tipada (capa de dominio)
// ─────────────────────────────────────────────────────────────────────────────
//
// Modelo puro de datos para recomendaciones del Orchestrator.
// Solo contiene identificadores semánticos (id, priority, pillar).
// NO contiene textos de UI (title, description) — eso pertenece a la capa
// de presentación y se resuelve via mapeo id → string localizable.
//
// SPEC-00: Dart puro — sin imports de providers, notifiers o repositorios.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';

/// Recomendación emitida por el OrchestratorEngine.
///
/// [id] es un identificador semántico estable (e.g., 'hydrate_during_autophagy')
/// que la capa de presentación mapea a textos localizados.
class Recommendation {
  /// Identificador semántico estable para mapeo de UI.
  final String id;

  /// Prioridad de la recomendación.
  final RecommendationPriority priority;

  /// Pilar metabólico asociado a la recomendación.
  final Pillar pillar;

  const Recommendation({
    required this.id,
    required this.priority,
    required this.pillar,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recommendation &&
          id == other.id &&
          priority == other.priority &&
          pillar == other.pillar;

  @override
  int get hashCode => Object.hash(id, priority, pillar);

  @override
  String toString() => 'Recommendation($id, $priority, $pillar)';
}
