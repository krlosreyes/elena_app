// ─────────────────────────────────────────────────────────────────────────────
// SPEC-01 / SPEC-46: OrchestratorState determinista (Freezed, no-nullable)
// ─────────────────────────────────────────────────────────────────────────────
//
// Modelo único del orquestador. Usa enums tipados de biological_phases.dart.
// 100% no-nullable excepto campos opcionalmente ausentes.
//
// Historia:
//   - SPEC-46 (6-may-2026): unificación. Antes existían dos versiones
//     (OrchestratorState con strings + OrchestratorState con enums).
//     La v1 fue eliminada y la v2 renombrada a este archivo.
//
// SPEC-00: Dart puro — sin imports de providers, notifiers o repositorios.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/orchestrator/recommendation.dart';

part 'orchestrator_state.freezed.dart';

/// Estado sincronizado de todos los pilares metabólicos.
///
/// Calculado por [OrchestratorEngine.calculate] como función pura:
///   (MetabolicState, UserModel, StreakState) → OrchestratorState
///
/// NO contiene lógica. NO tiene side effects.
/// Todos los campos de fase usan enums tipados (no strings).
@freezed
class OrchestratorState with _$OrchestratorState {
  const factory OrchestratorState({
    // ── Fases biológicas (tipadas) ──────────────────────────────────────
    required FastingPhase fastingPhase,
    required CircadianPhase circadianPhase,

    // ── Decisiones booleanas ────────────────────────────────────────────
    required bool canExerciseNow,
    required bool canEatNow,
    required bool isOptimalForFasting,
    required bool isInNutritionWindow,

    // ── Multiplicadores de seguridad (0.0–1.0) ─────────────────────────
    required double exerciseSafetyMultiplier,
    required double nutritionPhaseMultiplier,

    // ── Recomendaciones tipadas ─────────────────────────────────────────
    required List<Recommendation> recommendations,

    // ── Ejercicio ───────────────────────────────────────────────────────
    String? exerciseRecommendedType,
    @Default(0) int exerciseRecommendedIntensity,

    // ── Coherencia y violaciones ────────────────────────────────────────
    required double metabolicCoherence,
    @Default([]) List<String> activeSyncViolations,

    // ── Datos temporales crudos ─────────────────────────────────────────
    required double fastedHours,
    required double hoursSinceLastMeal,
    int? minutesToWindowClose,

    // ── Timestamp de la fuente de datos ─────────────────────────────────
    // SPEC-60: nullable. `null` indica state inicial sin lectura del reloj.
    DateTime? sourceTimestamp,
  }) = _OrchestratorState;

  const OrchestratorState._();

  /// Estado inicial seguro (sin datos).
  ///
  /// SPEC-60: cumple la Ley de Factories Puras — sin `DateTime.now()`,
  /// sin `Random()`, sin efectos secundarios. La instancia es const y
  /// equivalente entre llamadas.
  factory OrchestratorState.initial() => const OrchestratorState(
        fastingPhase: FastingPhase.alerta,
        circadianPhase: CircadianPhase.alerta,
        canExerciseNow: false,
        canEatNow: false,
        isOptimalForFasting: false,
        isInNutritionWindow: false,
        exerciseSafetyMultiplier: 1.0,
        nutritionPhaseMultiplier: 1.0,
        recommendations: [],
        exerciseRecommendedIntensity: 0,
        metabolicCoherence: 0.0,
        activeSyncViolations: [],
        fastedHours: 0.0,
        hoursSinceLastMeal: 0.0,
        sourceTimestamp: null,
      );

  // ── Computed getters (lógica trivial, no de negocio) ─────────────────

  /// True si hay violaciones activas de sincronización.
  bool get hasSyncViolations => activeSyncViolations.isNotEmpty;

  /// True si el sistema está en estado óptimo global.
  bool get isOptimal =>
      canExerciseNow &&
      canEatNow &&
      isOptimalForFasting &&
      metabolicCoherence > 0.8 &&
      !hasSyncViolations;
}
