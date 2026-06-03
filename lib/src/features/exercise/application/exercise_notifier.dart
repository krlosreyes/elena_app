import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_repository.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final exerciseProvider =
    StateNotifierProvider<ExerciseNotifier, ExerciseState>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  // SPEC-50.2: ExerciseRepository (no UserRepository).
  final repo = ref.watch(exerciseRepositoryProvider);

  return ExerciseNotifier(
    userId: userAsync.valueOrNull?.id,
    repository: repo,
    ref: ref,
  );
});

class ExerciseNotifier extends StateNotifier<ExerciseState> {
  final String? userId;
  final ExerciseRepository repository;
  final Ref ref;
  StreamSubscription? _subscription;
  DateTime? _currentCycleStartedAt;

  ExerciseNotifier({
    required this.userId,
    required this.repository,
    required this.ref,
  }) : super(const ExerciseState()) {
    _initCycleListener();
  }

  /// SPEC-149.2: escucha el ciclo metabólico y re-suscribe el stream
  /// con `watchSince(cycle.startedAt)` cuando cambia. Si no hay ciclo
  /// abierto, fallback a `startOfDay` (comportamiento previo).
  void _initCycleListener() {
    if (userId == null) return;
    ref.listen<AsyncValue<MetabolicCycle?>>(
      currentMetabolicCycleProvider,
      (previous, next) {
        next.whenData((cycle) {
          final newSince = cycle?.startedAt;
          if (newSince != _currentCycleStartedAt) {
            _currentCycleStartedAt = newSince;
            _subscribeFor(newSince);
          }
        });
      },
      fireImmediately: true,
    );
  }

  void _subscribeFor(DateTime? cycleStartedAt) {
    if (userId == null) return;
    _subscription?.cancel();
    final since =
        cycleStartedAt ?? DayBoundaryResolver.startOfDay(DateTime.now());
    _subscription = repository.watchSince(userId!, since).listen(
      (logs) {
        if (mounted) {
          final totalMinutes = logs.fold<int>(
            0,
            (sum, log) => sum + log.durationMinutes,
          );
          state = state.copyWith(todayMinutes: totalMinutes, error: null);
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
    // SPEC-71.2: tipado opcional (SPEC-68). Si no se provee, los logs
    // legacy siguen funcionando y el ScoreEngine usa multiplicadores
    // neutros (= curva minutos/30 de antes).
    ExerciseType? type,
    ExerciseIntensity? intensity,
    int? rpe,
    int? heartRateAvg,
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
        type: type,
        intensity: intensity,
        rpe: rpe,
        heartRateAvg: heartRateAvg,
      );

      await repository.save(userId!, log);
      state = state.copyWith(isSaving: false, error: null);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: "Fallo al guardar: $e");
      throw Exception(state.error);
    }
  }

  /// SPEC-58 + SPEC-149.2: Reset idempotente disparado al cierre del
  /// ciclo metabólico o a medianoche calendárica (red de seguridad).
  ///
  /// Limpia minutos en caché y mensajes de error, y re-suscribe el
  /// stream usando el `since` del ciclo activo (anclado al Día
  /// Metabólico, no al calendario).
  void resetDaily() {
    if (!mounted) return;
    state = const ExerciseState();
    _subscribeFor(_currentCycleStartedAt);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
