import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_prediction_notifier.dart';

/// Provider global del notifier de predicción de fin de ayuno
export 'fasting_prediction_notifier.dart';

/// Re-exportar todos los selectors
export 'fasting_prediction_notifier.dart' show
  fastingPredictionNotifierProvider,
  currentFastingPredictionProvider,
  estimatedGlycogenProvider,
  optimalBreakTimeProvider,
  macroOptionsProvider;
