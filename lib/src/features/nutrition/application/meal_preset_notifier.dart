// "Mis platos frecuentes" (25-jul-2026) — orquesta el ciclo de vida de
// los presets: se suscribe al usuario activo, escucha el stream de
// Firestore, y expone save/use/delete con el mismo patrón offline-first
// que el resto del proyecto (nunca `await` un write en el camino
// principal — estado local optimista primero, `unawaited(...)
// .catchError(...)` después; el stream reconcilia).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/nutrition/data/meal_preset_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_preset.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────

class MealPresetState {
  /// Presets del usuario, ordenados por `lastUsedAt` descendente (más
  /// reciente primero) — mismo orden que devuelve el repositorio.
  final List<MealPreset> presets;

  final bool isLoading;

  const MealPresetState({this.presets = const [], this.isLoading = true});

  bool get isEmpty => presets.isEmpty;

  MealPresetState copyWith({List<MealPreset>? presets, bool? isLoading}) {
    return MealPresetState(
      presets: presets ?? this.presets,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────

class MealPresetNotifier extends StateNotifier<MealPresetState> {
  MealPresetNotifier(this._ref) : super(const MealPresetState()) {
    _init();
  }

  final Ref _ref;
  String? _activeUserId;
  StreamSubscription<List<MealPreset>>? _sub;

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) {
          if (user == null) {
            _sub?.cancel();
            _sub = null;
            _activeUserId = null;
            if (mounted) state = const MealPresetState(isLoading: false);
            return;
          }
          if (_activeUserId != user.id) {
            _activeUserId = user.id;
            _subscribe(user.id);
          }
        });
      },
      fireImmediately: true,
    );
  }

  void _subscribe(String userId) {
    _sub?.cancel();
    final repo = _ref.read(mealPresetRepositoryProvider);
    _sub = repo.watchPresets(userId).listen(
      (presets) {
        if (mounted) {
          state = state.copyWith(presets: presets, isLoading: false);
        }
      },
      onError: (Object e) {
        // Error transitorio de red o permiso. Mantener estado previo —
        // mismo criterio que el resto de los streams del proyecto.
        AppLogger.warning('meal_presets: stream error (transitorio): $e');
      },
    );
  }

  /// Guarda el plato actual como preset reutilizable.
  ///
  /// [foodIds] debe venir de `PlateBuilder.items.map((f) => f.id)` —
  /// CON repetición, para preservar la cantidad exacta (ver comentario
  /// de cabecera en meal_preset.dart). No hace nada si el usuario no
  /// está autenticado o si el plato está vacío (guardia defensiva; la
  /// UI ya debería impedir llegar acá con builder vacío).
  Future<void> savePreset({
    required String name,
    required List<String> foodIds,
  }) async {
    final userId = _activeUserId;
    if (userId == null || foodIds.isEmpty) return;

    final trimmedName = name.trim();
    final now = DateTime.now();
    final preset = MealPreset(
      id: const Uuid().v4(),
      name: trimmedName.isEmpty ? 'Mi plato' : trimmedName,
      foodIds: foodIds,
      createdAt: now,
      lastUsedAt: now,
      useCount: 1,
    );

    // Update optimista inmediato — el chip nuevo aparece en la UI sin
    // esperar el roundtrip de Firestore, mismo patrón que NutritionNotifier
    // .logMeal.
    if (mounted) {
      state = state.copyWith(presets: [preset, ...state.presets]);
    }

    final repo = _ref.read(mealPresetRepositoryProvider);
    unawaited(repo.savePreset(userId, preset).catchError((Object e) {
      AppLogger.error(
          'meal_presets: guardar preset falló (reintenta al sync)', e);
    }));
  }

  /// Marca un preset como usado: sube `useCount` y refresca `lastUsedAt`
  /// (así la lista se reordena con los más usados/recientes primero).
  /// Se llama cada vez que el usuario aplica un preset a un plato nuevo.
  Future<void> markUsed(String presetId) async {
    final userId = _activeUserId;
    if (userId == null) return;

    final idx = state.presets.indexWhere((p) => p.id == presetId);
    if (idx == -1) return;

    final updated = state.presets[idx].copyWith(
      lastUsedAt: DateTime.now(),
      useCount: state.presets[idx].useCount + 1,
    );

    if (mounted) {
      final reordered = [
        updated,
        ...state.presets.where((p) => p.id != presetId),
      ];
      state = state.copyWith(presets: reordered);
    }

    final repo = _ref.read(mealPresetRepositoryProvider);
    unawaited(repo.savePreset(userId, updated).catchError((Object e) {
      AppLogger.error(
          'meal_presets: marcar uso de preset falló (reintenta al sync)', e);
    }));
  }

  /// Elimina un preset. Update optimista + borrado real no bloqueante,
  /// mismo patrón offline-first que `NutritionNotifier.deleteMealById`.
  Future<void> deletePreset(String presetId) async {
    final userId = _activeUserId;
    if (userId == null) return;

    if (mounted) {
      state = state.copyWith(
        presets: state.presets.where((p) => p.id != presetId).toList(),
      );
    }

    final repo = _ref.read(mealPresetRepositoryProvider);
    unawaited(repo.deletePreset(userId, presetId).catchError((Object e) {
      AppLogger.error(
          'meal_presets: eliminar preset falló (reintenta al sync)', e);
    }));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

final mealPresetProvider =
    StateNotifierProvider<MealPresetNotifier, MealPresetState>((ref) {
  return MealPresetNotifier(ref);
});
