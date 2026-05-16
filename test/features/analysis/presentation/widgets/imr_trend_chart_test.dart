// SPEC-117: tests funcionales + golden del ImrTrendChart.

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );

DailySummaryDoc _doc(String date, int imr) => DailySummaryDoc(
      date: date,
      imrScore: imr,
      fastingProgress: 0,
      sleepProgress: 0,
      hydrationProgress: 0,
      exerciseProgress: 0,
      mealsProgress: 0,
      updatedAt: DateTime(2026, 5, 16),
    );

void main() {
  group('ImrTrendChart funcional', () {
    testWidgets('sin datos muestra estado vacío', (tester) async {
      await tester.pumpWidget(_wrap(
        const ImrTrendChart(docs: [], daysInPeriod: 7),
      ));
      expect(find.text('IMR DÍA A DÍA'), findsOneWidget);
      // El header chip de promedio NO debe aparecer (no hay data).
      expect(find.textContaining('Promedio ·'), findsNothing);
    });

    testWidgets('con 1 día muestra chip de promedio pero oculta footer',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ImrTrendChart(
          docs: [_doc('2026-05-16', 75)],
          daysInPeriod: 7,
        ),
      ));
      expect(find.textContaining('Promedio · 75'), findsOneWidget);
      // 1 día → no hay mejor/peor distinguible → footer oculto.
      expect(find.text('Mejor'), findsNothing);
      expect(find.text('Peor'), findsNothing);
    });

    testWidgets('con varios días muestra chips Mejor/Peor en footer',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ImrTrendChart(
          docs: [
            _doc('2026-05-10', 60),
            _doc('2026-05-12', 82),
            _doc('2026-05-14', 54),
            _doc('2026-05-16', 75),
          ],
          daysInPeriod: 7,
        ),
      ));
      expect(find.text('Mejor'), findsOneWidget);
      expect(find.text('Peor'), findsOneWidget);
      // Promedio (60+82+54+75)/4 = 67.75 ≈ 68
      expect(find.textContaining('Promedio · 68'), findsOneWidget);
      // Valores extremos.
      expect(find.textContaining('82 · 12 may'), findsOneWidget);
      expect(find.textContaining('54 · 14 may'), findsOneWidget);
    });
  });

  group('ImrTrendChart golden', () {
    testWidgets('semana con varios datos — golden', (tester) async {
      await tester.pumpWidget(_wrap(
        ImrTrendChart(
          docs: [
            _doc('2026-05-10', 60),
            _doc('2026-05-11', 65),
            _doc('2026-05-12', 82),
            _doc('2026-05-13', 70),
            _doc('2026-05-14', 54),
            _doc('2026-05-15', 72),
            _doc('2026-05-16', 75),
          ],
          daysInPeriod: 7,
        ),
      ));
      await expectLater(
        find.byType(ImrTrendChart),
        matchesGoldenFile('goldens/imr_trend_week_full.png'),
      );
    });
  });
}
