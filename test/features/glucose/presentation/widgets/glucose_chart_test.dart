// Módulo "Tu Glucosa" — tests de GlucoseChart (rediseño 23-nov).

import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );

/// El painter es privado; se identifica por su nombre en tiempo de
/// ejecución para no afirmar sobre los CustomPaint internos de Flutter.
final Finder _chartPainter = find.byWidgetPredicate(
  (w) =>
      w is CustomPaint &&
      (w.painter?.runtimeType.toString().contains('GlucoseChartPainter') ??
          false),
  description: 'CustomPaint del GlucoseChart',
);

final _now = DateTime(2026, 11, 23, 9);

GlucoseReading _reading(int value, int daysAgo,
        [GlucoseReadingContext c = GlucoseReadingContext.ayunas]) {
  final at = _now.subtract(Duration(days: daysAgo));
  return GlucoseReading(
    id: 'r-$daysAgo-$value-${c.name}',
    userId: 'u1',
    valueMgDl: value,
    context: c,
    measuredAt: at,
    symptomsReported: const [],
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  group('GlucoseChart', () {
    testWidgets('sin lecturas muestra estado vacío, sin gráfica',
        (tester) async {
      await tester.pumpWidget(_wrap(const GlucoseChart(readings: [])));
      expect(
          find.text('Todavía no hay lecturas para graficar.'), findsOneWidget);
      expect(_chartPainter, findsNothing);
    });

    testWidgets('con 1 lectura pinta, muestra su zona y la fuente',
        (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [_reading(95, 1)],
      )));
      expect(_chartPainter, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('En rango'), findsWidgets);
      expect(find.text('1 de 1 lectura en rango (100 %)'), findsOneWidget);
      expect(find.text('Rangos de referencia: ADA 2025'), findsOneWidget);
    });

    testWidgets('valores iguales no rompen la escala', (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [_reading(90, 3), _reading(90, 2), _reading(90, 1)],
      )));
      expect(_chartPainter, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('resume lecturas en rango, promedio y extremos',
        (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [_reading(80, 3), _reading(105, 2), _reading(130, 1)],
      )));
      expect(find.text('1 de 3 lecturas en rango (33 %)'), findsOneWidget);
      expect(find.text('Promedio 105 mg/dL · mínimo 80 · máximo 130'),
          findsOneWidget);
      expect(find.text('Elevado 1'), findsOneWidget);
      expect(find.text('Alto 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pestañas por contexto solo si hay ayunas y 2 h',
        (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [_reading(90, 1)],
      )));
      expect(find.text('2 h después de comer'), findsNothing);

      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [
          _reading(90, 1),
          _reading(150, 1, GlucoseReadingContext.postprandial2h),
        ],
      )));
      expect(find.text('En ayunas'), findsOneWidget);
      await tester.tap(find.text('2 h después de comer'));
      await tester.pumpAndSettle();
      expect(find.text('150 mg/dL'), findsOneWidget);
      expect(find.textContaining('prueba de tolerancia oral'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la ventana de días filtra las lecturas', (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [_reading(90, 20), _reading(110, 2)],
      )));
      expect(find.text('1 de 2 lecturas en rango (50 %)'), findsOneWidget);
      await tester.tap(find.text('14 días'));
      await tester.pumpAndSettle();
      expect(find.text('0 de 1 lectura en rango (0 %)'), findsOneWidget);
    });

    testWidgets('sin lecturas en la ventana lo dice', (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [_reading(90, 60)],
      )));
      expect(find.text('Sin lecturas en ayunas en los últimos 30 días.'),
          findsOneWidget);
      expect(_chartPainter, findsOneWidget);
    });

    testWidgets('solo momentos sin rango ADA: explica en vez de graficar',
        (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [_reading(120, 1, GlucoseReadingContext.antesDeDormir)],
      )));
      expect(find.textContaining('sin rango de referencia'), findsOneWidget);
      expect(_chartPainter, findsNothing);
    });

    testWidgets('tocar la gráfica selecciona la lectura más cercana',
        (tester) async {
      await tester.pumpWidget(_wrap(GlucoseChart(
        now: _now,
        readings: [_reading(80, 28), _reading(120, 1)],
      )));
      expect(find.text('120 mg/dL'), findsOneWidget);
      // Misma geometría que el painter: área útil de x = 32 a ancho − 6,
      // ventana de 30 días. La lectura de hace 28 días cae en 2/30.
      final rect = tester.getRect(_chartPainter);
      final x = rect.left + 32 + (2 / 30) * (rect.width - 38);
      await tester.tapAt(Offset(x, rect.center.dy));
      await tester.pump();
      expect(find.text('80 mg/dL'), findsOneWidget);
    });
  });
}
