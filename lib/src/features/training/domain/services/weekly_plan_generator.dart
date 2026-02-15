import '../entities/daily_workout.dart';
import '../entities/training_entities.dart';
import '../enums/workout_enums.dart';

class WeeklyPlanGenerator {
  static List<DailyWorkout> generate(WorkoutGoal goal, {required int age, required bool hasDumbbells}) {
    // Calculate Max HR
    final maxHr = 220 - age;
    final zone2Low = (maxHr * 0.60).round();
    final zone2High = (maxHr * 0.70).round();
    final zone2String = "Zona 2 ($zone2Low-$zone2High BPM)";

    switch (goal) {
      case WorkoutGoal.fatLoss:
        return _generateFatLossPlan(zone2String, hasDumbbells);
      case WorkoutGoal.recomp:
      case WorkoutGoal.metabolic_health:
        return _generateRecompPlan(zone2String, hasDumbbells);
      case WorkoutGoal.muscleGain:
        return _generateMuscleGainPlan(zone2String, hasDumbbells);
    }
  }

  static List<DailyWorkout> _generateFatLossPlan(String zone2, bool hasDumbbells) {
    return [
      _strengthDay(1, "FullBody A", "RIR 2", hasDumbbells, 'A'),
      _cardioDay(2, 30, "Cardio LISS", zone2),
      _strengthDay(3, "FullBody B", "RIR 2", hasDumbbells, 'B'),
      _cardioDay(4, 45, "Cardio LISS", zone2),
      _strengthDay(5, "FullBody C", "RIR 2", hasDumbbells, 'C'),
      _cardioDay(6, 60, "Cardio LISS", zone2),
      _restDay(7),
    ];
  }

  static List<DailyWorkout> _generateRecompPlan(String zone2, bool hasDumbbells) {
    return [
      _strengthDay(1, "FullBody A", "RIR 1-2", hasDumbbells, 'A'),
      _cardioDay(2, 45, "Cardio LISS", zone2),
      _strengthDay(3, "FullBody B", "RIR 1-2", hasDumbbells, 'B'),
      _cardioDay(4, 36, "HIIT Nórdico", "4x4 min"),
      _strengthDay(5, "FullBody C", "RIR 1-2", hasDumbbells, 'C'),
      _cardioDay(6, 45, "Cardio LISS", zone2),
      _restDay(7),
    ];
  }

  static List<DailyWorkout> _generateMuscleGainPlan(String zone2, bool hasDumbbells) {
    return [
      _strengthDay(1, "FullBody Volumen A", "RIR 0-1", hasDumbbells, 'A'),
      _cardioDay(2, 30, "Recuperación Activa", "Zona 1-2"),
      _strengthDay(3, "FullBody Volumen B", "RIR 0-1", hasDumbbells, 'B'),
      _cardioDay(4, 30, "Recuperación Activa", "Zona 1-2"),
      _strengthDay(5, "FullBody Volumen C", "RIR 0-1", hasDumbbells, 'C'),
      _cardioDay(6, 30, "Recuperación Activa", "Zona 1-2"),
      _restDay(7),
    ];
  }

  static DailyWorkout _strengthDay(int day, String desc, String details, bool hasDumbbells, String routineType) {
    return DailyWorkout(
      dayIndex: day,
      type: WorkoutType.strength,
      durationMinutes: 60,
      description: desc,
      details: details,
      exercises: _getExercisesFor(routineType, hasDumbbells),
    );
  }

  static DailyWorkout _cardioDay(int day, int mins, String desc, String details) {
    return DailyWorkout(
      dayIndex: day,
      type: WorkoutType.cardio,
      durationMinutes: mins,
      description: desc,
      details: details,
      exercises: [],
    );
  }

  static DailyWorkout _restDay(int day) {
    return DailyWorkout(
      dayIndex: day,
      type: WorkoutType.rest,
      durationMinutes: 0,
      description: "Descanso Total",
      details: "Recuperación",
      exercises: [],
    );
  }

  // --- Exercise Database ---

