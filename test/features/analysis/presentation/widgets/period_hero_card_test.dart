// SPEC-117: tests funcionales + golden del PeriodHeroCard.

import 'package:elena_app/src/features/analysis/domain/period_comparison.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/period_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );

PeriodComparison _comp({
  required int avg,
  int? today,
  int? bestImr,
  DateTime? bestDate,
  int? worstImr,
  DateTime? worstDate,
}) =>
    PeriodComparison(
      imrAverage: avg,
      imrAveragePrevious: null,
      imrToday: today,
      bestDayImr: bestImr,
      bestDayDate: bestDate,
      worstDayImr: worstImr,
      worstDayDate: worstDate,
      daysWithData: 1,
      daysInPeriod: 7,
    );

void main() {
  group('PeriodHeroCard funcional', () {
    testWidgets('con HOY=85 muestra ring grande y delta verde positivo',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PeriodHeroCard(
          data: _comp(
            avg: 70,
            today: 85,
            // Best/worst con valores distintos al today para evitar
            // duplicados en `find.text` y poder afirmar de forma única.
            bestImr: 92,
            bestDate: DateTime(2026, 5, 12),
            worstImr: 54,
            worstDate: DateTime(2026, 5, 14),
          ),
          periodLabel: 'Semana',
        ),
      ));

      expect(find.text('85'), findsOneWidget); // HOY
      expect(find.text('70'), findsOneWidget); // PROMEDIO
      expect(find.text('92'), findsOneWidget); // MEJOR
      expect(find.text('54'), findsOneWidget); // PEOR
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('PROMEDIO'), findsOneWidget);
      // Delta +15 vs promedio.
      expect(find.textContaining('+15 vs tu promedio'), findsOneWidget);
    });

    testWidgets('sin HOY muestra "—" y mensaje de placeholder',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PeriodHeroCard(
          data: _comp(avg: 0),
          periodLabel: 'Semana',
        ),
      ));

      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('Registra tu día'), findsOneWidget);
    });

    testWidgets('con HOY < PROMEDIO muestra delta rojo negativo',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PeriodHeroCard(
          data: _comp(avg: 70, today: 60),
          periodLabel: 'Mes',
        ),
      ));
      expect(find.textContaining('-10 vs tu promedio'), findsOneWidget);
    });

    testWidgets('eyebrow refleja el periodLabel en mayúscula', (tester) async {
      await tester.pumpWidget(_wrap(
        PeriodHeroCard(
          data: _comp(avg: 50, today: 50),
          periodLabel: '3 Meses',
        ),
      ));
      expect(find.text('TU IMR · 3 MESES'), findsOneWidget);
    });
  });

  group('PeriodHeroCard golden', () {
    testWidgets('estado típico semana — golden', (tester) async {
      await tester.pumpWidget(_wrap(
        PeriodHeroCard(
          data: _comp(
            avg: 68,
            today: 75,
            bestImr: 82,
            bestDate: DateTime(2026, 5, 12),
            worstImr: 54,
            worstDate: DateTime(2026, 5, 14),
          ),
          periodLabel: 'Semana',
        ),
      ));
      await expectLater(
        find.byType(PeriodHeroCard),
        matchesGoldenFile('goldens/period_hero_typical_week.png'),
      );
    });

    testWidgets('estado vacío — golden', (tester) async {
      await tester.pumpWidget(_wrap(
        PeriodHeroCard(
          data: PeriodComparison.empty(7),
          periodLabel: 'Semana',
        ),
      ));
      await expectLater(
        find.byType(PeriodHeroCard),
        matchesGoldenFile('goldens/period_hero_empty.png'),
      );
    });
  });
}
