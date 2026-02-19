
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../authentication/data/auth_repository.dart';
import '../../training/domain/entities/training_entities.dart';
import '../domain/workout_stats.dart';

part 'history_repository.g.dart';

class HistoryRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  HistoryRepository(this._firestore, this._uid);

  Future<WorkoutStats?> getWorkoutSummary(DateTime date) async {
    try {
      // 1. Query Firestore for workouts on this date
      // Note: This assumes workouts are stored with a 'date' field.
      // We need to match the date range (start of day to end of day).
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('workouts')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .limit(1) // Get the latest workout for that day
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final workout = WorkoutSession.fromJson(doc.data());

      // 2. Calculate Stats
      double totalVolume = 0;
      int totalSets = 0;
      for (final set in workout.sets) {
        totalVolume += (set.weight * set.repsCompleted);
        totalSets++;
      }

      // 3. Fetch User Weight for Calories (Optional optimization: cache or pass in)
      // For now, use a default or try to fetch from profile if needed.
      // Let's assume a standard 75kg if we don't want to make an extra call right now,
      // or we can fetch the user profile.
      // Given the prompt asks for a "Helper or Entity method", we'll use the static method with default.
      // Ideally we'd fetch the user's weight from a profile provider.
      final double userWeight = 75.0; // Todo: Fetch from ProfileRepository if available

      final calories = WorkoutStats.calculateCalories(
        durationMinutes: workout.durationMinutes,
        userWeightKg: userWeight,
      );

      return WorkoutStats(
        date: workout.date,
        totalVolume: totalVolume,
        durationMinutes: workout.durationMinutes,
        caloriesBurned: calories,
        workoutType: workout.type,
        totalSets: totalSets,
      );

    } catch (e) {
      // Log error
      print('Error fetching workout summary: $e');
      return null;
    }
  }
}

@riverpod
HistoryRepository historyRepository(HistoryRepositoryRef ref) {
  final auth = ref.watch(authRepositoryProvider);
  return HistoryRepository(FirebaseFirestore.instance, auth.currentUser?.uid ?? '');
}

// Stats Provider
@riverpod
Future<WorkoutStats?> workoutStats(WorkoutStatsRef ref, DateTime date) {
  return ref.watch(historyRepositoryProvider).getWorkoutSummary(date);
}
