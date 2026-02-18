import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/domain/user_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/entities/training_entities.dart';
import '../domain/entities/interactive_routine.dart';
import '../data/repositories/training_repository.dart';
import '../../../core/science/training_physiology.dart';

part 'training_engine_provider.freezed.dart';
part 'training_engine_provider.g.dart';

// ==============================================================================
// 1. Training Recommendation (DECISION LAYER)
//    Determines *what* the user should do today (Strength, Cardio, Deload, etc.)
// ==============================================================================
@riverpod
Future<WorkoutRecommendation> trainingRecommendation(TrainingRecommendationRef ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
      return WorkoutRecommendation.activeRecovery();
  }
  
  // Watch user model
  final userModel = await ref.watch(userStreamProvider(user.uid).future);
  if (userModel == null) return WorkoutRecommendation.activeRecovery();

  // Mock Recovery Score
  final double recoveryScore = 4.0; 

  // Watch weekly stats (Defined in this file or imported?)
  // We need to define or import weeklyTrainingStatsProvider.
  // It was defined in the previous version of this file. Let's keep it.
  final stats = await ref.watch(weeklyTrainingStatsProvider.future);

  // Logic Moved to internal helper or inline
  // Regla 1: Deload
  if (stats.consecutiveWeeksTrained >= 6) {
    return WorkoutRecommendation.deloadWeek();
  }

  // Regla 2: Max HIIT
  if (stats.totalHiitMins >= TrainingPhysiology.maxHiitMinutesWeekly) {
    final maxHr = TrainingPhysiology.calculateMaxHR(user.age);
    final zones = TrainingPhysiology.getAerobicZones(maxHr);
    final zone2 = zones[2]; 

    return WorkoutRecommendation(
      type: 'Cardio',
      targetMuscle: TargetMuscle.cardio,
      durationMinutes: 45,
      intensity: 'Zona 2 (${zone2?[0]}-${zone2?[1]} BPM)',
      notes: 'Has excedido el límite de HIIT. Prioriza cardio de baja intensidad.',
    );
  }

  // Regla 3: Recovery
  if (recoveryScore < 3) {
    return WorkoutRecommendation.activeRecovery();
  }

  // Regla 4: Default Strength
  return const WorkoutRecommendation(
    type: 'Strength',
    targetMuscle: TargetMuscle.fullBody,
    durationMinutes: 60,
    intensity: 'RIR 2',
    notes: 'Entrenamiento de fuerza. Mantén 2 repeticiones en reserva.',
  );
}

@riverpod
Future<WeeklyTrainingStats> weeklyTrainingStats(WeeklyTrainingStatsRef ref) {
  // Re-implement or fix usage of trainingRepositoryProvider
  // We need to make sure trainingRepositoryProvider is available.
  // For now, assume it's imported or we define a local helper.
  return ref.watch(trainingRepositoryProvider).getWeeklyStats();
}

// Temporary repo provider (from previous file, kept to avoid breaking)
@riverpod
TrainingRepository trainingRepository(TrainingRepositoryRef ref) {
  return TrainingRepository(FirebaseFirestore.instance);
}


// ==============================================================================
// 2. Training Engine (EXECUTION LAYER)
//    Manages the *state* of the active workout (Progress, Index, Validation)
// ==============================================================================

@freezed
class TrainingSessionState with _$TrainingSessionState {
  const factory TrainingSessionState({
    @Default(0) int currentIndex,
    @Default(false) bool isDeload,
    @Default(false) bool isSessionActive,
  }) = _TrainingSessionState;
}

@Riverpod(keepAlive: true)
class TrainingEngine extends _$TrainingEngine {
  @override
  TrainingSessionState build() {
    return const TrainingSessionState();
  }

  void initialize({required bool isDeload, int startIndex = 0}) {
    state = state.copyWith(
      isDeload: isDeload,
      currentIndex: startIndex,
      isSessionActive: true,
    );
  }

  void nextPage() {
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }
  
  void previousPage() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  // Helper to check completion (Uses data from DailyRoutineProvider usually)
  // But since we can't easily watch another provider's specific family inside a sync method without ref,
  // we usually pass the exercise object to this method.
  bool isExerciseComplete(InteractiveExercise exercise) {
    if (exercise.sets.isEmpty) return false;
    return exercise.sets.every((s) => s.isDone);
  }
  
  void setIndex(int index) {
      state = state.copyWith(currentIndex: index);
  }
  
  void endSession() {
      state = state.copyWith(isSessionActive: false, currentIndex: 0);
  }
}
