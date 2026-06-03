// SPEC-154: tests del GoalProgressComputer (pure Dart).

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/goals/application/goal_progress_computer.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  double weight = 84.0,
  double? bodyFat = 22.0,
  int exerciseGoalMinutes = 30,
}) {
  return UserModel(
    id: 'u1',
    name: 'Test',
    age: 35,
    gender: 'masculino',
    weight: weight,
    height: 175.0,
    bodyFatPercentage: bodyFat,
    waistCircumference: 90,
    exerciseGoalMinutes: exerciseGoalMinutes,
    profile: CircadianProfile(
      wakeUpTime: DateTime(2026, 1, 1, 7, 0),
      sleepTime: DateTime(2026, 1, 1, 23, 0),
    ),
  );
}

DailySummaryDoc _day({
  String date = '2026-06-01',
  double fasting = 0.5,
  double sleep = 0.5,
  double hydration = 0.5,
  double exercise = 0.5,
  double meals = 0.5,
}) {
  return DailySummaryDoc(
    date: date,
    imrScore: 50,
    fastingProgress: fasting,
    sleepProgress: sleep,
    hydrationProgress: hydration,
    exerciseProgress: exercise,
    mealsProgress: meals,
    updatedAt: DateTime(2026, 6, 1),
  );
}

UserGoal _goal({
  required GoalType type,
  required double start,
  required double target,
}) {
  return UserGoal(
    type: type,
    targetValue: target,
    startValue: start,
    createdAt: DateTime(2026, 6, 1),
  );
}

