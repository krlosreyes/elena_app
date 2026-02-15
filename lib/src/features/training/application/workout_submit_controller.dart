import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/entities/workout_log.dart';
import '../data/repositories/training_repository.dart';
import 'daily_routine_provider.dart';

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
      
      // Data to save
      final List<Map<String, dynamic>> completedExercises = [];
      int finalCalories = calories ?? 0;
      int totalMinutes = durationMinutes ?? 0;

      // Handle Strength Logic
      if (workoutType == 'Strength' || (workoutType == null && exercises.isNotEmpty)) {
         for (final exercise in exercises) {
          final sets = exercise['sets'] as List<dynamic>;
          final validSets = sets.where((s) => s['isDone'] == true).toList();

          if (validSets.isNotEmpty) {
            completedExercises.add({
              'exerciseId': exercise['id'],
              'name': exercise['name'],
              'sets': validSets,
            });
          }
        }
        
        if (completedExercises.isEmpty) {
           throw Exception("No hay ejercicios completados para guardar.");
        }

        // Estimate calories for Strength if not provided (~6 kcal/min)
        // We calculate duration based on sets or generic if not provided
        if (finalCalories == 0) {
           // Simple estimation: 3 mins per set? Or just use provided duration?
           // If duration is 0, let's guess based on sets count * 3 mins
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
        date: DateTime.now(),
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
