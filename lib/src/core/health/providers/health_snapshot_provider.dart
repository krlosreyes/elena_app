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

final healthSnapshotProvider = FutureProvider.autoDispose<FullUserState?>((ref) async {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return null;

  final dailyLog = ref.watch(todayLogProvider(user.uid)).valueOrNull;
  if (dailyLog == null) return null;

  // 🛡️ CONEXIÓN REAL: Obtenemos el estado de ayuno activo
  final fastingState = ref.watch(fastingControllerProvider).valueOrNull;
  
  final profile = MetabolicProfile.fromUser(
    user,
    isCurrentlyFasting: fastingState?.isFasting ?? false,
    currentFastingElapsedHours: fastingState != null ? fastingState.elapsed.inSeconds / 3600.0 : 0.0,
  );

  // Mapeo de Sueño
  final sleepLog = dailyLog.sleepMinutes > 0 ? SleepLog(
    id: dailyLog.id, 
    userId: user.uid,
    hours: (dailyLog.sleepMinutes / 60.0).clamp(0.0, 24.0),
    timestamp: DateTime.now(),
  ) : null;

  // Mapeo de Entrenamientos
  List<WorkoutLog> workouts = [];
  try { 
    workouts = await ref.read(trainingStatsProvider.future); 
  } catch (_) {}

  final orchestrator = HealthOrchestrator();
  orchestrator.setEngagementRepository(ref.read(engagementRepositoryProvider), user.uid);

  try {
    return await orchestrator.buildState(
      dailyLog: dailyLog,
      metabolicProfile: profile,
      sleepLog: sleepLog,
      workouts: workouts,
    );
  } catch (e) {
    debugPrint('❌ Orchestrator failed to build state: $e');
    return null;
  }
});