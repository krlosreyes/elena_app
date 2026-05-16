// SPEC-117: tests funcionales + golden del PillarsHeatmap.

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/pillars_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );

DailySummaryDoc _doc(
  String date, {
  double f = 0,
  double s = 0,
  double h = 0,
  double e = 0,
  double m = 0,
}) =>
    DailySummaryDoc(
      date: date,
      imrScore: 70,
      fastingProgress: f,
      sleepProgress: s,
      hydrationProgress: h,
      exerciseProgress: e,
      mealsProgress: m,
      updatedAt: DateTime(2026, 5, 16),
    );

void main() {
  group('PillarsHeatmap funcional', () {
    testWidgets('modo snapshot (<3 días): muestra TU DÍA + barras de pilar',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PillarsHeatmap(
          docs: [_doc('2026-05-16', f: 1.0, s: 0.8, h: 0.5, e: 0.7, m: 0.3)],
          daysInPeriod: 7,
        ),
      ));
      expect(find.text('TU DÍA'), findsOneWidget);
      expect(find.text('Ayuno'), findsOneWidget);
      expect(find.text('Sueño'), findsOneWidget);
      expect(find.text('Hidrat.'), findsOneWidget);
      expect(find.text('Ejerc.'), findsOneWidget);
      expect(find.text('Comidas'), findsOneWidget);
      // Porcentajes
      expect(find.text('100%'), findsOneWidget); // Ayuno
      expect(find.text('80%'), findsOneWidget); // Sueño
      expect(find.text('50%'), findsOneWidget); // Hidrat
      expect(find.text('70%'), findsOneWidget); // Ejerc
      expect(find.text('30%'), findsOneWidget); // Comidas
    });

    testWidgets('modo heatmap (≥3 días): muestra CUMPLIMIENTO POR PILAR',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PillarsHeatmap(
          docs: [
            _doc('2026-05-14', f: 1.0, s: 0.7, h: 0.5, e: 0.6, m: 0.4),
            _doc('2026-05-15', f: 0.9, s: 0.8, h: 0.6, e: 0.7, m: 0.5),
            _doc('2026-05-16', f: 1.0, s: 0.9, h: 0.7, e: 0.8, m: 0.6),
          ],
          daysInPeriod: 7,
        ),
      ));
      expect(find.text('CUMPLIMIENTO POR PILAR'), findsOneWidget);
      // Pilares en columna izquierda
      expect(find.text('Ayuno'), findsOneWidget);
      expect(find.text('Sueño'), findsOneWidget);
      // Columna PROM a la derecha
      expect(find.text('PROM'), findsOneWidget);
    });

    testWidgets('modo snapshot vacío: muestra mensaje informativo',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const PillarsHeatmap(docs: [], daysInPeriod: 7),
      ));
      expect(find.text('TU DÍA'), findsOneWidget);
      expect(find.textContaining('Aún no tienes registros'), findsOneWidget);
    });
  });

  group('PillarsHeatmap golden', () {
    testWidgets('modo snapshot 1 día — golden', (tester) async {
      await tester.pumpWidget(_wrap(
        PillarsHeatmap(
          docs: [_doc('2026-05-16', f: 1.0, s: 0.7, h: 0.5, e: 0.6, m: 0.3)],
          daysInPeriod: 7,
        ),
      ));
      await expectLater(
        find.byType(PillarsHeatmap),
        matchesGoldenFile('goldens/pillars_heatmap_snapshot.png'),
      );
    });
  });
}
