import '../domain/decision_output.dart';
import '../domain/user_health_state.dart';
import '../domain/user_behavior_profile.dart';

class AdaptiveEngine {
  const AdaptiveEngine();

  DecisionOutput adapt({
    required DecisionOutput baseDecision,
    required UserHealthState state,
    required UserBehaviorProfile profile,
  }) {
    DecisionOutput selected = baseDecision;

    if (profile.trainingRecoveryRate < 0.4 && selected.primaryAction.contains('ENTRENAMIENTO')) {
      selected = selected.copyWith(
        primaryAction: 'MOVILIDAD SUAVE',
        secondaryAction: 'Recuperación baja detectada.',
        explanation: 'Tus métricas de fatiga sugieren que una carga pesada hoy sería contraproducente para tu metabolismo.',
        priority: DecisionPriority.medium,
      );
    }

    return selected;
  }
}