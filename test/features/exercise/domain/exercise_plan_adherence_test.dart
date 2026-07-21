// Tests de ExercisePlanAdherence — propuesta módulo Ejercicio
// (2026-07-21), Fase 5.

import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_plan_adherence.dart';
import 'package:elena_app/src/features/exercise/domain/weekly_exercise_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExerciseLog log({required int min, ExerciseType? type}) => ExerciseLog(
        id: 'x',
        userId: 'u',
        durationMinutes: min,
        activityType: type?.name ?? 'unknown',
        timestamp: DateTime(2026, 7, 20, 16),
        type: type,
      );

  const scheduledStrength = PlanDayEntry(
    weekday: 1,
    type: PlanSessionType.fuerza,
    durationMinutes: 30,
    cardioIntensity: null,
    recommendedPhase: null,
    rationale: '',
  );

  const scheduledCardio = PlanDayEntry(
    weekday: 2,
    type: PlanSessionType.cardio,
    durationMinutes: 25,
    cardioIntensity: CardioIntensity.baja,
    recommendedPhase: null,
    rationale: '',
  );

  const scheduledRest = PlanDayEntry(
    weekday: 7,
    type: PlanSessionType.descanso,
    durationMinutes: 0,
    cardioIntensity: null,
    recommendedPhase: null,
    rationale: '',
  );

  group('ExercisePlanAdherence.evaluate — descanso', () {
    test('Descanso sin registro → restHonored', () {
      final result = ExercisePlanAdherence.evaluate(
        scheduled: scheduledRest,
        loggedToday: const [],
      );
      expect(result, PlanAdherenceLevel.restHonored);
    });

    test('Descanso con registro voluntario → restBrokenVoluntarily', () {
      final result = ExercisePlanAdherence.evaluate(
        scheduled: scheduledRest,
        loggedToday: [log(min: 20, type: ExerciseType.liss)],
      );
      expect(result, PlanAdherenceLevel.restBrokenVoluntarily);
    });
  });

  group('ExercisePlanAdherence.evaluate — día programado', () {
    test('Sin registro → missed', () {
      final result = ExercisePlanAdherence.evaluate(
        scheduled: scheduledStrength,
        loggedToday: const [],
      );
      expect(result, PlanAdherenceLevel.missed);
    });

    test('Tipo y duración correctos → fullMatch', () {
      final result = ExercisePlanAdherence.evaluate(
        scheduled: scheduledStrength,
        loggedToday: [log(min: 30, type: ExerciseType.strength)],
      );
      expect(result, PlanAdherenceLevel.fullMatch);
    });

    test('Duración ≥80% del objetivo → fullMatch', () {
      final result = ExercisePlanAdherence.evaluate(
        scheduled: scheduledStrength,
        loggedToday: [log(min: 24, type: ExerciseType.strength)], // 80%
      );
      expect(result, PlanAdherenceLevel.fullMatch);
    });

    test('Duración <80% del objetivo → partialDuration', () {
      final result = ExercisePlanAdherence.evaluate(
        scheduled: scheduledStrength,
        loggedToday: [log(min: 15, type: ExerciseType.strength)], // 50%
      );
      expect(result, PlanAdherenceLevel.partialDuration);
    });

    test('Tipo incorrecto (tocaba fuerza, se hizo cardio) → wrongType', () {
      final result = ExercisePlanAdherence.evaluate(
        scheduled: scheduledStrength,
        loggedToday: [log(min: 30, type: ExerciseType.liss)],
      );
      expect(result, PlanAdherenceLevel.wrongType);
    });

    test('Cardio con HIIT o LISS ambos cuentan como tipo correcto', () {
      final resultLiss = ExercisePlanAdherence.evaluate(
        scheduled: scheduledCardio,
        loggedToday: [log(min: 25, type: ExerciseType.liss)],
      );
      final resultHiit = ExercisePlanAdherence.evaluate(
        scheduled: scheduledCardio,
        loggedToday: [log(min: 25, type: ExerciseType.hiit)],
      );
      expect(resultLiss, PlanAdherenceLevel.fullMatch);
      expect(resultHiit, PlanAdherenceLevel.fullMatch);
    });

    test('Log legacy sin type → beneficio de la duda (fullMatch si dura lo suficiente)',
        () {
      final result = ExercisePlanAdherence.evaluate(
        scheduled: scheduledStrength,
        loggedToday: [log(min: 30)],
      );
      expect(result, PlanAdherenceLevel.fullMatch);
    });
  });
}
