import 'package:freezed_annotation/freezed_annotation.dart';

part 'orchestrator_state.freezed.dart';
part 'orchestrator_state.g.dart';

/// SPEC-34: Estado sincronizado de todos los pilares.
/// Contrato de datos que representa el estado metabólico actual del usuario
/// basado en: Fasting Phase + Circadian Phase + Nutrition Window + Sleep + Exercise.
@freezed
class OrchestratorState with _$OrchestratorState {
  const factory OrchestratorState({
    /// Última actualización del estado
    required DateTime lastUpdated,

    /// Fase actual de ayuno (ALERTA, GLUCONEOGÉNESIS, CETOSIS, AUTOFAGIA)
    required String currentFastingPhase,

    /// Fase circadiana actual (ALERTA, ENERGÍA, CREPÚSCULO, SUEÑO, LIMPIEZA)
    required String currentCircadianPhase,

    /// Horas de ayuno actual
    required double fastedHours,

    /// Es seguro hacer ejercicio ahora
    required bool canExerciseNow,

    /// Es seguro comer ahora (dentro de ventana circadiana)
    required bool canEatNow,

    /// Tipo de ejercicio recomendado (LISS, STRENGTH, HIIT o null)
    String? exerciseRecommendedType,

    /// Intensidad recomendada (0-100 percent)
    @Default(0) int exerciseRecommendedIntensity,

    /// Es óptimo continuar en ayuno
    required bool isOptimalForFasting,

    /// Score de sincronización metabólica (0-1)
    required double metabolicCoherence,

    /// Violaciones activas (lista de strings descriptivos)
    @Default([]) List<String> activeSyncViolations,

    /// Sugerencia de acción principal para ahora
    String? primaryActionSuggestion,

    /// Cache de scores por pilar
    @Default({}) Map<String, double> syncMetrics,

    /// Penalización de ejercicio por estado de ayuno (0-1, donde 1 = sin penalización)
    @Default(1.0) double exerciseSafetyMultiplier,

    /// Penalización de nutrición por fase circadiana (0-1)
    @Default(1.0) double nutritionPhaseMultiplier,

    /// Horas desde última comida
    required double hoursSinceLastMeal,

    /// Minutos hasta cierre de ventana de comida
    int? minutesToWindowClose,

    /// Recovery status del sueño (0-1)
    @Default(0.5) double sleepRecoveryScore,
  }) = _OrchestratorState;

  factory OrchestratorState.fromJson(Map<String, dynamic> json) =>
      _$OrchestratorStateFromJson(json);

  const OrchestratorState._();

  /// Retorna verdadero si hay violaciones activas de sincronización
  bool get hasSyncViolations => activeSyncViolations.isNotEmpty;

  /// Retorna verdadero si el estado es óptimo para todas las acciones
  bool get isOptimal =>
      canExerciseNow &&
      canEatNow &&
      isOptimalForFasting &&
      metabolicCoherence > 0.8 &&
      !hasSyncViolations;
}
