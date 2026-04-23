import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/fasting/domain/models/fasting_prediction.dart';
import 'package:elena_app/src/features/fasting/application/fasting_predictor_service.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_provider.dart';

/// Provider del notifier de predicciones
final fastingPredictionNotifierProvider =
    StateNotifierProvider<FastingPredictionNotifier, FastingPredictionState?>((ref) {
  final currentUser = ref.watch(currentUserStreamProvider).valueOrNull;
  final fastingState = ref.watch(fastingProvider);

  if (currentUser == null || fastingState == null) {
    return FastingPredictionNotifier(userId: null);
  }

  return FastingPredictionNotifier(
    userId: currentUser.id,
  );
});

/// Selector para acceso rápido a predicción actual
final currentFastingPredictionProvider =
    StateProvider.autoDispose<FastingPrediction?>((ref) {
  return ref.watch(fastingPredictionNotifierProvider)?.currentPrediction;
});

/// Estado del notifier de predicciones
class FastingPredictionState {
  final FastingPrediction? currentPrediction;
  final List<FastingPrediction>? predictionHistory;
  final bool isCalculating;
  final String? error;

  FastingPredictionState({
    this.currentPrediction,
    this.predictionHistory,
    this.isCalculating = false,
    this.error,
  });

  FastingPredictionState copyWith({
    FastingPrediction? currentPrediction,
    List<FastingPrediction>? predictionHistory,
    bool? isCalculating,
    String? error,
  }) {
    return FastingPredictionState(
      currentPrediction: currentPrediction ?? this.currentPrediction,
      predictionHistory: predictionHistory ?? this.predictionHistory,
      isCalculating: isCalculating ?? this.isCalculating,
      error: error,
    );
  }
}

/// Notifier para gestionar predicciones de fin de ayuno
/// SPEC-35: Predictor de Fin de Ayuno
class FastingPredictionNotifier extends StateNotifier<FastingPredictionState?> {
  final String? userId;

  FastingPredictionNotifier({
    required this.userId,
  }) : super(FastingPredictionState()) {
    if (userId != null) {
      _initializeTracking();
    }
  }

  void _initializeTracking() {
    // Inicialización de tracking de predicciones
    _recalculatePrediction();
  }

  void _recalculatePrediction() {
    // Placeholder para recalcular predicción
    // Será mejorado en futuras versiones
    final now = DateTime.now();
    final optimalTime = now.add(const Duration(hours: 1));
    final minutesDiff = optimalTime.difference(now).inMinutes;

    state = state?.copyWith(
      currentPrediction: FastingPrediction(
        id: 'prediction_${now.millisecondsSinceEpoch}',
        userId: userId ?? 'unknown',
        generatedAt: now,
        fastedHours: 0,
        estimatedGlycogen: 380,
        currentFastingPhase: 'ALERTA',
        currentCircadianPhase: 'ENERGÍA',
        optimalBreakTime: optimalTime,
        suggestedMacroProfile: 'B',
        glucemicResponse: 'MEDIA',
        confidence: 0.85,
        minutesUntilOptimal: minutesDiff,
        macroOptions: const [],
      ),
    );
  }

  /// Obtiene predicción actual
  FastingPrediction? getPrediction() {
    return state?.currentPrediction;
  }

  /// Obtiene opciones de macros para romper ayuno
  List<Map<String, double>> getMacroOptions() {
    return [
      {
        'carbsPercent': 30,
        'proteinPercent': 40,
        'fatPercent': 30,
      },
      {
        'carbsPercent': 50,
        'proteinPercent': 25,
        'fatPercent': 25,
      },
      {
        'carbsPercent': 20,
        'proteinPercent': 50,
        'fatPercent': 30,
      },
    ];
  }
}
