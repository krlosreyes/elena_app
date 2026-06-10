// SPEC-198 — decide CUÁNDO ofrecer el paywall proactivamente (Dart puro).
//
// Regla §2.2: tras valor demostrado, no al arranque.
//   Ofrecer si: (1 ayuno completado  OR  día 7 desde registro)
//               Y no es premium  Y no se mostró ya hoy
//               Y no está en onboarding.

class PaywallTrigger {
  const PaywallTrigger._();

  /// Día (umbral) desde el registro a partir del cual se ofrece aunque no
  /// haya completado un ayuno.
  static const int kDay7 = 7;

  static bool shouldOffer({
    required bool isPremium,
    required bool onboardingCompleted,
    required int daysSinceRegistration,
    required int fastsCompleted,
    required bool shownToday,
  }) {
    if (isPremium) return false;
    if (!onboardingCompleted) return false; // nunca interrumpe el onboarding
    if (shownToday) return false;
    final valueDemonstrated =
        fastsCompleted >= 1 || daysSinceRegistration >= kDay7;
    return valueDemonstrated;
  }
}
