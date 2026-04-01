class MealMilestoneCalculator {
  /// Calculates offsets (in hours since feeding start) for meal milestones
  /// based on the user's protocol (e.g., "16:8").
  ///
  /// V = Feeding Window
  /// Rules:
  /// - V ≥ 8h: 3 meals at 0.0, 4.0, 7.5 (or window closure)
  /// - 4h ≤ V < 8h: 2 meals at 0.0, V
  /// - V < 4h: 1 meal at 0.0
  static List<double> calculateOffsets(String protocol, {int? numberOfMeals}) {
    try {
      final parts = protocol.split(':');
      if (parts.length != 2) return [0.0, 4.0, 8.0];

      final int fastingHours = int.tryParse(parts[0].trim()) ?? 16;
      final double feedingWindow = 24.0 - fastingHours.toDouble();

      // If numberOfMeals is explicitly provided, use it. Otherwise, calculate dynamically.
      int numMeals = numberOfMeals ?? ((feedingWindow / 4.0).floor() + 1);

      // OMAD or single meal constraint
      if (feedingWindow <= 1.5 || numMeals <= 1) return [0.0];

      // Clamp to protocol limits (1-3) if provided, or at least 2 for significant windows
      if (numberOfMeals == null && numMeals < 2 && feedingWindow >= 2.0) {
        numMeals = 2;
      }
      
      // Typical Elena protocols favor 2 or 3 meals.
      if (numMeals > 3) numMeals = 3;

      final List<double> offsets = [];
      final double step = numMeals > 1 ? feedingWindow / (numMeals - 1) : 0.0;

      for (int i = 0; i < numMeals; i++) {
        offsets.add(double.parse((i * step).toStringAsFixed(1)));
      }

      return offsets;
    } catch (_) {
      return [0.0, 4.0, 8.0];
    }
  }
}
