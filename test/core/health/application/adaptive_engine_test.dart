import 'package:elena_app/src/core/health/application/adaptive_engine.dart';
import 'package:elena_app/src/core/health/domain/decision_output.dart';
import 'package:elena_app/src/core/health/domain/user_behavior_profile.dart';
import 'package:elena_app/src/core/health/domain/user_health_state.dart';
import 'package:elena_app/src/features/health/domain/daily_log.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/metabolic_profile.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveEngine', () {
    const engine = AdaptiveEngine();

    test('very low energy -> must eat (critical rule)', () {
      final state = _buildState(
        isCurrentlyFasting: false,
        fastingHours: 0,
        sleepMinutes: 60,
        waterGlasses: 0,
        calories: 0,
      );

      final result = engine.adapt(
        baseDecision: _baseHydrateDecision(),
        state: state,
        profile: UserBehaviorProfile(),
      );

      expect(result.primaryAction.toLowerCase(), contains('romper el ayuno'));
      expect(result.priority, equals(5));
    });

    test('severe fatigue -> must rest (critical rule)', () {
      final state = _buildState(
        isCurrentlyFasting: false,
        fastingHours: 0,
        sleepMinutes: 180,
        waterGlasses: 8,
        calories: 2200,
      );

      final result = engine.adapt(
        baseDecision: _baseTrainDecision(),
        state: state,
        profile: UserBehaviorProfile(),
      );

      expect(result.primaryAction.toLowerCase(), contains('descanso'));
      expect(result.priority, equals(5));
    });

    test('high fastingTolerance biases to fastingContinue', () {
      final state = _buildState(
        isCurrentlyFasting: true,
        fastingHours: 14,
        sleepMinutes: 450,
        waterGlasses: 6,
        calories: 1800,
      );

      final result = engine.adapt(
        baseDecision: _baseHydrateDecision(),
        state: state,
        profile: UserBehaviorProfile(
          fastingTolerance: 0.9,
          actionSuccessRates: const {'fasting_continue': 0.92},
          actionHistoryCounts: const {'fasting_continue': 8},
        ),
      );

      expect(result.primaryAction.toLowerCase(), contains('mantén tu ayuno'));
    });

    test('frequent fasting failures reduce fasting recommendations', () {
      final state = _buildState(
        isCurrentlyFasting: true,
        fastingHours: 10,
        sleepMinutes: 420,
        waterGlasses: 7,
        calories: 1900,
      );

      final baseFasting = DecisionOutput.fastingContinue(
        pillarScores: _pillarScores(),
        hoursElapsed: 10,
      );

      final result = engine.adapt(
        baseDecision: baseFasting,
        state: state,
        profile: UserBehaviorProfile(
          fastingTolerance: 0.6,
          actionSuccessRates: const {'fasting_continue': 0.12},
          actionHistoryCounts: const {'fasting_continue': 10},
        ),
      );

      expect(result.primaryAction.toLowerCase(),
          isNot(contains('mantén tu ayuno')));
    });

    test('low nutritionCompliance simplifies recommendation payload', () {
      final state = _buildState(
        isCurrentlyFasting: false,
        fastingHours: 0,
        sleepMinutes: 420,
        waterGlasses: 8,
        calories: 2100,
      );

      final result = engine.adapt(
        baseDecision: DecisionOutput.eatNow(
          pillarScores: _pillarScores(),
          mealSuggestion: 'Comida completa con proteína.',
        ),
        state: state,
        profile: UserBehaviorProfile(nutritionCompliance: 0.2),
      );

      expect(
        result.explanation,
        equals(
            'Enfoque simple y ejecutable hoy. Prioriza una sola acción clave.'),
      );
      expect(result.secondaryActions.length, lessThanOrEqualTo(2));
    });
  });
}

DecisionOutput _baseHydrateDecision() {
  return DecisionOutput.hydrate(
    pillarScores: _pillarScores(),
    currentGlasses: 2,
    targetGlasses: 8,
  );
}

DecisionOutput _baseTrainDecision() {
  return DecisionOutput.train(
    pillarScores: _pillarScores(),
    routineType: 'Moderado',
    isFasted: false,
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

UserHealthState _buildState({
  required bool isCurrentlyFasting,
  required double fastingHours,
  required int sleepMinutes,
  required int waterGlasses,
  required int calories,
}) {
  final dailyLog = DailyLog(
    id: 'adaptive-test',
    waterGlasses: waterGlasses,
    calories: calories,
    proteinGrams: 90,
    carbsGrams: 120,
    fatGrams: 55,
    exerciseMinutes: 20,
    sleepMinutes: sleepMinutes,
    fastingStartTime: DateTime(2026, 4, 2, 20),
    fastingEndTime: isCurrentlyFasting ? null : DateTime(2026, 4, 3, 10),
    imrScore: 65,
    mealEntries: const [],
    exerciseEntries: const [],
  );

  final profile = MetabolicProfile(
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
    dailyExerciseGoalMinutes: 30,
    fastingContext: FastingContext(
      protocol: FastingProtocol.standard16_8,
      fastingWindowHours: 16,
      feedingWindowHours: 8,
      experience: FastingExperience.intermediate,
      trainingTiming: TrainingTiming.fed,
      isCurrentlyFasting: isCurrentlyFasting,
      currentFastingElapsedHours: fastingHours,
    ),
  );

  return UserHealthState(
    dailyLog: dailyLog,
    metabolicProfile: profile,
    sleepLog: null,
    workouts: const [],
  );
}
