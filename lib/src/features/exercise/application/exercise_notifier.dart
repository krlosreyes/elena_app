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
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// SPEC-180 (2026-06-05): factory simple sin ref.watch del usuario.
// Antes hacíamos `ref.watch(currentUserStreamProvider)` dentro de la
// factory, lo cual destruía el ExerciseNotifier cada vez que el stream
// del usuario emitía (token refresh, cambio de perfil, etc.) y
// re-inicializaba todo el state desde cero — perdiendo subscripción
// al ciclo metabólico y dejando ejercicio en 0 hasta el próximo
// cambio de ciclo.
//
// Patrón nuevo (alineado con HydrationNotifier y NutritionNotifier):
// el notifier es singleton durante la sesión; usa `_ref.listen` para
// reaccionar a cambios de usuario sin reconstruirse.
final exerciseProvider =
    StateNotifierProvider<ExerciseNotifier, ExerciseState>((ref) {
  return ExerciseNotifier(ref: ref);
});

class ExerciseNotifier extends StateNotifier<ExerciseState> {
  final Ref ref;
  String? _activeUserId;
  StreamSubscription? _subscription;
  DateTime? _currentCycleStartedAt;

  ExerciseNotifier({required this.ref}) : super(const ExerciseState()) {
    _init();
  }

  void _init() {
    // Listener del usuario activo. Cambia userId interno sin destruir
    // el notifier. Al cambiar, re-suscribe al stream con la nueva uid.
    ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) {
          if (user != null && user.id.isNotEmpty) {
            if (_activeUserId != user.id) {
              _activeUserId = user.id;
              _subscribeFor(_currentCycleStartedAt);
            }
          } else {
            // Logout: cancelar y limpiar estado.
            _subscription?.cancel();
            _subscription = null;
            _activeUserId = null;
            if (mounted) state = const ExerciseState();
          }
        });
      },
      fireImmediately: true,
    );

    // SPEC-149.2 + SPEC-178.bugfix2: re-suscribir cuando cambia el
    // ciclo metabólico. La condición `_subscription == null` cubre el
    // caso inicial donde el primer fire trae cycle=null y la igualdad
    // null==null bloquearía la suscripción.
    ref.listen<AsyncValue<MetabolicCycle?>>(
      currentMetabolicCycleProvider,
      (previous, next) {
        next.whenData((cycle) {
          final newSince = cycle?.startedAt;
          if (_subscription == null ||
              newSince != _currentCycleStartedAt) {
            _currentCycleStartedAt = newSince;
            _subscribeFor(newSince);
          }
        });
      },
      fireImmediately: true,
    );
  }

  void _subscribeFor(DateTime? cycleStartedAt) {
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) return;
    _subscription?.cancel();
    final since =
        cycleStartedAt ?? DayBoundaryResolver.startOfDay(DateTime.now());
    final repo = ref.read(exerciseRepositoryProvider);
    _subscription = repo.watchSince(userId, since).listen(
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
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) {
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
        userId: userId,
        durationMinutes: minutes,
        activityType: activityType,
        timestamp: timestamp,
        type: type,
        intensity: intensity,
        rpe: rpe,
        heartRateAvg: heartRateAvg,
      );

      final repo = ref.read(exerciseRepositoryProvider);
      await repo.save(userId, log);
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
