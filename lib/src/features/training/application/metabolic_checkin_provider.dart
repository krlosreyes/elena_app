import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/metabolic_state.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/repositories/training_repository.dart';
import '../domain/logic/metabolic_logic.dart';
import '../../profile/data/user_repository.dart';

part 'metabolic_checkin_provider.g.dart';

@riverpod
class MetabolicCheckin extends _$MetabolicCheckin {
  @override
  Future<MetabolicState?> build() async {
    // 1. Try to load from repository (if check-in already done today)
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return null;

    final today = DateTime.now();
    try {
        final repo = ref.watch(trainingRepositoryProvider);
        final checkin = await repo.getDailyCheckin(uid, today);
        return checkin;
    } catch(e) {
        // Log error
        print("Error loading metabolic checkin: $e");
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
    if (state.valueOrNull != null) return;

    final stateData = MetabolicState(
      date: DateTime.now(),
      sleepHours: sleepHours,
      sorenessLevel: sorenessLevel,
      nutritionStatus: nutritionStatus,
      energyLevel: energyLevel,
      insightMessage: null, // Will be set below
    );
    
    // Generate Insight using Domain Logic
    final user = ref.read(currentUserProvider).valueOrNull;
    final userName = user?.name ?? "Atleta";
    
    // Logic import needed or duplicate? Let's assume we can import logic.
    // Since we are in application layer, we should import domain logic.
    // import '../domain/logic/metabolic_logic.dart';
    
    // For now, I'll use the static method. I need to add import to file.
    final insight = MetabolicLogic.generateInsightMessage(stateData, userName);
    final finalState = stateData.copyWith(insightMessage: insight);

    state = AsyncData(finalState);
    
    // Persist logic
     final uid = ref.read(authRepositoryProvider).currentUser?.uid;
     if (uid != null) {
       await ref.read(trainingRepositoryProvider).saveCheckin(uid, finalState);
     }
  }
}
