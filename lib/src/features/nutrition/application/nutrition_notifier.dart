import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NutritionState
// ─────────────────────────────────────────────────────────────────────────────

class NutritionState {
  /// Cuántas comidas tiene como objetivo el usuario por día (de UserModel).
  final int targetMeals;

  /// Registro en memoria de comidas del día actual.
  final List<NutritionLog> todayLogs;

  /// Score 0.0-1.0 que el ScoreEngine consume para el bloque Conducta.
  /// Fórmula: 60% adherencia de cantidad + 40% adherencia de ventana circadiana.
  final double nutritionScore;

  /// % de las comidas registradas que cayeron dentro de la ventana circadiana.
  final double windowAdherence;

  final bool isSaving;

  const NutritionState({
    this.targetMeals = 3,
    this.todayLogs = const [],
    this.nutritionScore = 0.0,
    this.windowAdherence = 0.0,
    this.isSaving = false,
  });

  // ── Computed ────────────────────────────────────────────────────────────────

  int get mealsLoggedToday => todayLogs.length;

  /// Progreso de 0.0 a 1.0 respecto a la meta de comidas del día.
  double get progressPercentage =>
      (mealsLoggedToday / targetMeals.clamp(1, 10)).clamp(0.0, 1.0);

  /// Etiqueta de la próxima comida sugerida según el índice actual.
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

// ─────────────────────────────────────────────────────────────────────────────
// NutritionNotifier
// ─────────────────────────────────────────────────────────────────────────────

class NutritionNotifier extends StateNotifier<NutritionState> {
  final Ref _ref;
  CircadianProfile? _circadianProfile;

  NutritionNotifier(this._ref) : super(const NutritionState()) {
    _init();
  }

  void _init() {
    // Escucha cambios en el usuario para actualizar targetMeals y perfil circadiano.
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) {
          if (user != null) {
            _circadianProfile = user.profile;
            // Recalcula con los nuevos parámetros del usuario.
            final updated = _recalculate(state.todayLogs, user.mealsPerDay);
            state = updated.copyWith(targetMeals: user.mealsPerDay);
          }
        });
      },
      fireImmediately: true,
    );
  }

  /// Registra una comida en el momento actual.
  /// [label] — etiqueta semántica opcional; si no se provee se infiere por índice.
  Future<void> logMeal({String? label}) async {
    final now = DateTime.now();
    final effectiveLabel = label ?? state.nextMealLabel;
    final withinWindow = _isWithinCircadianWindow(now);

    final log = NutritionLog(
      id: const Uuid().v4(),
      timestamp: now,
      label: effectiveLabel,
      withinCircadianWindow: withinWindow,
    );

    final newLogs = [...state.todayLogs, log];
    final updated = _recalculate(newLogs, state.targetMeals);
    state = updated;
  }

  /// Elimina el último registro (acción de deshacer).
  void removeLastMeal() {
    if (state.todayLogs.isEmpty) return;
    final newLogs = state.todayLogs.sublist(0, state.todayLogs.length - 1);
    state = _recalculate(newLogs, state.targetMeals);
  }

  /// Resetea el estado diario (llamar en inicio de sesión o a medianoche).
  void resetDaily() {
    state = NutritionState(
      targetMeals: state.targetMeals,
      todayLogs: const [],
      nutritionScore: 0.0,
      windowAdherence: 0.0,
    );
  }

  // ── Lógica interna ──────────────────────────────────────────────────────────

  /// Calcula si [time] está dentro de la ventana circadiana configurada
  /// [firstMealGoal, lastMealGoal]. Si no hay ventana configurada, retorna true.
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
  ///
  /// Fórmula científica:
  ///   mealCountScore   = min(logsCount / targetMeals, 1.0)
  ///   windowAdherence  = logs dentro de ventana / total logs  (1.0 si sin logs)
  ///   nutritionScore   = (0.60 × mealCountScore) + (0.40 × windowAdherence)
  NutritionState _recalculate(List<NutritionLog> logs, int target) {
    final int count = logs.length;
    final double mealCountScore =
        (count / target.clamp(1, 10)).clamp(0.0, 1.0);

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

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  return NutritionNotifier(ref);
});
