import 'dart:developer';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/entities/workout_log.dart';
import '../domain/entities/interactive_routine.dart';
import '../data/repositories/training_repository.dart';
import 'daily_routine_provider.dart';
import 'calendar_state_provider.dart';
import 'workout_log_provider.dart';

import 'training_cycle_provider.dart';

part 'workout_submit_controller.g.dart';

@riverpod
class WorkoutSubmitController extends _$WorkoutSubmitController {
  @override
  FutureOr<void> build() {
    // Initial state is idle
  }

  Future<WorkoutLog?> submitWorkout({
    required int sessionRir, 
    int? durationMinutes, 
    int? calories,
    String? workoutType,
  }) async {
    state = const AsyncLoading();

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      final userId = user?.uid ?? 'current_user_id'; 

      // Get selected date early to check for bypass
      final selectedDate = ref.read(calendarStateProvider);
      
      // Check if this is a Retroactive Cardio save (Cardio + Manual Minutes > 0)
      // We rely on durationMinutes being provided by the UI for past dates.
      final isCardioRetroactive = workoutType == 'Cardio' && (durationMinutes ?? 0) > 0;

      // 1. Get current routine state (AsyncValue)
      final routineState = ref.read(dailyRoutineProvider);
      
      // Ensure data is loaded -> BYPASS if it's retroactive cardio
      if (!routineState.hasValue && !isCardioRetroactive) {
        throw Exception("La rutina no está cargada o hubo un error.");
      }
      final routine = routineState.valueOrNull ?? [];
      
      log('[WorkoutSubmit] userId=$userId, workoutType=$workoutType');
      log('[WorkoutSubmit] routine has ${routine.length} exercises');

      final now = DateTime.now();
      final logDate = DateTime(
          selectedDate.year, 
          selectedDate.month, 
          selectedDate.day, 
          now.hour, 
          now.minute,
      );

      final List<Map<String, dynamic>> completedExercises = [];
      int finalCalories = calories ?? 0;
      int totalMinutes = durationMinutes ?? 0;

      // Handle Strength Logic
      final isStrength = workoutType == 'Strength' || (workoutType == null && routine.isNotEmpty);
      
      if (isStrength) {
        for (final exercise in routine) {
          final doneSets = exercise.sets.where((s) => s.isDone).toList();
          
          if (doneSets.isEmpty) continue;

          log('[WorkoutSubmit] Exercise "${exercise.name}" (${exercise.id}): '
              '${doneSets.length}/${exercise.sets.length} sets done');

          completedExercises.add({
            'exerciseId': exercise.id,
            'name': exercise.name,
            'sets': doneSets.map((s) => {
              'setIndex': s.setIndex,
              'weight': s.weight,
              'reps': s.reps ?? int.tryParse(s.targetReps.split(RegExp(r'\D')).firstWhere((e) => e.isNotEmpty, orElse: () => '0')),
              'isDone': s.isDone,
              'targetReps': s.targetReps,
            }).toList(),
          });
        }
        
        log('[WorkoutSubmit] Total completed exercises: ${completedExercises.length}');
        
        // If Strength, we MUST have exercises. (Unless it's a rest day? But we shouldn't be submitting strength on rest day usually)
        if (completedExercises.isEmpty) {
          throw Exception("No hay series marcadas como completadas.\nMarca al menos una serie (check verde).");
        }

        // Estimate calories (~6 kcal/min) if not provided
        if (finalCalories == 0) {
           // If duration needs estimation
           if (totalMinutes == 0) {
             final totalSets = completedExercises.fold(0, (sum, ex) => sum + (ex['sets'] as List).length);
             totalMinutes = totalSets * 3; // 3 mins per set roughly
           }
           finalCalories = totalMinutes * 5; // Conservative 5 kcal/min
        }
      } 
      // Handle Cardio Logic
      else if (workoutType == 'Cardio') {
        if (totalMinutes <= 0) {
          throw Exception("La duración del cardio debe ser mayor a 0.");
        }
        if (finalCalories == 0) {
          finalCalories = totalMinutes * 7;
        }
      }

      // 3. Upsert Logic: Check if a log already exists for this date to prevent duplicates
      final existingLog = await ref.read(trainingRepositoryProvider).getWorkoutLogForDate(userId, logDate);
      final logId = existingLog?.id ?? const Uuid().v4();

      final newLog = WorkoutLog(
        id: logId,
        templateId: 'generated_daily',
        date: logDate,
        sessionRirScore: sessionRir,
        completedExercises: completedExercises,
        durationMinutes: totalMinutes,
        caloriesBurned: finalCalories,
      );

      log('[WorkoutSubmit] Saving log: id=${newLog.id}, exercises=${newLog.completedExercises.length}');

      // 4. Save to Firestore
      await ref.read(trainingRepositoryProvider).saveWorkoutLog(userId, newLog);

      log('[WorkoutSubmit] ✅ Saved successfully');
      
      state = const AsyncData(null);
      // 6. Update Training Cycle (Session Count)
      ref.read(trainingCycleProviderProvider.notifier).incrementSession();

      return newLog; 
    } catch (e, st) {
      log('[WorkoutSubmit] ❌ Error: $e', error: e, stackTrace: st);
      state = AsyncError(e, st);
      return null;
    } finally {
       // Force refresh of log data to update UI to "Completed" state
       if (state.hasValue || state.isLoading == false) { // Relaxed check to ensure invalidation happens
          final selectedDate = ref.read(calendarStateProvider);
          ref.invalidate(workoutLogProvider(selectedDate));
          ref.invalidate(dailyRoutineProvider);
       }
    }
  }
}
