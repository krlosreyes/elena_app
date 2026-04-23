import 'package:elena_app/src/core/orchestrator/orchestrator_service.dart';
import 'package:elena_app/src/core/orchestrator/models/orchestrator_state.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SPEC-34: Notifier que sincroniza estado de todos los pilares.
/// Observa cambios en FastingNotifier, NutritionNotifier, ExerciseNotifier,
/// SleepNotifier, HydrationNotifier y recalcula OrchestratorState en tiempo real.
class OrchestratorNotifier extends StateNotifier<OrchestratorState?> {
  final Ref _ref;
  bool _isRecalculating = false;

  OrchestratorNotifier(this._ref) : super(null) {
    _initializeAndWatch();
  }

  void _initializeAndWatch() {
    // Observar cambios en todos los pilares
    _ref.listen(currentUserStreamProvider, (previous, next) {
      next.whenData((_) {
        // Usar Future.microtask para evitar ConcurrentModificationError
        Future.microtask(() => _recalculateState());
      });
    });

    _ref.listen(
      fastingProvider.select((s) => '${s.isActive}_${s.phase}'), 
      (_, __) => Future.microtask(() => _recalculateState()),
    );

    _ref.listen(nutritionProvider, (previous, next) {
      Future.microtask(() => _recalculateState());
    });

    _ref.listen(exerciseProvider, (previous, next) {
      Future.microtask(() => _recalculateState());
    });


    // Cálculo inicial
    Future.microtask(() => _recalculateState());
  }

  /// Recalcula el estado completo basado en pilares actuales.
  /// Guard: previene recálculos simultáneos (evita bucle infinito)
  Future<void> _recalculateState() async {
    // Guard: si ya estamos recalculando, no iniciar otro
    if (_isRecalculating) return;

    _isRecalculating = true;
    try {
      final userAsync = _ref.read(currentUserStreamProvider);
      final fastingState = _ref.read(fastingProvider);
      final nutritionState = _ref.read(nutritionProvider);
      final exerciseState = _ref.read(exerciseProvider);

      await userAsync.when(
        data: (user) {
          if (user != null && fastingState != null && nutritionState != null && exerciseState != null) {
            final orchestratorState = OrchestratorService.calculateState(
              user: user,
              fastingHours: fastingState.duration.inHours.toDouble(),
              lastMealTime: nutritionState.firstMealTime,
              exerciseMinutesToday: exerciseState.todayMinutes.toDouble(),
              sleepRecoveryScore: 0.5, // Default, será mejorado en futuro
              hydrationMlToday: 2000, // Default
              hydrationGoalMl: 2200,
            );

            state = orchestratorState;
            
            /* 
            debugPrint(
              '✅ SPEC-34: Orquestrador actualizado. '
              'Coherencia: ${(orchestratorState.metabolicCoherence * 100).toStringAsFixed(1)}%',
            );
            */


            // Log violaciones
            if (orchestratorState.hasSyncViolations) {
              debugPrint(
                '⚠️  Violaciones detectadas:\n${orchestratorState.activeSyncViolations.join('\n')}',
              );
            }
          }
        },
        loading: () {},
        error: (err, st) {
          debugPrint('❌ Error en OrchestratorNotifier: $err');
        },
      );
    } catch (e) {
      debugPrint('❌ Error recalculando OrchestratorState: $e');
    } finally {
      _isRecalculating = false;
    }
  }

  /// API pública: Obtener estado actual
  OrchestratorState? getState() => state;

  /// API pública: Verificar si es seguro hacer determinada acción
  bool canExerciseNow() => state?.canExerciseNow ?? false;
  bool canEatNow() => state?.canEatNow ?? false;
  bool isOptimalForFasting() => state?.isOptimalForFasting ?? false;

  /// API pública: Obtener multiplier de seguridad para ejercicio
  double getExerciseSafetyMultiplier() =>
      state?.exerciseSafetyMultiplier ?? 1.0;

  /// API pública: Obtener multiplier de nutrición
  double getNutritionPhaseMultiplier() =>
      state?.nutritionPhaseMultiplier ?? 1.0;

  /// API pública: Verificar violaciones activas
  bool hasSyncViolations() => state?.hasSyncViolations ?? false;
  List<String> getViolations() => state?.activeSyncViolations ?? [];

  /// API pública: Coherencia metabólica
  double getMetabolicCoherence() => state?.metabolicCoherence ?? 0.0;

  /// API pública: Sugerencia principal
  String? getPrimaryActionSuggestion() =>
      state?.primaryActionSuggestion;
}
