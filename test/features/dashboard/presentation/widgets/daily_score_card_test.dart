// SPEC-140 §8.3: tests de widget del DailyScoreCard.

import 'package:elena_app/src/features/dashboard/presentation/widgets/daily_score_card.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required int score, int? delta}) {
  return ProviderScope(
    overrides: [
      dailyScoreProvider.overrideWithValue(score),
      dailyScoreDeltaProvider.overrideWithValue(delta),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Center(child: DailyScoreCard()),
      ),
    ),
  );
}

void main() {
  group('SPEC-140 — DailyScoreCard', () {
    testWidgets('Renderiza el número del provider', (tester) async {
      await tester.pumpWidget(_wrap(score: 87));
      await tester.pumpAndSettle();

      expect(find.text('87'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
      expect(find.text('TU DÍA'), findsOneWidget);
    });

    testWidgets('Renderiza 0 cuando score es 0', (tester) async {
      await tester.pumpWidget(_wrap(score: 0));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Renderiza 100 cuando score es 100', (tester) async {
      await tester.pumpWidget(_wrap(score: 100));
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('Muestra delta positivo con flecha arriba', (tester) async {
      await tester.pumpWidget(_wrap(score: 87, delta: 12));
      await tester.pumpAndSettle();
      expect(find.text('12 vs ayer'), findsOneWidget);
      expect(find.text('↑'), findsOneWidget);
    });

    testWidgets('Muestra delta negativo con flecha abajo', (tester) async {
      await tester.pumpWidget(_wrap(score: 60, delta: -13));
      await tester.pumpAndSettle();
      expect(find.text('13 vs ayer'), findsOneWidget);
      expect(find.text('↓'), findsOneWidget);
    });

    testWidgets('Delta 0 muestra "igual que ayer"', (tester) async {
      await tester.pumpWidget(_wrap(score: 75, delta: 0));
      await tester.pumpAndSettle();
      expect(find.text('igual que ayer'), findsOneWidget);
    });

    testWidgets('Delta null oculta el label de comparación', (tester) async {
      await tester.pumpWidget(_wrap(score: 75, delta: null));
      await tester.pumpAndSettle();
      expect(find.textContaining('vs ayer'), findsNothing);
      expect(find.text('igual que ayer'), findsNothing);
    });

    testWidgets('Tap en icono ⓘ abre el BottomSheet', (tester) async {
      await tester.pumpWidget(_wrap(score: 75));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('daily_score_info_button')));
      await tester.pumpAndSettle();

      // El sheet contiene el título y los 5 pilares con porcentaje.
      expect(find.text('Tu Score del Día'), findsOneWidget);
      expect(find.text('Sueño'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Ayuno'), findsOneWidget);
      expect(find.text('22%'), findsOneWidget);
      expect(find.text('Ejercicio'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('Nutrición'), findsOneWidget);
      expect(find.text('18%'), findsOneWidget);
      expect(find.text('Hidratación'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
    });

    testWidgets('Sheet incluye disclaimer Score del Día vs IMR',
        (tester) async {
      await tester.pumpWidget(_wrap(score: 75));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('daily_score_info_button')));
      await tester.pumpAndSettle();

      // El disclaimer vive al final del ListView del sheet
      // (DraggableScrollableSheet con initialChildSize 0.55) — scroll
      // para forzar renderizado lazy del último item.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('IMR'),
        findsOneWidget,
        reason: 'El disclaimer debe mencionar el IMR para distinguir métricas',
      );
      expect(
        find.textContaining('más lento'),
        findsOneWidget,
      );
    });
  });
}
