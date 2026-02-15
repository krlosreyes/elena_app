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
    // 1. Listen to Selected Day (1=Mon, 7=Sun)
    final selectedDay = ref.watch(selectedDayProvider);
    
    // 2. Listen to Weekly Plan (generated based on Profile)
    final weeklyPlan = ref.watch(weeklyPlanProvider);

    if (weeklyPlan.isEmpty) return [];

    // 3. Find the workout for the selected day
    // We use a safe lookup. If not found, return empty (Rest day or error).
    final dailyWorkout = weeklyPlan.firstWhere(
      (w) => w.dayIndex == selectedDay,
      orElse: () => DailyWorkout(
        dayIndex: selectedDay, 
        type: WorkoutType.rest, 
        durationMinutes: 0, 
        description: 'Rest', 
        details: '', 
        exercises: [],
      ),
    );

    // 4. Ensure it's a Strength workout
    if (dailyWorkout.type != WorkoutType.strength) {
      return [];
    }

    // 5. Map to Interactive Mode
    if (dailyWorkout.exercises.isNotEmpty) {
      return dailyWorkout.exercises.map((e) {
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
