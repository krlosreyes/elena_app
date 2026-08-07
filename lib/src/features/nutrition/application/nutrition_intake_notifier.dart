// SPEC-270 — Orquesta el ciclo de vida del intake dietético.
//
// Se suscribe al usuario activo, escucha el stream de Firestore del
// documento único `nutritionProfile/intake`, y expone `saveIntake` con el
// mismo patrón offline-first que el resto del proyecto (nunca `await` un
// write en el camino principal: estado local optimista primero,
// `unawaited(...).catchError(...)` después; el stream reconcilia).
//
// Al guardar, DERIVA los objetivos (peso ideal, proteína y ventana) desde
// el UserModel ya capturado en el onboarding (height/gender/activityLevel
// + firstMealGoal/lastMealGoal). No pide biometría nueva.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_intake_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/protein_target_service.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────

class NutritionIntakeState {
  /// Intake persistido del usuario. `null` = aún no completó el onboarding
  /// del pilar (o todavía cargando).
  final NutritionIntake? intake;
  final bool isLoading;

  const NutritionIntakeState({this.intake, this.isLoading = true});

  bool get hasIntake => intake != null;

  /// True si el usuario ya tiene un retrato utilizable por el motor.
  bool get isComplete => intake?.isComplete ?? false;

  NutritionIntakeState copyWith({
    NutritionIntake? intake,
    bool? isLoading,
    bool clearIntake = false,
  }) {
    return NutritionIntakeState(
      intake: clearIntake ? null : (intake ?? this.intake),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────

class NutritionIntakeNotifier extends StateNotifier<NutritionIntakeState> {
  NutritionIntakeNotifier(this._ref) : super(const NutritionIntakeState()) {
    _init();
  }

  final Ref _ref;
  static const ProteinTargetService _proteinService = ProteinTargetService();

  UserModel? _activeUser;
  StreamSubscription<NutritionIntake?>? _sub;

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) {
          if (user == null) {
            _sub?.cancel();
            _sub = null;
            _activeUser = null;
            if (mounted) {
              state = const NutritionIntakeState(isLoading: false);
            }
            return;
          }
          final changedUser = _activeUser?.id != user.id;
          _activeUser = user; // siempre refrescar (biometría puede cambiar)
          if (changedUser) _subscribe(user.id);
        });
      },
      fireImmediately: true,
    );
  }

  void _subscribe(String userId) {
    _sub?.cancel();
    final repo = _ref.read(nutritionIntakeRepositoryProvider);
    _sub = repo.watchIntake(userId).listen(
      (intake) {
        if (mounted) {
          state = state.copyWith(
            intake: intake,
            isLoading: false,
            clearIntake: intake == null,
          );
        }
      },
      onError: (Object e) {
        // Error transitorio de red/permiso: mantener estado previo.
        AppLogger.warning('nutrition_intake: stream error (transitorio): $e');
      },
    );
  }

  /// Guarda el retrato dietético. Recalcula `updatedAt` y `derived` desde
  /// el UserModel activo — el draft que arma la UI NO necesita traer los
  /// campos derivados. No hace nada si no hay usuario autenticado.
  Future<void> saveIntake(NutritionIntake draft) async {
    final user = _activeUser;
    if (user == null) return;

    final intake = draft.copyWith(
      updatedAt: DateTime.now(),
      derived: _deriveFor(user),
    );

    // Optimista primero (offline-first): el stream reconciliará.
    if (mounted) {
      state = state.copyWith(intake: intake, isLoading: false);
    }

    final repo = _ref.read(nutritionIntakeRepositoryProvider);
    unawaited(
      repo.saveIntake(user.id, intake).catchError((Object e) {
        AppLogger.warning('nutrition_intake: saveIntake falló (reintenta '
            'en próxima escritura): $e');
      }),
    );
  }

  DerivedTargets _deriveFor(UserModel user) {
    return _proteinService.deriveTargets(
      heightCm: user.height,
      gender: user.gender,
      pal: user.activityLevel,
      windowFirst: _fmt(user.profile.firstMealGoal),
      windowLast: _fmt(user.profile.lastMealGoal),
    );
  }

  /// Formatea un DateTime a "HH:mm" (24h). Vacío si es null.
  static String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final nutritionIntakeNotifierProvider =
    StateNotifierProvider<NutritionIntakeNotifier, NutritionIntakeState>((ref) {
  return NutritionIntakeNotifier(ref);
});

/// Azúcar sintáctico: `true` si el usuario ya tiene un intake completo.
/// Útil para gatear la entrada al motor de la minuta (SPEC-272/273).
final hasCompletedIntakeProvider = Provider<bool>((ref) {
  return ref.watch(nutritionIntakeNotifierProvider).isComplete;
});
