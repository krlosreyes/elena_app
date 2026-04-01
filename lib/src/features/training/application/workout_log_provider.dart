import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/data/auth_repository.dart';
import '../domain/entities/workout_log.dart';
import 'training_provider.dart';

/// Get workout log for a specific date
final workoutLogProvider =
    FutureProvider.family<WorkoutLog?, DateTime>((ref, date) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;

  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getWorkoutLogForDate(user.uid, date);
});
