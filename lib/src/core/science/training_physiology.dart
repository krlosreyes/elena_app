class TrainingPhysiology {
  // Pure static logic class, no dependencies.
  const TrainingPhysiology._();

  // Constants
  static const int maxStrengthMinutesForLongevity = 140;
  static const int maxHiitMinutesWeekly = 75;

  /// Calculates max heart rate based on age.
  static int calculateMaxHR(int age) => 220 - age;

  /// Checks if a muscle group is ready for training.
  ///
  /// Returns [true] if enough recovery time has passed.
  /// Default recovery is 48 hours. If [recoveryScore] is low (< 3), requires 72 hours.
  static bool isMuscleReady(DateTime lastTrained, double recoveryScore) {
    // Determine required hours based on recovery score (1-5 scale)
    final int requiredHours = (recoveryScore < 3) ? 72 : 48;

    final Duration timeSinceLastTrained =
        DateTime.now().difference(lastTrained);
    return timeSinceLastTrained.inHours >= requiredHours;
  }

  /// Returns aerobic heart rate zones based on Max HR.
  ///
  /// Returns a Map where key is Zone number (1-5) and value is [min, max] BPM.
  static Map<int, List<int>> getAerobicZones(int maxHr) {
    return {
      1: [(maxHr * 0.50).round(), (maxHr * 0.60).round()], // Very Light
      2: [(maxHr * 0.60).round(), (maxHr * 0.70).round()], // Light
      3: [(maxHr * 0.70).round(), (maxHr * 0.80).round()], // Moderate
      4: [(maxHr * 0.80).round(), (maxHr * 0.90).round()], // Hard
      5: [(maxHr * 0.90).round(), maxHr], // Maximum
    };
  }

  static double calculateNextWeight(
      double lastWeight, int lastRir, int targetRir) {
    final rirDelta = lastRir - targetRir;
    if (rirDelta >= 2) return lastWeight + 2.5; // Muy fácil
    if (rirDelta == 1) return lastWeight + 1.25; // Ligeramente fácil
    return lastWeight; // Exacto o fallo: mantener
  }
}
