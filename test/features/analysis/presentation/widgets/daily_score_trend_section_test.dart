// SPEC-200: tests del DailyScoreTrendSection (Score del Día día a día).

import 'package:elena_app/src/features/analysis/presentation/widgets/daily_score_trend_section.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_trend_chart.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: SingleChildScrollView(child: DailyScoreTrendSection()),
        ),
      ),
    );

void main() {
  testWidgets('sin historial → no renderiza la sección', (tester) async {
    await tester.pumpWidget(_wrap([
      dailyScoreTrendProvider.overrideWithValue(const []),
    ]));
    expect(find.text('Score del día'), findsNothing);
    expect(find.byType(ImrTrendChart), findsNothing);
  });

  testWidgets('con historial → renderiza chart con promedio', (tester) async {
    await tester.pumpWidget(_wrap([
      dailyScoreTrendProvider.overrideWithValue(const [
        (date: '2026-06-04', value: 60),
        (date: '2026-06-05', value: 80),
        (date: '2026-06-06', value: 70),
      ]),
    ]));
    expect(find.text('Score del día'), findsOneWidget);
    expect(find.byType(ImrTrendChart), findsOneWidget);
    // Promedio (60+80+70)/3 = 70.
    expect(find.textContaining('Promedio · 70'), findsOneWidget);
    expect(find.text('SCORE DEL DÍA · DÍA A DÍA'), findsOneWidget);
  });
}
