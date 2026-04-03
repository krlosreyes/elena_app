import 'package:elena_app/src/core/health/application/behavior_tracker.dart';
import 'package:elena_app/src/core/health/domain/decision_output.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BehaviorTracker', () {
    test('tracks decision, user action and outcome updating profile', () async {
      final store = InMemoryBehaviorTrackerStore();
      final tracker = BehaviorTracker(store: store);

      tracker.trackDecision(
        DecisionOutput.eatNow(
          pillarScores: _pillarScores(),
          mealSuggestion: 'Proteína + vegetales',
        ),
      );
      tracker.trackUserAction('eat_now');
      tracker.trackOutcome('eat_now', true);

      expect(tracker.lastDecisionAction, equals('eat_now'));
      expect(tracker.lastUserAction, equals('eat_now'));
      expect(tracker.profile.actionHistoryCounts['eat_now'], equals(3));
      expect(
        tracker.profile.actionSuccessRates['eat_now'],
        closeTo(1 / 3, 0.0001),
      );
      expect(tracker.events.length, equals(3));

      final restored = BehaviorTracker(store: store);
      await restored.initialize();

      expect(restored.lastDecisionAction, equals('eat_now'));
      expect(restored.profile.actionHistoryCounts['eat_now'], equals(3));
      expect(
        restored.profile.actionSuccessRates['eat_now'],
        closeTo(1 / 3, 0.0001),
      );
      expect(restored.events.length, equals(3));
    });
  });
}

Map<String, double> _pillarScores() {
  return const {
    DecisionOutput.fastingPillar: 60,
    DecisionOutput.nutritionPillar: 60,
    DecisionOutput.trainingPillar: 60,
    DecisionOutput.hydrationPillar: 60,
    DecisionOutput.sleepPillar: 60,
  };
}
