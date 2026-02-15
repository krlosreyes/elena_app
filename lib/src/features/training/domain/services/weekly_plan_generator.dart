import '../entities/daily_workout.dart';
import '../enums/workout_enums.dart';

class WeeklyPlanGenerator {
  static List<DailyWorkout> generate(WorkoutGoal goal) {
    switch (goal) {
      case WorkoutGoal.fatLoss:
        return _generateFatLossPlan();
      case WorkoutGoal.recomp:
        return _generateRecompPlan();
      case WorkoutGoal.muscleGain:
        return _generateMuscleGainPlan();
    }
  }

  static List<DailyWorkout> _generateFatLossPlan() {
    return [
      _strengthDay(1, "FullBody A", "RIR 2"),
      _cardioDay(2, 30, "Cardio LISS", "Zona 2"),
      _strengthDay(3, "FullBody B", "RIR 2"),
      _cardioDay(4, 45, "Cardio LISS", "Zona 2"),
      _strengthDay(5, "FullBody C", "RIR 2"),
      _cardioDay(6, 60, "Cardio LISS", "Zona 2"),
      _restDay(7),
    ];
  }

  static List<DailyWorkout> _generateRecompPlan() {
    return [
      _strengthDay(1, "FullBody A", "RIR 1-2"),
      _cardioDay(2, 45, "Cardio LISS", "Zona 2"),
      _strengthDay(3, "FullBody B", "RIR 1-2"),
      _cardioDay(4, 36, "HIIT Nórdico", "4x4 min"),
      _strengthDay(5, "FullBody C", "RIR 1-2"),
      _cardioDay(6, 45, "Cardio LISS", "Zona 2"),
      _restDay(7),
    ];
  }

  static List<DailyWorkout> _generateMuscleGainPlan() {
    return [
      _strengthDay(1, "FullBody Volumen", "RIR 0-1"),
      _cardioDay(2, 30, "Recuperación Activa", "Zona 1-2"),
      _strengthDay(3, "FullBody Volumen", "RIR 0-1"),
      _cardioDay(4, 30, "Recuperación Activa", "Zona 1-2"),
      _strengthDay(5, "FullBody Volumen", "RIR 0-1"),
      _cardioDay(6, 30, "Recuperación Activa", "Zona 1-2"),
      _restDay(7),
    ];
  }

  static DailyWorkout _strengthDay(int day, String desc, String details) {
    return DailyWorkout(
      dayIndex: day,
      type: WorkoutType.strength,
      durationMinutes: 60,
      description: desc,
      details: details,
    );
  }

  static DailyWorkout _cardioDay(int day, int mins, String desc, String details) {
    return DailyWorkout(
      dayIndex: day,
      type: WorkoutType.cardio,
      durationMinutes: mins,
      description: desc,
      details: details,
    );
  }

  static DailyWorkout _restDay(int day) {
    return DailyWorkout(
      dayIndex: day,
      type: WorkoutType.rest,
      durationMinutes: 0,
      description: "Descanso Total",
      details: "Recuperación",
    );
  }
}
