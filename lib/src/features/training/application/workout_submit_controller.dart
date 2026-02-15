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
    // Initial state is idle (data is null)
  }

  Future<WorkoutLog?> submitWorkout({
    required int sessionRir, 
    int? durationMinutes, 
    int? calories,
    String? workoutType, // 'Strength' or 'Cardio' 
  }) async {
    state = const AsyncLoading();

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      final userId = user?.uid ?? 'current_user_id'; 

      // 1. Get current routine state for Strength
      final exercises = ref.read(dailyRoutineProvider);
      
      // Get selected date for the log (support retroactive logging)
      final selectedDate = ref.read(calendarStateProvider); // Fix for retroactive bug
      // Normalize to ensure we capture the specific day, time can be current time if preferred 
      // or just the date. Let's keep the date with current time component or just date.
      // Requirements say "fecha del día seleccionado". 
      // Let's combine selected date with current time to preserve ordering if multiple logs?
      // Or just midnight? Usually workout logs have timestamps. 
      // Let's use selectedDate (which might be midnight) combined with current time 
      // OR just selectedDate if we want to strictly bind to that day. 
      // Let's use start of that day + current time offset? 
      // Simplest: use selectedDate (which is normalized to 00:00 usually in calendar state?)
      // CalendarState usually holds midnight. Let's use that but update the hour if it is today?
      // Actually, for retroactive, midnight is fine or 12:00. 
      // Let's use selectedDate directly but ensure it's a DateTime.
      final logDate = DateTime(
          selectedDate.year, 
          selectedDate.month, 
          selectedDate.day, 
          DateTime.now().hour, 
          DateTime.now().minute
      );
      
      // Data to save
      final List<Map<String, dynamic>> completedExercises = [];
      int finalCalories = calories ?? 0;
      int totalMinutes = durationMinutes ?? 0;

      // Handle Strength Logic
      if (workoutType == 'Strength' || (workoutType == null && exercises.isNotEmpty)) {
         for (final exercise in exercises) {
          final validSets = exercise.sets.where((s) => s.isDone).toList();

          if (validSets.isNotEmpty) {
            completedExercises.add({
              'exerciseId': exercise.id,
              'name': exercise.name,
              'sets': validSets.map((s) => {
                'setIndex': s.setIndex,
                'weight': s.weight,
                'reps': s.reps,
                'isDone': s.isDone,
                'targetReps': s.targetReps,
              }).toList(),
            });
          }
        }
        
        if (completedExercises.isEmpty) {
           throw Exception("No hay ejercicios completados para guardar.");
        }

        // Estimate calories for Strength if not provided (~6 kcal/min)
        if (finalCalories == 0) {
           int calculatedDuration = totalMinutes > 0 ? totalMinutes : completedExercises.fold(0, (sum, ex) => sum + (ex['sets'] as List).length * 3);
           finalCalories = calculatedDuration * 6;
           totalMinutes = calculatedDuration;
        }
      } 
      // Handle Cardio Logic
      else if (workoutType == 'Cardio') {
         if (totalMinutes <= 0) {
           throw Exception("La duración del cardio debe ser mayor a 0.");
         }
         // Estimate calories for Cardio (~8 kcal/min)
         if (finalCalories == 0) {
           finalCalories = totalMinutes * 8;
         }
      }

      // 3. Create DTO
      final log = WorkoutLog(
        id: const Uuid().v4(),
        templateId: 'generated_daily', // Could be dynamic
        date: logDate, // Use correct date
        sessionRirScore: sessionRir,
        completedExercises: completedExercises,
        durationMinutes: totalMinutes,
        caloriesBurned: finalCalories,
      );

      // 4. Save to Firestore
      await ref.read(trainingRepositoryProvider).saveWorkoutLog(userId, log);

      state = const AsyncData(null);
      return log; 
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
