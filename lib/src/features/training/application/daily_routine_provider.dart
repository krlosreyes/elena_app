import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/enums/workout_enums.dart';
import 'selected_day_provider.dart';
import 'weekly_plan_provider.dart';

part 'daily_routine_provider.g.dart';

@riverpod
class DailyRoutine extends _$DailyRoutine {
  @override
  List<Map<String, dynamic>> build() {
    final selectedDay = ref.watch(selectedDayProvider);
    final todayIndex = DateTime.now().weekday;

    // Only show routine if selected day is today
    if (selectedDay != todayIndex) {
      return [];
    }

    // Get the planned workout for today
    final plannedWorkout = ref.watch(todayWorkoutProvider);
    
    // If no plan or not strength, return empty
    if (plannedWorkout == null || plannedWorkout.type != WorkoutType.strength) {
      return [];
    }

    // Determine routine based on description coming from WeeklyPlanGenerator
    final desc = plannedWorkout.description;

    if (desc.contains('FullBody A')) return _routineA();
    if (desc.contains('FullBody B')) return _routineB();
    if (desc.contains('FullBody C')) return _routineC();
    if (desc.contains('Volumen')) return _hypertrophyRoutine();

    // Default fallback
    return _routineA();
  }

  List<Map<String, dynamic>> _routineA() {
    return [
      {
        'id': 'sq_goblet',
        'name': 'Sentadilla Goblet',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '10-12', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '10-12', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '10-12', 'weight': 5.0, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'pushups',
        'name': 'Flexiones (Push-ups)',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': 'Al fallo', 'weight': 0.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': 'Al fallo', 'weight': 0.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': 'Al fallo', 'weight': 0.0, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'rows_db',
        'name': 'Remo con Mancuernas',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '10-12', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '10-12', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '10-12', 'weight': 5.0, 'reps': null, 'isDone': false },
        ]
      },
    ];
  }

  List<Map<String, dynamic>> _routineB() {
    return [
      {
        'id': 'lunges',
        'name': 'Zancadas (Lunges)',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '10 cada lado', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '10 cada lado', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '10 cada lado', 'weight': 5.0, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'oh_press',
        'name': 'Press Militar Mancuernas',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '8-10', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '8-10', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '8-10', 'weight': 5.0, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'lat_pulldown',
        'name': 'Jalón al Pecho (Bandas/Máquina)',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '12-15', 'weight': 15.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '12-15', 'weight': 15.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '12-15', 'weight': 15.0, 'reps': null, 'isDone': false },
        ]
      },
    ];
  }

  List<Map<String, dynamic>> _routineC() {
    return [
      {
        'id': 'rdl',
        'name': 'Peso Muerto Rumano',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '10-12', 'weight': 20.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '10-12', 'weight': 20.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '10-12', 'weight': 20.0, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'bench_press',
        'name': 'Press de Banca (Mancuernas/Barra)',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '8-10', 'weight': 10.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '8-10', 'weight': 10.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '8-10', 'weight': 10.0, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'facepulls',
        'name': 'Face Pulls',
        'targetRir': 3,
        'sets': [
          { 'setIndex': 1, 'targetReps': '15-20', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '15-20', 'weight': 5.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '15-20', 'weight': 5.0, 'reps': null, 'isDone': false },
        ]
      },
    ];
  }

  List<Map<String, dynamic>> _hypertrophyRoutine() {
    return [
      {
        'id': 'squat_heavy',
        'name': 'Sentadilla Trasera',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '6-8', 'weight': 40.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '6-8', 'weight': 40.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '6-8', 'weight': 40.0, 'reps': null, 'isDone': false },
          { 'setIndex': 4, 'targetReps': '6-8', 'weight': 40.0, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'bench_heavy',
        'name': 'Press Banca',
        'targetRir': 2,
        'sets': [
          { 'setIndex': 1, 'targetReps': '6-8', 'weight': 30.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': '6-8', 'weight': 30.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': '6-8', 'weight': 30.0, 'reps': null, 'isDone': false },
          { 'setIndex': 4, 'targetReps': '6-8', 'weight': 30.0, 'reps': null, 'isDone': false },
        ]
      },
      {
        'id': 'pullups_weighted',
        'name': 'Dominadas Lastradas',
        'targetRir': 1,
        'sets': [
          { 'setIndex': 1, 'targetReps': 'Al fallo', 'weight': 0.0, 'reps': null, 'isDone': false },
          { 'setIndex': 2, 'targetReps': 'Al fallo', 'weight': 0.0, 'reps': null, 'isDone': false },
          { 'setIndex': 3, 'targetReps': 'Al fallo', 'weight': 0.0, 'reps': null, 'isDone': false },
        ]
      },
    ];
  }

  void toggleSet(String exerciseId, int setIndex, double? weight, int? reps) {
    // Correct deep copy implementation
    state = state.map((exercise) {
      if (exercise['id'] != exerciseId) return exercise;

      final updatedSets = (exercise['sets'] as List).map((set) {
        if (set['setIndex'] != setIndex) return set;
        
        return {
          ...set,
          'isDone': !set['isDone'],
          'weight': weight, // Update with current value
          'reps': reps,     // Update with current value
        };
      }).toList();

      return {
        ...exercise,
        'sets': updatedSets,
      };
    }).toList();
  }
}
