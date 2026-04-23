import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_predictor_service.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Provider del estado de predicción de fin de ayuno
final fastingPredictionNotifierProvider =
    StateNotifierProvider<FastingPredictionNotifier, FastingPredictionState?>((ref) {
  return FastingPredictionNotifier(ref: ref);
});

/// Selector: Obtener predicción actual
final currentFastingPredictionProvider =
    StateProvider.autoDispose<FastingPredictionState?>((ref) {
  return ref.watch(fastingPredictionNotifierProvider);
});

/// Selector: Obtener glucógeno estimado
final estimatedGlycogenProvider =
    StateProvider.autoDispose<double>((ref) {
  return ref.watch(fastingPredictionNotifierProvider)?.estimatedGlycogen ?? 400;
});

/// Selector: Obtener momento óptimo para ruptura
final optimalBreakTimeProvider =
    StateProvider.autoDispose<DateTime?>((ref) {
  return ref.watch(fastingPredictionNotifierProvider)?.optimalBreakTime;
});

/// Selector: Obtener opciones de macros
final macroOptionsProvider =
    StateProvider.autoDispose<List<MacroOption>>((ref) {
  return ref.watch(fastingPredictionNotifierProvider)?.macroOptions ?? [];
});

/// Estado de predicción de fin de ayuno
class FastingPredictionState {
  final double fastedHours;
  final String currentFastingPhase;
  final double estimatedGlycogen;
  final DateTime? optimalBreakTime;
  final List<MacroOption> macroOptions;
  final String? recommendation;
  final bool canBreakFastNow;
  final DateTime lastCalculated;

  FastingPredictionState({
    required this.fastedHours,
    required this.currentFastingPhase,
    required this.estimatedGlycogen,
    required this.optimalBreakTime,
    required this.macroOptions,
    required this.recommendation,
    required this.canBreakFastNow,
    required this.lastCalculated,
  });

  FastingPredictionState copyWith({
    double? fastedHours,
    String? currentFastingPhase,
    double? estimatedGlycogen,
    DateTime? optimalBreakTime,
    List<MacroOption>? macroOptions,
    String? recommendation,
    bool? canBreakFastNow,
    DateTime? lastCalculated,
  }) {
    return FastingPredictionState(
      fastedHours: fastedHours ?? this.fastedHours,
      currentFastingPhase: currentFastingPhase ?? this.currentFastingPhase,
      estimatedGlycogen: estimatedGlycogen ?? this.estimatedGlycogen,
      optimalBreakTime: optimalBreakTime ?? this.optimalBreakTime,
      macroOptions: macroOptions ?? this.macroOptions,
      recommendation: recommendation ?? this.recommendation,
      canBreakFastNow: canBreakFastNow ?? this.canBreakFastNow,
      lastCalculated: lastCalculated ?? this.lastCalculated,
    );
  }
}

/// Notifier que gestiona predicción de fin de ayuno
/// SPEC-35: Predice momento óptimo para romper ayuno
class FastingPredictionNotifier extends StateNotifier<FastingPredictionState?> {
  final Ref _ref;

  FastingPredictionNotifier({required Ref ref})
      : _ref = ref,
        super(null) {
    _initializeTracking();
  }

  void _initializeTracking() {
    // Observar cambios en ayuno para recalcular predicción
    _ref.listen(fastingProvider, (previous, next) {
      if (mounted && next != null) {
        _recalculatePrediction(next);
      }
    });

    // Observar cambios en orchestrator (includes sleep recovery)
    _ref.listen(orchestratorProvider, (previous, next) {
      if (mounted) {
        _updateWithOrchestratorState(next);
      }
    });

    // Cálculo inicial
    final fastingState = _ref.read(fastingProvider);
    if (fastingState != null) {
      _recalculatePrediction(fastingState);
    }
  }

