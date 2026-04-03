import 'user_engagement_profile.dart';

/// Result of streak processing.
///
/// Contains updated streak state plus reward/warning flags.
class StreakUpdateOutput {
  final UserEngagementProfile updatedProfile;
  final int updatedStreak;
  final bool streakBroken;
  final bool streakAtRisk;
  final bool rewardTriggered;
  final int? milestoneReached;
  final bool usedStreakProtection;

  const StreakUpdateOutput({
    required this.updatedProfile,
    required this.updatedStreak,
    this.streakBroken = false,
    this.streakAtRisk = false,
    this.rewardTriggered = false,
    this.milestoneReached,
    this.usedStreakProtection = false,
  });
}
