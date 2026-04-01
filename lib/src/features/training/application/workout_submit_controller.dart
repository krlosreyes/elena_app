import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../authentication/data/auth_repository.dart';
import '../../fasting/application/fasting_controller.dart';
import '../domain/entities/workout_log.dart';
import 'calendar_state_provider.dart';
import 'daily_routine_provider.dart';
import 'training_cycle_controller.dart';
import 'training_provider.dart';
import 'workout_log_provider.dart';

/// Controller for submitting workout logs
/// Manual implementation to avoid build_runner conflicts
final workoutSubmitControllerProvider =
    StateNotifierProvider<WorkoutSubmitController, AsyncValue<WorkoutLog?>>(
        (ref) {
  return WorkoutSubmitController(ref);
});

class WorkoutSubmitController extends StateNotifier<AsyncValue<WorkoutLog?>> {
  final Ref ref;

  WorkoutSubmitController(this.ref) : super(const AsyncValue.data(null));

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

      final selectedDate = ref.read(calendarStateProvider);

      final isCardioRetroactive =
          workoutType == 'Cardio' && (durationMinutes ?? 0) > 0;

      final routineState = ref.read(dailyRoutineProvider);

      if (!routineState.hasValue && !isCardioRetroactive) {
        throw Exception("La rutina no está cargada o hubo un error.");
      }
      final routine = routineState.asData?.value ?? [];

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

      final isStrength = workoutType == 'Strength' ||
          (workoutType == null && routine.isNotEmpty);

      if (isStrength) {
        for (final exercise in routine) {
          final doneSets = exercise.sets.where((s) => s.isDone).toList();

          if (doneSets.isEmpty) continue;

          log('[WorkoutSubmit] Exercise "${exercise.name}" (${exercise.id}): '
              '${doneSets.length}/${exercise.sets.length} sets done');

          completedExercises.add({
            'exerciseId': exercise.id,
            'name': exercise.name,
            'sets': doneSets
                .map((s) => {
                      'setIndex': s.setIndex,
                      'weight': s.weight,
                      'reps': s.reps ??
                          int.tryParse(s.targetReps
                              .split(RegExp(r'\D'))
                              .firstWhere((e) => e.isNotEmpty,
                                  orElse: () => '0')),
                      'isDone': s.isDone,
                      'targetReps': s.targetReps,
                    })
                .toList(),
          });
        }

        log('[WorkoutSubmit] Total completed exercises: ${completedExercises.length}');

        if (completedExercises.isEmpty) {
          throw Exception(
              "No hay series marcadas como completadas.\nMarca al menos una serie (check verde).");
        }

        if (finalCalories == 0) {
          if (totalMinutes == 0) {
            final totalSets = completedExercises.fold(
                0, (sum, ex) => sum + (ex['sets'] as List).length);
            totalMinutes = totalSets * 3;
          }
          finalCalories = totalMinutes * 5;
        }
      } else if (workoutType == 'Cardio') {
        if (totalMinutes <= 0) {
          throw Exception("La duración del cardio debe ser mayor a 0.");
        }
        if (finalCalories == 0) {
          finalCalories = totalMinutes * 7;
        }
      }

      final existingLog = await ref
          .read(trainingRepositoryProvider)
          .getWorkoutLogForDate(userId, logDate);
      final logId = existingLog?.id ?? const Uuid().v4();

      final fastingState = ref.read(fastingControllerProvider).valueOrNull;
      final isFasted = fastingState?.isFasting ?? false;

      final newLog = WorkoutLog(
        id: logId,
        templateId: 'generated_daily',
        date: logDate,
        sessionRirScore: sessionRir,
        completedExercises: completedExercises,
        durationMinutes: totalMinutes,
        caloriesBurned: finalCalories,
        isFasted: isFasted,
        type: workoutType ?? 'Fuerza',
      );

      log('[WorkoutSubmit] Saving log: id=${newLog.id}, type=${newLog.type}');

      final isHighIntensity =
          (workoutType == 'Fuerza' || workoutType == 'HIIT');

      await ref.read(trainingRepositoryProvider).completeWorkoutSession(
            userId: userId,
            log: newLog,
            isHighIntensity: isHighIntensity,
          );

      log('[WorkoutSubmit] ✅ Saved successfully');

      state = AsyncValue.data(newLog);
      ref.read(trainingCycleControllerProvider.notifier).incrementSession();

      return newLog;
    } catch (e, st) {
      log('[WorkoutSubmit] ❌ Error: $e', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
      return null;
    } finally {
      if (state.hasValue || !state.isLoading) {
        final selectedDate = ref.read(calendarStateProvider);
        ref.invalidate(workoutLogProvider(selectedDate));
        ref.invalidate(dailyRoutineProvider);
      }
    }
  }
}
