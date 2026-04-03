import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/health/providers/health_snapshot_provider.dart';
import '../../authentication/application/auth_controller.dart';
import '../domain/entities/metabolic_state.dart';
import 'training_provider.dart';

part 'metabolic_checkin_provider.g.dart';

@Riverpod(keepAlive: true)
class MetabolicCheckin extends _$MetabolicCheckin {
  @override
  FutureOr<MetabolicState?> build() async {
    // 1. Check if we already have one in state (cache)
    //    We don't want to re-fetch if we just saved it.
    if (state.asData?.value != null) return state.asData!.value;

    // 2. Fetch from Repository
    final user = ref.read(authControllerProvider.notifier).currentUser;
    final uid = user?.uid; // Define uid from user
    if (uid == null) return null;

    final today = DateTime.now();
    try {
      final repo = ref.watch(trainingRepositoryProvider);
      final checkin = await repo.getDailyCheckin(uid, today);
      return checkin;
    } catch (e) {
      // Log error
      debugPrint("Error loading metabolic checkin: $e");
      return null;
    }
  }

  Future<void> submitCheckin({
    required double sleepHours,
    required int sorenessLevel,
    required String nutritionStatus,
    required double energyLevel,
  }) async {
    // IMMUTABILITY CHECK: If already checked in for today, do NOT overwrite.
    if (state.value != null) return;

    final snapshot = ref.read(healthSnapshotProvider).valueOrNull;
    final stateData = snapshot != null
        ? MetabolicState.fromUserHealthState(
            snapshot.state,
            date: DateTime.now(),
            sleepHoursOverride: sleepHours,
            sorenessLevelOverride: sorenessLevel,
            nutritionStatusOverride: nutritionStatus,
            energyLevelOverride: energyLevel,
            insightMessage: null,
          )
        : MetabolicState(
            date: DateTime.now(),
            sleepHours: sleepHours,
            sorenessLevel: sorenessLevel,
            nutritionStatus: nutritionStatus,
            energyLevel: energyLevel,
            insightMessage: null,
          );

    // Moved to DecisionEngine in Phase 3
    final decision = ref.read(healthSnapshotProvider).valueOrNull?.decision;
    final insight = decision != null
        ? '${decision.primaryAction}. ${decision.explanation}'
        : 'Check-in registrado. Elena ajustará tu plan con tu estado integral.';
    final finalState = stateData.copyWith(insightMessage: insight);

    state = AsyncData(finalState);

    // Persist logic
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    if (uid != null) {
      await ref.read(trainingRepositoryProvider).saveCheckin(uid, finalState);
      // Invalidate the future provider so the UI updates!
      ref.invalidate(isDailyCheckInCompletedProvider);
    }
  }
}

@riverpod
Future<bool> isDailyCheckInCompleted(Ref ref) async {
  final uid = ref.watch(authControllerProvider.notifier).currentUser?.uid;
  if (uid == null) return false;

  final repo = ref.watch(trainingRepositoryProvider);
  final today = DateTime.now();

  // Reuse the repository logic or cache?
  // It's safer to fetch fresh or rely on the other provider if it's consistent.
  // But user asked for a "Guardia de Ruta" that works.
  try {
    final checkin = await repo.getDailyCheckin(uid, today);

    if (checkin == null) return false;

    // STRICT DATE VALIDATION (Application Layer)
    final checkInDate = checkin.date; // already DateTime in entity
    final isSameDay = checkInDate.year == today.year &&
        checkInDate.month == today.month &&
        checkInDate.day == today.day;

    return isSameDay;
  } catch (e) {
    return false; // Fail safe to "Needs checkin" or "Error"?
    // If error, maybe allow? No, better to force check-in to be safe.
  }
}
