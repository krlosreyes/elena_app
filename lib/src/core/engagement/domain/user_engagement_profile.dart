import 'dart:collection';

/// Domain model for user engagement and adherence tracking.
///
/// Pure data entity: immutable, framework-agnostic, and without UI logic.
class UserEngagementProfile {
  final int currentStreak;
  final int longestStreak;
  final int totalActionsCompleted;

  /// Normalized adherence score in [0.0, 1.0].
  final double adherenceScore;

  /// Normalized motivation level in [0.0, 1.0].
  final double motivationLevel;

  final DateTime lastActive;
  final int missedDays;

  /// Aggregated completions by action category/type.
  final Map<String, int> completedActionsByType;

  UserEngagementProfile({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalActionsCompleted = 0,
    this.adherenceScore = 0.5,
    this.motivationLevel = 0.5,
    DateTime? lastActive,
    this.missedDays = 0,
    Map<String, int> completedActionsByType = const {},
  })  : assert(currentStreak >= 0, 'currentStreak must be >= 0'),
        assert(longestStreak >= 0, 'longestStreak must be >= 0'),
        assert(
          longestStreak >= currentStreak,
          'longestStreak must be >= currentStreak',
        ),
        assert(
          totalActionsCompleted >= 0,
          'totalActionsCompleted must be >= 0',
        ),
        assert(
          adherenceScore >= 0.0 && adherenceScore <= 1.0,
          'adherenceScore must be in [0,1]',
        ),
        assert(
          motivationLevel >= 0.0 && motivationLevel <= 1.0,
          'motivationLevel must be in [0,1]',
        ),
        assert(missedDays >= 0, 'missedDays must be >= 0'),
        lastActive =
            lastActive ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        completedActionsByType =
            UnmodifiableMapView(Map<String, int>.from(completedActionsByType));

  UserEngagementProfile copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalActionsCompleted,
    double? adherenceScore,
    double? motivationLevel,
    DateTime? lastActive,
    int? missedDays,
    Map<String, int>? completedActionsByType,
  }) {
    return UserEngagementProfile(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalActionsCompleted:
          totalActionsCompleted ?? this.totalActionsCompleted,
      adherenceScore: adherenceScore ?? this.adherenceScore,
      motivationLevel: motivationLevel ?? this.motivationLevel,
      lastActive: lastActive ?? this.lastActive,
      missedDays: missedDays ?? this.missedDays,
      completedActionsByType:
          completedActionsByType ?? this.completedActionsByType,
    );
  }
}
