import '../../health/domain/decision_output.dart';
import '../../health/domain/user_behavior_profile.dart';
import '../domain/user_engagement_profile.dart';
import '../domain/user_experience_output.dart';

/// Builds an engagement-enhanced experience from health recommendations.
///
/// Responsibilities:
/// - Tone adaptation by motivation
/// - Gamification signals (streak, risk, rewards)
/// - Recovery/risk mode detection
/// - Preserve critical health decisions as-is
class EngagementEngine {
  const EngagementEngine();

  UserExperienceOutput enhance({
    required DecisionOutput decision,
    required UserBehaviorProfile behavior,
    required UserEngagementProfile engagement,
  }) {
    final isCritical = _isCriticalHealthDecision(decision);

    final recoveryMode =
        engagement.missedDays >= 2 && engagement.adherenceScore < 0.4;
    final lowAdherence = engagement.adherenceScore < 0.4;

    if (recoveryMode) {
      final recoveryDecision = _buildRecoveryDecision(decision);

      return UserExperienceOutput(
        decision: recoveryDecision,
        tone: 'recovery',
        primaryMessage:
            'Recovery mode active: focus on rebuilding consistency today.',
        suggestedActions: const [
          'Drink water',
          'Walk 10 minutes',
          'Eat something light',
          'No strict fasting today.',
          'No intense training today.',
        ],
        gamificationMessage:
            'Objetivo del día: recuperar ritmo con acciones simples y sostenibles.',
        streakAtRisk: engagement.currentStreak > 0,
        rewardTriggered: false,
        recoveryMode: true,
        systemFlags: const [
          'recovery_mode',
          'consistency_rebuild',
          'expectations_reset',
        ],
      );
    }

    final tone = _resolveTone(
      motivationLevel: engagement.motivationLevel,
      isCritical: isCritical,
      recoveryMode: recoveryMode,
    );

    final streakAtRisk =
        engagement.currentStreak > 0 && engagement.missedDays >= 1;
    final rewardTriggered = _hasRewardTrigger(engagement);

    final suggestedActions = _buildSuggestedActions(
      decision: decision,
      lowMotivation: engagement.motivationLevel < 0.4,
      highMotivation: engagement.motivationLevel > 0.75,
      lowAdherence: lowAdherence,
      isCritical: isCritical,
    );

    final primaryMessage = _buildPrimaryMessage(
      decision: decision,
      tone: tone,
      isCritical: isCritical,
      lowMotivation: engagement.motivationLevel < 0.4,
      highMotivation: engagement.motivationLevel > 0.75,
    );

    final gamificationMessage = _buildGamificationMessage(
      currentStreak: engagement.currentStreak,
      longestStreak: engagement.longestStreak,
      streakAtRisk: streakAtRisk,
      rewardTriggered: rewardTriggered,
      recoveryMode: recoveryMode,
    );

    final flags = <String>[];
    if (recoveryMode) flags.add('recovery_mode');
    if (lowAdherence) flags.add('low_adherence_simplification');
    if (streakAtRisk) flags.add('streak_risk');
    if (rewardTriggered) flags.add('reward_triggered');
    if (decision.isPersonalized) flags.add('health_personalized');
    if (behavior.nutritionCompliance < 0.4) {
      flags.add('behavior_low_nutrition_compliance');
    }

    return UserExperienceOutput(
      decision: decision,
      tone: tone,
      primaryMessage: primaryMessage,
      suggestedActions: suggestedActions,
      gamificationMessage: gamificationMessage,
      streakAtRisk: streakAtRisk,
      rewardTriggered: rewardTriggered,
      recoveryMode: recoveryMode,
      systemFlags: flags,
    );
  }

  bool _isCriticalHealthDecision(DecisionOutput decision) {
    if (decision.priority >= 5) return true;

    final action = decision.primaryAction.toLowerCase();
    return action.contains('romper el ayuno') || action.contains('descanso');
  }

  DecisionOutput _buildRecoveryDecision(DecisionOutput baseDecision) {
    return DecisionOutput(
      primaryAction: 'Drink water',
      explanation:
          'Recovery mode activated due to missed days and low adherence. '
          'Keep it simple and rebuild consistency first.',
      secondaryActions: const [
        'Walk 10 minutes',
        'Eat something light',
        'No strict fasting today.',
        'No intense training today.',
      ],
      pillarScores: baseDecision.pillarScores,
      metabolicState: 'recovery',
      priority: 2,
      isPersonalized: true,
      personalizationReason:
          'Recovery mode was triggered by missed days and low adherence.',
    );
  }

  String _resolveTone({
    required double motivationLevel,
    required bool isCritical,
    required bool recoveryMode,
  }) {
    if (isCritical) return 'clinical';
    if (recoveryMode) return 'recovery';
    if (motivationLevel < 0.4) return 'soft';
    if (motivationLevel > 0.75) return 'challenge';
    return 'balanced';
  }

  List<String> _buildSuggestedActions({
    required DecisionOutput decision,
    required bool lowMotivation,
    required bool highMotivation,
    required bool lowAdherence,
    required bool isCritical,
  }) {
    var actions = List<String>.from(decision.secondaryActions);

    if (lowAdherence) {
      actions = actions.take(2).toList();
      actions =
          actions.map((a) => a.startsWith('Paso:') ? a : 'Paso: $a').toList();
    }

    if (lowMotivation && !isCritical) {
      if (actions.isEmpty) {
        actions = [
          'Paso: Haz la versión más simple de esta recomendación hoy.'
        ];
      } else {
        actions = actions.take(2).toList();
      }
    }

    if (highMotivation && !isCritical) {
      actions = [
        ...actions,
        'Reto extra: completa una acción adicional de alta calidad hoy.',
      ];
    }

    return actions;
  }

  String _buildPrimaryMessage({
    required DecisionOutput decision,
    required String tone,
    required bool isCritical,
    required bool lowMotivation,
    required bool highMotivation,
  }) {
    if (isCritical) {
      return 'Prioridad clínica: ${decision.primaryAction}';
    }

    if (lowMotivation) {
      return 'Vamos paso a paso: ${decision.primaryAction}';
    }

    if (highMotivation) {
      return 'Excelente momento para subir nivel: ${decision.primaryAction}';
    }

    return decision.primaryAction;
  }

  bool _hasRewardTrigger(UserEngagementProfile engagement) {
    if (engagement.currentStreak > 0 && engagement.currentStreak % 7 == 0) {
      return true;
    }

    if (engagement.totalActionsCompleted > 0 &&
        engagement.totalActionsCompleted % 25 == 0) {
      return true;
    }

    return false;
  }

  String _buildGamificationMessage({
    required int currentStreak,
    required int longestStreak,
    required bool streakAtRisk,
    required bool rewardTriggered,
    required bool recoveryMode,
  }) {
    if (recoveryMode) {
      return 'Modo recuperación activo: reinicia con objetivos mínimos para retomar constancia.';
    }

    if (rewardTriggered) {
      return '¡Logro desbloqueado! Llevas una gran racha. Recompensa tu consistencia.';
    }

    if (streakAtRisk) {
      return 'Tu racha está en riesgo. Completa una acción pequeña hoy para mantenerla.';
    }

    if (currentStreak > 0) {
      final remainingForRecord =
          (longestStreak - currentStreak).clamp(0, 10000);
      if (remainingForRecord == 0) {
        return '¡Racha activa de $currentStreak días! Ya igualaste o superaste tu récord.';
      }
      return 'Racha activa de $currentStreak días. Te faltan $remainingForRecord para tu récord.';
    }

    return 'Empieza hoy: una acción completada activa tu nueva racha.';
  }
}
