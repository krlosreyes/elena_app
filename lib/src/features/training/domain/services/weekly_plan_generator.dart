import '../entities/daily_workout.dart';
import '../entities/training_entities.dart';
// import '../enums/workout_enums.dart'; // Removed to avoid conflict

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
        case 'A':
          return [
            const RoutineExercise(id: 'goblet_squat', name: 'Sentadilla Goblet', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'db_press_stand', name: 'Press Militar (Pie)', sets: 3, targetReps: '8-10', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'db_row_one', name: 'Remo a una mano', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'lunges_db', name: 'Zancadas c/Mancuernas', sets: 3, targetReps: '10/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'floor_press', name: 'Press de Pecho (Suelo)', sets: 3, targetReps: '10-15', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'plank', name: 'Plank Abdominal', sets: 3, targetReps: '45-60s', rir: 0, restSeconds: 45),
          ];
        case 'B':
          return [
            const RoutineExercise(id: 'rdl_db', name: 'Peso Muerto Rumano', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'pushups_weighted', name: 'Flexiones (Lastre/Deficit)', sets: 3, targetReps: 'Al fallo', rir: 1, restSeconds: 90),
            const RoutineExercise(id: 'db_pullover', name: 'Pullover Mancuerna', sets: 3, targetReps: '12-15', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'step_ups', name: 'Subidas al Cajón (Step-Ups)', sets: 3, targetReps: '10/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'lateral_raises', name: 'Elevaciones Laterales', sets: 3, targetReps: '15-20', rir: 1, restSeconds: 45),
            const RoutineExercise(id: 'leg_raises', name: 'Elevación de Piernas', sets: 3, targetReps: '15-20', rir: 1, restSeconds: 45),
          ];
        case 'C':
          return [
            const RoutineExercise(id: 'thrusters', name: 'Thrusters (Sentadilla+Press)', sets: 3, targetReps: '10-12', rir: 2, restSeconds: 120),
            const RoutineExercise(id: 'renegade_row', name: 'Remo Renegado', sets: 3, targetReps: '8-10/lado', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'glute_bridge_db', name: 'Puente Glúteo c/Peso', sets: 3, targetReps: '12-15', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'push_press_db', name: 'Push Press', sets: 3, targetReps: '8-10', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'bicep_curl_hammer', name: 'Curl Martillo', sets: 3, targetReps: '12-15', rir: 1, restSeconds: 45),
            const RoutineExercise(id: 'russian_twist', name: 'Giros Rusos', sets: 3, targetReps: '20/lado', rir: 1, restSeconds: 45),
          ];
      }
    } else {
      // Bodyweight / Calisthenics
      switch (routine) {
        case 'A':
          return [
            const RoutineExercise(id: 'air_squat', name: 'Sentadilla Aire (Air Squat)', sets: 4, targetReps: '20-25', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'pushups_std', name: 'Flexiones Estándar', sets: 4, targetReps: 'Al fallo', rir: 1, restSeconds: 90),
            const RoutineExercise(id: 'superman_pull', name: 'Superman Pull (Suelo)', sets: 3, targetReps: '15-20', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'lunges_bw', name: 'Zancadas (Alternas)', sets: 3, targetReps: '15/pierna', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'dips_chair', name: 'Fondos en silla/banco', sets: 3, targetReps: '12-15', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'bicycle_crunches', name: 'Abdominales Bicicleta', sets: 3, targetReps: '20/lado', rir: 1, restSeconds: 45),
          ];
        case 'B':
          return [
            const RoutineExercise(id: 'glute_bridge_bw', name: 'Puente de Glúteo (1 pierna)', sets: 3, targetReps: '12-15/lado', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'pike_pushups', name: 'Flexiones Pike (Hombro)', sets: 3, targetReps: '8-12', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'door_frame_rows', name: 'Remo en Marco Puerta', sets: 3, targetReps: '12-15', rir: 2, restSeconds: 60),
            const RoutineExercise(id: 'bulgarian_split', name: 'Sentadilla Búlgara', sets: 3, targetReps: '8-12/lado', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'diamond_pushups', name: 'Flexiones Diamante', sets: 3, targetReps: 'Al fallo', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'mountain_climbers', name: 'Escaladores', sets: 3, targetReps: '45s', rir: 0, restSeconds: 45),
          ];
        case 'C':
          return [
            const RoutineExercise(id: 'burpees', name: 'Burpees (Sin salto)', sets: 3, targetReps: '10-15', rir: 2, restSeconds: 90),
            const RoutineExercise(id: 'plank_shoulder_tap', name: 'Plank c/Toque Hombro', sets: 3, targetReps: '20 taps', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'single_leg_rdl_bw', name: 'Peso Muerto 1 Pierna (Eq)', sets: 3, targetReps: '10/lado', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'bear_crawl', name: 'Caminata de Oso', sets: 3, targetReps: '30s', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'tricep_ext_floor', name: 'Extensión Tríceps Suelo', sets: 3, targetReps: '10-12', rir: 1, restSeconds: 60),
            const RoutineExercise(id: 'hollow_body', name: 'Hollow Body Hold', sets: 3, targetReps: '30-45s', rir: 0, restSeconds: 45),
          ];
      }
    }
    return [];
  }
}
