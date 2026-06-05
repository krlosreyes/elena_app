// SPEC-170 §RF-170-04 (2026-06-04): widget tests del DualScoreRing.
//
// Validan render con/sin delta, render del IMR, callback de tap. El
// widget es stateless puro — no necesita ProviderContainer.

import 'package:elena_app/src/features/dashboard/presentation/widgets/dual_score_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))),
    );

void main() {
  group('SPEC-170 §RF-170-04 — DualScoreRing render', () {
    testWidgets('muestra ambos scores y labels HOY + IMR', (tester) async {
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 87,
          dailyDelta: 5,
          imrScore: 64,
          onTap: () {},
        ),
      ));

      expect(find.text('87'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('IMR'), findsOneWidget);
    });

    testWidgets('muestra sub-label de delta positivo en HOY',
        (tester) async {
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 87,
          dailyDelta: 5,
          imrScore: 64,
          onTap: () {},
        ),
      ));

      expect(find.text('↑5 vs ayer'), findsOneWidget);
    });

    testWidgets('muestra sub-label de delta negativo en HOY',
        (tester) async {
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 75,
          dailyDelta: -3,
          imrScore: 64,
          onTap: () {},
        ),
      ));

      expect(find.text('↓3 vs ayer'), findsOneWidget);
    });

    testWidgets('delta cero rinde "igual que ayer"', (tester) async {
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 80,
          dailyDelta: 0,
          imrScore: 64,
          onTap: () {},
        ),
      ));

      expect(find.text('igual que ayer'), findsOneWidget);
    });

    testWidgets('delta null no rinde sub-label de delta (espacio reservado)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 50,
          dailyDelta: null,
          imrScore: 64,
          onTap: () {},
        ),
      ));

      // No debe aparecer ningún texto con "ayer" — solo el placeholder
      // de espacio reservado para mantener altura.
      expect(find.textContaining('vs ayer'), findsNothing);
      expect(find.textContaining('igual'), findsNothing);
    });

    testWidgets('IMR siempre muestra sub-label "tu base"', (tester) async {
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 87,
          dailyDelta: 5,
          imrScore: 64,
          onTap: () {},
        ),
      ));

      expect(find.text('tu base'), findsOneWidget);
    });

    testWidgets('score 0 rinde sin crash', (tester) async {
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 0,
          dailyDelta: null,
          imrScore: 0,
          onTap: () {},
        ),
      ));

      // Dos textos con "0" — uno en cada ring.
      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('score 100 rinde sin crash', (tester) async {
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 100,
          dailyDelta: 0,
          imrScore: 100,
          onTap: () {},
        ),
      ));

      expect(find.text('100'), findsNWidgets(2));
    });
  });

  group('SPEC-170 — interacción', () {
    testWidgets('tap dispara onTap callback', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(_wrap(
        DualScoreRing(
          dailyScore: 87,
          dailyDelta: 5,
          imrScore: 64,
          onTap: () => tapCount++,
        ),
      ));

      await tester.tap(find.byType(DualScoreRing));
      expect(tapCount, 1);
    });
  });
}
