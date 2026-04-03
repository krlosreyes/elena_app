import 'package:elena_app/src/core/engagement/application/engagement_engine.dart';
import 'package:elena_app/src/core/engagement/domain/user_engagement_profile.dart';
import 'package:elena_app/src/core/health/domain/decision_output.dart';
import 'package:elena_app/src/core/health/domain/user_behavior_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EngagementEngine', () {
    const engine = EngagementEngine();

    test('low motivation + low adherence softens and simplifies actions', () {
      final result = engine.enhance(
        decision: _baseDecision(priority: 3),
        behavior: UserBehaviorProfile(),
        engagement: UserEngagementProfile(
          motivationLevel: 0.25,
          adherenceScore: 0.3,
          currentStreak: 3,
          longestStreak: 7,
          missedDays: 0,
        ),
      );

      expect(result.tone, equals('soft'));
      expect(result.primaryMessage.toLowerCase(), contains('paso a paso'));
      expect(result.suggestedActions.length, lessThanOrEqualTo(2));
      expect(result.systemFlags, contains('low_adherence_simplification'));
    });

    test('critical decisions are preserved unchanged', () {
      final critical = DecisionOutput.rest(
        pillarScores: _pillars(),
        sleepDebt: 4.0,
      ).copyWith(priority: 5);

      final result = engine.enhance(
        decision: critical,
        behavior: UserBehaviorProfile(),
        engagement: UserEngagementProfile(
          motivationLevel: 0.95,
          adherenceScore: 0.9,
        ),
      );

      expect(result.decision.primaryAction, equals(critical.primaryAction));
      expect(result.decision.priority, equals(5));
      expect(result.tone, equals('clinical'));
    });

    test('detects recovery mode and gamification triggers', () {
      final result = engine.enhance(
        decision: _baseDecision(priority: 2),
        behavior: UserBehaviorProfile(),
        engagement: UserEngagementProfile(
          motivationLevel: 0.7,
          adherenceScore: 0.8,
          currentStreak: 14,
          longestStreak: 20,
          totalActionsCompleted: 50,
          missedDays: 3,
        ),
      );

      expect(result.recoveryMode, isTrue);
      expect(result.rewardTriggered, isTrue);
      expect(
          result.gamificationMessage.toLowerCase(), contains('recuperación'));
      expect(result.systemFlags, contains('recovery_mode'));
      expect(result.systemFlags, contains('reward_triggered'));
    });
  });
}

DecisionOutput _baseDecision({required int priority}) {
  return DecisionOutput.hydrate(
    pillarScores: _pillars(),
    currentGlasses: 2,
    targetGlasses: 8,
  ).copyWith(priority: priority);
}

Map<String, double> _pillars() {
  return const {
    DecisionOutput.fastingPillar: 60,
    DecisionOutput.nutritionPillar: 60,
    DecisionOutput.trainingPillar: 60,
    DecisionOutput.hydrationPillar: 60,
    DecisionOutput.sleepPillar: 60,
  };
}
