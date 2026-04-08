import 'package:elena_app/src/core/health/application/decision_engine.dart';
import 'package:elena_app/src/core/health/domain/user_health_state.dart';
import 'package:elena_app/src/features/health/domain/daily_log.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/metabolic_profile.dart';
import 'package:elena_app/src/features/training/domain/entities/workout_log.dart';
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
        sleepMinutes: 60,
        waterGlasses: 0,
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

  group('DecisionEngine — reglas circadianas', () {
    const engine = DecisionEngine();

    test('ventana matutina con energía estable → deepWork', () {
      final state = _stateWith(energy: 70, recovery: 75, sleepHours: 7.5);
      final result = engine.decide(state, now: _at(10));

      expect(result.primaryAction.toLowerCase(),
          contains('cerebro está en su pico'));
      expect(result.metadata?['type'], equals('deep_work'));
      expect(result.metadata?['circadianPhase'], equals('morningSensitivity'));
    });

    test('ventana matutina con energía muy baja → NO deepWork', () {
      final state = _stateWith(energy: 30, recovery: 40, sleepHours: 7.5);
      final result = engine.decide(state, now: _at(10));

      expect(result.primaryAction.toLowerCase(),
          isNot(contains('cerebro está en su pico')));
    });

    test('ventana de tarde con energía alta → entrenamiento neuromotor', () {
      final state = _stateWith(
        energy: 80,
        recovery: 70,
        sleepHours: 7.5,
        isFasting: false,
      );
      final result = engine.decide(state, now: _at(15));

      expect(
        result.primaryAction.toLowerCase(),
        anyOf(
          contains('entrenar'),
          contains('fuerza'),
          contains('neuromotora'),
        ),
      );
      expect(result.primaryAction.toLowerCase(), contains('neuromotora'));
      expect(result.priority, greaterThanOrEqualTo(2));
    });

    test('ventana de melatonina en alimentación → advertencia circadiana', () {
      final state = _stateWith(
        energy: 75,
        recovery: 70,
        sleepHours: 7.5,
        isFeeding: true,
      );
      final result = engine.decide(state, now: _at(19));

      expect(result.explanation.toLowerCase(), contains('sistema digestivo'));
      expect(result.metadata?['type'], equals('circadian_warning'));
    });

    test('ventana de sueño con déficit leve → rest recomendado', () {
      final state = _stateWith(
        energy: 70,
        recovery: 65,
        sleepHours: 6.5,
      );
      final result = engine.decide(state, now: _at(22));

      expect(
        result.primaryAction.toLowerCase(),
        anyOf(contains('descanso'), contains('rest'), contains('dormir')),
      );
    });

    test('deepWork no aplica en ventana de tarde', () {
      final state = _stateWith(energy: 70, recovery: 75, sleepHours: 7.5);
      final result = engine.decide(state, now: _at(15));

      expect(result.metadata?['circadianPhase'],
          isNot(equals('morningSensitivity')));
      expect(result.metadata?['type'], isNot(equals('deep_work')));
    });

    test('advertencia circadiana no aplica si está en ayuno', () {
      final state = _stateWith(
        energy: 75,
        recovery: 70,
        sleepHours: 7.5,
        isFasting: true,
        isFeeding: false,
      );
      final result = engine.decide(state, now: _at(19));

      expect(result.metadata?['type'], isNot(equals('circadian_warning')));
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
    imrScore: 65,
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
    dailyExerciseGoalMinutes: 30,
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

DateTime _at(int hour) => DateTime(2025, 1, 15, hour, 0);

UserHealthState _stateWith({
  double energy = 80,
  double recovery = 75,
  double sleepHours = 7.5,
  bool isFasting = false,
  bool isFeeding = false,
}) {
  final currentlyFasting = isFasting ? true : false;

  final waterGlasses = switch (energy) {
    >= 75 => 8,
    >= 50 => 7,
    >= 35 => 7,
    _ => 0,
  };

  final calories = switch (energy) {
    >= 75 => 2200,
    >= 50 => 1200,
    >= 35 => 900,
    _ => 0,
  };

  final workouts = recovery < 65
      ? [
          WorkoutLog(
            id: 'w-1',
            templateId: 'hiit-a',
            date: _at(8),
            sessionRirScore: 0,
            completedExercises: const [],
            durationMinutes: 90,
            isFasted: true,
          ),
          WorkoutLog(
            id: 'w-2',
            templateId: 'hiit-b',
            date: _at(9),
            sessionRirScore: 0,
            completedExercises: const [],
            durationMinutes: 90,
            isFasted: true,
          ),
          WorkoutLog(
            id: 'w-3',
            templateId: 'hiit-c',
            date: _at(10),
            sessionRirScore: 0,
            completedExercises: const [],
            durationMinutes: 90,
            isFasted: true,
          ),
        ]
      : const <WorkoutLog>[];

  final dailyLog = DailyLog(
    id: '2025-01-15',
    waterGlasses: waterGlasses,
    calories: calories,
    proteinGrams: 90,
    carbsGrams: 120,
    fatGrams: 55,
    exerciseMinutes: 20,
    sleepMinutes: (sleepHours * 60).round(),
    fastingStartTime: DateTime(2025, 1, 14, 20),
    fastingEndTime: currentlyFasting ? null : DateTime(2025, 1, 15, 10),
    imrScore: 65,
    mealEntries: currentlyFasting
        ? const []
        : [
            {
              'name': 'Comida 1',
              'timestamp': '2025-01-15T07:30:00.000Z',
              'calories': 700,
            }
          ],
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
    dailyExerciseGoalMinutes: 30,
    fastingContext: FastingContext(
      protocol: fastingContext.protocol,
      fastingWindowHours: fastingContext.fastingWindowHours,
      feedingWindowHours: fastingContext.feedingWindowHours,
      experience: fastingContext.experience,
      trainingTiming: fastingContext.trainingTiming,
      isCurrentlyFasting: currentlyFasting,
      currentFastingElapsedHours: currentlyFasting ? 16 : 0,
    ),
  );

  return UserHealthState(
    dailyLog: dailyLog,
    metabolicProfile: profile,
    sleepLog: null,
    workouts: workouts,
  );
}
