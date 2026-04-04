import '../../engagement/domain/user_experience_output.dart';
import 'decision_output.dart';
import 'user_health_state.dart';

/// Full user state produced by the unified health + engagement pipeline.
class FullUserState {
  final UserHealthState health;
  final DecisionOutput decision;
  final UserExperienceOutput experience;

  const FullUserState({
    required this.health,
    required this.decision,
    required this.experience,
  });

  /// Backward compatibility getter for older consumers.
  UserHealthState get state => health;
}
