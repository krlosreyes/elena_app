import 'package:elena_app/src/core/health/application/decision_engine.dart';
import 'package:elena_app/src/core/health/domain/user_health_state.dart';
import 'package:elena_app/src/features/health/domain/daily_log.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/metabolic_profile.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecisionEngine', () {
    const engine = DecisionEngine();
    final fixedNow = DateTime.utc(2026, 4, 3, 12);

    test(
        'recomienda fastingContinue cuando el ayuno está activo y la energía es estable',
        () {
      final state = _buildState(
        isCurrentlyFasting: true,
        fastingHours: 12,
        sleepMinutes: 480,
        waterGlasses: 8,
        calories: 1900,
        mealEntries: const [
          {
            'name': 'Comida 1',
            'timestamp': '2026-04-03T07:30:00.000Z',
            'calories': 700,
          }
        ],
      );

      final output = engine.decide(state, now: fixedNow);

      expect(output.primaryAction.toLowerCase(), contains('mantén tu ayuno'));
      expect(output.metabolicState, equals('fat_burning'));
    });

    test('prioriza eatNow cuando hay energía baja en ventana de alimentación',
        () {
      final state = _buildState(
        isCurrentlyFasting: false,
        fastingHours: 0,
        sleepMinutes: 420,
        waterGlasses: 4,
        calories: 0,
        mealEntries: const [],
      );

      final output = engine.decide(state, now: fixedNow);

      expect(output.primaryAction.toLowerCase(), contains('romper el ayuno'));
      expect(output.priority, equals(5));
    });

    test('prioriza rest cuando el sueño es muy pobre', () {
      final state = _buildState(
        isCurrentlyFasting: false,
        fastingHours: 0,
        sleepMinutes: 180,
        waterGlasses: 6,
        calories: 1700,
        mealEntries: const [
          {
            'name': 'Comida 1',
            'timestamp': '2026-04-03T09:00:00.000Z',
            'calories': 600,
          }
        ],
      );

      final output = engine.decide(state, now: fixedNow);

      expect(output.primaryAction.toLowerCase(), contains('descanso'));
      expect(output.priority, equals(5));
    });
  });
}

UserHealthState _buildState({
  required bool isCurrentlyFasting,
  required double fastingHours,
  required int sleepMinutes,
  required int waterGlasses,
  required int calories,
  required List<Map<String, dynamic>> mealEntries,
}) {
  final dailyLog = DailyLog(
    id: '2026-04-03',
    waterGlasses: waterGlasses,
    calories: calories,
    proteinGrams: 90,
    carbsGrams: 120,
    fatGrams: 55,
    exerciseMinutes: 20,
    sleepMinutes: sleepMinutes,
    fastingStartTime: DateTime(2026, 4, 2, 20),
    fastingEndTime: isCurrentlyFasting ? null : DateTime(2026, 4, 3, 10),
    mtiScore: 65,
    mealEntries: mealEntries,
    exerciseEntries: const [],
  );

  const fastingContext = FastingContext(
    protocol: FastingProtocol.standard16_8,
    fastingWindowHours: 16,
    feedingWindowHours: 8,
    experience: FastingExperience.intermediate,
    trainingTiming: TrainingTiming.fed,
    isCurrentlyFasting: false,
    currentFastingElapsedHours: 0,
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
    fastingContext: FastingContext(
      protocol: fastingContext.protocol,
      fastingWindowHours: fastingContext.fastingWindowHours,
      feedingWindowHours: fastingContext.feedingWindowHours,
      experience: fastingContext.experience,
      trainingTiming: fastingContext.trainingTiming,
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
