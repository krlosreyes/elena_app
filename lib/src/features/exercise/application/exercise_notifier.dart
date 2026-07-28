import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
// SPEC-194.1 (2026-06-06): day_boundary_resolver reintroducido como
// fallback exclusivo para el caso "sin ciclo abierto". Cuando hay
// ciclo, sigue cycle-aware estricto (Constitución §1).
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/core/offline_first_stream_mixin.dart';
import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/features/coaching/application/coaching_completion_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
// SPEC-189: el import del repositorio abstracto era unused (pre-existente).
// import 'package:elena_app/src/features/exercise/domain/exercise_repository.dart';
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

class ExerciseNotifier extends StateNotifier<ExerciseState>
    with OfflineFirstStreamMixin<ExerciseState> {
  final Ref ref;
  String? _activeUserId;
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
            cancelActiveSubscription();
            _activeUserId = null;
            if (mounted) state = const ExerciseState();
          }
        });
      },
      fireImmediately: true,
    );

    // SPEC-149.2 + SPEC-178.bugfix2: re-suscribir cuando cambia el
    // ciclo metabólico. La condición `!hasActiveSubscription` cubre el
    // caso inicial donde el primer fire trae cycle=null y la igualdad
    // null==null bloquearía la suscripción.
    ref.listen<AsyncValue<MetabolicCycle?>>(
      currentMetabolicCycleProvider,
      (previous, next) {
        next.whenData((cycle) {
          final newSince = cycle?.startedAt;
          if (!hasActiveSubscription || newSince != _currentCycleStartedAt) {
            _currentCycleStartedAt = newSince;
            _subscribeFor(newSince);
          }
        });
      },
      fireImmediately: true,
    );
  }

  /// SPEC-149.2 + SPEC-189 + SPEC-194.1 (2026-06-06): suscripción
  /// cycle-aware con FALLBACK `startOfDay(now)` cuando no hay ciclo
  /// abierto. Con ciclo activo, ventana desde `cycle.startedAt`
  /// (Constitución §1). Sin ciclo, ventana desde startOfDay para que
  /// los registros del día sean visibles. Cuando se abra el ciclo, el
  /// listener re-suscribe automáticamente con la ventana cycle-aware.
  void _subscribeFor(DateTime? cycleStartedAt) {
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) return;
    final since =
        cycleStartedAt ?? DayBoundaryResolver.startOfDay(DateTime.now());
    final repo = ref.read(exerciseRepositoryProvider);
    attachSubscription(repo.watchSince(userId, since).listen(
      (logs) {
        if (mounted) {
          final totalMinutes = logs.fold<int>(
            0,
            (sum, log) => sum + log.durationMinutes,
          );
          // Ordenamos desc por timestamp para que history[0] sea la más reciente.
          final sorted = [...logs]
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          state = state.copyWith(
            todayMinutes: totalMinutes,
            history: sorted,
            error: null,
          );
        }
      },
      onError: (Object err) {
        // SPEC-211: no cambiar state — el dato anterior sigue siendo válido.
        AppLogger.warning(
            '[ExerciseNotifier] stream error (transitorio): $err');
      },
      onDone: () {
        // SPEC-211: Firestore cerró el stream (token refresh, reconexión).
        if (mounted) _subscribeFor(cycleStartedAt);
      },
    ));
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

    // SPEC-206 (offline-first): registro optimista. El listener `watchSince`
    // refleja el log desde la caché al instante (con o sin red) y el write
    // sincroniza al reconectar.
    // BUG-FIX: antes se ponía isSaving=false directamente sin pasar por true
    // → el botón del sheet NUNCA se deshabilitaba → taps rápidos creaban
    // sesiones duplicadas (cada tap genera un UUID nuevo → no hay dedup).
    final repo = ref.read(exerciseRepositoryProvider);
    state = state.copyWith(isSaving: true, error: null);

    // SPEC-193/194: analytics (se auto-encola sin red) + coaching.
    AnalyticsService.logEvent(
      AnalyticsEvents.pillarLogged,
      params: const {AnalyticsParams.pillar: 'exercise'},
    );
    ref.read(coachingCompletionProvider).onPillarActivity(Pillar.exercise);

    unawaited(
      repo.save(userId, log).then((_) {
        if (mounted) state = state.copyWith(isSaving: false);
      }).catchError((Object e) {
        // Error REAL (no el offline pendiente): informar a la UI.
        if (mounted)
          state =
              state.copyWith(isSaving: false, error: 'Fallo al guardar: $e');
      }),
    );
  }

  /// Elimina la última sesión registrada en el ciclo activo.
  /// El stream re-emite la lista corregida automáticamente.
  Future<void> removeLastSession() async {
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) return;
    if (state.history.isEmpty) return;

    final since = _currentCycleStartedAt ??
        DayBoundaryResolver.startOfDay(DateTime.now());

    unawaited(
      ref
          .read(exerciseRepositoryProvider)
          .removeLastSession(userId, since)
          .catchError((Object e) {
        AppLogger.error('ExerciseNotifier.removeLastSession falló', e);
        if (mounted) {
          state = state.copyWith(
              error: 'No pudimos eliminar la sesión. Revisa tu conexión.');
        }
      }),
    );
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
}
