import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/data/auth_repository.dart';
import '../../data/performance_repository.dart';

final weeklyPerformanceProvider = StreamProvider.autoDispose<Map<DateTime, int>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  
  if (user == null) {
    return Stream.value({});
  }

  final repository = ref.watch(performanceRepositoryProvider);
  return repository.getWeeklyScores(user.uid);
});
