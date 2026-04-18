import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final exerciseProvider = StateNotifierProvider<ExerciseNotifier, ExerciseState>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  final repo = ref.watch(userRepositoryProvider);
  
  return ExerciseNotifier(
    userId: userAsync.valueOrNull?.id,
    repository: repo,
  );
});

class ExerciseNotifier extends StateNotifier<ExerciseState> {
  final String? userId;
  final UserRepository repository;
  StreamSubscription? _subscription;

  ExerciseNotifier({
    required this.userId,
    required this.repository,
  }) : super(const ExerciseState()) {
    _initSubscription();
  }

  void _initSubscription() {
    if (userId == null) return;
    
    _subscription?.cancel();
    _subscription = repository.watchTodayExercise(userId!).listen(
      (minutes) {
        if (mounted) {
          state = state.copyWith(todayMinutes: minutes, error: null);
        }
      },
      onError: (err) {
        if (mounted) {
          state = state.copyWith(error: "Error al cargar ejercicio: $err");
        }
      },
    );
  }

  Future<void> registerExercise({
    required int minutes,
    required String activityType,
    required DateTime timestamp,
  }) async {
    if (userId == null) {
      state = state.copyWith(error: "No hay sesión activa");
      return;
    }

    if (minutes > 120) {
      state = state.copyWith(error: "Máximo 120 min por registro");
      throw Exception("Máximo 120 min por registro");
    }

    if (timestamp.isAfter(DateTime.now())) {
      state = state.copyWith(error: "No se puede registrar ejercicio futuro");
      throw Exception("No se puede registrar ejercicio futuro");
    }

    if (minutes <= 0) {
      state = state.copyWith(error: "La duración debe ser mayor a 0");
      throw Exception("La duración debe ser mayor a 0");
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final log = ExerciseLog(
        id: const Uuid().v4(),
        userId: userId!,
        durationMinutes: minutes,
        activityType: activityType,
        timestamp: timestamp,
      );

      await repository.saveExerciseLog(userId!, log);
      state = state.copyWith(isSaving: false, error: null);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: "Fallo al guardar: $e");
      throw Exception(state.error);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
