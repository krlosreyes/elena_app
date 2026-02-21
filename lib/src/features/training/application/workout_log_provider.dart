import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/entities/workout_log.dart';
import '../data/repositories/training_repository.dart';

part 'workout_log_provider.g.dart';

@riverpod
Future<WorkoutLog?> workoutLog(Ref ref, DateTime date) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getWorkoutLogForDate(user.uid, date);
}
