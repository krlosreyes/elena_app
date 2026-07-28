// SPEC-194 — Scorer puro del motor de decisión de coaching.
//
// Determinista y explicable (CONSTITUTION §3.1, Dart puro): mismo
// (snapshot, candidatos) → misma selección. No lee providers ni Firestore;
// eso vive en application (CoachingDecisionEngine, generadores).
//
// Fórmula (Adenda circadiana §2):
//   score = 0.28·urgency + 0.27·relevance + 0.30·circadianImpact
//         + 0.15·confidence − 0.12·fatigue
// Regla especial: un deadline duro inminente (urgency ≥ 0.90) es SIEMPRE la
// principal, saltando el score.

import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_snapshot.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';
import 'package:elena_app/src/features/coaching/domain/scoring/scoring_weights.dart';

/// Resultado de la selección: principal + secundaria opcional.
class CoachingSelection {
  const CoachingSelection({this.primary, this.secondary});
  final CoachingAction? primary;
  final CoachingAction? secondary;

  bool get isEmpty => primary == null;
}

class CoachingScorer {
  const CoachingScorer._();

  /// Urgencia 0..1. Para deadlines duros escala por proximidad.
  static double urgency(CoachingAction a) {
    final double base = switch (a.urgencyKind) {
      ActionUrgencyKind.deadlineHard => kUrgencyDeadline,
      ActionUrgencyKind.phaseOpportunity => kUrgencyPhase,
      ActionUrgencyKind.habit => kUrgencyHabit,
      ActionUrgencyKind.protocol => kUrgencyProtocol,
    };
    if (a.urgencyKind == ActionUrgencyKind.deadlineHard &&
        a.minutesToDeadline != null) {
      final int m = a.minutesToDeadline!.clamp(0, kUrgencyWindowMin);
      final double proximity = 1 - (m / kUrgencyWindowMin);
      return (base + (1 - base) * proximity).clamp(0.0, 1.0).toDouble();
    }
    return base;
  }

  /// Relevancia 0..1 = encaje con el usuario ahora.
  static double relevance(CoachingAction a, CoachingSnapshot s) {
    final double pillarFit = a.pillar == s.weakestPillar
        ? kPillarFitWeakest
        : (a.pillar == s.secondWeakestPillar
            ? kPillarFitSecond
            : kPillarFitOther);
    final double actionability =
        a.actionableNow ? kActionableYes : kActionableNo;
    final double goal =
        s.goalPillars.contains(a.pillar) ? kGoalAligned : kGoalUnaligned;
    return (kRelPillarFit * pillarFit) +
        (kRelActionability * actionability) +
        (kRelGoal * goal);
  }

  /// Penalización por fatiga 0..1.
  static double fatigue(CoachingAction a, CoachingSnapshot s) {
    final int ignored = s.ignoredStreakByActionId[a.id] ?? 0;
    final double repeat = s.shownTodayActionIds.contains(a.id) ? 1.0 : 0.0;
    final double f =
        (kFatiguePerIgnore * ignored) + (kFatigueRepeatToday * repeat);
    return f.clamp(0.0, 1.0).toDouble();
  }

  /// Score lineal combinado.
  static double score(CoachingAction a, CoachingSnapshot s) {
    return (kWUrgency * urgency(a)) +
        (kWRelevance * relevance(a, s)) +
        (kWCircadian * a.circadianImpact) +
        (kWConfidence * a.confidence.weight) -
        (kWFatigue * fatigue(a, s));
  }

  /// Selecciona principal (+ secundaria opcional) entre los candidatos.
  static CoachingSelection select(
    List<CoachingAction> candidates,
    CoachingSnapshot s,
  ) {
    if (s.isGracePeriod || candidates.isEmpty) {
      return const CoachingSelection();
    }

    // 1. Override de deadline duro: el de mayor urgencia gana sin pasar score.
    final overrides = candidates
        .where((a) => urgency(a) >= kHardOverrideUrgency)
        .toList()
      ..sort((a, b) => urgency(b).compareTo(urgency(a)));

    final List<CoachingAction> ranked;
    final CoachingAction primary;
    if (overrides.isNotEmpty) {
      primary = overrides.first;
      ranked = [...candidates]..sort((a, b) => _cmp(a, b, s));
    } else {
      ranked = [...candidates]..sort((a, b) => _cmp(a, b, s));
      primary = ranked.first;
    }

    // 2. Secundaria: mayor score, pilar distinto, score ≥ umbral.
    CoachingAction? secondary;
    for (final a in ranked) {
      if (a.id == primary.id) continue;
      if (a.pillar != primary.pillar && score(a, s) >= kSecondaryThreshold) {
        secondary = a;
        break;
      }
    }

    return CoachingSelection(primary: primary, secondary: secondary);
  }

  /// Orden descendente por score; desempate por confianza, luego por
  /// ser el pilar más débil (determinista).
  static int _cmp(CoachingAction a, CoachingAction b, CoachingSnapshot s) {
    final int byScore = score(b, s).compareTo(score(a, s));
    if (byScore != 0) return byScore;
    final int byConf = b.confidence.weight.compareTo(a.confidence.weight);
    if (byConf != 0) return byConf;
    final int aw = a.pillar == s.weakestPillar ? 1 : 0;
    final int bw = b.pillar == s.weakestPillar ? 1 : 0;
    if (aw != bw) return bw.compareTo(aw);
    return a.id.compareTo(b.id); // estable
  }
}
