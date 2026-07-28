// SPEC-203.1 (auditoría onboarding) — tests de los fixes de coherencia del
// GoalSuggestionEngine: piso de ayuno del principiante (3 días) y la zona
// Fitness que ya no sugiere bajar si no se activa.

import 'package:elena_app/src/features/goals/application/goal_suggestion_engine.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  String gender = 'M',
  double weight = 80,
  double? bodyFat,
  double weeklyAdherence = 0,
}) =>
    UserModel(
      age: 30,
      gender: gender,
      weight: weight,
      height: 175,
      exerciseGoalMinutes: 20,
      bodyFatPercentage: bodyFat,
      weeklyAdherence: weeklyAdherence,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 6),
        sleepTime: DateTime(2026, 1, 1, 22),
      ),
    );

void main() {
  GoalSuggestion fasting(UserModel u) =>
      GoalSuggestionEngine.suggest(u)[GoalType.fastingDaysPerWeek]!;
  GoalSuggestion bodyFat(String gender, double bf) =>
      GoalSuggestionEngine.suggest(
          _user(gender: gender, bodyFat: bf))[GoalType.bodyFatTarget]!;

  group('Ayuno — piso de 3 días (SPEC-203.1)', () {
    test('principiante (0 días) → meta 3, no 2', () {
      final s = fasting(_user(weeklyAdherence: 0));
      expect(s.suggestedTarget, 3);
      expect(s.shouldActivate, isTrue);
    });

    test('ya en 6 días → fija 5', () {
      final s = fasting(_user(weeklyAdherence: 6 / 7));
      expect(s.suggestedTarget, 5);
    });
  });

  group('Ejercicio — actividad real (SPEC-203.2)', () {
    GoalSuggestion ex(UserModel u, {double? recent}) =>
        GoalSuggestionEngine.suggest(u,
            recentExerciseMinPerDay: recent)[GoalType.exerciseMinPerDay]!;

    test('sin actividad real → "estimado" (cae al goal)', () {
      final s = ex(_user());
      expect(s.currentValue, 20); // exerciseGoalMinutes default del helper
      expect(s.currentStatusLabel, contains('estimado'));
    });

    test('con actividad real reciente → usa ese valor como actual', () {
      final s = ex(_user(), recent: 42);
      expect(s.currentValue, 42);
      expect(s.currentStatusLabel, isNot(contains('estimado')));
      // SPEC-244: target ya no es un flat "+10 acotado 30-60" — depende del
      // protocolo por zona grasa. Usuario default (M, bf 20% → zona
      // Promedio, minTarget 35): target = (42+5) acotado [35,75] = 47 →
      // redondeo a múltiplo de 5 = 45.
      expect(s.suggestedTarget, 45.0);
    });
  });

  group('Grasa corporal — coherencia activación/objetivo (SPEC-203.1)', () {
    test('hombre Fitness (16%) → mantener (no baja) y NO se activa', () {
      final s = bodyFat('M', 16);
      expect(s.suggestedTarget, 16);
      expect(s.shouldActivate, isFalse);
    });

    test('hombre Promedio (22%) → 17% y se activa', () {
      final s = bodyFat('M', 22);
      expect(s.suggestedTarget, 17);
      expect(s.shouldActivate, isTrue);
    });

    test('hombre Alto (28%) → 20% y se activa', () {
      final s = bodyFat('M', 28);
      expect(s.suggestedTarget, 20);
      expect(s.shouldActivate, isTrue);
    });

    test('mujer Fitness (23%) → mantener y NO se activa', () {
      final s = bodyFat('F', 23);
      expect(s.suggestedTarget, 23);
      expect(s.shouldActivate, isFalse);
    });

    test('mujer Alto (34%) → 28% y se activa', () {
      final s = bodyFat('F', 34);
      expect(s.suggestedTarget, 28);
      expect(s.shouldActivate, isTrue);
    });
  });
}
