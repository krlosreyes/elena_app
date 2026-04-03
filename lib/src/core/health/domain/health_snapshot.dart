import 'decision_output.dart';
import 'user_health_state.dart';

/// Unified health payload produced by [HealthOrchestrator].
///
/// Combines the normalized state snapshot with a single prioritized decision.
class HealthSnapshot {
  final UserHealthState state;
  final DecisionOutput decision;

  const HealthSnapshot({
    required this.state,
    required this.decision,
  });
}