void main() {
  group('SPEC-154 — buildCurrentValues', () {
    test('weight y bodyFat vienen del UserModel directo', () {
      final values = GoalProgressComputer.buildCurrentValues(
        user: _user(weight: 80.5, bodyFat: 20.0),
        weekDocs: const [],
      );
      expect(values[GoalType.weightTarget], 80.5);
      expect(values[GoalType.bodyFatTarget], 20.0);
    });

    test('bodyFat null en UserModel se reporta como 0', () {
      final values = GoalProgressComputer.buildCurrentValues(
        user: _user(bodyFat: null),
        weekDocs: const [],
      );
      expect(values[GoalType.bodyFatTarget], 0.0);
    });

    test('fastingDaysPerWeek cuenta días con fastingProgress >= 0.95', () {
      final values = GoalProgressComputer.buildCurrentValues(
        user: _user(),
        weekDocs: [
          _day(date: '2026-06-01', fasting: 1.0),
          _day(date: '2026-06-02', fasting: 0.97),
          _day(date: '2026-06-03', fasting: 0.94), // no cuenta
          _day(date: '2026-06-04', fasting: 0.50),
        ],
      );
      expect(values[GoalType.fastingDaysPerWeek], 2.0);
    });

    test('exercise se reconstruye multiplicando por la meta del usuario',
        () {
      final values = GoalProgressComputer.buildCurrentValues(
        user: _user(exerciseGoalMinutes: 30),
        weekDocs: [
          _day(date: '2026-06-01', exercise: 1.0), // 30 min
          _day(date: '2026-06-02', exercise: 0.5), // 15 min
        ],
      );
      // Promedio: (30 + 15) / 2 = 22.5
      expect(values[GoalType.exerciseMinPerDay], closeTo(22.5, 0.001));
    });

    test('sleepHours promedia con base 8h', () {
      final values = GoalProgressComputer.buildCurrentValues(
        user: _user(),
        weekDocs: [
          _day(date: '2026-06-01', sleep: 1.0), // 8h
          _day(date: '2026-06-02', sleep: 0.5), // 4h
        ],
      );
      expect(values[GoalType.sleepHoursPerNight], closeTo(6.0, 0.001));
    });

    test('hydration usa 35ml × kg como base de la conversión', () {
      final values = GoalProgressComputer.buildCurrentValues(
        user: _user(weight: 80), // hydroGoal = 2.8L
        weekDocs: [
          _day(date: '2026-06-01', hydration: 1.0), // 2.8L
          _day(date: '2026-06-02', hydration: 0.5), // 1.4L
        ],
      );
      // Promedio: (2.8 + 1.4) / 2 = 2.1
      expect(values[GoalType.hydrationLitersPerDay], closeTo(2.1, 0.001));
    });

    test('semana vacía: ayuno 0 días, otros 0 promedios', () {
      final values = GoalProgressComputer.buildCurrentValues(
        user: _user(),
        weekDocs: const [],
      );
      expect(values[GoalType.fastingDaysPerWeek], 0.0);
      expect(values[GoalType.exerciseMinPerDay], 0.0);
      expect(values[GoalType.sleepHoursPerNight], 0.0);
      expect(values[GoalType.hydrationLitersPerDay], 0.0);
    });
  });

  group('SPEC-154 — compute & motivationalMessage', () {
    test('progress >= 1.0 → mensaje de logro', () {
      final goal = _goal(
        type: GoalType.weightTarget,
        start: 90,
        target: 80,
      );
      final snap = GoalProgressComputer.compute(
        goal: goal,
        currentValue: 78,
      );
      expect(snap.isAchieved, isTrue);
      expect(snap.motivationalMessage, contains('Objetivo alcanzado'));
    });

    test('progress 0.85..1.0 → mensaje "Casi llegás" con gap', () {
      final goal = _goal(
        type: GoalType.weightTarget,
        start: 90,
        target: 80,
      );
      // start=90, target=80, current=81 → progress = (90-81)/(90-80) = 0.9
      final snap = GoalProgressComputer.compute(
        goal: goal,
        currentValue: 81,
      );
      expect(snap.isAlmostThere, isTrue);
      expect(snap.motivationalMessage, contains('Casi llegás'));
      expect(snap.motivationalMessage, contains('1.0 kg'));
    });

    test('progress 0.50..0.85 → "Más de la mitad"', () {
      final goal = _goal(
        type: GoalType.exerciseMinPerDay,
        start: 10,
        target: 30,
      );
      // current=24 → progress = (24-10)/20 = 0.7
      final snap = GoalProgressComputer.compute(
        goal: goal,
        currentValue: 24,
      );
      expect(snap.motivationalMessage, contains('Más de la mitad'));
    });

    test('progress 0.10..0.50 → "X% recorrido"', () {
      final goal = _goal(
        type: GoalType.weightTarget,
        start: 90,
        target: 80,
      );
      // current=87 → progress = (90-87)/10 = 0.3
      final snap = GoalProgressComputer.compute(
        goal: goal,
        currentValue: 87,
      );
      expect(snap.motivationalMessage, contains('30%'));
      expect(snap.motivationalMessage, contains('recorrido'));
    });

    test('progress < 0.10 → "Estás arrancando"', () {
      final goal = _goal(
        type: GoalType.sleepHoursPerNight,
        start: 6,
        target: 8,
      );
      // current=6.1 → progress = (6.1-6)/(8-6) = 0.05
      final snap = GoalProgressComputer.compute(
        goal: goal,
        currentValue: 6.1,
      );
      expect(snap.motivationalMessage, contains('arrancando'));
    });

    test('isReductionGoal (peso/grasa) calcula progreso correcto', () {
      final goal = _goal(
        type: GoalType.bodyFatTarget,
        start: 25,
        target: 18,
      );
      // current=21.5 → progress = (25-21.5)/(25-18) = 0.5
      final snap = GoalProgressComputer.compute(
        goal: goal,
        currentValue: 21.5,
      );
      expect(snap.progress, closeTo(0.5, 0.001));
    });

    test('isIncreaseGoal (sleep/exercise) calcula progreso correcto', () {
      final goal = _goal(
        type: GoalType.hydrationLitersPerDay,
        start: 1.5,
        target: 2.5,
      );
      // current=2.0 → progress = (2.0-1.5)/(2.5-1.5) = 0.5
      final snap = GoalProgressComputer.compute(
        goal: goal,
        currentValue: 2.0,
      );
      expect(snap.progress, closeTo(0.5, 0.001));
    });
  });

  group('SPEC-154 — mensajes de "Casi llegás" por tipo', () {
    test('peso muestra kg', () {
      final goal = _goal(type: GoalType.weightTarget, start: 90, target: 80);
      final snap = GoalProgressComputer.compute(goal: goal, currentValue: 81);
      expect(snap.motivationalMessage, contains('kg'));
    });

    test('hidratación muestra ml', () {
      final goal = _goal(
        type: GoalType.hydrationLitersPerDay,
        start: 1.5,
        target: 2.5,
      );
      // current=2.4 → progress = 0.9, gap = 0.1L = 100ml
      final snap = GoalProgressComputer.compute(goal: goal, currentValue: 2.4);
      expect(snap.motivationalMessage, contains('100 ml'));
    });

    test('ayuno muestra día', () {
      final goal = _goal(
        type: GoalType.fastingDaysPerWeek,
        start: 2,
        target: 5,
      );
      // current=4.5 → progress = (4.5-2)/(5-2) = 0.83 — no entra a "casi llegás"
      // current=4.8 → progress = (4.8-2)/(5-2) = 0.93
      final snap = GoalProgressComputer.compute(goal: goal, currentValue: 4.8);
      expect(snap.motivationalMessage, contains('día'));
    });
  });
}
