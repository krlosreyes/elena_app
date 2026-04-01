import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/profile/application/user_controller.dart';
import 'package:elena_app/src/features/training/data/repositories/training_repository.dart';
import 'package:elena_app/src/features/training/domain/entities/exercise_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRAINING PROVIDERS — Riverpod state management for training features
// Manual definitions to avoid build_runner conflicts
// ─────────────────────────────────────────────────────────────────────────────

/// Singleton TrainingRepository provider
final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  return TrainingRepositoryImpl(FirebaseFirestore.instance);
});

/// Get exercise by ID
final exerciseByIdProvider =
    FutureProvider.family<ExerciseModel?, String>((ref, exerciseId) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getExerciseById(exerciseId);
});

/// Get exercises by category
final exercisesByCategoryProvider =
    FutureProvider.family<List<ExerciseModel>, ExerciseCategory>(
        (ref, category) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getExercisesByCategory(category);
});

/// Search exercises by query
final searchExercisesProvider =
    FutureProvider.family<List<ExerciseModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.searchExercises(query);
});

/// Get active muscles from last 24 hours of workouts
final activeMusclesLast24HoursProvider =
    FutureProvider.family<Set<String>, String>((ref, userId) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getActiveMusclesLast24Hours(userId);
});

/// Get recent workout sessions for current user in last 24 hours
final recentRecordedWorkoutSessionsProvider =
    FutureProvider.autoDispose<List<RecordedWorkoutSession>>((ref) async {
  final userAsync = await ref.watch(currentUserStreamProvider.future);
  if (userAsync == null) return [];

  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getRecentWorkoutSessions(userAsync.uid, 24);
});

/// Seed Metamorfosis exercises (one-time operation)
final seedMetamorfosisExercisesProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.seedMetamorfosisExercises();
});

/// Trigger to invalidate providers when workout is saved
/// Used for cascading updates (biometric profile, metabolic hub)
final workoutSessionSavedNotifier =
    StateNotifierProvider<WorkoutSessionSavedNotifier, RecordedWorkoutSession?>(
        (ref) {
  return WorkoutSessionSavedNotifier(null);
});

class WorkoutSessionSavedNotifier
    extends StateNotifier<RecordedWorkoutSession?> {
  WorkoutSessionSavedNotifier(super.initialState);

  void setWorkoutSession(RecordedWorkoutSession session) {
    state = session;
  }
}
