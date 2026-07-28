// SPEC-194: recomendación candidata emitida por un generador y puntuada
// por el CoachingScorer. Value object inmutable, Dart puro.
//
// Reusa `Pillar` de biological_phases (SOURCE OF TRUTH de los 5 pilares).

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';

/// Naturaleza de la urgencia intrínseca de la acción (SPEC-194 Anexo §2.1).
enum ActionUrgencyKind {
  /// Deadline duro (ventana cerrando, eTRF cutoff, bloqueo intestinal).
  deadlineHard,

  /// Oportunidad de fase biológica (autofagia cerca, pico de fuerza).
  phaseOpportunity,

  /// Hábito / longitudinal (pilar débil).
  habit,

  /// Ajuste de protocolo (AdaptiveEngine).
  protocol,
}

class CoachingAction {
  const CoachingAction({
    required this.id,
    required this.title,
    required this.actionText,
    required this.reason,
    required this.pillar,
    required this.confidence,
    required this.citation,
    required this.source,
    required this.urgencyKind,
    required this.circadianImpact,
    this.minutesToDeadline,
    this.actionableNow = true,
  }) : assert(circadianImpact >= 0.0 && circadianImpact <= 1.0,
            'circadianImpact debe estar en [0,1]');

  /// Identificador semántico estable (para telemetría y anti-fatiga).
  final String id;

  /// Texto corto de cabecera (lockscreen / card).
  final String title;

  /// Acción concreta sugerida.
  final String actionText;

  /// Por qué — lenguaje humano, visible en "saber más".
  final String reason;

  /// Pilar que ataca la acción.
  final Pillar pillar;

  /// Nivel de evidencia que respalda la recomendación.
  final ConfidenceLevel confidence;

  /// Cita bibliográfica corta (patrón SPEC-169: "· Autor Año").
  final String citation;

  /// Fuente generadora.
  final ActionSource source;

  /// Naturaleza de la urgencia.
  final ActionUrgencyKind urgencyKind;

  /// Impacto circadiano 0..1 (SPEC-194 Adenda §3): cuánto protege/mejora
  /// el factor circadiano del usuario (el mismo que entra al IMR).
  final double circadianImpact;

  /// Minutos al deadline si [urgencyKind] == deadlineHard; null si no aplica.
  final int? minutesToDeadline;

  /// True si la acción es ejecutable en el momento actual (actionability).
  final bool actionableNow;
}