  /// Recalcula predicción basada en estado de ayuno actual
  void _recalculatePrediction(dynamic fastingState) {
    try {
      final fastedHours = fastingState.duration.inHours.toDouble();
      final fastingPhase = FastingPredictorService.determineFastingPhase(fastedHours);
      final estimatedGlycogen = FastingPredictorService.estimateGlycogenLevel(fastedHours);

      // Obtener sleep quality y fase circadiana del orchestrator (SPEC-01)
      final orchestratorState = _ref.read(orchestratorProvider);
      final metabolicState = _ref.read(metabolicStateProvider);
      
      final sleepQuality = metabolicState.sleepQuality;
      final circadianPhase = orchestratorState.circadianPhase;

      // Predecir momento óptimo
      final optimalBreakTime = FastingPredictorService.predictOptimalBreakTime(
        currentFastingHours: fastedHours,
        currentCircadianPhase: circadianPhase,
        sleepQuality: sleepQuality,
        estimatedGlycogen: estimatedGlycogen,
      );

      // Sugerir opciones de macros
      final macroOptions = FastingPredictorService.suggestBreakfastMacros(
        currentFastingPhase: fastingPhase,
        currentCircadianPhase: circadianPhase,
        estimatedGlycogen: estimatedGlycogen,
        sleepRecoveryScore: sleepRecoveryScore,
      );

      // Determinar si es seguro romper ayuno
      final canBreakNow = FastingPredictorService.canBreakFastNow(
        currentFastingPhase: fastingPhase,
        currentCircadianPhase: circadianPhase,
        sleepRecoveryScore: sleepRecoveryScore,
      );

      // Generar recomendación
      final recommendation = _generateRecommendation(
        fastingPhase: fastingPhase,
        estimatedGlycogen: estimatedGlycogen,
        canBreakNow: canBreakNow,
        sleepRecoveryScore: sleepRecoveryScore,
      );

      state = FastingPredictionState(
        fastedHours: fastedHours,
        currentFastingPhase: fastingPhase,
        estimatedGlycogen: estimatedGlycogen,
        optimalBreakTime: optimalBreakTime,
        macroOptions: macroOptions,
        recommendation: recommendation,
        canBreakFastNow: canBreakNow,
        lastCalculated: DateTime.now(),
      );

      debugPrint(
        '⏱️ SPEC-35: Predicción actualizada.\n'
        'Fase: $fastingPhase | Glucógeno: ${estimatedGlycogen.toStringAsFixed(0)}g\n'
        'Óptimo romper: ${optimalBreakTime?.toString() ?? "En otra fase circadiana"}\n'
        'Seguro ahora: $canBreakNow',
      );
    } catch (e) {
      debugPrint('❌ Error en FastingPredictionNotifier: $e');
    }
  }

  /// Actualiza predicción con cambios en estado orquestrador
  void _updateWithOrchestratorState(dynamic orchestratorState) {
    if (state != null) {
      _recalculatePrediction(_ref.read(fastingProvider));
    }
  }

  /// Genera recomendación basada en estado de ayuno
  String _generateRecommendation({
    required String fastingPhase,
    required double estimatedGlycogen,
    required bool canBreakNow,
    required double sleepRecoveryScore,
  }) {
    if (fastingPhase == 'ALERTA') {
      return 'Ayuno temprano. Puedes comer cuando sientas hambre o después del ejercicio.';
    } else if (fastingPhase == 'GLUCONEOGÉNESIS') {
      return 'Gluconeogénesis activa. El cuerpo produce glucosa. Buen momento para romper.';
    } else if (fastingPhase == 'CETOSIS') {
      return 'Cetosis: glucógeno bajo (${estimatedGlycogen.toStringAsFixed(0)}g). '
          'Decide: continuar o romper con carbos complejos.';
    } else if (fastingPhase == 'AUTOFAGIA') {
      if (sleepRecoveryScore < 0.5) {
        return '🚨 AUTOFAGIA + Recovery bajo. Recomienda romper con proteína + grasa.';
      } else {
        return 'AUTOFAGIA: Máxima autofagia. Si continúas, solo agua/electrolitos. '
            'Si rompes, hacerlo con cuidado.';
      }
    }
    return 'Estado de ayuno desconocido.';
  }

  /// API pública: Registra ruptura de ayuno
  void recordBreakFast({
    required String chosenMacroProfile,
    required double postMealGlucose,
    required String userFeedback,
  }) {
    if (state == null) return;

    FastingPredictorService.recordBreakResult(
      fastingDuration: state!.fastedHours.toInt(),
      chosenMacroProfile: chosenMacroProfile,
      glucoseLevelPostMeal: postMealGlucose,
      userFeedback: userFeedback,
    );
  }

  /// API pública: Obtener estado actual
  FastingPredictionState? getState() => state;

  /// API pública: Obtener glucógeno estimado
  double getEstimatedGlycogen() => state?.estimatedGlycogen ?? 400;

  /// API pública: Obtener fase actual
  String? getCurrentFastingPhase() => state?.currentFastingPhase;

  /// API pública: Obtener momento óptimo para romper
  DateTime? getOptimalBreakTime() => state?.optimalBreakTime;

  /// API pública: Obtener opciones de macros
  List<MacroOption> getMacroOptions() => state?.macroOptions ?? [];

  /// API pública: Obtener recomendación
  String? getRecommendation() => state?.recommendation;

  /// API pública: Obtener si es seguro romper ahora
  bool canBreakFastNow() => state?.canBreakFastNow ?? false;
}
