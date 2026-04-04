import 'full_user_state.dart';
import 'user_health_state.dart';

/// Unified health payload produced by [HealthOrchestrator].
///
/// Combines the normalized state snapshot with a single prioritized decision.
///
/// Deprecated: use [FullUserState]. Kept only for compatibility.
@Deprecated('Use FullUserState instead')
class HealthSnapshot extends FullUserState {
  const HealthSnapshot({
    required UserHealthState state,
    required super.decision,
    required super.experience,
  }) : super(health: state);
}
