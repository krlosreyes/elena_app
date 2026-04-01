import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import '../domain/entities/routine_cycle.dart';
import '../domain/entities/training_entities.dart';

part 'routine_factory_provider.g.dart';

@riverpod
RoutineFactory routineFactory(RoutineFactoryRef ref) {
  return RoutineFactory();
}

class RoutineFactory {
  /// Entry point to generate the 8-week cycle based on user profile.
  RoutineCycle generateCycle(UserModel user, DateTime startDate) {
    // Strategy selection based on goal and equipment.
    // For now, we seed: Body Recomposition - No Dumbbells (Bodyweight)

    // In the future, you can implement specific strategies
    // if (goal == HealthGoal.muscleGain && hasDumbbells) return buildMuscleGainDumbbells(...);

    return _buildBodyRecompNoDumbbells(startDate);
  }

  RoutineCycle _buildBodyRecompNoDumbbells(DateTime startDate) {
    List<RoutineWeek> weeks = [];

    // Generate 8 weeks
    for (int weekNum = 1; weekNum <= 8; weekNum++) {
      bool isDeload = (weekNum == 5);

      List<RoutineDay> days = [];

      // Seed week logic:
      // Day 1: Full Body (Strength)
      // Day 2: Cardio Zona 2
      // Day 3: Full Body (Strength)
      // Day 4: Cardio Zona 2
      // Day 5: Full Body (Strength)
      // Day 6: Cardio Zona 2
      // Day 7: Active Rest

      for (int dayNum = 1; dayNum <= 7; dayNum++) {
        if (dayNum == 1 || dayNum == 3 || dayNum == 5) {
          // Strength Day
          days.add(_buildStrengthDay(
              dayNumber: dayNum, weekNumber: weekNum, isDeload: isDeload));
        } else if (dayNum == 2 || dayNum == 4 || dayNum == 6) {
          // Cardio Day
          days.add(RoutineDay(
            dayNumber: dayNum,
            isRestDay: false,
            type: 'Cardio Zona 2',
            description: '45 minutos de caminata a ritmo moderado (MAFF)',
            exercises: [],
          ));
        } else {
          // Rest Day
          days.add(RoutineDay(
            dayNumber: dayNum,
            isRestDay: true,
            type: 'Descanso / Movilidad',
            description: 'Recuperación activa o descanso total.',
            exercises: [],
          ));
        }
      }

      weeks.add(RoutineWeek(
        weekNumber: weekNum,
        isDeload: isDeload,
        days: days,
      ));
    }

    return RoutineCycle(
      startDate: startDate,
      weeks: weeks,
      goalDescriptive: "Recomposición Corporal - Sin Mancuernas",
    );
  }

  /// Helper to build a standard Full Body strength day
  RoutineDay _buildStrengthDay(
      {required int dayNumber,
      required int weekNumber,
      required bool isDeload}) {
    // Base volume parameters for Week 1
    int baseSets = 3;

    // Progressive Overload Logic: increase slightly over weeks 1-4, 6-8.
    // E.g., week 1-2: 3 sets, week 3-4: 4 sets.
    int targetSets = baseSets;
    if (weekNumber >= 3 && weekNumber != 5) targetSets = 4;
    if (weekNumber >= 7) targetSets = 5;

    // Week 5 Deload Rule: 50% Volume
    if (isDeload) {
      targetSets = (targetSets / 2).ceil();
      if (targetSets < 1) targetSets = 1;
    }

    // Define the exercises for a typical bodyweight full-body routine
    List<RoutineExercise> exercises = [
      RoutineExercise(
        id: 'bw_squat',
        name: 'Sentadillas con Peso Corporal',
        sets: targetSets,
        targetReps: '12-15',
        rir: isDeload ? 4 : 2, // Leave more reps in reserve during deload
        restSeconds: 90,
        targetMuscle: 'Piernas',
        requiresWeight: false,
      ),
      RoutineExercise(
        id: 'bw_pushup',
        name: 'Flexiones (Push-ups) de pecho',
        sets: targetSets,
        targetReps: '8-12',
        rir: isDeload ? 4 : 2,
        restSeconds: 90,
        targetMuscle: 'Pecho/Tríceps',
        requiresWeight: false,
      ),
      RoutineExercise(
        id: 'bw_lunges',
        name: 'Zancadas (Desplantes)',
        sets: targetSets,
        targetReps: '10-12 / pierna',
        rir: isDeload ? 4 : 2,
        restSeconds: 90,
        targetMuscle: 'Piernas',
        requiresWeight: false,
      ),
      RoutineExercise(
        id: 'bw_plank',
        name: 'Plancha Abdominal (Isométrica)',
        sets: targetSets,
        targetReps: isDeload ? '30 seg' : '45-60 seg',
        rir: 0,
        restSeconds: 60,
        targetMuscle: 'Core',
        requiresWeight: false,
      ),
    ];

    return RoutineDay(
      dayNumber: dayNumber,
      isRestDay: false,
      type: 'Full Body',
      description: 'Entrenamiento de fuerza general para recomposición.',
      exercises: exercises,
    );
  }
}
