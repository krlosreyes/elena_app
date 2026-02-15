import '../entities/daily_workout.dart';
import '../enums/workout_enums.dart';

class WeeklyPlanGenerator {
  static List<DailyWorkout> generate(WorkoutGoal goal, {required int age}) {
    // Calculate Max HR
    final maxHr = 220 - age;
    final zone2Low = (maxHr * 0.60).round();
    final zone2High = (maxHr * 0.70).round();
    final zone2String = "Zona 2 ($zone2Low-$zone2High BPM)";

    switch (goal) {
      case WorkoutGoal.fatLoss:
        return _generateFatLossPlan(zone2String);
      case WorkoutGoal.recomp:
      case WorkoutGoal.metabolic_health: // Map to recomp or similar
        return _generateRecompPlan(zone2String);
      case WorkoutGoal.muscleGain:
        return _generateMuscleGainPlan(zone2String);
    }
  }

  static List<DailyWorkout> _generateFatLossPlan(String zone2) {
    return [
      _strengthDay(1, "FullBody A", "RIR 2"),
      _cardioDay(2, 30, "Cardio LISS", zone2),
      _strengthDay(3, "FullBody B", "RIR 2"),
      _cardioDay(4, 45, "Cardio LISS", zone2),
      _strengthDay(5, "FullBody C", "RIR 2"),
      _cardioDay(6, 60, "Cardio LISS", zone2),
      _restDay(7),
    ];
  }

  static List<DailyWorkout> _generateRecompPlan(String zone2) {
    return [
      _strengthDay(1, "FullBody A", "RIR 1-2"),
      _cardioDay(2, 45, "Cardio LISS", zone2),
      _strengthDay(3, "FullBody B", "RIR 1-2"),
      _cardioDay(4, 36, "HIIT Nórdico", "4x4 min"),
      _strengthDay(5, "FullBody C", "RIR 1-2"),
      _cardioDay(6, 45, "Cardio LISS", zone2),
      _restDay(7),
    ];
  }

  static List<DailyWorkout> _generateMuscleGainPlan(String zone2) {
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
