import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/metabolic_state.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/repositories/training_repository.dart';
import '../domain/logic/metabolic_logic.dart';
import '../../profile/data/user_repository.dart';

part 'metabolic_checkin_provider.g.dart';

@Riverpod(keepAlive: true)
class MetabolicCheckin extends _$MetabolicCheckin {
  @override
  FutureOr<MetabolicState?> build() async {
    // 1. Check if we already have one in state (cache)
    //    We don't want to re-fetch if we just saved it.
    if (state.asData?.value != null) return state.asData!.value;

    // 2. Fetch from Repository
    final user = ref.read(currentUserProvider).asData?.value;
    final uid = user?.uid; // Define uid from user
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
    if (state.value != null) return;

    final stateData = MetabolicState(
      date: DateTime.now(),
      sleepHours: sleepHours,
      sorenessLevel: sorenessLevel,
      nutritionStatus: nutritionStatus,
      energyLevel: energyLevel,
      insightMessage: null, // Will be set below
    );
    
    // Generate Insight using Domain Logic
    final user = ref.read(currentUserProvider).value;
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
       // Invalidate the future provider so the UI updates!
       ref.invalidate(isDailyCheckInCompletedProvider); 
     }
  }
}

@riverpod
Future<bool> isDailyCheckInCompleted(Ref ref) async {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
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
  } catch(e) {
     return false; // Fail safe to "Needs checkin" or "Error"?
     // If error, maybe allow? No, better to force check-in to be safe.
  }
}
