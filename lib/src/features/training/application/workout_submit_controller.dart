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

  Future<WorkoutLog?> submitWorkout({required int sessionRir}) async {
    state = const AsyncLoading();

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      final userId = user?.uid ?? 'current_user_id'; // Fallback per requirements

      // 1. Get current routine state
      final exercises = ref.read(dailyRoutineProvider);

      // 2. Filter valid sets (isDone == true) and map to simpler structure
      final List<Map<String, dynamic>> completedExercises = [];

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
        // Just return null or throw depending on UX preference.
        // Throwing allows UI to show snackbar error.
        throw Exception("No hay ejercicios completados para guardar.");
      }

      // 3. Create DTO
      final log = WorkoutLog(
        id: const Uuid().v4(),
        templateId: 'generated_daily',
        date: DateTime.now(),
        sessionRirScore: sessionRir,
        completedExercises: completedExercises,
      );

      // 4. Save to Firestore
      await ref.read(trainingRepositoryProvider).saveWorkoutLog(userId, log);

      state = const AsyncData(null);
      return log; // Return the log for navigation
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
