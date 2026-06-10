// SPEC-198 — tests de las piezas puras del inc2: schedule de nudges + store.

import 'package:elena_app/src/features/billing/application/paywall_nudges.dart';
import 'package:elena_app/src/features/billing/application/paywall_prompt_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PaywallNudges.nudgeDatesFor', () {
    test('día 5 y día 12 desde el registro', () {
      final created = DateTime(2026, 6, 1, 9, 0);
      final dates = PaywallNudges.nudgeDatesFor(created);
      expect(dates[0], DateTime(2026, 6, 6, 9, 0)); // +5d
      expect(dates[1], DateTime(2026, 6, 13, 9, 0)); // +12d
    });
  });

  group('PaywallPromptStore', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('no mostrado al inicio; mostrado tras markShown el mismo día',
        () async {
      final store = PaywallPromptStore(prefs);
      final now = DateTime(2026, 6, 9, 10);
      expect(store.shownToday(now), false);
      await store.markShown(now);
      expect(store.shownToday(now), true);
    });

    test('al día siguiente vuelve a permitir', () async {
      final store = PaywallPromptStore(prefs);
      await store.markShown(DateTime(2026, 6, 9, 10));
      expect(store.shownToday(DateTime(2026, 6, 10, 8)), false);
    });
  });
}
