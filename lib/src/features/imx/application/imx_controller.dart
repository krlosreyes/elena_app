import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/imx_engine.dart';
import '../../profile/application/user_controller.dart';
import '../../progress/application/progress_controller.dart';
import '../../profile/domain/user_model.dart';
import './imx_providers.dart';

/// Controller that manages the IMX v2 Score state
class ImxController extends AsyncNotifier<ImxResult> {
  @override
  FutureOr<ImxResult> build() async {
    // Watch relevant data streams
    final userState = ref.watch(currentUserStreamProvider);
    final fastingState = ref.watch(fastingHistoryStreamProvider); // Assuming this exists or using a similar one
    final measurementsState = ref.watch(userMeasurementsStreamProvider);

    // If any is loading, return loading state
    if (userState.isLoading || fastingState.isLoading || measurementsState.isLoading) {
      // If we have previous state (cache), we could return it here instead of loading
      // but build() should return the latest data or loading.
    }

    final user = userState.value;
    if (user == null) return ImxResult.empty;

    final history = fastingState.value ?? [];
    final measurements = measurementsState.value ?? [];
    
    // Calculate extra inputs for Motor v2
    // 1. Fasting Hours in last 24h (approx from history)
    final latestSession = history.isNotEmpty ? history.first : null;
    double fastingHours24h = 0;
    if (latestSession != null && latestSession.endTime != null) {
      final duration = latestSession.endTime!.difference(latestSession.startTime).inMinutes / 60.0;
      final hoursAgo = DateTime.now().difference(latestSession.endTime!).inHours;
      if (hoursAgo < 24) {
        fastingHours24h = duration;
      }
    }

    // 2. Consistency (last 7 days)
    final last7Days = history.take(7).toList();
    int planned = 7; // Assuming a daily goal for now
    int completed = last7Days.where((s) => s.isCompleted).length;

    // 3. Activity & Sleep (from user model/measurements)
    final latestLog = measurements.isNotEmpty ? measurements.last : null;
    
    // Call repository
    return ref.read(imxRepositoryProvider).fetchIMXScore(
      user: user,
      recentSessions: last7Days,
      fastingHours24h: fastingHours24h,
      fastingDaysPlanned: planned,
      fastingDaysCompleted: completed,
      activityMinutes: user.activityLevel == ActivityLevel.sedentary ? 0 : 45, // Placeholder if not in model
      sleepHours: latestLog?.energyLevel != null ? 7.5 : user.averageSleepHours, // Dynamic weighting
    );
  }

  /// Manually trigger a refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => build());
  }
}
