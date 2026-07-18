// SPEC-14: Objetivos del Usuario
// StateNotifier que gestiona el mapa de goals del usuario en memoria
// y lo sincroniza con Firestore via GoalRepository.
// Sigue el mismo patrón de HydrationNotifier: escucha currentUserStreamProvider.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/data/goal_repository.dart';

// ─── State: mapa de GoalType → UserGoal ──────────────────────────────────────

typedef GoalsMap = Map<GoalType, UserGoal>;

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GoalNotifier extends StateNotifier<GoalsMap> {
  final Ref _ref;
  StreamSubscription<GoalsMap>? _goalsSubscription;
  String? _currentUserId;

  GoalNotifier(this._ref) : super(const {}) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (_, next) {
        next.whenData((user) {
          if (user != null && user.id.isNotEmpty) {
            if (_currentUserId != user.id) {
              _currentUserId = user.id;
              _subscribeToGoals(user.id);
            }
          } else {
            _cancelSubscription();
            if (mounted) state = const {};
          }
        });
      },
      fireImmediately: true, // dispara con el valor actual al inicializar
    );
  }

  void _subscribeToGoals(String userId) {
    _goalsSubscription?.cancel();
    _goalsSubscription =
        _ref.read(goalRepositoryProvider).watchGoals(userId).listen((goals) {
      if (mounted) state = goals;
    });
  }

  void _cancelSubscription() {
    _goalsSubscription?.cancel();
    _goalsSubscription = null;
    _currentUserId = null;
  }

  // ─── API pública ────────────────────────────────────────────────────────────

  /// Agrega o actualiza un objetivo. Persiste en Firestore.
  ///
  /// FB-03 (auditoría 2026-07-11): antes hacía `await` directo sobre el
  /// write de Firestore. Si el dispositivo estaba offline, ese `await`
  /// nunca resolvía y cualquier caller que esperara este Future (p. ej.
  /// goal_setup_screen.dart mostrando un spinner de "guardando") quedaba
  /// bloqueado indefinidamente — el mismo bug raíz que motivó SPEC-206.
  /// Ahora se sigue el patrón "write no-bloqueante + listener como fuente
  /// de verdad" ya validado en HydrationNotifier: el estado local se
  /// actualiza de inmediato (optimista) y el write a Firestore corre en
  /// background; `watchGoals` (la subscripción activa) reconcilia el
  /// estado cuando el servidor confirma.
  Future<void> setGoal(UserGoal goal) async {
    if (_currentUserId == null) return;
    final updated = {...state, goal.type: goal};
    state = updated;
    final userId = _currentUserId!;
    unawaited(
      _ref
          .read(goalRepositoryProvider)
          .saveGoals(userId, updated)
          .catchError((Object e) {
        AppLogger.error('GoalNotifier.setGoal falló', e);
      }),
    );
  }

  /// Desactiva un objetivo (lo mantiene en Firestore pero con isActive = false).
  Future<void> deactivateGoal(GoalType type) async {
    final existing = state[type];
    if (existing == null || _currentUserId == null) return;
    await setGoal(existing.copyWith(isActive: false));
  }

  /// Activa un objetivo previamente desactivado.
  Future<void> activateGoal(GoalType type) async {
    final existing = state[type];
    if (existing == null || _currentUserId == null) return;
    await setGoal(existing.copyWith(isActive: true));
  }

  /// Elimina un objetivo completamente.
  /// FB-03: mismo patrón no-bloqueante que setGoal (ver comentario arriba).
  Future<void> removeGoal(GoalType type) async {
    if (_currentUserId == null) return;
    final updated = Map<GoalType, UserGoal>.from(state)..remove(type);
    state = updated;
    final userId = _currentUserId!;
    unawaited(
      _ref
          .read(goalRepositoryProvider)
          .saveGoals(userId, updated)
          .catchError((Object e) {
        AppLogger.error('GoalNotifier.removeGoal falló', e);
      }),
    );
  }

  /// Persiste todos los goals actuales (útil tras el setup masivo).
  /// FB-03: mismo patrón no-bloqueante que setGoal (ver comentario arriba).
  /// Los callers (goal_setup_screen.dart, onboarding_screen.dart) hacen
  /// `await saveAll(...)` para mostrar su propio spinner local; con este
  /// cambio ese await resuelve tan pronto el estado local se actualiza,
  /// sin esperar la confirmación de red.
  Future<void> saveAll(Map<GoalType, UserGoal> goals) async {
    if (_currentUserId == null) return;
    state = goals;
    final userId = _currentUserId!;
    unawaited(
      _ref
          .read(goalRepositoryProvider)
          .saveGoals(userId, goals)
          .catchError((Object e) {
        AppLogger.error('GoalNotifier.saveAll falló', e);
      }),
    );
  }

  /// Lista de goals activos ordenados por pilar.
  List<UserGoal> get activeGoals =>
      state.values.where((g) => g.isActive).toList()
        ..sort((a, b) => a.type.index.compareTo(b.type.index));

  @override
  void dispose() {
    _goalsSubscription?.cancel();
    super.dispose();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final goalsProvider = StateNotifierProvider<GoalNotifier, GoalsMap>((ref) {
  return GoalNotifier(ref);
});
