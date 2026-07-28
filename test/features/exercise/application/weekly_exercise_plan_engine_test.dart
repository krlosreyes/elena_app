// Tests de WeeklyExercisePlanEngine — propuesta módulo Ejercicio
// (2026-07-21), Fase 2.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/analysis/domain/body_zone.dart';
import 'package:elena_app/src/features/exercise/application/weekly_exercise_plan_engine.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_profile.dart';
import 'package:elena_app/src/features/exercise/domain/weekly_exercise_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseProfile = ExerciseProfile.initial();

  group('WeeklyExercisePlanEngine.generate — estructura básica', () {
    test('Siempre produce exactamente 7 días', () {
      for (final zone in BodyZone.values) {
        final plan = WeeklyExercisePlanEngine.generate(
          zone: zone,
          isExcited: false,
          profile: baseProfile,
        );
        expect(plan.days.length, 7, reason: 'zone=$zone');
      }
    });

    test('Los días están ordenados de lunes (1) a domingo (7)', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: baseProfile,
      );
      for (var i = 0; i < 7; i++) {
        expect(plan.days[i].weekday, i + 1);
      }
    });

    test('Exactamente 1 día de descanso por semana', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.fitness,
        isExcited: false,
        profile: baseProfile,
      );
      final rest = plan.days.where((d) => d.type == PlanSessionType.descanso);
      expect(rest.length, 1);
    });

    test('Sin disponibilidad declarada, el descanso cae en domingo', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: baseProfile,
      );
      final rest = plan.days.firstWhere(
        (d) => d.type == PlanSessionType.descanso,
      );
      expect(rest.weekday, 7);
    });

    test('Con 6 días disponibles declarados, el descanso es el 7mo', () {
      final profile = baseProfile.copyWith(
        availableWeekdays: [1, 2, 3, 4, 5, 6], // libre lun-sáb
      );
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: profile,
      );
      final rest = plan.days.firstWhere(
        (d) => d.type == PlanSessionType.descanso,
      );
      expect(rest.weekday, 7);

      final profileMonOff = baseProfile.copyWith(
        availableWeekdays: [2, 3, 4, 5, 6, 7], // libre mar-dom, descansa lunes
      );
      final planMonOff = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: profileMonOff,
      );
      final restMonOff = planMonOff.days.firstWhere(
        (d) => d.type == PlanSessionType.descanso,
      );
      expect(restMonOff.weekday, 1);
    });
  });

  group('WeeklyExercisePlanEngine.generate — split por zona (§4.2)', () {
    test('Zona Alto: 3 fuerza + 3 cardio', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.alto,
        isExcited: false,
        profile: baseProfile,
      );
      expect(plan.fuerzaCount, 3);
      expect(plan.cardioCount, 3);
    });

    test('Zona Promedio: 4 fuerza + 2 cardio', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: baseProfile,
      );
      expect(plan.fuerzaCount, 4);
      expect(plan.cardioCount, 2);
    });

    test('Zona Fitness: 4 fuerza + 2 cardio', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.fitness,
        isExcited: false,
        profile: baseProfile,
      );
      expect(plan.fuerzaCount, 4);
      expect(plan.cardioCount, 2);
    });

    test('Zona Atlético: 5 fuerza + 1 cardio', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.atletico,
        isExcited: false,
        profile: baseProfile,
      );
      expect(plan.fuerzaCount, 5);
      expect(plan.cardioCount, 1);
    });

    test('Todas las zonas suman 6 días activos + 1 descanso', () {
      for (final zone in BodyZone.values) {
        final plan = WeeklyExercisePlanEngine.generate(
          zone: zone,
          isExcited: false,
          profile: baseProfile,
        );
        expect(plan.fuerzaCount + plan.cardioCount, 6, reason: 'zone=$zone');
      }
    });
  });

  group('WeeklyExercisePlanEngine.generate — sistema nervioso excitado', () {
    test('Excitado → todo el cardio es baja intensidad (zona 2)', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.alto,
        isExcited: true,
        profile: baseProfile,
      );
      final cardioDays =
          plan.days.where((d) => d.type == PlanSessionType.cardio);
      expect(
        cardioDays.every((d) => d.cardioIntensity == CardioIntensity.baja),
        isTrue,
      );
    });

    test('No excitado + ≥2 cardio → exactamente 1 sesión HIIT', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.alto, // 3 cardio
        isExcited: false,
        profile: baseProfile,
      );
      final hiitDays = plan.days.where(
        (d) =>
            d.type == PlanSessionType.cardio &&
            d.cardioIntensity == CardioIntensity.alta,
      );
      expect(hiitDays.length, 1);
    });

    test('Zona Atlético (1 solo cardio) nunca es HIIT aunque no esté excitado',
        () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.atletico,
        isExcited: false,
        profile: baseProfile,
      );
      final cardioDay = plan.days.firstWhere(
        (d) => d.type == PlanSessionType.cardio,
      );
      expect(cardioDay.cardioIntensity, CardioIntensity.baja);
    });
  });

  group('WeeklyExercisePlanEngine.generate — fase circadiana (§4.3)', () {
    test('Toda sesión de fuerza recomienda fase motorFuerza', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: baseProfile,
      );
      final fuerzaDays =
          plan.days.where((d) => d.type == PlanSessionType.fuerza);
      expect(
        fuerzaDays
            .every((d) => d.recommendedPhase == CircadianPhase.motorFuerza),
        isTrue,
      );
    });

    test('El día de descanso no tiene fase recomendada', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: baseProfile,
      );
      final rest = plan.days.firstWhere(
        (d) => d.type == PlanSessionType.descanso,
      );
      expect(rest.recommendedPhase, isNull);
    });
  });

  group('WeeklyExercisePlanEngine.generate — experiencia y duración', () {
    test('Sin experiencia de fuerza → sesiones más cortas que avanzado', () {
      final beginner = baseProfile.copyWith(
        strengthExperience: ExerciseExperienceLevel.none,
      );
      final advanced = baseProfile.copyWith(
        strengthExperience: ExerciseExperienceLevel.moreThan2Years,
      );
      final planBeginner = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: beginner,
      );
      final planAdvanced = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: advanced,
      );
      final beginnerMinutes = planBeginner.days
          .firstWhere((d) => d.type == PlanSessionType.fuerza)
          .durationMinutes;
      final advancedMinutes = planAdvanced.days
          .firstWhere((d) => d.type == PlanSessionType.fuerza)
          .durationMinutes;
      expect(beginnerMinutes, lessThan(advancedMinutes));
    });
  });

  group('WeeklyExercisePlanEngine.generate — lesiones (§4.5)', () {
    test('Con lesión declarada, el rationale de fuerza menciona seguridad', () {
      final injured = baseProfile.copyWith(
        injuries: [InjuryTag.rodilla],
      );
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: injured,
      );
      final fuerzaDay = plan.days.firstWhere(
        (d) => d.type == PlanSessionType.fuerza,
      );
      expect(fuerzaDay.rationale.toLowerCase(), contains('molestias'));
    });
  });

  group('WeeklyExercisePlan.entryFor', () {
    test('Devuelve la entrada del weekday correspondiente', () {
      final plan = WeeklyExercisePlanEngine.generate(
        zone: BodyZone.promedio,
        isExcited: false,
        profile: baseProfile,
      );
      final monday = DateTime(2026, 7, 20); // lunes
      expect(plan.entryFor(monday).weekday, 1);
      final sunday = DateTime(2026, 7, 26); // domingo
      expect(plan.entryFor(sunday).weekday, 7);
    });
  });
}
