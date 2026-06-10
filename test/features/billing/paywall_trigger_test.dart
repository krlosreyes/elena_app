// SPEC-198 — tests del PaywallTrigger (cuándo ofrecer el paywall).

import 'package:elena_app/src/features/billing/application/paywall_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool offer({
    bool isPremium = false,
    bool onboardingCompleted = true,
    int days = 0,
    int fasts = 0,
    bool shownToday = false,
  }) =>
      PaywallTrigger.shouldOffer(
        isPremium: isPremium,
        onboardingCompleted: onboardingCompleted,
        daysSinceRegistration: days,
        fastsCompleted: fasts,
        shownToday: shownToday,
      );

  test('ofrece tras 1 ayuno completado', () {
    expect(offer(fasts: 1), true);
  });

  test('ofrece al día 7 aunque no haya ayunos', () {
    expect(offer(days: 7), true);
  });

  test('NO ofrece antes de valor (día 3, 0 ayunos)', () {
    expect(offer(days: 3, fasts: 0), false);
  });

  test('NO ofrece a premium', () {
    expect(offer(isPremium: true, fasts: 5, days: 30), false);
  });

  test('NO ofrece si ya se mostró hoy', () {
    expect(offer(fasts: 2, shownToday: true), false);
  });

  test('NO ofrece durante onboarding', () {
    expect(offer(onboardingCompleted: false, fasts: 3, days: 10), false);
  });
}
