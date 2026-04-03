import '../../health/domain/decision_output.dart';

/// Enhanced messaging payload for user-facing coaching systems.
///
/// This model is framework-agnostic and contains no UI logic.
class UserExperienceOutput {
  final DecisionOutput decision;
  final String tone;
  final String primaryMessage;
  final List<String> suggestedActions;
  final String gamificationMessage;
  final bool streakAtRisk;
  final bool rewardTriggered;
  final bool recoveryMode;
  final List<String> systemFlags;

  const UserExperienceOutput({
    required this.decision,
    required this.tone,
    required this.primaryMessage,
    this.suggestedActions = const [],
    this.gamificationMessage = '',
    this.streakAtRisk = false,
    this.rewardTriggered = false,
    this.recoveryMode = false,
    this.systemFlags = const [],
  });
}
