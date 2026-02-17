import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/interactive_routine.dart';
import '../domain/entities/daily_workout.dart'; // Added missing import
import '../domain/enums/workout_enums.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/repositories/training_repository.dart';
import 'calendar_state_provider.dart'; // Added for flexible planning
import 'selected_day_provider.dart';
import 'weekly_plan_provider.dart';
import 'workout_log_provider.dart';

part 'daily_routine_provider.g.dart';

@riverpod
class DailyRoutine extends _$DailyRoutine {
  @override
  Future<List<InteractiveExercise>> build() async {
    // 1. Listen to Calendar State (DateTime) directly
    final selectedDate = ref.watch(calendarStateProvider);
    final dayIndex = selectedDate.weekday; // 1=Mon, 7=Sun
    
    // 1b. Check for Existing Log (History Priority) - REACTIVE
    // We watch the specific log provider for this date. If it updates, we update.
    final logAsync = ref.watch(workoutLogProvider(selectedDate));
    
    // Unpack AsyncValue
    final log = logAsync.valueOrNull;

      if (log != null && log.completedExercises.isNotEmpty) {
        debugPrint("ElenaApp Log: Log encontrado (Reactive) para $selectedDate. Cargando historial.");
        return log.completedExercises.map((e) {
             final List<dynamic> setsList = e['sets'] ?? [];
             return InteractiveExercise(
               id: e['exerciseId'] ?? 'unknown',
               name: e['name'] ?? 'Unknown Exercise',
               targetRir: 0, // Not stored in log item usually, preserving structure
               sets: setsList.map<InteractiveSet>((s) => InteractiveSet(
                 setIndex: s['setIndex'] as int,
                 targetReps: s['targetReps'] as String? ?? '0',
                 weight: (s['weight'] as num?)?.toDouble() ?? 0.0,
                 reps: s['reps'] as int? ?? 0,
                 isDone: s['isDone'] as bool? ?? true, // If in log, it's done-ish
               )).toList(),
             );
        }).toList();
      }
    
    debugPrint("ElenaApp Log: Cargando rutina PLANIFICADA para FECHA: $selectedDate (Dia: $dayIndex)");
    
    // 2. Listen to Weekly Plan (generated based on Profile)
    final weeklyPlan = ref.watch(weeklyPlanProvider);

    if (weeklyPlan.isEmpty) {
      debugPrint("ElenaApp Log: WeeklyPlan está vacío.");
      return [];
    }

    // 3. Find the workout for the selected day
    final dailyWorkout = weeklyPlan.firstWhere(
      (w) => w.dayIndex == dayIndex,
      orElse: () {
        debugPrint("ElenaApp Log: No se encontró workout para el día $dayIndex. Retornando Rest.");
        return DailyWorkout(
          dayIndex: dayIndex, 
          type: WorkoutType.rest, 
          durationMinutes: 0, 
          description: 'Rest', 
          details: '', 
          exercises: [],
        );
      },
    );

    // 4. Ensure it's a Strength OR Cardio workout
    if (dailyWorkout.type == WorkoutType.rest) {
       debugPrint("ElenaApp Log: Día de descanso (Day $dayIndex). Retornando lista vacía.");
       return [];
    }

    // 5. Map to Interactive Mode
    if (dailyWorkout.exercises.isNotEmpty) {
      debugPrint("ElenaApp Log: Mapeando ${dailyWorkout.exercises.length} ejercicios a interactivos.");
      return dailyWorkout.exercises.map((e) {
        return InteractiveExercise(
          id: e.id,
          name: e.name,
          targetRir: e.rir,
          sets: List.generate(e.sets, (index) => InteractiveSet(
            setIndex: index + 1,
            targetReps: e.targetReps,
            weight: 5.0, // Default weight
            isDone: false,
          )),
        );
      }).toList();
    }

    debugPrint("ElenaApp Log: Lista de ejercicios vacía para el día $dayIndex.");
    return [];
  }

  void toggleSet(String exerciseId, int setIndex, double weight, int reps) {
    // Nuclear Async Immutable Update with Debugging
    state.whenData((routine) {
      final updatedRoutine = [
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
      ];
      
      state = AsyncData(updatedRoutine);
      
      // Debug print to confirm reactivity
      try {
        final updatedExercise = updatedRoutine.firstWhere((e) => e.id == exerciseId);
        final updatedSet = updatedExercise.sets[setIndex - 1];
        debugPrint("ElenaApp Log: Set $setIndex del ejercicio $exerciseId actualizado a isDone: ${updatedSet.isDone}");
      } catch (e) {
        debugPrint("ElenaApp Log: Error al imprimir debug del set actualizado: $e");
      }
    });
  }
}
