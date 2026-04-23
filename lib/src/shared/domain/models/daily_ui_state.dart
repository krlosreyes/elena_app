class DailyUIState {
  final bool fastingStarted;
  final bool fastingCompletedShown;
  final bool nutritionCompletedShown;
  final DateTime lastUpdated;

  DailyUIState({
    this.fastingStarted = false,
    this.fastingCompletedShown = false,
    this.nutritionCompletedShown = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory DailyUIState.initial() => DailyUIState();

  DailyUIState copyWith({
    bool? fastingStarted,
    bool? fastingCompletedShown,
    bool? nutritionCompletedShown,
  }) {
    return DailyUIState(
      fastingStarted: fastingStarted ?? this.fastingStarted,
      fastingCompletedShown: fastingCompletedShown ?? this.fastingCompletedShown,
      nutritionCompletedShown: nutritionCompletedShown ?? this.nutritionCompletedShown,
    );
  }

  Map<String, dynamic> toJson() => {
    'fastingStarted': fastingStarted,
    'fastingCompletedShown': fastingCompletedShown,
    'nutritionCompletedShown': nutritionCompletedShown,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory DailyUIState.fromJson(Map<String, dynamic> json) {
    return DailyUIState(
      fastingStarted: json['fastingStarted'] ?? false,
      fastingCompletedShown: json['fastingCompletedShown'] ?? false,
      nutritionCompletedShown: json['nutritionCompletedShown'] ?? false,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }
}
