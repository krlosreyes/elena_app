import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/fasting/application/fasting_controller.dart';
import '../../../features/health/data/health_repository.dart';
import '../../../features/nutrition/domain/entities/metabolic_profile.dart';
import '../../../features/profile/application/user_controller.dart';
import '../../../features/sleep/domain/entities/sleep_log.dart';
import '../../../features/training/application/training_stats_provider.dart';
import '../../../features/training/domain/entities/workout_log.dart';
import '../../engagement/data/engagement_repository.dart';
import '../application/health_orchestrator.dart';
import '../domain/full_user_state.dart';

/// Feature flag for the unified health pipeline.
final useHealthStatePipelineProvider = StateProvider<bool>((ref) => false);

/// Aggregates domain sources and returns a unified [FullUserState].
///
/// Async-safe by design (`FutureProvider`):
/// - exposes loading/error states automatically via `AsyncValue`
/// - guards nullable upstream sources
/// - catches non-critical data failures (workouts/profile) gracefully
final healthSnapshotProvider =
    FutureProvider.autoDispose<FullUserState?>((ref) async {
  final isEnabled = ref.watch(useHealthStatePipelineProvider);
  if (!isEnabled) return null;

  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return null;

  final dailyLog = ref.watch(todayLogProvider(user.uid)).valueOrNull;
  if (dailyLog == null) return null;

  MetabolicProfile profile;
  try {
    final fastingState = ref.watch(fastingControllerProvider).valueOrNull;
    final isCurrentlyFasting = fastingState?.isFasting ?? false;
    final elapsedHours =
        fastingState != null ? fastingState.elapsed.inSeconds / 3600.0 : 0.0;

    profile = MetabolicProfile.fromUser(
      user,
      isCurrentlyFasting: isCurrentlyFasting,
      currentFastingElapsedHours: elapsedHours,
    );
  } catch (e, st) {
    debugPrint('⚠️ [HealthSnapshotProvider] MetabolicProfile failed: $e');
    debugPrint(st.toString());
    return null;
  }

  SleepLog? sleepLog;
  if (dailyLog.sleepMinutes > 0) {
    sleepLog = SleepLog(
      id: dailyLog.id,
      userId: user.uid,
      hours: dailyLog.sleepMinutes / 60.0,
      timestamp: DateTime.now(),
    );
  }

  List<WorkoutLog> workouts;
  try {
    workouts = await ref.read(trainingStatsProvider.future);
  } catch (e) {
    debugPrint('⚠️ [HealthSnapshotProvider] Training stats unavailable: $e');
    workouts = const [];
  }

  final orchestrator = HealthOrchestrator();
  final engagementRepository = ref.read(engagementRepositoryProvider);
  orchestrator.setEngagementRepository(engagementRepository, user.uid);

  try {
    return await orchestrator.buildState(
      dailyLog: dailyLog,
      metabolicProfile: profile,
      sleepLog: sleepLog,
      workouts: workouts,
    );
  } catch (e, st) {
    debugPrint('❌ [HealthSnapshotProvider] Orchestrator failed: $e');
    debugPrint(st.toString());
    return null;
  }
});
