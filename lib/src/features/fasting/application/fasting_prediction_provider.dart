import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/fasting/application/fasting_prediction_notifier.dart';
import 'package:elena_app/src/features/fasting/domain/models/fasting_prediction.dart';

/// Provider principal del notifier de predicciones de fin de ayuno
/// SPEC-35: Predictor de Fin de Ayuno
final fastingPredictionProvider =
    StateNotifierProvider<FastingPredictionNotifier, FastingPredictionState?>((ref) {
  // Instancia del notifier sin parámetro ref (ya no es necesario)
  return FastingPredictionNotifier(userId: null);
});

/// Selector: Obtener predicción actual
final currentPredictionProvider =
    StateProvider.autoDispose<FastingPrediction?>((ref) {
  return ref.watch(fastingPredictionProvider)?.currentPrediction;
});

/// Selector: Obtener glucógeno estimado
final estimatedGlycogenProvider =
    StateProvider.autoDispose<double?>((ref) {
  return ref.watch(currentPredictionProvider)?.estimatedGlycogen;
});

/// Selector: Obtener tiempo óptimo para romper
final optimalBreakTimeProvider =
    StateProvider.autoDispose<DateTime?>((ref) {
  return ref.watch(currentPredictionProvider)?.optimalBreakTime;
});

/// Selector: Obtener minutos hasta momento óptimo
final minutesUntilOptimalProvider =
    StateProvider.autoDispose<int>((ref) {
  return ref.watch(currentPredictionProvider)?.minutesUntilOptimal ?? 0;
});

/// Selector: Obtener opción macro sugerida
final suggestedMacroProfileProvider =
    StateProvider.autoDispose<String>((ref) {
  return ref.watch(currentPredictionProvider)?.suggestedMacroProfile ?? 'B';
});

/// Selector: Obtener respuesta glucémica
final glucemicResponseProvider =
    StateProvider.autoDispose<String>((ref) {
  return ref.watch(currentPredictionProvider)?.glucemicResponse ?? 'MEDIA';
});

/// Selector: Obtener opciones macro
final macroOptionsProvider =
    StateProvider.autoDispose<List<MacroOption>>((ref) {
  final prediction = ref.watch(currentPredictionProvider);
  return prediction?.macroOptions ?? const [];
});

/// Selector: Obtener confianza del predictor
final predictionConfidenceProvider =
    StateProvider.autoDispose<double>((ref) {
  return ref.watch(currentPredictionProvider)?.confidence ?? 0.5;
});
