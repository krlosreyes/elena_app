import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/interactive_routine.dart';
import '../domain/enums/workout_enums.dart';
import 'selected_day_provider.dart';
import 'weekly_plan_provider.dart';

part 'daily_routine_provider.g.dart';

@riverpod
class DailyRoutine extends _$DailyRoutine {
  @override
  List<InteractiveExercise> build() {
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

  List<InteractiveExercise> _routineA() {
    return [
      const InteractiveExercise(
        id: 'sq_goblet',
        name: 'Sentadilla Goblet',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '10-12', weight: 5.0),
          InteractiveSet(setIndex: 2, targetReps: '10-12', weight: 5.0),
          InteractiveSet(setIndex: 3, targetReps: '10-12', weight: 5.0),
        ],
      ),
      const InteractiveExercise(
        id: 'pushups',
        name: 'Flexiones (Push-ups)',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: 'Al fallo', weight: 0.0),
          InteractiveSet(setIndex: 2, targetReps: 'Al fallo', weight: 0.0),
          InteractiveSet(setIndex: 3, targetReps: 'Al fallo', weight: 0.0),
        ],
      ),
      const InteractiveExercise(
        id: 'rows_db',
        name: 'Remo con Mancuernas',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '10-12', weight: 5.0),
          InteractiveSet(setIndex: 2, targetReps: '10-12', weight: 5.0),
          InteractiveSet(setIndex: 3, targetReps: '10-12', weight: 5.0),
        ],
      ),
    ];
  }

  List<InteractiveExercise> _routineB() {
    return [
      const InteractiveExercise(
        id: 'lunges',
        name: 'Zancadas (Lunges)',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '10 cada lado', weight: 5.0),
          InteractiveSet(setIndex: 2, targetReps: '10 cada lado', weight: 5.0),
          InteractiveSet(setIndex: 3, targetReps: '10 cada lado', weight: 5.0),
        ],
      ),
      const InteractiveExercise(
        id: 'oh_press',
        name: 'Press Militar Mancuernas',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '8-10', weight: 5.0),
          InteractiveSet(setIndex: 2, targetReps: '8-10', weight: 5.0),
          InteractiveSet(setIndex: 3, targetReps: '8-10', weight: 5.0),
        ],
      ),
      const InteractiveExercise(
        id: 'lat_pulldown',
        name: 'Jalón al Pecho (Bandas/Máquina)',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '12-15', weight: 15.0),
          InteractiveSet(setIndex: 2, targetReps: '12-15', weight: 15.0),
          InteractiveSet(setIndex: 3, targetReps: '12-15', weight: 15.0),
        ],
      ),
    ];
  }

  List<InteractiveExercise> _routineC() {
    return [
      const InteractiveExercise(
        id: 'rdl',
        name: 'Peso Muerto Rumano',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '10-12', weight: 20.0),
          InteractiveSet(setIndex: 2, targetReps: '10-12', weight: 20.0),
          InteractiveSet(setIndex: 3, targetReps: '10-12', weight: 20.0),
        ],
      ),
      const InteractiveExercise(
        id: 'bench_press',
        name: 'Press de Banca (Mancuernas/Barra)',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '8-10', weight: 10.0),
          InteractiveSet(setIndex: 2, targetReps: '8-10', weight: 10.0),
          InteractiveSet(setIndex: 3, targetReps: '8-10', weight: 10.0),
        ],
      ),
      const InteractiveExercise(
        id: 'facepulls',
        name: 'Face Pulls',
        targetRir: 3,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '15-20', weight: 5.0),
          InteractiveSet(setIndex: 2, targetReps: '15-20', weight: 5.0),
          InteractiveSet(setIndex: 3, targetReps: '15-20', weight: 5.0),
        ],
      ),
    ];
  }

  List<InteractiveExercise> _hypertrophyRoutine() {
    return [
      const InteractiveExercise(
        id: 'squat_heavy',
        name: 'Sentadilla Trasera',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '6-8', weight: 40.0),
          InteractiveSet(setIndex: 2, targetReps: '6-8', weight: 40.0),
          InteractiveSet(setIndex: 3, targetReps: '6-8', weight: 40.0),
          InteractiveSet(setIndex: 4, targetReps: '6-8', weight: 40.0),
        ],
      ),
      const InteractiveExercise(
        id: 'bench_heavy',
        name: 'Press Banca',
        targetRir: 2,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: '6-8', weight: 30.0),
          InteractiveSet(setIndex: 2, targetReps: '6-8', weight: 30.0),
          InteractiveSet(setIndex: 3, targetReps: '6-8', weight: 30.0),
          InteractiveSet(setIndex: 4, targetReps: '6-8', weight: 30.0),
        ],
      ),
      const InteractiveExercise(
        id: 'pullups_weighted',
        name: 'Dominadas Lastradas',
        targetRir: 1,
        sets: [
          InteractiveSet(setIndex: 1, targetReps: 'Al fallo', weight: 0.0),
          InteractiveSet(setIndex: 2, targetReps: 'Al fallo', weight: 0.0),
          InteractiveSet(setIndex: 3, targetReps: 'Al fallo', weight: 0.0),
        ],
      ),
    ];
  }

  /// Strict 2-level deep copy using Freezed copyWith.
  /// Level 1: Maps over exercises, creates a NEW list reference.
  /// Level 2: Maps over sets within the matched exercise, creates a NEW list reference.
  /// This guarantees Riverpod detects the state change and triggers UI rebuild.
  void toggleSet(String exerciseId, int setIndex, double? weight, int? reps) {
    state = state.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      return exercise.copyWith(
        sets: exercise.sets.map((set) {
          if (set.setIndex != setIndex) return set;
          return set.copyWith(
            isDone: !set.isDone,
            weight: weight ?? set.weight,
            reps: reps,
          );
        }).toList(),
      );
    }).toList(); // <-- Forces Riverpod to detect new List reference
  }
}
