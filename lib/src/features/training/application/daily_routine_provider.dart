import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/science/training_physiology.dart';

import '../data/repositories/training_repository.dart';
import '../domain/entities/exercise.dart';
import '../domain/entities/routine_template.dart';

import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';

part 'daily_routine_provider.freezed.dart';
part 'daily_routine_provider.g.dart';

@freezed
class DailyExercise with _$DailyExercise {
  const factory DailyExercise({
    required Exercise exercise,
    required RoutineExercise routineDetails,
    double? recommendedWeight,
    int? lastRir,
  }) = _DailyExercise;
}

@freezed
class DailyWorkoutState with _$DailyWorkoutState {
  const factory DailyWorkoutState({
    required RoutineTemplate? routine,
    required List<DailyExercise> exercises,
  }) = _DailyWorkoutState;
}

@riverpod
Future<DailyWorkoutState> dailyRoutine(DailyRoutineRef ref) async {
  final authUser = ref.watch(authRepositoryProvider).currentUser;
  if (authUser == null) throw Exception('No user logged in');

  // 1. Get User Profile for Goal/Level
  final user = await ref.watch(userStreamProvider(authUser.uid).future);
  if (user == null) throw Exception('User profile not found');

  final goal = 'hypertrophy'; 
  final level = 'intermediate';

  final repository = ref.watch(trainingRepositoryProvider);

  // 2. Fetch Routine Template
  final routine = await repository.getRoutineTemplate(goal, level);

  if (routine == null) {
    return const DailyWorkoutState(routine: null, exercises: []);
  }

  // 3. Extract IDs and Fetch Exercises
  final exerciseIds = routine.exercises.map((e) => e.exerciseId).toList();
  final exerciseDefinitions = await repository.getExercisesByIds(exerciseIds);

  // 4. Progressive Overload Engine
  List<DailyExercise> dailyExercises = [];

  for (final routineEx in routine.exercises) {
    // Find definition
    final definition = exerciseDefinitions.firstWhere(
      (e) => e.id == routineEx.exerciseId,
      orElse: () => Exercise(id: 'unknown', name: 'Unknown', targetMuscle: '', mechanics: '', description: ''),
    );

    // Get Last Log for this specific exercise
    double? recommendedWeight;
    int? lastRir;

    final lastLogMap = await repository.getLastExerciseLog(authUser.uid, routineEx.exerciseId);

    if (lastLogMap != null) {
      // Parse last performance
      final double lastWeight = (lastLogMap['weight_used'] as num?)?.toDouble() ?? 0.0;
      lastRir = lastLogMap['rir_score'] as int?;

      if (lastRir != null && lastWeight > 0) {
        // Calculate Next Weight using Science Module
        recommendedWeight = TrainingPhysiology.calculateNextWeight(
          lastWeight, 
          lastRir, 
          routineEx.targetRir
        );
      }
    }

    dailyExercises.add(DailyExercise(
      exercise: definition,
      routineDetails: routineEx,
      recommendedWeight: recommendedWeight,
      lastRir: lastRir,
    ));
  }

  return DailyWorkoutState(
    routine: routine, 
    exercises: dailyExercises
  );
}
