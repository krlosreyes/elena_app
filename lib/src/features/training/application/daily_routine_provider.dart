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
            weight: 0.0, // Default weight, user will input actuals
            isDone: false,
          )),
        );
      }).toList();
    }

    // Fallback? NO. Return empty if generation failed.
    return [];
  }

  void toggleSet(String exerciseId, int setIndex, double weight, int reps) {
    // Nuclear Immutable Update
    // We recreate the entire list structure to guarantee Riverpod detects the change.
    state = [
      for (final exercise in state)
        if (exercise.id == exerciseId)
          exercise.copyWith(
            sets: [
              for (final set in exercise.sets)
                if (set.setIndex == setIndex)
                  set.copyWith(
                    isDone: !set.isDone,
                    weight: weight,
                    reps: reps,
                  )
                else
                  set
            ],
          )
        else
          exercise
    ];
  }
}
