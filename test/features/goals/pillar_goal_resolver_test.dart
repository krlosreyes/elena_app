// BUGFIX objetivos — tests del PillarGoalResolver (goals SoT + fallback).

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_resolver.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

UserModel _user({int exGoal = 20, double weight = 80}) => UserModel(
      age: 30,
      gender: 'M',
      weight: weight,
      height: 175,
      exerciseGoalMinutes: exGoal,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 6),
        sleepTime: DateTime(2026, 1, 1, 22),
      ),
    );

UserGoal _goal(GoalType t, double v, {bool active = true}) => UserGoal(
      type: t,
      targetValue: v,
      startValue: 0,
      createdAt: DateTime(2026, 1, 1),
      isActive: active,
    );

void main() {
  group('PillarGoalResolver.exerciseMinutes', () {
    test('goal activo manda sobre el UserModel', () {
      final goals = <GoalType, UserGoal>{
        GoalType.exerciseMinPerDay: _goal(GoalType.exerciseMinPerDay, 40),
      };
      expect(PillarGoalResolver.exerciseMinutes(goals, _user(exGoal: 20)), 40);
    });

    test('sin goal → fallback al UserModel', () {
      expect(PillarGoalResolver.exerciseMinutes(const {}, _user(exGoal: 25)), 25);
    });

    test('goal inactivo se ignora (fallback)', () {
      final goals = <GoalType, UserGoal>{
        GoalType.exerciseMinPerDay:
            _goal(GoalType.exerciseMinPerDay, 40, active: false),
      };
      expect(PillarGoalResolver.exerciseMinutes(goals, _user(exGoal: 25)), 25);
    });
  });

  group('PillarGoalResolver.sleepHours', () {
    test('goal activo manda', () {
      final goals = <GoalType, UserGoal>{
        GoalType.sleepHoursPerNight: _goal(GoalType.sleepHoursPerNight, 7.0),
      };
      expect(PillarGoalResolver.sleepHours(goals), 7.0);
    });

    test('sin goal → default 8h', () {
      expect(PillarGoalResolver.sleepHours(const {}), 8.0);
    });

    test('goal inactivo se ignora', () {
      final goals = <GoalType, UserGoal>{
        GoalType.sleepHoursPerNight:
            _goal(GoalType.sleepHoursPerNight, 6.0, active: false),
      };
      expect(PillarGoalResolver.sleepHours(goals), 8.0);
    });
  });

  group('PillarGoalResolver.hydrationLiters', () {
    test('goal activo manda', () {
      final goals = <GoalType, UserGoal>{
        GoalType.hydrationLitersPerDay:
            _goal(GoalType.hydrationLitersPerDay, 3.0),
      };
      expect(
        PillarGoalResolver.hydrationLiters(goals, _user(weight: 80)),
        3.0,
      );
    });

    test('sin goal → fórmula por peso (35 ml/kg)', () {
      expect(
        PillarGoalResolver.hydrationLiters(const {}, _user(weight: 80)),
        2.8,
      );
    });
  });
}