  static List<RoutineExercise> _getExercisesFor(String routine, bool hasDumbbells) {
    if (hasDumbbells) {
      switch (routine) {
        case 'A': // Lunes: Empuje/Pierna Dominante
          return [
            const RoutineExercise(id: 'goblet_squat', name: 'Sentadilla Goblet', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'floor_press_db', name: 'Press de Pecho (Suelo)', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'one_arm_row', name: 'Remo a una mano', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'lunges_db', name: 'Estocadas con Mancuernas', sets: 3, targetReps: '10/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'shoulder_press_seated', name: 'Press Militar Sentado', sets: 3, targetReps: '8-10', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'plank', name: 'Plancha Abdominal', sets: 3, targetReps: '45-60s', rir: 0, restSeconds: 45),
          ];
        case 'B': // Miércoles: Tracción/Cadera Dominante
          return [
            const RoutineExercise(id: 'rdl_db', name: 'Peso Muerto Rumano', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'inclined_row_db', name: 'Remo Inclinado (2 manos)', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'step_ups_db', name: 'Step-ups (Silla/Banco)', sets: 3, targetReps: '10/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'inclined_press_db', name: 'Press Inclinado (o Puente)', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'bicep_curl_press', name: 'Curl de Bíceps + Press', sets: 3, targetReps: '10-12', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'deadbug', name: 'Deadbug (Core)', sets: 3, targetReps: '12-15', rir: 1, restSeconds: 45),
          ];
        case 'C': // Viernes: Híbrido/Accesorios
          return [
            const RoutineExercise(id: 'sumo_squat_db', name: 'Sentadilla Sumo', sets: 3, targetReps: '12-15', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'dips_chair', name: 'Fondos de Tríceps (Silla)', sets: 3, targetReps: 'Al fallo', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'lateral_lunges_db', name: 'Zancada Lateral', sets: 3, targetReps: '10/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'lateral_raises', name: 'Pájaros/Vuelos Laterales', sets: 3, targetReps: '15-20', rir: 1, restSeconds: 45),
            const RoutineExercise(id: 'woodchoppers', name: 'Woodchoppers (Leñador)', sets: 3, targetReps: '15/lado', rir: 1, restSeconds: 45),
            const RoutineExercise(id: 'mountain_climbers', name: 'Escaladores', sets: 3, targetReps: '45s', rir: 0, restSeconds: 45),
          ];
      }
    } else {
      // Bodyweight / Calisthenics
      switch (routine) {
        case 'A':
          return [
            const RoutineExercise(id: 'air_squat', name: 'Sentadilla Aire (Bodyweight)', sets: 4, targetReps: '20-25', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'pushups_std', name: 'Flexiones (Push-ups)', sets: 4, targetReps: 'Al fallo', rir: 1, restSeconds: 90),
            const RoutineExercise(id: 'inverted_row_table', name: 'Remo Invertido (Mesa)', sets: 3, targetReps: 'Al fallo', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'lunges_bw', name: 'Estocadas (Alternas)', sets: 3, targetReps: '15/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'pike_pushups', name: 'Pike Pushups (Hombro)', sets: 3, targetReps: '8-12', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'plank', name: 'Plancha Abdominal', sets: 3, targetReps: '60s', rir: 0, restSeconds: 45),
          ];
        case 'B':
          return [
            const RoutineExercise(id: 'single_leg_glute_bridge', name: 'Puente Glúteo 1 Pierna', sets: 3, targetReps: '15/lado', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'superman', name: 'Superman (Extensiones)', sets: 3, targetReps: '15-20', rir: 1, restSeconds: 45),
            const RoutineExercise(id: 'step_ups_bw', name: 'Step-ups (Silla/Banco)', sets: 3, targetReps: '15/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'decline_pushups', name: 'Flexiones Pies Elevados', sets: 3, targetReps: 'Al fallo', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'backpack_curl', name: 'Curl con Mochila/Resistencia', sets: 3, targetReps: '15-20', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'deadbug', name: 'Deadbug (Core)', sets: 3, targetReps: '15-20', rir: 1, restSeconds: 45),
          ];
        case 'C':
          return [
            const RoutineExercise(id: 'sumo_squat_bw', name: 'Sentadilla Sumo (BW)', sets: 3, targetReps: '20-25', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'dips_chair', name: 'Fondos de Tríceps (Silla)', sets: 3, targetReps: 'Al fallo', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'lateral_lunges_bw', name: 'Zancada Lateral', sets: 3, targetReps: '12/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'lateral_raises_bottle', name: 'Elevaciones Laterales (Botellas)', sets: 3, targetReps: '20-25', rir: 1, restSeconds: 45),
            const RoutineExercise(id: 'trunk_rotations', name: 'Rotaciones de Tronco', sets: 3, targetReps: '20/lado', rir: 0, restSeconds: 45),
            const RoutineExercise(id: 'mountain_climbers', name: 'Escaladores', sets: 3, targetReps: '60s', rir: 0, restSeconds: 45),
          ];
      }
    }
    return [];
  }
}
