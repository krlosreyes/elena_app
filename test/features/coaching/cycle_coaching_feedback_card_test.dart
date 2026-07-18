// SPEC-194 RF-194-05 — widget test del card de feedback de cierre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/application/feature_gate.dart';
import 'package:elena_app/src/features/coaching/application/coaching_providers.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_feedback.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/cycle_coaching_feedback_card.dart';

Widget _wrap(CoachingFeedback? feedback) {
  return ProviderScope(
    overrides: [
      coachingClosureFeedbackProvider.overrideWith((ref) => feedback),
      // SPEC-197: el feedback de cierre es Premium; el test corre como premium.
      featureGateProvider.overrideWithValue(
          const FeatureGate(isPremium: true, isInTrial: false)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: CycleCoachingFeedbackCard()),
    ),
  );
}

void main() {
  testWidgets('renderiza el mensaje de feedback', (tester) async {
    await tester.pumpWidget(
      _wrap(const CoachingFeedback(
        outcome: CoachingOutcome.notCompleted,
        message: 'Ayer te propuse enfocarte en tu sueño. Sin culpa.',
      )),
    );
    expect(
      find.text('Ayer te propuse enfocarte en tu sueño. Sin culpa.'),
      findsOneWidget,
    );
  });

  testWidgets('feedback null → no renderiza', (tester) async {
    await tester.pumpWidget(_wrap(null));
    expect(find.byType(CycleCoachingFeedbackCard), findsOneWidget);
    expect(find.byIcon(Icons.eco_outlined), findsNothing); // shrink, sin card
  });
}
