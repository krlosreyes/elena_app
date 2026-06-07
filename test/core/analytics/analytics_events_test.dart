// SPEC-193 §6: el catálogo de eventos no debe tener nombres duplicados,
// y AnalyticsEvents.all debe cubrir todos los eventos declarados.

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/core/analytics/analytics_events.dart';

void main() {
  group('AnalyticsEvents (SPEC-193)', () {
    test('no hay nombres de evento duplicados', () {
      final set = AnalyticsEvents.all.toSet();
      expect(set.length, AnalyticsEvents.all.length,
          reason: 'Hay eventos duplicados en AnalyticsEvents.all');
    });

    test('todos los nombres son snake_case no vacíos', () {
      final re = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final name in AnalyticsEvents.all) {
        expect(re.hasMatch(name), isTrue, reason: 'Nombre inválido: "$name"');
      }
    });

    test('catálogo incluye los eventos de coaching (SPEC-194)', () {
      expect(
        AnalyticsEvents.all,
        containsAll(<String>[
          AnalyticsEvents.coachingActionShown,
          AnalyticsEvents.coachingActionFollowed,
          AnalyticsEvents.coachingActionCompleted,
          AnalyticsEvents.coachingFeedbackShown,
        ]),
      );
    });

    test('catálogo incluye el embudo de monetización (Ola C)', () {
      expect(
        AnalyticsEvents.all,
        containsAll(<String>[
          AnalyticsEvents.paywallShown,
          AnalyticsEvents.trialStarted,
          AnalyticsEvents.subscriptionStarted,
          AnalyticsEvents.subscriptionCancelled,
        ]),
      );
    });
  });
}
