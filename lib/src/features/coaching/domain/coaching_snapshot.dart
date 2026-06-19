// SPEC-194: estado actual del usuario que alimenta al motor de coaching.
// Es el INPUT del scorer. Value object inmutable, Dart puro — lo ensambla
// el CoachingSnapshotBuilder (application) desde providers existentes.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/domain/fasting_check_in.dart';

class CoachingSnapshot {
  const CoachingSnapshot({
    required this.currentPhase,
    this.weakestPillar,
    this.secondWeakestPillar,
    this.goalPillars = const {},
    this.minutesToIntestinalLock,
    this.minutesToSleepOnset,
    this.liveCircadianScore,
    this.ignoredStreakByActionId = const {},
    this.shownTodayActionIds = const {},
    this.isGracePeriod = false,
    this.lastFeeling,
  });

  /// Fase circadiana activa (de CircadianEngine).
  final CircadianPhase currentPhase;

  /// Pilar más débil de la semana (menor adherencia/score). Núcleo de la
  /// personalización: las acciones sobre este pilar reciben pillarFit máximo.
  final Pillar? weakestPillar;

  /// Segundo pilar más débil.
  final Pillar? secondWeakestPillar;

  /// Pilares ligados a metas declaradas del usuario (goalAlignment).
  final Set<Pillar> goalPillars;

  /// Minutos al bloqueo intestinal (21:30). Null si ya pasó o no aplica.
  final int? minutesToIntestinalLock;

  /// SPEC-194 Adenda §8: minutos al inicio de la fase de SUEÑO (22:30).
  /// Alimenta la priorización de "proteger el inicio de sueño". Null si
  /// no aplica.
  final int? minutesToSleepOnset;

  /// SPEC-194 Adenda §8: factor circadiano en vivo [0,1] que entra al IMR
  /// (`MetabolicState.circadianAlignment`). Es el mismo valor que mide el
  /// IMR, expuesto al coach para explicabilidad ("lo que recomiendo = lo
  /// que mido"). Null si aún no se ha resuelto el estado metabólico.
  final double? liveCircadianScore;

  /// Veces consecutivas que cada acción (por id) se mostró y NO se siguió.
  /// De telemetría SPEC-193. Alimenta la penalización por fatiga.
  final Map<String, int> ignoredStreakByActionId;

  /// Acciones ya mostradas hoy como principal (evita repetir el mismo día).
  final Set<String> shownTodayActionIds;

  /// Período de gracia (engagement neutro, <3 días de datos): se suprime el
  /// motor y la UI muestra "Elena está aprendiendo tu ritmo".
  final bool isGracePeriod;

  /// SPEC-232: último sentimiento reportado en el ciclo de ayuno actual.
  /// Alimenta al CheckInResponseGenerator para priorizar coaching empático.
  final FastingFeeling? lastFeeling;
}
