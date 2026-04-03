import 'package:elena_app/src/core/health/application/adaptive_engine.dart';
import 'package:elena_app/src/core/health/application/behavior_tracker.dart';
import 'package:elena_app/src/core/health/application/decision_engine.dart';
import 'package:elena_app/src/core/health/application/health_orchestrator.dart';
import 'package:elena_app/src/core/health/domain/decision_output.dart';
import 'package:elena_app/src/core/health/domain/user_behavior_profile.dart';
import 'package:elena_app/src/core/health/domain/user_health_state.dart';
import 'package:elena_app/src/features/health/domain/daily_log.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/metabolic_profile.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HealthOrchestrator usa AdaptiveEngine con perfil conductual cargado',
      () async {
    final baseDecision = DecisionOutput.hydrate(
      pillarScores: _pillarScores(),
      currentGlasses: 2,
      targetGlasses: 8,
    );

    final fakeDecisionEngine = _FakeDecisionEngine(baseDecision);
    final fakeAdaptiveEngine = _FakeAdaptiveEngine();
    final fakeStore = _FakeBehaviorStore(
      profile: UserBehaviorProfile(
        fastingTolerance: 0.8,
        actionSuccessRates: const {'fasting_continue': 0.9},
        actionHistoryCounts: const {'fasting_continue': 5},
      ),
    );

    final orchestrator = HealthOrchestrator(
      decisionEngine: fakeDecisionEngine,
      adaptiveEngine: fakeAdaptiveEngine,
      behaviorStore: fakeStore,
    );

    final snapshot = await orchestrator.buildState(
      dailyLog: _dailyLog(),
      metabolicProfile: _metabolicProfile(),
      workouts: const [],
      now: DateTime.utc(2026, 4, 3, 12),
    );

    expect(fakeStore.loadCalled, isTrue);
    expect(fakeAdaptiveEngine.called, isTrue);
    expect(snapshot.decision.explanation, equals('adapted-decision'));
    expect(snapshot.decision.priority, equals(4));
  });
}

class _FakeDecisionEngine extends DecisionEngine {
  final DecisionOutput _output;
  const _FakeDecisionEngine(this._output);

  @override
  DecisionOutput decide(UserHealthState state, {DateTime? now}) => _output;
}

class _FakeAdaptiveEngine extends AdaptiveEngine {
  bool called = false;

  @override
  DecisionOutput adapt({
    required DecisionOutput baseDecision,
    required UserHealthState state,
    required UserBehaviorProfile profile,
  }) {
    called = true;
    return baseDecision.copyWith(
      explanation: 'adapted-decision',
      priority: 4,
    );
  }
}

class _FakeBehaviorStore implements BehaviorTrackerStore {
  final UserBehaviorProfile profile;
  bool loadCalled = false;

  _FakeBehaviorStore({required this.profile});

  @override
  Future<BehaviorTrackerSnapshot?> load() async {
    loadCalled = true;
    return BehaviorTrackerSnapshot(profile: profile);
  }

  @override
  Future<void> save(BehaviorTrackerSnapshot snapshot) async {}
}

DailyLog _dailyLog() {
  return DailyLog(
    id: 'orchestrator-test',
    waterGlasses: 2,
    calories: 1800,
    proteinGrams: 100,
    carbsGrams: 140,
    fatGrams: 60,
    exerciseMinutes: 30,
    sleepMinutes: 420,
    fastingStartTime: DateTime(2026, 4, 2, 20),
    fastingEndTime: DateTime(2026, 4, 3, 10),
    mtiScore: 68,
    mealEntries: const [],
    exerciseEntries: const [],
  );
}

MetabolicProfile _metabolicProfile() {
  return const MetabolicProfile(
    totalWeightKg: 75,
    bodyFatPercent: 22,
    leanMassKg: 58.5,
    fatMassKg: 16.5,
    bmr: 1600,
    tdee: 2200,
    activityMultiplier: 1.375,
    bmi: 24,
    whtr: 0.49,
    whr: 0.88,
    insulinSensitivity: InsulinSensitivity.normal,
    metabolicFlexibility: MetabolicFlexibility.medium,
    adaptationState: AdaptationState.normal,
    hasMetabolicRisk: false,
    hasHormonalRisk: false,
    age: 34,
    gender: Gender.male,
    goal: MetabolicGoal.maintenance,
    fastingContext: FastingContext(
      protocol: FastingProtocol.standard16_8,
      fastingWindowHours: 16,
      feedingWindowHours: 8,
      experience: FastingExperience.intermediate,
      trainingTiming: TrainingTiming.fed,
      isCurrentlyFasting: false,
      currentFastingElapsedHours: 0,
    ),
  );
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
