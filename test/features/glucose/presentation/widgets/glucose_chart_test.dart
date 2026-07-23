// Módulo "Tu Glucosa" — tests funcionales de GlucoseChart. Widget sin
// dependencia de Riverpod (StatelessWidget puro) — mismo patrón de
// wrapping que imr_trend_chart_test.dart. Cubre el estado vacío y que
// el CustomPaint no lance excepciones con 1 o varias lecturas
// (incluyendo min==max, caso borde del clamp de rango en el painter).

import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );

GlucoseReading _reading(int value, DateTime measuredAt) => GlucoseReading(
      id: 'r-${measuredAt.millisecondsSinceEpoch}',
      userId: 'u1',
      valueMgDl: value,
      context: GlucoseReadingContext.ayunas,
      measuredAt: measuredAt,
      symptomsReported: const [],
      createdAt: measuredAt,
      updatedAt: measuredAt,
    );

void main() {
  group('GlucoseChart', () {
    testWidgets('sin lecturas muestra estado vacío, sin CustomPaint',
        (tester) async {
      await tester.pumpWidget(_wrap(const GlucoseChart(readings: [])));
      expect(find.text('Todavía no hay lecturas para graficar.'),
          findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('con 1 lectura renderiza sin excepción (xFor divide por 0 '
        'evitado)', (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(readings: [
        _reading(95, DateTime(2026, 7, 20)),
      ])));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('con varias lecturas de igual valor (range==0, clamp a 1) '
        'renderiza sin excepción', (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(readings: [
        _reading(90, DateTime(2026, 7, 18)),
        _reading(90, DateTime(2026, 7, 19)),
        _reading(90, DateTime(2026, 7, 20)),
      ])));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('con lecturas variadas dentro y fuera de la banda 100 '
        'renderiza sin excepción', (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(readings: [
        _reading(80, DateTime(2026, 7, 18)),
        _reading(105, DateTime(2026, 7, 19)),
        _reading(130, DateTime(2026, 7, 20)),
      ])));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
