import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/training_repository.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine_template.dart';

import '../../../authentication/data/auth_repository.dart';
import '../../../profile/data/user_repository.dart';

part 'daily_routine_provider.freezed.dart';
part 'daily_routine_provider.g.dart';

@freezed
class DailyWorkoutState with _$DailyWorkoutState {
  const factory DailyWorkoutState({
    required RoutineTemplate? routine,
    required List<Exercise> exercises,
  }) = _DailyWorkoutState;
}

@riverpod
Future<DailyWorkoutState> dailyRoutine(DailyRoutineRef ref) async {
  final authUser = ref.watch(authRepositoryProvider).currentUser;
  if (authUser == null) throw Exception('No user logged in');

  // 1. Get User Profile for Goal/Level
  final user = await ref.watch(userStreamProvider(authUser.uid).future);
  if (user == null) throw Exception('User profile not found');

  // Hardcoded for now as per instructions, or fallback if fields missing
  // Assuming UserModel doesn't have explicit 'trainingGoal' yet, using mock.
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
  final exercises = await repository.getExercisesByIds(exerciseIds);

  return DailyWorkoutState(
    routine: routine, 
    exercises: exercises
  );
}
