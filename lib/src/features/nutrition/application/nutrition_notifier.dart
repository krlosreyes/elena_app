// SPEC-63: NutritionNotifier consume el NutritionRepository — los logs
// ahora persisten en Firestore en lugar de vivir solo en memoria.
//
// Antes: la lista de logs vivía en `state.todayLogs` y se perdía al cerrar
// la app. Ahora: el repositorio es la fuente de verdad; el state local
// sólo es un cache reactivo del stream `watchTodayLogs`.
//
// CONSTITUTION §3.2: este archivo NO importa cloud_firestore. Solo conoce
// el contrato `NutritionRepository`.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class NutritionState {
  /// Cuántas comidas tiene como objetivo el usuario por día.
  final int targetMeals;

  /// Logs del día actual (cache reactivo del stream del repositorio).
  final List<NutritionLog> todayLogs;

  /// Score 0.0-1.0 que el ScoreEngine consume para el bloque Conducta.
  /// 60% adherencia de cantidad + 40% adherencia de ventana circadiana.
  final double nutritionScore;

  /// % de comidas registradas dentro de la ventana circadiana.
  final double windowAdherence;

  final bool isSaving;

  const NutritionState({
    this.targetMeals = 3,
    this.todayLogs = const [],
    this.nutritionScore = 0.0,
    this.windowAdherence = 0.0,
    this.isSaving = false,
  });

  int get mealsLoggedToday => todayLogs.length;

  double get progressPercentage =>
      (mealsLoggedToday / targetMeals.clamp(1, 10)).clamp(0.0, 1.0);

  String get nextMealLabel {
    switch (mealsLoggedToday) {
      case 0:
        return 'Desayuno';
      case 1:
        return targetMeals <= 2 ? 'Cena' : 'Almuerzo';
      case 2:
        return 'Cena';
      default:
        return 'Snack';
    }
  }

  NutritionState copyWith({
    int? targetMeals,
    List<NutritionLog>? todayLogs,
    double? nutritionScore,
    double? windowAdherence,
    bool? isSaving,
  }) {
    return NutritionState(
      targetMeals: targetMeals ?? this.targetMeals,
      todayLogs: todayLogs ?? this.todayLogs,
      nutritionScore: nutritionScore ?? this.nutritionScore,
      windowAdherence: windowAdherence ?? this.windowAdherence,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NutritionNotifier extends StateNotifier<NutritionState> {
  NutritionNotifier(this._ref) : super(const NutritionState()) {
    _init();
  }

  final Ref _ref;
  CircadianProfile? _circadianProfile;
  StreamSubscription<List<NutritionLog>>? _logsSub;
  String? _activeUserId;

  void _init() {
    // Escucha cambios de usuario para targetMeals, perfil circadiano y stream.
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) {
          if (user == null) {
            _activeUserId = null;
            _logsSub?.cancel();
            _logsSub = null;
            if (mounted) state = const NutritionState();
            return;
          }
          _circadianProfile = user.profile;
          if (_activeUserId != user.id) {
            _activeUserId = user.id;
            _subscribeToLogs(user.id);
          }
          // Recalcula con los nuevos parámetros del usuario.
          final updated = _recalculate(state.todayLogs, user.mealsPerDay);
          state = updated.copyWith(targetMeals: user.mealsPerDay);
        });
      },
      fireImmediately: true,
    );
  }

  void _subscribeToLogs(String userId) {
    _logsSub?.cancel();
    final repo = _ref.read(nutritionRepositoryProvider);
    _logsSub = repo.watchTodayLogs(userId).listen(
      (logs) {
        if (!mounted) return;
        state = _recalculate(logs, state.targetMeals);
      },
      onError: (Object _) {
        // El repositorio puede emitir errors transitorios de red. Mantener
        // el estado anterior; el próximo evento estable corregirá.
      },
    );
  }

  // ─── API pública ─────────────────────────────────────────────────────────

  /// Registra una comida.
  ///
  /// [label]    — etiqueta semántica opcional; si no se provee se infiere.
  /// [mealTime] — timestamp opcional; si no se provee se usa `DateTime.now()`.
  ///
  /// SPEC-71.3: macros opcionales (SPEC-64). Si el usuario no los provee,
  /// quedan null y el log se persiste sin información nutricional — el
  /// ScoreEngine sigue contando la comida en el ratio meal/target sin
  /// penalizar la ausencia de macros (peso 0.12 conservador, ver
  /// IMR_BIBLIOGRAPHY.md §4.4).
  Future<void> logMeal({
    String? label,
    DateTime? mealTime,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? glycemicIndex,
    NutritionLogSource source = NutritionLogSource.userInput,
  }) async {
    final userId = _activeUserId;
    if (userId == null) return;

    final timestamp = mealTime ?? DateTime.now();
    final effectiveLabel = label ?? state.nextMealLabel;
    final withinWindow = _isWithinCircadianWindow(timestamp);

    final log = NutritionLog(
      id: const Uuid().v4(),
      timestamp: timestamp,
      label: effectiveLabel,
      withinCircadianWindow: withinWindow,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      glycemicIndex: glycemicIndex,
      source: source,
    );

    if (mounted) state = state.copyWith(isSaving: true);
    try {
      final repo = _ref.read(nutritionRepositoryProvider);
      await repo.saveMeal(userId, log);
      // El stream emitirá la nueva lista; no hay que mutar todayLogs aquí.
    } finally {
      if (mounted) state = state.copyWith(isSaving: false);
    }
  }

  /// Elimina el último registro del día.
  Future<void> removeLastMeal() async {
    final userId = _activeUserId;
    if (userId == null) return;
    final repo = _ref.read(nutritionRepositoryProvider);
    await repo.removeLastMeal(userId);
    // El stream emitirá la lista actualizada.
  }

  /// Reset diario: solo limpia el cache local. Los logs persistidos quedan
  /// para análisis longitudinal; el stream emitirá lista vacía mañana.
  void resetDaily() {
    if (!mounted) return;
    state = state.copyWith(
      todayLogs: const [],
      nutritionScore: 0.0,
      windowAdherence: 0.0,
    );
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    super.dispose();
  }

  // ─── Lógica interna ──────────────────────────────────────────────────────

  bool _isWithinCircadianWindow(DateTime time) {
    final profile = _circadianProfile;
    if (profile == null) return true;
    final first = profile.firstMealGoal;
    final last = profile.lastMealGoal;
    if (first == null || last == null) return true;
    final timeMinutes = time.hour * 60 + time.minute;
    final firstMinutes = first.hour * 60 + first.minute;
    final lastMinutes = last.hour * 60 + last.minute;
    return timeMinutes >= firstMinutes && timeMinutes <= lastMinutes;
  }

  /// Recalcula nutritionScore y windowAdherence dado un conjunto de logs.
  NutritionState _recalculate(List<NutritionLog> logs, int target) {
    final int count = logs.length;
    final double mealCountScore = (count / target.clamp(1, 10)).clamp(0.0, 1.0);
    final double windowAdherence = count == 0
        ? 0.0
        : logs.where((l) => l.withinCircadianWindow).length / count;
    final double score =
        ((0.60 * mealCountScore) + (0.40 * windowAdherence)).clamp(0.0, 1.0);
    return state.copyWith(
      todayLogs: logs,
      nutritionScore: score,
      windowAdherence: windowAdherence,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  return NutritionNotifier(ref);
});
