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
  Future<List<InteractiveExercise>> build() async {
    final selectedDay = ref.watch(selectedDayProvider);
    final todayIndex = DateTime.now().weekday;

    // Only show routine if selected day is today
    if (selectedDay != todayIndex) {
      return []; 
    }

    // Get the planned workout for today
    final plannedWorkout = ref.watch(todayWorkoutProvider);
    
    // If no plan or not strength, return empty (Nuclear Reset: No Legacy Fallback)
    if (plannedWorkout == null || plannedWorkout.type != WorkoutType.strength) {
      return [];
    }

    // Dynamic Routine Construction
    if (plannedWorkout.exercises.isNotEmpty) {
      return plannedWorkout.exercises.map((e) {
        return InteractiveExercise(
          id: e.id,
          name: e.name,
          targetRir: e.rir,
          sets: List.generate(e.sets, (index) => InteractiveSet(
            setIndex: index + 1,
            targetReps: e.targetReps,
            weight: 5.0, // Default weight 5.0 as requested
            isDone: false,
          )),
        );
      }).toList();
    }

    // Fallback? NO. Return empty if generation failed.
    return [];
  }

  void toggleSet(String exerciseId, int setIndex, double weight, int reps) {
    // Nuclear Async Immutable Update
    // Using state.whenData to ensure we are operating on loaded data
    state.whenData((routine) {
      state = AsyncData([
        for (final ex in routine)
          if (ex.id == exerciseId)
            ex.copyWith(sets: [
              for (int i = 0; i < ex.sets.length; i++)
                i == setIndex - 1 // setIndex is 1-based, list is 0-based
                  ? ex.sets[i].copyWith(
                      isDone: !ex.sets[i].isDone, 
                      weight: weight, 
                      reps: reps
                    )
                  : ex.sets[i]
            ])
          else ex
      ]);
    });
  }
}
