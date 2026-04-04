import 'package:elena_app/src/core/engagement/application/streak_engine.dart';
import 'package:elena_app/src/core/engagement/domain/user_engagement_profile.dart';
import 'package:elena_app/src/core/health/domain/decision_output.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreakEngine', () {
    const engine = StreakEngine();

    test('increases streak when user follows primary action', () {
      final output = engine.evaluate(
        decision: _hydrateDecision(priority: 3),
        engagement: UserEngagementProfile(currentStreak: 2, longestStreak: 4),
        userAction: 'hydrate',
        actionCompleted: true,
      );

      expect(output.updatedStreak, equals(3));
      expect(output.updatedProfile.currentStreak, equals(3));
      expect(output.streakBroken, isFalse);
      expect(output.rewardTriggered, isTrue);
      expect(output.milestoneReached, equals(3));
    });

    test('breaks streak when critical action is missed', () {
      final critical = DecisionOutput.rest(
        pillarScores: _pillars(),
        sleepDebt: 4.0,
      ).copyWith(priority: 5);

      final output = engine.evaluate(
        decision: critical,
        engagement: UserEngagementProfile(currentStreak: 5, longestStreak: 8),
        userAction: 'hydrate',
        actionCompleted: false,
      );

      expect(output.updatedStreak, equals(0));
      expect(output.streakBroken, isTrue);
      expect(output.streakAtRisk, isFalse);
    });

    test('uses one soft failure protection before breaking', () {
      final firstMiss = engine.evaluate(
        decision: _hydrateDecision(priority: 3),
        engagement: UserEngagementProfile(
          currentStreak: 6,
          longestStreak: 6,
          missedDays: 0,
        ),
        userAction: 'train',
        actionCompleted: false,
      );

      expect(firstMiss.updatedStreak, equals(6));
      expect(firstMiss.streakAtRisk, isTrue);
      expect(firstMiss.usedStreakProtection, isTrue);
      expect(firstMiss.streakBroken, isFalse);

      final secondMiss = engine.evaluate(
        decision: _hydrateDecision(priority: 3),
        engagement: firstMiss.updatedProfile,
        userAction: 'train',
        actionCompleted: false,
      );

      expect(secondMiss.updatedStreak, equals(0));
      expect(secondMiss.streakBroken, isTrue);
    });

    test('detects milestone rewards at 7/14/30', () {
      final at7 = engine.evaluate(
        decision: _hydrateDecision(priority: 2),
        engagement: UserEngagementProfile(currentStreak: 6, longestStreak: 6),
        userAction: 'hydrate',
        actionCompleted: true,
      );
      expect(at7.rewardTriggered, isTrue);
      expect(at7.milestoneReached, equals(7));

      final at14 = engine.evaluate(
        decision: _hydrateDecision(priority: 2),
        engagement: UserEngagementProfile(currentStreak: 13, longestStreak: 13),
        userAction: 'hydrate',
        actionCompleted: true,
      );
      expect(at14.rewardTriggered, isTrue);
      expect(at14.milestoneReached, equals(14));

      final at30 = engine.evaluate(
        decision: _hydrateDecision(priority: 2),
        engagement: UserEngagementProfile(currentStreak: 29, longestStreak: 29),
        userAction: 'hydrate',
        actionCompleted: true,
      );
      expect(at30.rewardTriggered, isTrue);
      expect(at30.milestoneReached, equals(30));
    });
  });
}

DecisionOutput _hydrateDecision({required int priority}) {
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
