import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_engine.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_state_v2.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SPEC-01: Provider global del Orquestador Central (Inmutable y Determinista).
///
/// Cumple SPEC-00:
/// - Es un Provider puro (mismo input -> mismo output).
/// - No contiene lógica propia (delega al OrchestratorEngine).
/// - No tiene efectos secundarios ni estado mutable.
final orchestratorProvider = Provider<OrchestratorStateV2>((ref) {
  final metabolicState = ref.watch(metabolicStateProvider);
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final streak = ref.watch(streakProvider);

  if (user == null) {
    return OrchestratorStateV2.initial();
  }

  return OrchestratorEngine.calculate(
    state: metabolicState,
    user: user,
    streak: streak,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// SELECTORES (Legacy compatibility & UI views)
// ─────────────────────────────────────────────────────────────────────────────

/// Selector: Estado completo del orquestador (alias directo)
final orchestratorStateProvider = orchestratorProvider;

/// Selector: ¿Es seguro ejercitar ahora?
final canExerciseNowProvider = Provider<bool>((ref) {
  return ref.watch(orchestratorProvider).canExerciseNow;
});

/// Selector: ¿Es seguro comer ahora?
final canEatNowProvider = Provider<bool>((ref) {
  return ref.watch(orchestratorProvider).canEatNow;
});

/// Selector: ¿Es óptimo continuar en ayuno?
final isOptimalForFastingProvider = Provider<bool>((ref) {
  return ref.watch(orchestratorProvider).isOptimalForFasting;
});

/// Selector: Multiplicador de seguridad para ejercicio
final exerciseSafetyMultiplierProvider = Provider<double>((ref) {
  return ref.watch(orchestratorProvider).exerciseSafetyMultiplier;
});

/// Selector: Multiplicador de nutrición por fase circadiana
final nutritionPhaseMultiplierProvider = Provider<double>((ref) {
  return ref.watch(orchestratorProvider).nutritionPhaseMultiplier;
});

/// Selector: ¿Hay violaciones de sincronización?
final hasSyncViolationsProvider = Provider<bool>((ref) {
  return ref.watch(orchestratorProvider).hasSyncViolations;
});

/// Selector: Lista de violaciones activas
final syncViolationsProvider = Provider<List<String>>((ref) {
  return ref.watch(orchestratorProvider).activeSyncViolations;
});

/// Selector: Coherencia metabólica (0-1)
final metabolicCoherenceProvider = Provider<double>((ref) {
  return ref.watch(orchestratorProvider).metabolicCoherence;
});

/// Selector: Recomendación de ejercicio (tipo + intensidad)
final exerciseRecommendationProvider =
    Provider<({String? type, int intensity})>((ref) {
  final state = ref.watch(orchestratorProvider);
  return (
    type: state.exerciseRecommendedType,
    intensity: state.exerciseRecommendedIntensity,
  );
});

/// Selector: Minutos hasta cierre de ventana de comida
final minutesToWindowCloseProvider = Provider<int?>((ref) {
  return ref.watch(orchestratorProvider).minutesToWindowClose;
});

/// Selector: Fase de ayuno actual (String para UI legacy)
final currentFastingPhaseProvider = Provider<String>((ref) {
  return ref.watch(orchestratorProvider).fastingPhase.name.toUpperCase();
});

/// Selector: Fase circadiana actual (String para UI legacy)
final currentCircadianPhaseProvider = Provider<String>((ref) {
  return ref.watch(orchestratorProvider).circadianPhase.name.toUpperCase();
});