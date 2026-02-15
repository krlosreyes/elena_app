import 'dart:developer';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/entities/workout_log.dart';
import '../domain/entities/interactive_routine.dart';
import '../data/repositories/training_repository.dart';
import 'daily_routine_provider.dart';
import 'calendar_state_provider.dart';

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

      // 1. Get current routine state
      final routine = ref.read(dailyRoutineProvider);
      
      log('[WorkoutSubmit] userId=$userId, workoutType=$workoutType');
      log('[WorkoutSubmit] routine has ${routine.length} exercises');

      // Get selected date for the log
      final selectedDate = ref.read(calendarStateProvider);
      final logDate = DateTime(
          selectedDate.year, 
          selectedDate.month, 
          selectedDate.day, 
          DateTime.now().hour, 
          DateTime.now().minute,
      );

      // Build completed exercises list
      final List<Map<String, dynamic>> completedExercises = [];
      int finalCalories = calories ?? 0;
      int totalMinutes = durationMinutes ?? 0;

      // Handle Strength Logic
      final isStrength = workoutType == 'Strength' || (workoutType == null && routine.isNotEmpty);
      
      if (isStrength) {
        for (final exercise in routine) {
          final doneSets = exercise.sets.where((s) => s.isDone).toList();
          
          log('[WorkoutSubmit] Exercise "${exercise.name}" (${exercise.id}): '
              '${doneSets.length}/${exercise.sets.length} sets done');

          if (doneSets.isEmpty) continue;

          completedExercises.add({
            'exerciseId': exercise.id,
            'name': exercise.name,
            'sets': doneSets.map((s) => {
              'setIndex': s.setIndex,
              'weight': s.weight,
              'reps': s.reps,
              'isDone': s.isDone,
              'targetReps': s.targetReps,
            }).toList(),
          });
        }
        
        log('[WorkoutSubmit] Total completed exercises: ${completedExercises.length}');

        if (completedExercises.isEmpty) {
          throw Exception("No hay series marcadas como completadas.");
        }

        // Estimate calories (~6 kcal/min)
        if (finalCalories == 0) {
          int calculatedDuration = totalMinutes > 0 
              ? totalMinutes 
              : completedExercises.fold(0, (sum, ex) => sum + (ex['sets'] as List).length * 3);
          finalCalories = calculatedDuration * 6;
          totalMinutes = calculatedDuration;
        }
      } 
      // Handle Cardio Logic
      else if (workoutType == 'Cardio') {
        if (totalMinutes <= 0) {
          throw Exception("La duración del cardio debe ser mayor a 0.");
        }
        if (finalCalories == 0) {
          finalCalories = totalMinutes * 8;
        }
      }

      // 3. Create DTO
      final log2 = WorkoutLog(
        id: const Uuid().v4(),
        templateId: 'generated_daily',
        date: logDate,
        sessionRirScore: sessionRir,
        completedExercises: completedExercises,
        durationMinutes: totalMinutes,
        caloriesBurned: finalCalories,
      );

      log('[WorkoutSubmit] Saving log: id=${log2.id}, date=${log2.date}, '
          'exercises=${log2.completedExercises.length}, '
          'duration=${log2.durationMinutes}min, '
          'calories=${log2.caloriesBurned}');

      // 4. Save to Firestore
      await ref.read(trainingRepositoryProvider).saveWorkoutLog(userId, log2);

      log('[WorkoutSubmit] ✅ Saved successfully');
      
      state = const AsyncData(null);
      return log2; 
    } catch (e, st) {
      log('[WorkoutSubmit] ❌ Error: $e', error: e, stackTrace: st);
      state = AsyncError(e, st);
      return null;
    }
  }
}
