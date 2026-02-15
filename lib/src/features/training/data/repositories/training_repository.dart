import '../../domain/entities/training_entities.dart';

abstract class TrainingRepository {
  Future<void> saveWorkoutSession(WorkoutSession session);
  Future<WeeklyTrainingStats> getWeeklyStats();
}

class TrainingRepositoryImpl implements TrainingRepository {
  // In a real implementation, this would inject a remote data source (Firebase).
  // For now, we stub methods or use local storage/mock.
  
  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    // TODO: Implement Firestore save
    await Future.delayed(const Duration(milliseconds: 500));
    print('Saved workout session: ${session.id}');
  }

  @override
  Future<WeeklyTrainingStats> getWeeklyStats() async {
    // TODO: Implement Firestore fetch
    await Future.delayed(const Duration(milliseconds: 500));
    // Return mock data for initial implementation/testing
    return const WeeklyTrainingStats(
      totalStrengthMins: 120,
      totalHiitMins: 30,
      zone2Mins: 45,
      consecutiveWeeksTrained: 4,
    );
  }
}
