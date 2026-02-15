
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/entities/workout_log.dart';
import '../data/repositories/training_repository.dart';

part 'training_stats_provider.g.dart';

enum StatsRange { week, month, year }

@riverpod
class TrainingStatsFilter extends _$TrainingStatsFilter {
  @override
  StatsRange build() => StatsRange.week;

  void setRange(StatsRange range) => state = range;
}

@riverpod
Future<List<WorkoutLog>> trainingStats(TrainingStatsRef ref) async {
  final range = ref.watch(trainingStatsFilterProvider);
  final repository = ref.watch(trainingRepositoryProvider);
  final user = ref.read(authRepositoryProvider).currentUser;
  
  if (user == null) return [];

  final now = DateTime.now();
  final DateTime startDate;
  final DateTime endDate = now;

  switch (range) {
    case StatsRange.week:
      // Last 7 days including today
      startDate = now.subtract(const Duration(days: 6));
      break;
    case StatsRange.month:
      // Last 30 days
      startDate = now.subtract(const Duration(days: 29));
      break;
    case StatsRange.year:
      // Last 12 months/365 days
      startDate = now.subtract(const Duration(days: 365));
      break;
  }

  // Normalize startDate to midnight
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

  return repository.getWorkoutLogs(user.uid, start, end);
}
