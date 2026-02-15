import 'package:flutter/foundation.dart';
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
      // For debugging/testing: Return routine A instead of empty
      // return []; 
      return _routineA(); 
    }

    // Get the planned workout for today
    final plannedWorkout = ref.watch(todayWorkoutProvider);
    
    // If no plan or not strength, return empty
    if (plannedWorkout == null || plannedWorkout.type != WorkoutType.strength) {
       // For debugging/testing: Return routine A
      // return [];
      return _routineA();
    }

    // Determine routine based on description coming from WeeklyPlanGenerator
    final desc = plannedWorkout.description;

    // Use exercises from the plan if available (Equipment-based logic)
    if (plannedWorkout.exercises.isNotEmpty) {
      return plannedWorkout.exercises.map((e) {
        return InteractiveExercise(
          id: e.id,
          name: e.name,
          targetRir: e.rir,
          sets: List.generate(e.sets, (index) => InteractiveSet(
            setIndex: index + 1,
            targetReps: e.targetReps,
            // Default weight based on equipment? 
            // If bodyweight, 0. If dumbbells, maybe 5-10kg or user history. 
            // For now default to 0 for bodyweight exercises (usually) or small weight
            weight: 0.0, 
            isDone: false,
          )),
        );
      }).toList();
    }

    // Legacy fallback (shouldn't be reached if generator works)
    if (desc.contains('FullBody A')) return _routineA();
    if (desc.contains('FullBody B')) return _routineB();
    if (desc.contains('FullBody C')) return _routineC();
    if (desc.contains('Volumen')) return _hypertrophyRoutine();

    return _routineA();
  }

  // Legacy Routines (kept as fallback for old plans or errors)
  List<InteractiveExercise> _routineA() {
    return [
      const InteractiveExercise(
        id: 'sq_goblet',
        name: 'Sentadilla Goblet (Legacy)',
        targetRir: 2,
        sets: [
           InteractiveSet(setIndex: 1, targetReps: '10-12', weight: 5.0),
           InteractiveSet(setIndex: 2, targetReps: '10-12', weight: 5.0),
           InteractiveSet(setIndex: 3, targetReps: '10-12', weight: 5.0),
        ]
      )
    ];
  }
  
  List<InteractiveExercise> _routineB() => []; // Placeholder
  List<InteractiveExercise> _routineC() => []; // Placeholder
  List<InteractiveExercise> _hypertrophyRoutine() => []; // Placeholder

  /// NUCLEAR REWRITE: Explicit list comprehensions for guaranteed immutability.
  /// This forces Riverpod to detect changes at BOTH list levels.
  void toggleSet(String exerciseId, int setIndex, double? weight, int? reps) {
    // Log the toggle request
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[DailyRoutine] toggleSet called:');
    debugPrint('  exerciseId: $exerciseId');
    debugPrint('  setIndex: $setIndex');
    debugPrint('  weight: $weight');
    debugPrint('  reps: $reps');
    
    // Verify exercise exists in state (prevents crash if UI shows mock data)
    final exists = state.any((e) => e.id == exerciseId);
    if (!exists) {
      debugPrint('[DailyRoutine] ⚠️ Exercise $exerciseId not found in state (likely mock data). Ignoring toggle.');
      debugPrint('  Current state IDs: ${state.map((e) => e.id).toList()}');
      return;
    }

    // Find the exercise and set BEFORE mutation
    final targetExercise = state.firstWhere((e) => e.id == exerciseId);
    final targetSet = targetExercise.sets.firstWhere((s) => s.setIndex == setIndex);
    debugPrint('  BEFORE: isDone=${targetSet.isDone}');
    
    // Nuclear rewrite: explicit list comprehensions
    state = [
      for (final exercise in state)
        if (exercise.id == exerciseId)
          exercise.copyWith(
            sets: [
              for (final set in exercise.sets)
                if (set.setIndex == setIndex)
                  set.copyWith(
                    isDone: !set.isDone,
                    weight: weight ?? set.weight,
                    reps: reps,
                  )
                else
                  set
            ],
          )
        else
          exercise
    ];
    
    // Verify the change
    final newExercise = state.firstWhere((e) => e.id == exerciseId);
    final newSet = newExercise.sets.firstWhere((s) => s.setIndex == setIndex);
    debugPrint('  AFTER: isDone=${newSet.isDone}');
    debugPrint('  ✅ State mutation complete');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

}
