import '../../health/domain/decision_output.dart';
import '../domain/streak_update_output.dart';
import '../domain/user_engagement_profile.dart';

/// Computes streak progression and warnings from user execution behavior.
class StreakEngine {
  static const Set<int> _milestones = {3, 7, 14, 30};

  const StreakEngine();

  StreakUpdateOutput evaluate({
    required DecisionOutput decision,
    required UserEngagementProfile engagement,
    required String? userAction,
    required bool actionCompleted,
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now().toUtc();

    final requiredAction = _actionKeyFromDecision(decision);
    final normalizedUserAction = _normalizeAction(userAction);
    final followedPrimaryAction =
        actionCompleted && normalizedUserAction == requiredAction;
    final isCritical = _isCriticalDecision(decision);

    int currentStreak = engagement.currentStreak;
    int longestStreak = engagement.longestStreak;
    int totalActionsCompleted = engagement.totalActionsCompleted;
    int missedDays = engagement.missedDays;
    final completedByType =
        Map<String, int>.from(engagement.completedActionsByType);

    var streakBroken = false;
    var streakAtRisk = false;
    var rewardTriggered = false;
    var milestoneReached = null as int?;
    var usedStreakProtection = false;

    if (followedPrimaryAction) {
      currentStreak += 1;
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }

      totalActionsCompleted += 1;
      missedDays = 0;
      completedByType.update(
        requiredAction,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      if (_milestones.contains(currentStreak)) {
        milestoneReached = currentStreak;
        rewardTriggered = true;
      }
    } else {
      // Rule 2: critical misses break the streak immediately.
      if (isCritical) {
        currentStreak = 0;
        missedDays += 1;
        streakBroken = true;
      } else {
        // Rule 3: one soft failure can be absorbed.
        if (missedDays == 0) {
          missedDays = 1;
          streakAtRisk = currentStreak > 0;
          usedStreakProtection = currentStreak > 0;
        } else {
          currentStreak = 0;
          missedDays += 1;
          streakBroken = true;
        }
      }
    }

    final updated = engagement.copyWith(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalActionsCompleted: totalActionsCompleted,
      missedDays: missedDays,
      lastActive: referenceNow,
      completedActionsByType: completedByType,
    );

    return StreakUpdateOutput(
      updatedProfile: updated,
      updatedStreak: updated.currentStreak,
      streakBroken: streakBroken,
      streakAtRisk: streakAtRisk,
      rewardTriggered: rewardTriggered,
      milestoneReached: milestoneReached,
      usedStreakProtection: usedStreakProtection,
    );
  }

  bool _isCriticalDecision(DecisionOutput decision) {
    if (decision.priority >= 5) return true;

    final action = decision.primaryAction.toLowerCase();
    return action.contains('romper el ayuno') || action.contains('descanso');
  }

  String _actionKeyFromDecision(DecisionOutput decision) {
    final action = decision.primaryAction.toLowerCase();

    if (action.contains('romper el ayuno') ||
        action.contains('momento de comer')) {
      return 'eat_now';
    }
    if (action.contains('mantén tu ayuno') ||
        action.contains('mantener ayuno')) {
      return 'fasting_continue';
    }
    if (action.contains('descanso')) return 'rest';
    if (action.contains('entrenar')) return 'train';
    if (action.contains('agua') || action.contains('hidrata')) return 'hydrate';

    return 'maintain';
  }

  String _normalizeAction(String? action) {
    if (action == null) return '';
    return action.trim().toLowerCase().replaceAll(' ', '_');
  }
}
