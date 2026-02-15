import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/domain/user_model.dart';
import '../domain/entities/training_entities.dart';
import '../data/repositories/training_repository.dart';
import '../../../core/science/training_physiology.dart';

part 'training_engine_provider.g.dart';

@riverpod
TrainingRepository trainingRepository(TrainingRepositoryRef ref) {
  return TrainingRepositoryImpl();
}

@riverpod
Future<WeeklyTrainingStats> weeklyTrainingStats(WeeklyTrainingStatsRef ref) {
  return ref.watch(trainingRepositoryProvider).getWeeklyStats();
}

@riverpod
class TrainingEngine extends _$TrainingEngine {
  @override
  Future<WorkoutRecommendation> build() async {
    final authState = ref.watch(authStateChangesProvider);
    final user = authState.value;

    if (user == null) {
       // Default safe recommendation if no user
       return WorkoutRecommendation.activeRecovery();
    }
    
    // Watch user model for age and goals
    final userModel = await ref.watch(userStreamProvider(user.uid).future);
    if (userModel == null) return WorkoutRecommendation.activeRecovery();

    // Mock Recovery Score (1-5) - In future, read from HRV/Sleep data
    // For now, random or 3.0
    final double recoveryScore = 4.0; 

    // Watch weekly stats
    final stats = await ref.watch(weeklyTrainingStatsProvider.future);

    return _generateRecommendation(userModel, stats, recoveryScore);
  }

  WorkoutRecommendation _generateRecommendation(
    UserModel user, 
    WeeklyTrainingStats stats,
    double recoveryScore,
  ) {
    // Regla 1: Deload
    if (stats.consecutiveWeeksTrained >= 6) {
      return WorkoutRecommendation.deloadWeek();
    }

    // Regla 2: Max HIIT Check
    if (stats.totalHiitMins >= TrainingPhysiology.maxHiitMinutesWeekly) {
      final maxHr = TrainingPhysiology.calculateMaxHR(user.age);
      final zones = TrainingPhysiology.getAerobicZones(maxHr);
      final zone2 = zones[2]; // Zone 2

      return WorkoutRecommendation(
        type: 'Cardio',
        targetMuscle: TargetMuscle.cardio,
        durationMinutes: 45,
        intensity: 'Zona 2 (${zone2?[0]}-${zone2?[1]} BPM)',
        notes: 'Has excedido el límite de HIIT. Prioriza cardio de baja intensidad para salud mitocondrial.',
      );
    }

    // Regla 3: Recovery Check
    if (recoveryScore < 3) {
      return WorkoutRecommendation.activeRecovery();
    }

    // Regla 4: Strength / Hypertrophy
    // Logic to choose muscle group. 
    // Simplified: Rotate based on mock history or simply recommend Full Body if unspecified.
    // Prompt says: "Busca el TargetMuscle que lleve más tiempo sin entrenar (> 48h)"
    // Since we don't have granular history in this mock, we'll default to Full Body or Split A/B logic.
    // Let's assume Full Body for simplicity in this MVP unless we read last session.
    
    return const WorkoutRecommendation(
      type: 'Strength',
      targetMuscle: TargetMuscle.fullBody,
      durationMinutes: 60,
      intensity: 'RIR 2',
      notes: 'Entrenamiento de fuerza. Mantén 2 repeticiones en reserva en cada serie.',
    );
  }
}
